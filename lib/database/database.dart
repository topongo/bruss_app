import 'package:drift/drift.dart';
import 'package:latlong2/latlong.dart';

import 'connection.dart' as impl;

import 'package:bruss/data/area_type.dart';
import 'package:bruss/data/area.dart';
import 'package:bruss/data/stop.dart';

import 'position_converter.dart';
import 'area.dart';
import 'stop.dart';

part 'database.g.dart';

@DriftDatabase(tables: [AreaCache, StopCache])
class BrussDB extends _$BrussDB {
  BrussDB(): super(impl.connect());

  // BrussDB.forTesting(DatabaseConnection connection) : super(connection);

  @override
  int get schemaVersion => 4;

  Future<List<Area>> getAreas() async {
    final query = select(areaCache);

    final result = await query.get();
    return result.map((row) {
      return Area(
        id: row.id,
        label: row.label,
        type: row.type,
      );
    }).toList();
  }

  Future<List<Stop>> getStops() async {
    final query = select(stopCache);

    final result = await query.get();
    return result.map((row) {
      return Stop(
        id: row.id,
        code: row.code,
        description: row.description,
        position: row.position,
        altitude: row.altitude,
        name: row.name,
        town: row.town,
        type: row.type,
        wheelchairBoarding: row.wheelchairBoarding,
        isFavorite: row.isFavorite,
      );
    }).toList();
  }

  Future<void> insertAreas(List<Area> areas) async {
    await batch((b) {
      b.insertAll(areaCache, areas.map((e) {
        return AreaCacheCompanion.insert(
          id: e.id,
          label: e.label,
          type: e.type,
          lastUpdated: DateTime.now(),
        );
      }));
    });
  }
  
  Future<void> insertStops(List<Stop> stops) async {
    await batch((b) {
      b.insertAll(stopCache, stops.map((e) => e.toCompanion()));
    });
  }

  Future<void> updateStops(List<Stop> stops) async {
    await batch((b) {
      b.replaceAll(stopCache, stops.map((e) => e.toCompanion()));
    });
  }

  Future<void> updateStop(Stop stop) async {
    await update(stopCache).replace(stop.toCompanion());
  }
}

