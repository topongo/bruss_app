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

  DateTime arriveAtStop(Stop stop) {
    return departure.add(trip.times[stop.id]!.arrival);
  }

  DateTime departFromStop(Stop stop) {
    return departure.add(trip.times[stop.id]!.departure);
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
}

// class Schedule extends BrussType {
//   final Trip trip;
//   final DateTime departure;
//   final DateTime? arrivalAtStop;
//
//   Schedule({
//     required this.trip,
//     required this.departure,
//     required this.arrivalAtStop,
//   });
//
//   factory Schedule.fromJson(final Map<String, dynamic> json) {
//     final proto = ProtoSchedule.fromJson(json);
//     return Schedule(
//       trip: Trip.fromJson(proto.trip),
//       departure: proto.departure,
//       arrivalAtStop: proto.arrivalAtStop,
//     );
//   }
//   factory Schedule.fromRawJson(final String json) => Schedule.fromJson(jsonDecode(json));
//
//   Map<String, dynamic> toMap() {
//     final proto = ProtoSchedule(
//       trip: trip.toMap(),
//       departure: departure,
//       arrivalAtStop: arrivalAtStop,
//     );
//     return proto.toMap();
//   }
//

//
// }
