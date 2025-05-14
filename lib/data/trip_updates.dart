import 'dart:convert';

import 'package:bruss/api.dart';
import 'package:bruss/data/bruss_type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'trip_updates.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class TripUpdates extends BrussType {
  final String id;
  final int delay;
  final int? lastStop;
  final int? nextStop;
  final int? busId;
  final DateTime? lastEvent;

  TripUpdates({
    required this.id,
    required this.delay,
    required this.lastStop,
    required this.nextStop,
    required this.lastEvent,
    this.busId,
  });

  factory TripUpdates.fromJson(final Map<String, dynamic> json) => _$TripUpdatesFromJson(json);
  factory TripUpdates.fromRawJson(final String json) => TripUpdates.fromJson(jsonDecode(json));

  static BrussRequest<TripUpdates> apiGet(List<String> ids) {
    return BrussRequest(
      endpoint: "tracking/trip/${ids.join(",")}",
      construct: (json) => TripUpdates.fromJson(json),
    );
  }
}
