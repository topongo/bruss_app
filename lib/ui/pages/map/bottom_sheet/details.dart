import 'package:bruss/ui/pages/map/bottom_sheet/card.dart';
import 'package:flutter/material.dart';
import 'package:bruss/database/database.dart';
import 'package:bruss/data/stop.dart';

abstract class DetailsType extends StatelessWidget {
  const DetailsType({super.key});
  Widget render(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return render(context);
  }
}

class StopDetails implements DetailsType {
  StopDetails({required this.stop, super.key});
  final Stop stop;
  final BrussDB db = BrussDB();

  @override
  Widget render(BuildContext context) {
    return StopCard(stop: stop);
  }
}
