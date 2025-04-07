import 'package:bruss/api.dart';
import 'package:bruss/data/area_type.dart';
import 'package:bruss/data/stop.dart';
import 'package:bruss/data/trip.dart';
import 'package:bruss/database/database.dart';
import 'package:flutter/foundation.dart';

import 'bruss_type.dart';
import 'route.dart' as br;
// import 'package:json_serializable/json_serializable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';


part 'path.g.dart';

@JsonSerializable()
class Path extends BrussType {
  final String id;
  final AreaType type;
  final List<int> sequence;
  final String rty;

  Path({
    required this.id,
    required this.type,
    required this.sequence,
    required this.rty,
  });

  factory Path.fromJson(final Map<String, dynamic> json) => _$PathFromJson(json);
  factory Path.fromRawJson(final String json) => Path.fromJson(jsonDecode(json));
  factory Path.fromDB(final PathCacheData p) {
    return Path(
      id: p.id,
      type: p.type,
      sequence: p.sequence,
      rty: p.rty,
    );
  }

  static BrussRequest<Path> apiGet(List<String> ids) {
    return BrussRequest(
      endpoint: "map/path/${ids.join(",")}", 
      construct: Path.fromJson,
      // query: "?limit=10",
    );
  }

  static Future<List<Path>> getPathsCached(Set<String> ids) async {
    final cached = await BrussDB().getPaths(ids);
    final Set<String> missing = ids.difference(cached.map((e) => e.id).toSet());
    final req = await BrussApi.request(apiGet(missing.toList()));
    final List<Path> paths = req.unwrap() + cached;
    if (kDebugMode) {
      final Set<String> keyCheck = {};
      for (final p in paths) {
        assert(!keyCheck.contains(p.id), "Duplicate path id ${p.id}");
        keyCheck.add(p.id);
        ids.remove(p.id);
      }
      assert(ids.isEmpty, "Missing paths: ${ids.join(",")}");
    }

    return paths;
  }
}
