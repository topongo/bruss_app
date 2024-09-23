import 'package:bruss/database/database.dart';
import 'package:flutter/material.dart';

import 'area_type.dart';
import 'bruss_type.dart';
import 'converters.dart';
// import 'package:json_serializable/json_serializable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:json_annotation/json_annotation.dart' as js;
import 'dart:convert';

import 'package:drift/drift.dart';

part 'route.g.dart';

@JsonSerializable()
class Route extends BrussType {
  final int id;
  final int type;
  final int area;
  @js.JsonKey(name: "area_ty")
  final AreaType areaType;
  @ColorConverter()
  final Color color;
  final String name;
  final String code;
  bool? isFavorite; 

  static String endpoint = "map/route";
 
  Route({
    required this.id,
    required this.type,
    required this.area,
    required this.areaType,
    required this.color,
    required this.name,
    required this.code,
    this.isFavorite,
  });

  factory Route.fromJson(final Map<String, dynamic> json) => _$RouteFromJson(json);
  factory Route.fromRawJson(final String json) => Route.fromJson(jsonDecode(json));
  factory Route.fromDB(final RouteCacheData s) {
    return Route(
      id: s.id,
      type: s.type,
      area: s.area,
      areaType: s.areaType,
      color: Color(int.parse(s.color, radix: 16)),
      name: s.name,
      code: s.code,
      isFavorite: s.isFavorite,
    );
  }

  Map<String, dynamic> toMap() => _$RouteToJson(this);

  @override
  String toString() {
    return "Route(id: $id, type: $type, area: $area, areaType: $areaType, color: $color, name: $name, code: $code, isFavorite: $isFavorite)";
  }

  RouteCacheCompanion toCompanion() {
    return RouteCacheCompanion(
      id: Value(id),
      type: Value(type),
      area: Value(area),
      areaType: Value(areaType),
      color: Value(color.value.toRadixString(16)),
      name: Value(name),
      code: Value(code),
      isFavorite: Value(isFavorite),
    );
  }
}
