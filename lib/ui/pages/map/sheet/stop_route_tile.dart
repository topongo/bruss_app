import 'package:bruss/data/schedule.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bruss/data/stop.dart';
import 'package:bruss/data/route.dart' as br;
import 'route_icon.dart';

class StopRouteTile extends StatelessWidget {
  final Schedule sched;
  final br.Route route;
  final Stop stop;
  final Function() onTap;
  final bool? Function() hasPassed;
  static final DateFormat fmt = DateFormat("HH:mm");
  StopRouteTile({required this.sched, required this.route, required this.stop, required this.hasPassed, required this.onTap});

  int get delay => sched.trip.delay ?? 0;
  bool get hasUpdates => sched.trip.busId != null;

  String fmtTime(DateTime time) {
    return fmt.format(time);
  }

  Widget genSubtitle(BuildContext context) {
    // final fmt = DateFormat("HH:mm");
    final TextSpan keywordSpan;
    if (hasUpdates) {
      if (delay > 0) {
        keywordSpan = const TextSpan(
          text: "Late",
          style: TextStyle(color: Colors.red),
        );
      } else if (delay < 0) {
        keywordSpan = const TextSpan(
          text: "Early",
          style: TextStyle(color: Colors.purple),
        );
      } else {
        keywordSpan = const TextSpan(
          text: "On time",
          style: TextStyle(color: Colors.green),
        );
      }
      final spacer = const WidgetSpan(child: SizedBox(width: 5));
      return RichText(text: TextSpan(
        children: [
          keywordSpan,
          spacer,
          TextSpan(text: "${delay.abs()} min.", /* style: Theme.of(context).textTheme.labelSmall */),
          spacer,
          const TextSpan(text: "•"),
          spacer,
          delay != 0 ? 
            TextSpan(
              children: [
                TextSpan(
                  text: fmt.format(sched.arriveAtStop(stop).toLocal()), 
                  style: Theme.of(context).textTheme.labelMedium!.merge(const TextStyle(decoration: TextDecoration.lineThrough))
                ),
                spacer,
                TextSpan(text: fmt.format(sched.arriveAtStopWithDelay(stop).toLocal()), style: Theme.of(context).textTheme.labelMedium),
              ],
            )
          : TextSpan(text: fmt.format(sched.arriveAtStop(stop).toLocal()), style: Theme.of(context).textTheme.labelMedium),
        ],
      ));
    } else {
      return const Text("Scheduled - No updates");
    }
  }

  Widget genTrailing(BuildContext context) {
    final s = StringBuffer();
    Duration delta = sched.arriveIn(stop);
    final isNegative = delta.isNegative;
    delta = delta.abs();
    final m = delta.inMinutes % 60 + 1;
    final h = delta.inHours % 24;
    final d = delta.inDays;
    if (d > 0) {
      s.write("${d}d");
    }
    if (d > 0) {
      s.write("${d}d");
    }
    if (h > 0) {
      s.write("${h}h ");
    }
    if (m > 0) {
      s.write("${m}m");
    }
    if (isNegative) {
      s.write(" ago");
    }
    if (s.isEmpty) {
      s.write("Now");
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(s.toString(), style: Theme.of(context).textTheme.titleSmall),
        Text(fmtTime(sched.departFromStopWithDelay(stop))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // true -> true; false -> false; null -> false
    final passed = hasPassed() == true;
    return GestureDetector(
      onTap: onTap,
      child: ListTile(
        leading: RouteIcon(label: route.code, color: route.color.withAlpha(passed ? 70 : 255)),
        title: Text("${sched.trip.headsign} (${sched.trip.direction.icon})"),
        subtitle: genSubtitle(context),
        trailing: genTrailing(context),
        tileColor: passed ? const Color(0xFF303030) : null,
      )
    );
  }
}
