import 'package:bruss/data/path.dart' as bp;
import 'package:bruss/data/route.dart';
import 'package:bruss/database/path.dart';
import 'package:drift/drift.dart';
import 'package:latlong2/latlong.dart';

import 'connection.dart' as impl;

import 'package:bruss/data/area_type.dart';
import 'package:bruss/data/area.dart';
import 'package:bruss/data/stop.dart';

import 'position_converter.dart';
import 'area.dart';
import 'stop.dart';
import 'route.dart';

part 'database.g.dart';

@DriftDatabase(tables: [AreaCache, StopCache, RouteCache, PathCache])
class BrussDB extends _$BrussDB {
  static BrussDB? _instance;

  factory BrussDB() {
    return _instance ??= BrussDB._();
  }


  BrussDB._(): super(impl.connect());

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
    return result.map((row) => Stop.fromDB(row)).toList();
  }

  Future<Stop> getStop(int id) async {
    return Stop.fromDB(await (select(stopCache)..where((s) => s.id.equals(id))).getSingle());
  }

  Future<List<Stop>> getStopsById(Set<(AreaType, int)> ids) async {
    // final query = select(stopCache)
    //   ..where((s) => s.c);

    final query = customSelect(
      "SELECT * FROM stop_cache WHERE (type, id) IN (${ids.map((e) => "(?, ?)").join(", ")})",
      variables: ids.expand((e) => [Variable.withInt(e.$1.index), Variable.withInt(e.$2)]).toList(),
      readsFrom: {stopCache},
    );

    final mapped = query.map((row) {
      return Stop(
        id: row.read<int>('id'),
        code: row.read<String>('code'),
        description: row.read<String>('description'),
        position: const PositionConverter()
            .fromSql(row.read<String>('position')),
        altitude: row.read<int>('altitude'),
        name: row.read<String>('name'),
        town: row.read<String?>('town'),
        type: AreaType.values[row.read<int>('type')],
        wheelchairBoarding: row.read<bool?>('wheelchair_boarding'),
        isFavorite: row.read<bool?>('is_favorite'),
      );
    });

    return mapped.get();
  }

  // Future<List<Route>> getRoutes() async {
  //   final query = select(routeCache);
  //
  //   final result = await query.get();
  //   return result.map((row) {
  //     return Route(
  //       
  //     );
  //   }).toList();
  // }

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

  Future<List<Route>> getRoutes() async {
    final query = select(routeCache);
    
    final result = await query.get();
    return result.map((row) => Route.fromDB(row)).toList();
  }

  Future<Route> getRoute(int id) async {
    return Route.fromDB(await (select(routeCache)..where((r) => r.id.equals(id))).getSingle());
  }

  Future<void> insertRoutes(List<Route> routes) async {
    await batch((b) {
      b.insertAll(routeCache, routes.map((e) => e.toCompanion()));
    });
  }

  Future<void> updateRoute(Route route) async {
    await update(routeCache).replace(route.toCompanion());
  }

  Future<List<bp.Path>> getPaths(Set<String> ids) async {
    final query = select(pathCache)..where((s) => s.id.isIn(ids));

    final result = await query.get();
    return result.map((row) => bp.Path.fromDB(row)).toList();
  }

  Future<void> insertPaths(List<bp.Path> paths) async {
    await batch((b) {
      b.insertAll(pathCache, paths.map((e) => e.toCompanion()));
    });
  }
}

