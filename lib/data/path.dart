import 'package:bruss/api.dart';
import 'package:bruss/data/area_type.dart';
import 'package:bruss/data/trip.dart';
import 'package:bruss/database/database.dart';
import 'package:flutter/foundation.dart';

import 'bruss_type.dart';
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
    final List<Path> paths = cached;
    if (missing.isNotEmpty) {
      final req = await BrussApi.request(apiGet(missing.toList()));
      cached.addAll(req.unwrap());
    }
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

  Iterable<(int, int)> stopPairs() sync* {
    for (int i = 0; i < sequence.length - 1; i++) {
      yield (sequence[i], sequence[i + 1]);
    }
  }

  Iterable<(AreaType, int, int)> stopPairsType() {
    return stopPairs().map((e) => (type, e.$1, e.$2));
  }

  int stopIndex(int stop) {
    final index = sequence.indexOf(stop);
    assert(index != -1, "Stop $stop not found in path $id");
    return index;
  }

  int? passedStopIndex(Trip trip) {
    assert(trip.path == id, "Trip path ${trip.path} does not match path $id");
    for (final e in sequence.asMap().entries) {
      if (trip.nextStop == e.value && trip.lastStop != trip.nextStop) {
        return e.key - 1;
      }
    }
    return null;
  }
}
