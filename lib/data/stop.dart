import 'package:bruss/database/database.dart';
import 'package:latlong2/latlong.dart';

import 'area_type.dart';
import 'bruss_type.dart';
import 'position_converter.dart';
// import 'package:json_serializable/json_serializable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

import 'package:drift/drift.dart';

part 'stop.g.dart';

@JsonSerializable()
class Stop extends BrussType {
  final int id;
  final String code;
  final String description;
  @PositionConverter()
  final LatLng position;
  final int altitude;
  final String name;
  final String? town;
  final AreaType type;
  final bool? wheelchairBoarding;
  bool? isFavorite; 

  static String endpoint = "map/stop";
 
  Stop({
    required this.id,
    required this.code,
    required this.description,
    required this.position,
    required this.altitude,
    required this.name,
    required this.town,
    required this.type,
    required this.wheelchairBoarding,
    this.isFavorite,
  });

  factory Stop.fromJson(final Map<String, dynamic> json) => _$StopFromJson(json);
  factory Stop.fromRawJson(final String json) => Stop.fromJson(jsonDecode(json));

  Map<String, dynamic> toMap() => _$StopToJson(this);

  @override
  String toString() {
    return "Stop { id: $id, code: \"$code\", description: \"$description\", position: $position, altitude: $altitude, name: \"$name\", town: \"$town\", type: $type, wheelchairBoarding: $wheelchairBoarding }";
  }

  StopCacheCompanion toCompanion() {
    return StopCacheCompanion(
      id: Value(id),
      code: Value(code),
      description: Value(description),
      position: Value(position),
      altitude: Value(altitude),
      name: Value(name),
      town: Value(town),
      type: Value(type),
      wheelchairBoarding: Value(wheelchairBoarding),
      isFavorite: Value(isFavorite),
    );
  }
}
