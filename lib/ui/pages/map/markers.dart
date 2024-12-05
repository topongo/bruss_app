import 'package:bruss/data/bruss_type.dart';
import 'package:bruss/data/stop.dart';
import 'package:bruss/database/database.dart';
import 'package:bruss/ui/pages/map/sheet/details.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

abstract class MapMarker<T extends BrussType> {
  final T entity;

  LatLng get position;
  MarkerType get type;

  DetailsType details();

  const MapMarker(this.entity);
}

enum MarkerType {
  stop(0, Colors.red, Icons.location_on);

  final int id;
  final Color color;
  final IconData icon;

  const MarkerType(this.id, this.color, this.icon);
}

class StopMarker extends MapMarker<Stop> {
  @override
  LatLng get position => entity.position;

  @override
  MarkerType get type => MarkerType.stop;

  @override
  DetailsType details() => StopDetails(stop: entity, sizeController: ValueNotifier(0.0));

  const StopMarker(super.entity);
}

class MarkerFilters {
  final Set<MarkerType> shownMarkers;
  final bool includeResolved;

  const MarkerFilters(this.shownMarkers, this.includeResolved);
}

class MapMarkerProvider {
  static const double markersZoomThreshold = 11.0;

  final Function _onStateChanged;
  final Distance _distance = const Distance();

  LatLng? _lastLoadMarkersPos;
  var _markerFilters = MarkerFilters(Set.unmodifiable(MarkerType.values), false);
  List<MapMarker> _markers = [];

  MapMarkerProvider(this._onStateChanged);

  void connectToMapEventStream(Stream<MapEvent> eventStream) {
    eventStream
        .where((event) =>
    event.camera.zoom >= markersZoomThreshold &&
        (_lastLoadMarkersPos == null ||
            _distance.distance(_lastLoadMarkersPos!, event.camera.center) > 5000))
        .forEach((event) => loadMarkers(event.camera.center));
  }

  void loadMarkers(final LatLng latLng) async {
    _lastLoadMarkersPos = latLng;
    BrussDB().getStops().then((value) {
      if (latLng == _lastLoadMarkersPos) {
        debugPrint("Loaded markers at $latLng");
        _markers = value.map((e) => StopMarker(e)).toList();
        _onStateChanged();
      } else {
        debugPrint("Ignoring outdated loaded markers at $latLng");
      }
    });
    // ignore errors when loading map markers (TODO maybe show a button to view errors somewhere?)
  }

  MapMarker? getClosestMarker(final LatLng latLng) {
    return minBy(getVisibleMarkers(), (MapMarker marker) => _distance(latLng, marker.position));
  }

  Iterable<MapMarker> getVisibleMarkers() {
    return _markers.where((e) => _markerFilters.shownMarkers.contains(e.type));
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
