import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart';

class PositionConverter extends JsonConverter<LatLng, List<dynamic>> {
  const PositionConverter();

  @override
  LatLng fromJson(List<dynamic> json) {
    return LatLng(json[0], json[1]);
  }

  @override
  List<dynamic> toJson(LatLng object) {
    return [object.latitude, object.longitude];
  }
}

class ColorConverter extends JsonConverter<Color, String> {
  const ColorConverter();

  @override
  Color fromJson(String json) {
    // json is a #RRGGBB string
    return Color(int.parse(json, radix: 16) + 0xFF000000);
  }

  @override
  String toJson(Color object) {
    return object.value.toRadixString(16);
  }
}

