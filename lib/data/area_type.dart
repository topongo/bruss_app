import 'package:json_annotation/json_annotation.dart';

// part 'area_type.g.dart';

enum AreaType {
  @JsonValue("u")
  urban,
  @JsonValue("e")
  extra;

  @override
  String toString() {
    switch(this) {
      case urban:
        return "u";
        break;
      case extra:
        return "e";
        break;
    }
  }
  // String get serialize() => this == urban ? "u" : "e";
}
