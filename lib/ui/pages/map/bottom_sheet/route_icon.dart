

import 'package:flutter/material.dart';

class RouteIcon extends StatelessWidget {
  const RouteIcon({required this.label, required this.color, super.key});
  final String label;
  final Color color;

  @override 
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(12.0)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Text(label, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
      ),
    );
  }
}
