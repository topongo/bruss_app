import 'package:bruss/data/stop.dart';

import 'area_type.dart';
import 'bruss_type.dart';
// import 'package:json_serializable/json_serializable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';


part 'trip.g.dart';

@JsonSerializable()
class Trip extends BrussType {
  final String id;
  final int delay;
  final String direction;
  final int? nextStop;
  final int? lastStop;
  final int? busId;
  final int route;
  final String headsign;
  final String path;
  final Map<int, Map<String, String>> times;
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

  static String endpointStop(Stop stop) {
    return "map/stop/${stop.type}/${stop.id}/trips";
  }

  // @override
  // String toString() {
    // return "Trip { id: $id, code: \"$code\", description: \"$description\", position: $position, altitude: $altitude, name: \"$name\", town: \"$town\", type: $type, wheelchairBoarding: $wheelchairBoarding }";
  // }

  // TripCacheCompanion toCompanion() {
  //   return TripCacheCompanion(
  //     id: Value(id),
  //     code: Value(code),
  //     description: Value(description),
  //     position: Value(position),
  //     altitude: Value(altitude),
  //     name: Value(name),
  //     town: Value(town),
  //     type: Value(type),
  //     wheelchairBoarding: Value(wheelchairBoarding),
  //     isFavorite: Value(isFavorite),
  //   );
  // }
}
