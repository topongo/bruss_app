import 'package:bruss/ui/pages/map/sheet/card.dart';
import 'package:flutter/material.dart';
import 'package:bruss/data/stop.dart';

abstract class DetailsType extends StatelessWidget {
  DetailsType({super.key});

  @override
  Widget build(BuildContext context);
}

class StopDetails extends StatelessWidget implements DetailsType {
  StopDetails({required this.stop, super.key});
  final Stop stop;

  @override
  Widget build(BuildContext context) {
    return StopCard(stop: stop);
  }
}
