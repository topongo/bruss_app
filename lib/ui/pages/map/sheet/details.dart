import 'package:bruss/data/direction.dart';
import 'package:bruss/ui/pages/map/sheet/card.dart';
import 'package:flutter/material.dart';
import 'package:bruss/data/stop.dart';
import 'package:bruss/data/route.dart' as br;

abstract class DetailsType extends StatelessWidget {
  // DetailsType({super.key});

  @override
  Widget build(BuildContext context);

  void updateSize(double off);
}

class StopDetails extends StatelessWidget implements DetailsType {
  StopDetails({required this.stop, required this.sizeController, super.key});
  final Stop stop;
  final ValueNotifier<double> sizeController;

  @override
  Widget build(BuildContext context) {
    print("Creating stopCard for stop ${stop.name}");
    return StopCard(stop: stop, sizeController: sizeController);
  }

  @override
  void updateSize(double off) {
    sizeController.value = off;
  }
}

class RouteDetails extends StatelessWidget implements DetailsType {
  RouteDetails({required this.route, required this.direction, required this.sizeController, super.key});
  final br.Route route;
  final Direction direction;
  final ValueNotifier<double> sizeController;


  @override
  Widget build(BuildContext context) {
    print("Creating routeCard for route ${route.name}");
    return RouteCard(route: route, direction: direction, sizeController: sizeController);
  }

  @override
  void updateSize(double off) {
    sizeController.value = off;
  }
}
