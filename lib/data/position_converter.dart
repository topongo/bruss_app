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
