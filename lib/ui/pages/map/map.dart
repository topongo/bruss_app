import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:bruss/api.dart';
import 'package:bruss/data/area_type.dart';
import 'package:bruss/data/path.dart' as br;
import 'package:bruss/data/route.dart' as br;
import 'package:bruss/data/schedule.dart';
import 'package:bruss/data/segment.dart';
import 'package:bruss/data/stop.dart';
import 'package:bruss/data/trip_bundle.dart';
import 'package:bruss/main.dart';
import 'package:bruss/settings/init.dart';
import 'package:bruss/ui/pages/map/fast_marker_layer.dart';
import 'package:bruss/ui/pages/map/markers.dart';
import 'package:bruss/ui/pages/map/sheet/details.dart';
import 'package:flutter/material.dart';
import 'package:bruss/database/database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:bruss/ui/pages/map/sheet/details_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

const trento = LatLng(46.0620, 11.1294);
final selectedEntity = ValueNotifier<DetailsType?>(null);

class MapDrawable {
  MapDrawable({
    required this.polylines,
    List<FastMarker>? extraMarkers,
  }) : _extraMarkers = extraMarkers;

  factory MapDrawable.withArrows(List<Polyline> polylines, Color primaryColor) {
    final List<FastMarker> extraMarkers = [];
    final dark = primaryColor.computeLuminance() > 0.5;
    for (final polyline in polylines) {
      LatLng? lastDrawn;
      const d = Distance();
      for (int i = 0; i < polyline.points.length - 1; i++)  {
        final start = polyline.points[i];
        final end = polyline.points[i + 1];
        final mid = LatLng(
          (start.latitude + end.latitude) / 2,
          (start.longitude + end.longitude) / 2,
        );
        final distance = lastDrawn == null ? double.infinity : d.distance(lastDrawn, mid);
        if (distance > 200) {
          extraMarkers.add(
            FastMarker(
              position: mid,
              type: dark ? MarkerType.blackArrow : MarkerType.whiteArrow,
              rotation: d.bearing(start, end),
            )
          );
          lastDrawn = mid;
        } else {
          // print("distance is $distance < 200, skipping");
        }
      }
    }
    // print("===> EXTRA MARKERS GENERATED: ${extraMarkers.length}");
    return MapDrawable(
      polylines: polylines,
      extraMarkers: extraMarkers,
    );
  }

  factory MapDrawable.empty() {
    return MapDrawable(polylines: []);
  }

  MapDrawable recreate() {
    return MapDrawable(
      polylines: polylines,
      extraMarkers: _extraMarkers,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! MapDrawable) return false;
    if (key != other.key) return false;
    return this == other;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }

  Iterable<FastMarker> visibleExtraMarkers(MapCamera? camera) {
    if (camera == null) return [];
    return _extraMarkers?.where((e) => camera.visibleBounds.contains(e.position)) ?? [];
  }

  final List<Polyline> polylines;
  final List<FastMarker>? _extraMarkers;
  final Key key = UniqueKey();
}

class MapInteractor {
  static final MapInteractor _instance = MapInteractor._internal();

  factory MapInteractor() {
    if (!_instance._positionReady) throw "MapInteractor not ready!";
    return _instance;
  }

  MapInteractor._internal();

