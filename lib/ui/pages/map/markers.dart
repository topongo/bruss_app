import 'package:bruss/data/area_type.dart';
import 'package:bruss/data/bruss_type.dart';
import 'package:bruss/data/stop.dart';
import 'package:bruss/data/trip.dart';
import 'package:bruss/database/database.dart';
import 'package:bruss/ui/pages/map/sheet/details.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

abstract class MapMarker<T extends BrussType> {
  final T entity;

  LatLng get position;
  MarkerType get type;

  DetailsType details();

  const MapMarker(this.entity);
}

enum MarkerType {
  urbanStop(0, "urban_stop"),
  extraurbanStop(1, "extraurban_stop"),
  whiteArrow(2, "white_arrow"),
  blackArrow(3, "black_arrow"),
  simpleStop(4, "simple_stop"),
  ;

  final int id;
  final String _name;
  static Map<MarkerType, PictureInfo> icons = {};

  const MarkerType(this.id, this._name);

  String get asset => "assets/icons/$_name.png";
}

class StopMarker extends MapMarker<Stop> {
  late final MarkerType? _type;

  @override
  LatLng get position => entity.position;

  @override
  MarkerType get type => _type ?? (entity.type == AreaType.urban ? MarkerType.urbanStop : MarkerType.extraurbanStop);

  @override
  DetailsType details() => StopDetails(stop: entity);

  StopMarker(super.entity, {MarkerType? type}) {
    _type = type;
  }
}

abstract class MarkerFilter<T extends BrussType> {
  const MarkerFilter();

  bool filter(MapMarker<T> marker);
  Iterable<MapMarker<T>> convert(Iterable<MapMarker<T>> markers);
}

class TripMarkerFilter extends MarkerFilter<Stop> {
  TripMarkerFilter(Trip trip, {this.typeProxy})
      : stopIds = trip.times.keys.toSet(),
        areaType = trip.type;

  final Set<int> stopIds;
  final AreaType areaType;
  final MarkerType? typeProxy;

  @override
  bool filter(MapMarker<Stop> marker) {
    return marker.entity.type == areaType && stopIds.contains(marker.entity.id);
  }

  @override
  Iterable<MapMarker<Stop>> convert(Iterable<MapMarker<Stop>> markers) {
    if (typeProxy != null) {
      return markers.map((marker) => StopMarker(marker.entity, type: typeProxy));
    } else {
      return markers;
    }
  }
}

class MapMarkerProvider {
  static const double markersZoomThreshold = 14.0;

  final Function _onStateChanged;
  final Distance _distance = const Distance();

  LatLng? _lastLoadMarkersPos;
  double? _lastLoadMarkersZoom;
  List<MarkerFilter> _markerFilters = [];
  MapMarker Function(MapMarker)? _markerMapper = (marker) => marker;
  List<MapMarker> _markers = [];
  List<Stop>? _stops;

  MapMarkerProvider(this._onStateChanged);

  void setMarkerFilters(List<MarkerFilter> filters, MapMarker Function(MapMarker)? markerMapper) {
    _markerFilters = filters;
    _markerMapper = markerMapper;
  }

  void unsetMarkerFilters() {
    _markerFilters = [];
  }

  Future<void> _loadStops() async {
    final db = BrussDB();
    _stops = await db.getStops();
    debugPrint("Loaded ${_stops?.length} stops");
  }

  void connectToMapEventStream(Stream<MapEvent> eventStream) {
    eventStream
        // .map((event) { print("RECEIVED MAP EVENT: $event"); return event; })
        .map((event) { if (event is MapEventFlingAnimationEnd) print("FLING ANIMATION END"); return event; })
        .where((event) =>
          event is MapEventFlingAnimationEnd ||
          event is MapEventMoveEnd ||
          event is MapEventScrollWheelZoom ||
          event is MapEventDoubleTapZoomEnd
        )
        .forEach((event) => reloadMarkers(event.camera, /* context */));
  }

  Future<void> reloadMarkers(MapCamera camera) async {
    final latLng = camera.center;
    final bounds = camera.visibleBounds;
    final zoom = camera.zoom;
    debugPrint("Loading markers at $latLng with zoom $zoom");
    if (zoom < markersZoomThreshold) {
      debugPrint("Clearing markers because zoom is too low");
      // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Zoom in to see the markers")));
      _markers = [];
      _onStateChanged();
      return;
    }
    if (_lastLoadMarkersPos != latLng || _lastLoadMarkersZoom != zoom) {
      _lastLoadMarkersPos = latLng;
      _lastLoadMarkersZoom = zoom;
      if (_stops == null) {
        await _loadStops();
      }
      // debugPrint("Loading markers in bounds: ");
      _markers = [];
      for (final s in _stops!) {
        // TODO: support for marker filters
        if (bounds.contains(s.position)) {
          _markers.add(s.toMarker());
        }
      }
      // debugPrint("Visible markers: ${_markers.length}");
      _onStateChanged();
    }
  }

  MapMarker? getClosestMarker(final LatLng latLng) {
    return minBy(getVisibleMarkers(), (MapMarker marker) => _distance(latLng, marker.position));
  }

  Iterable<MapMarker> getVisibleMarkers() {
    if (_markerFilters.isEmpty) {
      return _markers;
    } else {
      return _markers
        .where((marker) => _markerFilters.any((filter) => filter.filter(marker)))
        .map(_markerMapper ?? (marker) => marker);
    }
  }

  void addOrReplace(final MapMarker marker) {
    throw UnimplementedError();
    // _markers.removeWhere((element) => element.id == marker.id);
    // if (marker.resolutionDate == null || _lastLoadMarkersIncludeResolved) {
    //   // only add it back if it is not resolved or if the user wants to see resolved markers
    //   _markers.add(marker);
    // }
  }

  void openMarkerFiltersDialog(BuildContext context, LatLng currentMapCenter) {
    // showDialog(
    //   context: context,
    //   builder: (ctx) => MarkerFiltersDialog(_markerFilters),
    // ).then((newFilters) {
    //   if (newFilters is MarkerFilters) {
    //     _markerFilters = newFilters;
    //     _onStateChanged();
    //     if (newFilters.includeResolved && !_lastLoadMarkersIncludeResolved) {
    //       loadMarkers(currentMapCenter);
    //     }
    //   }
    // });
    throw UnimplementedError();
  }
}
