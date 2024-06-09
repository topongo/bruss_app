import 'area_type.dart';
import 'bruss_type.dart';
// import 'package:json_serializable/json_serializable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'area.g.dart';

@JsonSerializable()
class Area extends BrussType {
  final int id;
  final String label;
  final AreaType type;
  static String endpoint = "map/area";
 
  const Area({
    required this.id,
    required this.label,
    required this.type,
  });

  factory Area.fromJson(final Map<String, dynamic> json) => _$AreaFromJson(json);
  factory Area.fromRawJson(final String json) => Area.fromJson(jsonDecode(json));

  Map<String, dynamic> toMap() => _$AreaToJson(this);

  @override
  String toString() {
    return "Area { id: $id, label: \"$label\", type: $type }";
  }  
}

