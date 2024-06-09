import 'package:drift/drift.dart';
import 'package:latlong2/latlong.dart';

class PositionConverter extends TypeConverter<LatLng, String> {
  const PositionConverter();
  @override
  LatLng fromSql(String fromDb) {
    final parts = fromDb.split(";");
    return LatLng(double.parse(parts[0]), double.parse(parts[1]));
  }

  @override
  String toSql(LatLng value) {
    return "${value.latitude};${value.longitude}";
  }
}
