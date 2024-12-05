import 'package:json_annotation/json_annotation.dart';

// part 'area_type.g.dart';

enum Direction {
  @JsonValue("f")
  forward,
  @JsonValue("b")
  backward;

  @override
  String toString() {
    switch(this) {
      case forward:
        return "f";
        break;
      case backward:
        return "b";
        break;
    }
  }
  // String get serialize() => this == urban ? "u" : "e";
}