  static const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );

  final ValueNotifier<MapDrawable> drawableNotifier = ValueNotifier(MapDrawable.empty());
  final Map<String, br.Path> paths = {};
  final Map<(AreaType, int, int), Segment> segments = {};
  final Map<(AreaType, int), Stop> stops = {};
  bool _positionReady = false;

  AnimatedMapController? _animationController;
  MapMarkerProvider? _mapMarkerProvider;
  Schedule? _focusedSched;
  br.Route? _focusedRoute;
  Stream<Position>? _positionStream;
  StreamSubscription<Position>? _positionStreamSubscription;
  Stream<ServiceStatus>? _positionServiceStream;
  StreamSubscription<LatLng?>? _focusedSchedBusPositionSub;
  ValueNotifier<Marker?> busMarker = ValueNotifier(null);
  final StreamController<LatLng?> busMarkerStream = StreamController<LatLng?>.broadcast();
  final ValueNotifier<LatLng?> userPosition = ValueNotifier(null);
  final ValueNotifier<bool> locationServiceEnabled = ValueNotifier(false);
  late final bool _platformSupportsLocation;

  bool get isTripFocused => _focusedSched != null;
  Schedule? get focusedSched => _focusedSched;
  LatLng? get currentPosition => _animationController?.mapController.camera.center;

  static void init() {
    _instance._positionReady = true;
    _instance._busMarkerStream();
  }


  Polyline polylineGen(String pathId, Color color, {double strokeWidth = 6.0}) {
    final List<LatLng> points = paths[pathId]!.stopPairsType()
      .map((e) => segments[e]!.geometry)
      .expand((e) => e)
      .toList();

    return Polyline(
      points: points,
      color: color,
      strokeWidth: strokeWidth,
    );
  }

  Future<void> fetchStops(Set<(AreaType, int)> stopsToFetch) async {
    if (stopsToFetch.isEmpty) return;
    final fetched = await BrussDB().getStopsById(stopsToFetch);
    for (final stop in fetched) {
      stops[(stop.type, stop.id)] = stop;
    }
  }

  Future<void> fetchPathSegments(String id) async {
    final path = paths[id]!;
    final requested = path.stopPairs();
    final Set<(int, int)> missing = {for (final m in requested) if(!segments.containsKey((path.type, m.$1, m.$2))) m};
    if (missing.isEmpty) return;
    final fetched = (await BrussApi.request(Segment.apiGet(path.type, missing))).unwrap();
    final stopsToFetch = <(AreaType, int)>{};
    for (final s in fetched) {
      if (!stops.containsKey((path.type, s.from))) {
        stopsToFetch.add((path.type, s.from));
      }
      if (!stops.containsKey((path.type, s.to))) {
        stopsToFetch.add((path.type, s.to));
      }
      segments[(path.type, s.from, s.to)] = s;
    }

    await fetchStops(stopsToFetch);
  }

  Future<void> focusOnSched(Schedule sched, br.Route route) async {
    if (_focusedSched != null) {
      // already focused
      if (ScheduleKey.fromSched(_focusedSched!) == ScheduleKey.fromSched(sched)) {
        // same schedule: update only the schedule object
        _focusedSched = sched;
        return;
      } else {
        // unfocus current schedule
        await unfocusSched();
        // then continue
      }
    }

    final pathId = sched.trip.path;
    if (!paths.containsKey(pathId)) {
      await getPaths({pathId});
    }
    await fetchPathSegments(pathId);
    // print("RENDERING POLYLINE FOR $pathId");
    final geometry = polylineGen(pathId, route.color);
    drawableNotifier.value = MapDrawable.withArrows(
      [geometry],
      route.color,
    );
    // print("===> drawable generated (${drawableNotifier.value!._extraMarkers!.length} extra markers)! listeners will be notified");
    _mapMarkerProvider!.setMarkerFilters([TripMarkerFilter(sched.trip, typeProxy: MarkerType.simpleStop)], (marker) {
      if (marker is StopMarker) {
        return StopMarker(marker.entity, type: MarkerType.simpleStop);
      } else {
        return marker;
      }
    });
    _focusedSched = sched;
    _focusedRoute = route;
    busMarker.value = null;
    _focusedSchedBusPositionSub?.cancel();
    _focusedSchedBusPositionSub = busMarkerStream.stream.listen(
      (pos) {
          if (pos == null) {
            busMarker.value = null;
          } else {
            busMarker.value = Marker(
              point: pos,
              width: BusMarker.size,
              height: BusMarker.size,
              child: BusMarker(color: route.color),
            );
          }
        },
      );
    triggerMapUpdate();
  }

  void focusOnStop(Stop stop, {bool withZoom = false}) {
    // print("====> focus on stop: ${selectedEntity.value!.sheetSize/2}");
    _animationController!.animateTo(dest: stop.position, zoom: withZoom ? 18 : null, offset: Offset(0, -selectedEntity.value!.sheetSize/2)).then((_) {
      _mapMarkerProvider!.reloadMarkers(_animationController!.mapController.camera);
    });
  }

  Future<void> focusOnUser() async {
    if (userPosition.value == null) {
      final pos = await _positionStream!.take(1).first;
      userPosition.value = LatLng(pos.latitude, pos.longitude);
    }
    LatLng position = userPosition.value!;
    final offset = Offset(0, -(selectedEntity.value?.sheetSize ?? 0) / 2);
    await _animationController!.animateTo(dest: position, zoom: 17, offset: offset);
    _mapMarkerProvider!.reloadMarkers(_animationController!.mapController.camera);
  }

  Future<void> unfocusSched() async {
    _focusedSched = null;
    _focusedRoute = null;
    _focusedSchedBusPositionSub?.cancel();
    busMarker.value = null;
    _mapMarkerProvider!.unsetMarkerFilters();
    await _mapMarkerProvider!.reloadMarkers(_animationController!.mapController.camera);
    // this also triggers a map update
    drawableNotifier.value = MapDrawable.empty();
  }

  Future<void> getPaths(Set<String> ids) async {
    final paths = await br.Path.getPathsCached(ids.toSet());
    for (final path in paths) {
      this.paths[path.id] = path;
      // await fetchPathSegments(path.id);
    }
  }

  void register(AnimatedMapController controller, MapMarkerProvider mapMarkerProvider) {
    _animationController = controller;
    _mapMarkerProvider = mapMarkerProvider;
    selectedEntity.addListener(() {
      // print("================> RECEIVED EVENT FROM MAPINTERACTOR: ${selectedEntity.value}");
      if (selectedEntity.value == null) {
        if (_focusedSched != null) {
          unfocusSched();
        }
      } else {
        if (selectedEntity.value is StopDetails) {
          final stop = selectedEntity.value! as StopDetails;
          focusOnStop(stop.stop);
        } else if (selectedEntity.value is RouteDetails) {
          final route = selectedEntity.value! as RouteDetails;
          _focusedRoute = route.route;
        }
      }
    });

    // start position tracking if platform supports it.
    if (!Platform.isLinux) {
      () async {
        print("===> checking location permission");
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.deniedForever) {
          return;
        }
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
          permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
            // permission denied, do nothing
            return;
          }
        }

        _positionServiceStream = Geolocator.getServiceStatusStream();
        _positionServiceStream!.listen(_onPositionServiceChange);
        if (await Geolocator.isLocationServiceEnabled()) {
          _onPositionServiceChange(ServiceStatus.enabled);
        }
      }();
    }
  }

  void _onPositionServiceChange(ServiceStatus status) {
    print("===> position stream status changed: $status");
    if (status == ServiceStatus.disabled) {
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
      _positionStream = null;
      userPosition.value = null;
      locationServiceEnabled.value = false;
    } else {
      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings);
      _positionStreamSubscription = _positionStream!.listen(
        _onNewPosition,
        onError: (e) {
          debugPrint("warning: tried to get position but got error: $e");
        },
        cancelOnError: false,
      );
      locationServiceEnabled.value = true;
    }
  }

  void _onNewPosition(Position? position) {
    print("===> got user new position: $position");
    if (position == null) {
      userPosition.value = null;
    } else {
      userPosition.value = LatLng(position.latitude, position.longitude);
    }
  }

  void triggerMapUpdate() {
    drawableNotifier.value = drawableNotifier.value.recreate();
  }

  Future<void> _busMarkerStream() async {
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      if (_focusedSched == null) {
        busMarkerStream.add(null);
        continue;
      }
      final sched = _focusedSched!;
      if (sched.trip.nextStop == null || sched.trip.lastStop == null) {
        busMarkerStream.add(null);
        continue;
      }
      final nextStop = sched.trip.nextStop!;
      final lastStop = sched.trip.lastStop!;
      assert(lastStop != 0 && nextStop != 0);
      final departureFromLastStop = sched.departFromStopWithDelay(lastStop).toLocal();
      final arrivalAtNextStop = sched.arriveAtStopWithDelay(nextStop).toLocal();
      final timeInterval = arrivalAtNextStop.difference(departureFromLastStop);
      final double percent;

      final now = DateTime.now();
      final String debugPercentReason;
      if (lastStop == nextStop) {
        // bus has arrived
        percent = 1;
        debugPercentReason = "bus arrived (lastStop == nextStop)";
      } else if (timeInterval.inSeconds == 0) {
        if (sched.trip.lastEvent == null) {
          // we have no way to calculate the bus position
          percent = .5;
          debugPercentReason = "timeInterval is 0 and no lastEvent";
        } else {
          final timeFromLastEvent = now.difference(sched.trip.lastEvent!.toLocal());
          if ((sched.trip.delay ?? 0) == 0) {
            percent = ((timeFromLastEvent.inSeconds / (sched.trip.delay ?? 0) * 60).clamp(-1, 1) + 1) / 2;
            debugPercentReason = "timeInterval is 0 : used delay to calculate bus position";
          } else {
            percent = .5;
            debugPercentReason = "timeInterval is 0: no delay available";
          }
        }
      } else if (now.isAfter(arrivalAtNextStop)) {
        // very close to next stop
        percent = .9;
        debugPercentReason = "arrivalAtNextStop is after now";
      } else if (now.isBefore(departureFromLastStop)) {
        // at last stop
        percent = 0;
        debugPercentReason = "departureFromLastStop is before now";
      } else {
        // try to calculate actual bus position
        final timeFromLastStop = now.difference(departureFromLastStop);
        percent = timeFromLastStop.inSeconds / timeInterval.inSeconds * .9;
        debugPercentReason = "calculated based on departureFromLastStop and `now`";
      }

      // print("bus position data:\n"
      //       "  lastStop: $lastStop\n"
      //       "  nextStop: $nextStop\n"
      //       "  departureFromLastStop: $departureFromLastStop\n"
      //       "  arrivalAtNextStop: $arrivalAtNextStop\n"
      //       "  lastEvent: ${sched.trip.lastEvent?.toLocal()}\n"
      //       "  percent: $percent\n"
      //       "  percent reason: $debugPercentReason\n"
      //       "  timeInterval: $timeInterval\n");

      final LatLng busPoint;
      // check that we have both stops
      assert(stops.containsKey((sched.trip.type, lastStop)) && stops.containsKey((sched.trip.type, nextStop)), "Stops not found: ${sched.trip.type}, $lastStop, $nextStop");
      if (percent == 0) {
        busPoint = stops[(sched.trip.type, lastStop)]!.position;
      } else if (percent == 1) {
        busPoint = stops[(sched.trip.type, nextStop)]!.position;
      } else {
        final path = paths[sched.trip.path]!;

        // lastStop and nextStop should be in path and one after the other
        final lastStopIndex = path.sequence.indexOf(lastStop);
        final nextStopIndex = path.sequence.indexOf(nextStop);
        assert(lastStopIndex != -1 && nextStopIndex != -1, "Stops not in path: $lastStop, $nextStop");
        assert(lastStopIndex + 1 == nextStopIndex, "Stops not in sequence: $lastStop, $nextStop");

        final geometry = segments[(sched.trip.type, lastStop, nextStop)]!.geometry;
        double distance = 0.0;
        final List<double> distances = [0];
        for (int i = 0; i < geometry.length - 1; i++) {
          distance += (const Distance()).distance(geometry[i], geometry[i + 1]);
          distances.add(distance);
        }
        // edge cases:
        //   - bus is at position 0% => p1 is distances[0] that is always the first point
        //   - bus is at position 100% => we set p2 as distances[distances.length - 1] and p1 as distances[distances.length - 2]
        //   - the only critical case is when the float rounding is not correct: if busIndex is -1 then set it to `distances.length - 2`

        // NB: THIS INDEX REFERS TO THE GEOMETRY POINTS, NOT THE BUS STOPS.
        final busDistance = percent * distance;
        var busIndex = distances.indexWhere((d) => d >= busDistance);
        if (busIndex == -1) {
          busIndex = distances.length - 2;
        } else if (busIndex == distances.length - 1) {
          busIndex = distances.length - 2;
        }
        // print("lastStop: $lastStop, nextStop: $nextStop, busDistance: $busDistance, busIndex: $busIndex");
        final p1 = geometry[busIndex];
        final p2 = geometry[busIndex + 1];
        final pointPointDistance = distances[busIndex + 1] - distances[busIndex];
        busPoint = LatLng(
          p1.latitude + (p2.latitude - p1.latitude) * (busDistance - distances[busIndex]) / pointPointDistance,
          p1.longitude + (p2.longitude - p1.longitude) * (busDistance - distances[busIndex]) / pointPointDistance,
        );
      }

      busMarkerStream.add(busPoint);
    }
  }
}

