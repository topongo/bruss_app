import 'package:bruss/api.dart';
import 'package:bruss/data/converters.dart';
import 'package:bruss/data/direction.dart';
import 'package:bruss/data/stop.dart';
import 'package:bruss/data/trip_updates.dart';

import 'area_type.dart';
import 'bruss_type.dart';
import 'route.dart' as br;
// import 'package:json_serializable/json_serializable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';


part 'trip.g.dart';

@JsonSerializable()
class TripTime {
  
  @DurationConverter()
  final Duration arrival;
  @DurationConverter()
  final Duration departure;

  TripTime({required this.arrival, required this.departure});

  factory TripTime.fromJson(final Map<String, dynamic> json) => _$TripTimeFromJson(json);
  factory TripTime.fromRawJson(final String json) => TripTime.fromJson(jsonDecode(json));

  Map<String, dynamic> toMap() => _$TripTimeToJson(this);
}

@JsonSerializable()
class Trip extends BrussType {
  final String id;
  int? delay;
  final Direction direction;
  int? nextStop;
  int? lastStop;
  int? busId;
  DateTime? lastEvent;
  final int route;
  final String headsign;
  final String path;
  final AreaType type;
  @TimesConverter()
  final Map<int, TripTime> times;

  Trip({
    required this.id,
    required this.delay,
    required this.direction,
    required this.nextStop,
    required this.lastStop,
    required this.busId,
    required this.route,
    required this.headsign,
    required this.path,
    required this.times,
    required this.type,
    required this.lastEvent,
  });

  factory Trip.fromJson(final Map<String, dynamic> json) => _$TripFromJson(json);
  factory Trip.fromRawJson(final String json) => Trip.fromJson(jsonDecode(json));

  Map<String, dynamic> toMap() => _$TripToJson(this);

  static BrussRequest<Trip> apiGetByStop(Stop stop) {
    return BrussRequest(
      endpoint: "map/stop/${stop.type}/${stop.id}/trips", 
      construct: Trip.fromJson,
      // query: "?limit=10",
    );
  }

  static BrussRequest<Trip> apiGetByRoute(br.Route route) {
    return BrussRequest(
      endpoint: "map/route/${route.id}/trips", 
      construct: Trip.fromJson,
      query: "?limit=10",
    );
  }

  static int Function(Trip, Trip)? sortByTimesStop(Stop stop) {
    return (Trip a, Trip b) {
      return a.times[stop.id]!.arrival.compareTo(b.times[stop.id]!.arrival);
    };    
  }

  void update(TripUpdates other) {
    delay = other.delay;
    nextStop = other.nextStop;
    lastStop = other.lastStop;
    busId = other.busId;
    lastEvent = other.lastEvent;
  }
}

