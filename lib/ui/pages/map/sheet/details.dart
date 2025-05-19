import 'package:bruss/data/schedule.dart';
import 'package:bruss/ui/pages/map/sheet/card.dart';
import 'package:bruss/ui/pages/map/sheet/details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:bruss/data/stop.dart';
import 'package:bruss/data/route.dart' as br;

abstract class DetailsType extends StatelessWidget {
  // DetailsType({super.key});

  @override
  Widget build(BuildContext context);

  void updateSize(double off);
  double get sheetSize;
  DateTime? get refTimeOverride;
  Dragger? dragger;
}

class StopDetails extends StatelessWidget implements DetailsType {
  StopDetails({required this.stop, refTime, super.key}) {
    _refTimeOverride = refTime;
  }
  final Stop stop;
  final ValueNotifier<double> sizeController = ValueNotifier(0);
  late final DateTime? _refTimeOverride;
  @override
  double get sheetSize => sizeController.value;
  @override
  DateTime? get refTimeOverride => _refTimeOverride;
  @override
  Dragger? dragger;

  @override
  Widget build(BuildContext context) {
    print("Creating stopCard for stop ${stop.name}");
    return StopCard(stop: stop, sizeController: sizeController, dragger: dragger!);
  }

  @override
  void updateSize(double off) {
    sizeController.value = off;
  }
}

class RouteDetails extends StatelessWidget implements DetailsType {
  RouteDetails({required this.route, this.schedule, refTime, super.key}) {
    _refTimeOverride = refTime;
  }
  final br.Route route;
  // final Direction direction;
  final ValueNotifier<double> sizeController = ValueNotifier(0);
  final Schedule? schedule;
  late final DateTime? _refTimeOverride;
  @override
  DateTime? get refTimeOverride => _refTimeOverride;
  @override
  double get sheetSize => sizeController.value;
  @override
  Dragger? dragger;

  @override
  Widget build(BuildContext context) {
    return RouteCard(route: route, dragger: dragger!, sizeController: sizeController, schedule: schedule);
  }

  @override
  void updateSize(double off) {
    sizeController.value = off;
  }
}
