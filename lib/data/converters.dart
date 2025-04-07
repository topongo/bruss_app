import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart';

import 'trip.dart';

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

class DurationConverter extends JsonConverter<Duration, List<dynamic>> {
  const DurationConverter();

  @override
  Duration fromJson(List<dynamic> json) {
    assert(json.length == 2);
    return Duration(seconds: json[0] as int, milliseconds: json[1] as int);
  }

  @override
  List<int> toJson(Duration object) {
    throw Exception("Duration serialization isn't implemented yet");
  }
}

class TimesConverter extends JsonConverter<LinkedHashMap<int, TripTime>, Map<String, dynamic>> {
  const TimesConverter();

  @override
  LinkedHashMap<int, TripTime> fromJson(Map<String, dynamic> json) {
    return LinkedHashMap.from(json.map((key, value) => MapEntry(int.parse(key), TripTime.fromJson(value))));
  }

  @override
  Map<String, dynamic> toJson(LinkedHashMap<int, TripTime> object) {
    return object.map((key, value) => MapEntry(key.toString(), value));
  }
}
