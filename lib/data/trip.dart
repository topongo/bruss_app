import 'package:bruss/api.dart';
import 'package:bruss/data/converters.dart';
import 'package:bruss/data/stop.dart';
import 'package:bruss/data/trip_updates.dart';
import 'package:flutter/material.dart';

import 'area_type.dart';
import 'bruss_type.dart';
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
class Trip extends BrussType {
  final String id;
  int delay;
  final String direction;
  int? nextStop;
  int? lastStop;
  int? busId;
  final int route;
  final String headsign;
  final String path;
  final Map<int, TripTime> times;
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
