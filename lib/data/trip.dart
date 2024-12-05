import 'dart:collection';

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
  
  @DateTimeConverter()
  final DateTime arrival;
  @DateTimeConverter()
  final DateTime departure;

  TripTime({required this.arrival, required this.departure});

  factory TripTime.fromJson(final Map<String, dynamic> json) => _$TripTimeFromJson(json);
  factory TripTime.fromRawJson(final String json) => TripTime.fromJson(jsonDecode(json));

  Map<String, dynamic> toMap() => _$TripTimeToJson(this);
}

@JsonSerializable()
class ProtoTrip {
  final String id;
  int delay;
  final Direction direction;
  int? nextStop;
  int? lastStop;
  int? busId;
  final int route;
  final String headsign;
  final String path;
  final AreaType type;
  @TimesConverter()
  final Map<int, TripTime> times;
  final List<int> sequence;

  ProtoTrip({
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
    required this.sequence,
    required this.type,
  });

  factory ProtoTrip.fromJson(final Map<String, dynamic> json) => _$ProtoTripFromJson(json);
  factory ProtoTrip.fromRawJson(final String json) => ProtoTrip.fromJson(jsonDecode(json));

  Map<String, dynamic> toMap() => _$ProtoTripToJson(this);
}

class Trip extends BrussType {
  final String id;
  int delay;
  final Direction direction;
  int? nextStop;
  int? lastStop;
  int? busId;
  final int route;
  final String headsign;
  final String path;
  final LinkedHashMap<int, TripTime> times;
  final AreaType type;

  final bool? isFavorite;

  static String endpoint = "map/trip";
 
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
    this.isFavorite,
  });

  factory Trip.fromJson(final Map<String, dynamic> json) {
    final proto = ProtoTrip.fromJson(json);
    final LinkedHashMap<int, TripTime> times = LinkedHashMap.fromIterable(proto.sequence, key: (s) => s, value: (s) => proto.times[s]!);
    return Trip(
      id: proto.id,
      delay: proto.delay,
      direction: proto.direction,
      nextStop: proto.nextStop,
      lastStop: proto.lastStop,
      busId: proto.busId,
      route: proto.route,
      headsign: proto.headsign,
      times: times,
      type: proto.type,
      path: proto.path,
    );
  }
  factory Trip.fromRawJson(final String json) => Trip.fromJson(jsonDecode(json));

  Map<String, dynamic> toMap() {
    final sequence = times.keys.toList();
    final times_unord = times.map((k, v) => MapEntry(k, v));
    final proto = ProtoTrip(
      id: id,
      delay: delay,
      direction: direction,
      nextStop: nextStop!,
      lastStop: lastStop!,
      busId: busId!,
      route: route,
      headsign: headsign,
      type: type,
      path: path,
      sequence: sequence,
      times: times_unord,
    );
    return proto.toMap();
  }

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
  }
}
