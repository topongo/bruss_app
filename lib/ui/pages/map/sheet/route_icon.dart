

import 'package:bruss/data/route.dart' as br;
import 'package:flutter/material.dart';

class RouteIcon extends StatelessWidget {
  const RouteIcon({required this.label, required this.color, super.key});
  final String label;
  final Color color;

  factory RouteIcon.fromRoute(br.Route route) {
    return RouteIcon(
      label: route.code,
      color: route.color,
    );
  }

  @override 
  Widget build(BuildContext context) {
    final tColor = color.computeLuminance() < 0.5 ? Colors.white : Colors.black;
    final textStyle = Theme.of(context).textTheme.titleLarge?.copyWith(color: tColor) ??
      TextStyle(color: tColor, fontSize: 16);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(12.0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(child: Text(label, style: textStyle)),
      ),
    );
  }
}
