import 'dart:collection';

import 'package:bruss/database/database.dart';
import 'package:bruss/ui/pages/map/map.dart';
import 'package:collection/collection.dart';

import '../api.dart';
import 'area_type.dart';
import 'route.dart' as br;
import 'schedule.dart';
import 'stop.dart';
import 'trip_updates.dart';

final class ScheduleKey extends LinkedListEntry<ScheduleKey> {
  ScheduleKey(this.tripId, this.departure);
  final String tripId;
  final DateTime departure;

  @override
  String toString() {
    return "ScheduleKey($tripId, $departure)";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ScheduleKey) return false;
    return tripId == other.tripId && departure == other.departure;
  }

  @override
  int get hashCode => tripId.hashCode ^ departure.hashCode;

  factory ScheduleKey.fromSched(Schedule sched) => ScheduleKey(sched.trip.id, sched.departure);
}

class ScheduleTree {
  ScheduleTree();
  final LinkedList<ScheduleKey> sorted = LinkedList();
  Map<ScheduleKey, Schedule> data = {};

  // void add(Schedule sched) {
  //   final k = ScheduleKey.fromSched(sched);
  //   if(data.containsKey(k)) {
  //     update(sched);
  //   } else {
  //     // sorted.
  //   }
  // }
}

class TripBundle {
  TripBundle._({required this.routes, required this.stops, this.total, required Map<ScheduleKey, Schedule> scheds}) {
    _scheds = scheds;
  }
  Map<int, br.Route> routes = {};
  Map<(int, AreaType), Stop> stops = {};
  Map<ScheduleKey, Schedule> _scheds = {};
  Map<ScheduleKey, int?> tripIndexes = {};
  int? total;
  bool get hasMore => total == null || _scheds.length < total!;
  int get length => _scheds.length;
  Iterable<Schedule> get schedules => _scheds.values;
  Iterable<Schedule> schedsSortedByStop(Stop stop) {
    return _scheds
      .values
      .where((s) => s.trip.times.containsKey(stop.id))
      .where((s) => s.departFromStopWithDelay(stop).isAfter(DateTime.now().subtract(const Duration(minutes: 5))))
      .sorted(Schedule.compareByStopWithDelay(stop));
  }

  factory TripBundle.empty() {
    return TripBundle._(routes: {}, stops: {}, total: null, scheds: {});
  }

  static Future<TripBundle> fromRequest(BrussRequest<Schedule> request) {
    return BrussApi.request(request)
      .then((scheds) async {
        final Set<int> neededRoutes = scheds.data!.map((t) => t.trip.route).toSet();
        final Set<String> neededPaths = scheds.data!.map((t) => t.trip.path).toSet();
        final getters = neededRoutes.map((r) => BrussDB().getRoute(r));
        Map<int, br.Route> routes = {};
        final routesFuture = Future.wait(getters)
          .then((res) {
            for (final r in res) {
              routes[r.id] = r;
            }
          });
        final pathsFutute = MapInteractor().getPaths(neededPaths);
        final schedsH = {for (final s in scheds.data!) ScheduleKey(s.trip.id, s.departure): s};
        final stopIds = scheds.data!.expand((t) => t.trip.times.keys.map((s) => (t.trip.type, s))).toSet();
        final Map<(int, AreaType), Stop> stops = {};
        final stopsFuture = BrussDB().getStopsById(stopIds)
          .then((res) {
            for (final s in res) {
              stops[(s.id, s.type)] = s;
            }
          });

        await Future.wait([routesFuture, pathsFutute, stopsFuture]);
        return TripBundle._(routes: routes, stops: stops, total: scheds.total, scheds: schedsH);
      });
  }

  Future<void> getRtUpdates() async {
    final ids = _scheds.keys.map((v) => v.tripId).toList();
    if(ids.isEmpty) return;
    // this is a workaround, since the API doesn't distinguish a trip that departed now and a trip that
    // will depart next week, with the same id. we internally keep this data to being able to keep a
    // schedule, but in the end the tracking will be broken (aka: trips scheduled for monday at 7:00 from
    // a certain stop will receive rt updates even if it will depart next month or year...)
    final Map<String, DateTime> idsToDt = {for (final v in _scheds.keys) v.tripId: v.departure};
    final req = TripUpdates.apiGet(ids);
    final updates = (await BrussApi.request(req)).unwrap();
    for(var u in updates) {
      if(idsToDt.containsKey(u.id)) {
        final k = ScheduleKey(u.id, idsToDt[u.id]!);
        if (_scheds.containsKey(k)) {
          _scheds[k]!.trip.update(u);
          continue;
        }
      }
      print("WARNING: ignored trip update for ${u.id}");
    }
  }

  bool? hasPassedFromStop(Schedule schedKey, Stop stop) {
    final sched = _scheds[ScheduleKey.fromSched(schedKey)];
    if (sched == null) return null;
    final path = MapInteractor().paths[sched.trip.path];
    if (path == null) return null;
    final busAtIndex = path.passedStopIndex(sched.trip);
    final stopIndex = path.stopIndex(stop.id);
    if (busAtIndex == null) return null;
    return busAtIndex >= stopIndex;
  }

  bool contains(Schedule sched) {
    return _scheds.containsKey(ScheduleKey.fromSched(sched));
  }

  // merge to another TripBundle
  void merge(TripBundle other) {
    routes.addAll(other.routes);
    _scheds.addAll(other._scheds);
    stops.addAll(other.stops);
    tripIndexes = {for (final s in _scheds.entries) s.key: MapInteractor().paths[s.value.trip.path]!.passedStopIndex(s.value.trip)};
    total = other.total;
  }
}
