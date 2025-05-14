import 'package:bruss/api.dart';
import 'package:bruss/data/bruss_type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

import 'route.dart' as br;
import 'stop.dart';
import 'trip.dart';


part 'schedule.g.dart';

@JsonSerializable()
class Schedule extends BrussType {
  final Trip trip;
  final DateTime departure;
  final DateTime? arrivalAtStop;

  Schedule({
    required this.trip,
    required this.departure,
    required this.arrivalAtStop,
  });

  factory Schedule.fromJson(final Map<String, dynamic> json) => _$ScheduleFromJson(json);
  factory Schedule.fromRawJson(final String json) => Schedule.fromJson(jsonDecode(json));

  Map<String, dynamic> toMap() => _$ScheduleToJson(this);

  DateTime arriveAtStop(Object stop) {
    int intStop = stop is int ? stop : (stop as Stop).id;
    return departure.add(trip.times[intStop]!.arrival);
  }

  DateTime departFromStop(Object stop) {
    int intStop = stop is int ? stop : (stop as Stop).id;
    return departure.add(trip.times[intStop]!.departure);
  }

  DateTime arriveAtStopWithDelay(Object stop) {
    return departFromStop(stop).add(Duration(minutes: trip.delay ?? 0));
  }

  DateTime departFromStopWithDelay(Object stop) {
    return departFromStop(stop).add(Duration(minutes: trip.delay ?? 0));
  }

  Duration arriveIn(Object stop) {
    return arriveAtStopWithDelay(stop).toLocal().difference(DateTime.now());
  }

  Duration departIn(Object stop) {
    return departFromStopWithDelay(stop).difference(DateTime.now());
  }

  static BrussRequest<Schedule> apiGetByStop(Stop stop) {
    return BrussRequest(
      endpoint: "map/stop/${stop.type}/${stop.id}/trips", 
      construct: Schedule.fromJson,
      query: "?limit=10",
    );
  }

  static BrussRequest<Schedule> apiGetByRoute(br.Route route) {
    return BrussRequest(
      endpoint: "map/route/${route.id}/trips", 
      construct: Schedule.fromJson,
      query: "?limit=10",
    );
  }

  static int compareWithDelay(Schedule a, Schedule b) {
    final aDelay = a.trip.delay ?? 0;
    final bDelay = b.trip.delay ?? 0;
    return a.departure
      .add(Duration(minutes: aDelay))
      .compareTo(b.departure
        .add(Duration(minutes: bDelay)));
  }

  static int Function(Schedule a, Schedule b) compareByStopWithDelay(Stop stop) {
    return (a, b) {
      return a.departFromStopWithDelay(stop)
        .compareTo(b.departFromStopWithDelay(stop));
    };
  }
}

