import 'package:bruss/data/area.dart';
import 'package:bruss/data/area_type.dart';
import 'package:latlong2/latlong.dart';

import 'stop.dart';

class ApiSampleData {
  static Stop stop = Stop(
    id: 165,
    code: "21545-",
    description: "", 
    position: const LatLng(46.065117, 11.123289), 
    altitude: 80, 
    name: "Piazza di Fiera", 
    town: "Trento", 
    type: AreaType.urban, 
    wheelchairBoarding: true,
  );

  static const Area area = Area(
    id: 23,
    label: "Urbano Trento", 
    type: AreaType.urban,
  );
}
