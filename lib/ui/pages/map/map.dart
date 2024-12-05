import 'dart:math';

import 'package:bruss/data/area_type.dart';
import 'package:bruss/data/stop.dart';
import 'package:bruss/settings/init.dart';
import 'package:bruss/ui/pages/map/fast_marker_layer.dart';
import 'package:bruss/ui/pages/map/markers.dart';
import 'package:bruss/ui/pages/map/sheet/details.dart';
import 'package:flutter/material.dart';
import 'package:bruss/database/database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:bruss/ui/pages/map/sheet/details_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

const trento = LatLng(46.0620, 11.1294);
late Style mapStyle;
final selectedEntity = ValueNotifier<DetailsType?>(null);

class MapPage extends StatefulWidget {
  MapPage({super.key});
  List<MapMarker> markers = [];

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();
  late final MapMarkerProvider mapMarkerProvider;

  final BrussDB db = BrussDB();

  @override
  void initState() {
    super.initState();

    mapMarkerProvider = MapMarkerProvider(() => setState(() {}));
    mapMarkerProvider.connectToMapEventStream(mapController.mapEventStream);
    
    Settings().getConverted("map.position").then((value) {
      mapController.move(value, 15.0);
    });
    
    db.getStops().then((stops) {
      // for(var stop in stops) {
      //   if((const Distance()).as(LengthUnit.Kilometer, trento, stop.position) > 2) continue;
      //   markers.add(Marker(
      //     width: 200,
      //     height: 50,
      //     point: stop.position,
      //     child: GestureDetector(
      //       child: const Column(
      //         children: [
      //           // Text(stop.name, style: const TextStyle(color: Colors.red)),
      //           Icon(Icons.location_on, color: Colors.red),
      //         ],
      //       ),
	     //      // old version from conflicting commit
      //       // onTap: () => showBottomSheet(
      //       //   context: context, 
      //       //   builder: (context) => StopCard(stop: stop),
      //       // ), 
	     //      // newer version
      //       onTap: () async {
      //         final route = await db.getRoute(402);
      //         setState(() {
      //           // overridden to try RouteDetails
      //           selectedEntity.value = StopDetails(stop: stop);
      //           // selectedEntity.value = RouteDetails(route: route);
      //         });
      //       },
      //     ),
      //   ));
      // 
      // }
      setState(() {
      for (final stop in stops) {
        if (stop.type != AreaType.urban) continue;
        widget.markers.add(StopMarker(stop));
      }});
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (x, y) async {
        print("aaaah! ($x, $y)");
      },
      child: Scaffold(
        body: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter:  trento,
            initialZoom: 15.0,
            interactionOptions: const InteractionOptions(
              // flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              rotationThreshold: 100.0,
              enableMultiFingerGestureRace: false,
            ),
            onTap: (tapPosition, tapLatLng) {
              print("Tapped at $tapLatLng");
              final minMarker = mapMarkerProvider.getClosestMarker(tapLatLng);
              if (minMarker == null) {
                print("No marker found");
                return;
              }
              print("Closest marker is ${(minMarker.entity as Stop).name} at ${minMarker.position}");
              // print("The position distance is ")

              final markerScale = markerScaleFromMapZoom(mapController.camera.zoom);
              final screenPoint = mapController.camera.latLngToScreenPoint(minMarker.position);
              final dx = (tapPosition.relative!.dx - screenPoint.x).abs();
              final dy = (tapPosition.relative!.dy - screenPoint.y).abs();
              if (max(dx, dy) < markerScale * 0.7) {
                selectedEntity.value = minMarker.details();
              }
            },
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
            // MouseRegion(
            //   hitTestBehavior: HitTestBehavior.deferToChild,
            //   cursor: SystemMouseCursors.click,
            //   child: GestureDetector(
            //     onTap: () {
            //       
            //     },
            //     child: FastMarkersLayer(widget.markers),
            //   ),
            // ),
            FastMarkersLayer(mapMarkerProvider.getVisibleMarkers()),
            RichAttributionWidget(
              animationConfig: const ScaleRAWA(), // Or `FadeRAWA` as is default
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                ),
              ],
            ),
            DetailsSheet(),
          ], 
        ),
        // bottomNavigationBar: BottomNavigationBar(
        //   items: [
        //     BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
        //     BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        //   ],
        // ),
      ),
    );
  }
}