class UserMarker extends StatelessWidget {
  const UserMarker({super.key});
  static const double size = 20;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.lightBlue,
        borderRadius: BorderRadius.circular(size),
        border: Border.all(
          color: Colors.white,
          width: 2,
        )
      )
    );
  }
}

class BusMarker extends StatelessWidget {
  BusMarker({required this.color, super.key});
  final Color color;
  late final Color contrast = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  static const double size = 40;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
        border: Border.all(
          color: Colors.white,
          width: 2,
        )
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(Icons.directions_bus, color: contrast),
        ),
      ),
    );
  }
}

class MapPage extends StatefulWidget {
  MapPage({this.initialStop, super.key});
  List<MapMarker> markers = [];
  Map<String, Polyline> cachedPolylines = {};
  DateTime? lastTriedPop;
  final Stop? initialStop;
  // stream controller for polyline updates

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  late final MapMarkerProvider mapMarkerProvider;

  final BrussDB db = BrussDB();

  @override
  void initState() {
    super.initState();

    final globalController = MapInteractor();
    final aCtrl = AnimatedMapController(vsync: this);

    mapMarkerProvider = MapMarkerProvider(() { MapInteractor().triggerMapUpdate(); });
    mapMarkerProvider.connectToMapEventStream(aCtrl.mapController.mapEventStream, /* context */);

    globalController.register(aCtrl, mapMarkerProvider);

    Settings().getConverted("map.position").then((value) {
      aCtrl.mapController.move(value, 15.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapInteractor = MapInteractor();
    final mapController = mapInteractor._animationController!.mapController;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? value) async {
        print("pop invoked!");
        if (selectedEntity.value != null) {
          selectedEntity.value = null;
        } else {
          if (widget.lastTriedPop == null || DateTime.now().difference(widget.lastTriedPop!).inSeconds > 2) {
            widget.lastTriedPop = DateTime.now();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Go back again to exit"),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            // save map position
            final position = MapInteractor().currentPosition;
            if (position != null) {
              await Settings().setConverted("map.position", position);
            }
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: ListenableBuilder(
          listenable: mapInteractor.drawableNotifier,
          builder: (context, child) {
            // check if mapController is connected
            // print("====> drawableNotifier updated");
            MapCamera? camera;
            try {
              camera = mapController.camera;
            } catch (e) {
              // print("======> MapController is not connected");
            }
            final markers = mapMarkerProvider
              .getVisibleMarkers()
              .map((m) => FastMarker.fromMapMarker(m))
              .followedBy(mapInteractor.drawableNotifier.value.visibleExtraMarkers(camera));

            return FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter:  trento,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  rotationThreshold: 100.0,
                  enableMultiFingerGestureRace: false,
                ),
                onTap: (tapPosition, tapLatLng) {
                  // print("Tapped at $tapLatLng");
                  final minMarker = mapMarkerProvider.getClosestMarker(tapLatLng);
                  if (minMarker == null) {
                    // print("No marker found");
                    return;
                  }
                  // print("Closest marker is ${(minMarker.entity as Stop).name} at ${minMarker.position}");
                  // print("The position distance is ")

                  final markerScale = markerScaleFromMapZoom(mapController.camera.zoom);
                  final screenPoint = mapController.camera.latLngToScreenPoint(minMarker.position);
                  final dx = (tapPosition.relative!.dx - screenPoint.x).abs();
                  final dy = (tapPosition.relative!.dy - screenPoint.y).abs();
                  if (max(dx, dy) < markerScale * 0.7) {
                    selectedEntity.value = minMarker.details();
                  }
                },
                onPointerUp: (pointer, center) {
                  // print("Pointer up");
                  // print(center);
                },
                onMapReady: () {
                }
                  // interactiveFlags: InteractiveFlag.rotate,
              ),
              children: [
                VectorTileLayer(
                  theme: mapStyle.theme,
                  tileProviders: mapStyle.providers,
                  sprites: mapStyle.sprites,
                  layerMode: VectorTileLayerMode.vector,
                  // urlTemplate: 'https://api-l.cofractal.com/v0/maps/vt/overture/{z}/{x}/{y}',
                  // userAgentPackageName: '',
                  // Plenty of other options available!
                ),
                PolylineLayer(polylines: mapInteractor.drawableNotifier.value.polylines),
                FastMarkersLayer(
                  markers,
                  onLoad: () {
                    mapMarkerProvider.reloadMarkers(mapController.camera);
                    if (selectedEntity.value != null) {
                      if (selectedEntity.value is StopDetails) {
                        mapInteractor.focusOnStop((selectedEntity.value! as StopDetails).stop, withZoom: true);
                      }
                    }
                  },
                ),
                ValueListenableBuilder(
                  valueListenable: mapInteractor.userPosition,
                  builder: (context, value, child) {
                    return MarkerLayer(markers: [
                      if (value != null)
                        Marker(
                          point: value,
                          width: UserMarker.size,
                          height: UserMarker.size,
                          child: const UserMarker(),
                        )
                    ]);
                  }
                ),
                ValueListenableBuilder(
                  valueListenable: mapInteractor.busMarker,
                  builder: (context, value, child) {
                    return MarkerLayer(markers: [
                      if (value != null)
                        value
                    ]);
                  }
                ),
                RichAttributionWidget(
                  animationConfig: const ScaleRAWA(), // Or `FadeRAWA` as is default
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                    ),
                  ],
                ),
                child!,
              ],
            );
          },
          child: DetailsSheet(),
        ),
        // floatingActionButton for unfocusing current trip
        floatingActionButton: ValueListenableBuilder(
          valueListenable: MapInteractor().locationServiceEnabled,
          builder: (context, value, child) {
            if (value) {
              return FloatingActionButton(
                onPressed: () async {
                  await MapInteractor().focusOnUser();
                },
                child: const Icon(Icons.my_location),
              );
            } else {
              return Container();
            }
          }
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      ),
    );
  }
}
