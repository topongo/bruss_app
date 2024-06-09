import 'package:json_annotation/json_annotation.dart';

// part 'area_type.g.dart';

enum AreaType {
  @JsonValue("u")
  urban,
  @JsonValue("e")
  extra;

  // String get serialize() => this == urban ? "u" : "e";
}
