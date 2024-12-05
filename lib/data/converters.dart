import 'dart:collection';

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

class DateTimeConverter extends JsonConverter<DateTime, String> {
  const DateTimeConverter();

  @override
  DateTime fromJson(String json) {
    final parts = json.split(":");
    return DateTime.fromMillisecondsSinceEpoch(0).add(Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(parts[2]),
    ));
  }

  @override
  String toJson(DateTime object) {
    final fmt = DateFormat("HH:mm:ss");
    return fmt.format(object);
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
