import 'dart:convert';

import 'package:bruss/api.dart';
import 'package:bruss/data/bruss_type.dart';
import 'package:bruss/data/converters.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart';

import 'area_type.dart';

part 'segment.g.dart';

@JsonSerializable()
class Segment extends BrussType {
  final int from;
  final int to;
  final AreaType type;
  @PositionConverter()
  final List<LatLng> geometry;

  Segment({
    required this.from,
    required this.to,
    required this.type,
    required this.geometry,
  });

  factory Segment.fromJson(final Map<String, dynamic> json) => _$SegmentFromJson(json);
  factory Segment.fromRawJson(final String json) => Segment.fromJson(jsonDecode(json));

  static BrussRequest<Segment> apiGet(AreaType type, Set<(int, int)> ids) {
    return BrussRequest(
      endpoint: "map/segment/$type/${ids.map((p) => "${p.$1}-${p.$2}").join(",")}",
      construct: Segment.fromJson,
    );
  }
}
