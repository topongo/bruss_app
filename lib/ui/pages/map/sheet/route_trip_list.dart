import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/stop.dart';
import '../../../../data/trip.dart';
import '../../../../data/route.dart' as br;
import 'route_icon.dart';

class TripRouteTile extends StatelessWidget {
  final Trip trip;
  final br.Route route;
  final Stop stop;
  final bool passed;
  final Function() onTap;
  static final DateFormat fmt = DateFormat("HH:mm");
  TripRouteTile({required this.trip, required this.route, required this.stop, required this.passed, required this.onTap});

  int get delay => trip.delay;
  bool get hasUpdates => trip.busId != null;

  DateTime arriveIn() {
    return trip.times[stop.id]!.arrival.add(Duration(minutes: delay));
  }

  Duration timeUntil() {
    final now = DateTime.now();
    final nowEpoch = DateTime.fromMillisecondsSinceEpoch(0).add(Duration(
      hours: now.hour,
      minutes: now.minute,
      seconds: now.second,
    ));
    return arriveIn().difference(nowEpoch);
  }

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
                  text: fmt.format(trip.times[stop.id]!.arrival), 
                  style: Theme.of(context).textTheme.labelMedium!.merge(const TextStyle(decoration: TextDecoration.lineThrough))
                ),
                spacer,
                TextSpan(text: fmt.format(arriveIn()), style: Theme.of(context).textTheme.labelMedium),
              ],
            )
          : TextSpan(text: fmt.format(trip.times[stop.id]!.arrival), style: Theme.of(context).textTheme.labelMedium),
        ],
      ));
    } else {
      return const Text("Scheduled - No updates");
    }
  }

  Widget genTrailing(BuildContext context) {
    final delta = timeUntil();
    final m = delta.inMinutes % 60;
    final h = delta.inHours % 24;
    final d = delta.inDays;
    final s = StringBuffer();
    if (d > 0) {
      s.write("${d}d");
    }
    if (h > 0) {
      s.write("${h}h ");
    }
    if (m > 0) {
      s.write("${m}m");
    }
    if (s.isEmpty) {
      s.write("Now");
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(s.toString(), style: Theme.of(context).textTheme.titleSmall),
        Text(fmtTime(arriveIn())),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ListTile(
        leading: Icon(passed ? Icons.check_circle : Icons.circle_outlined), 
        title: Text("${stop.name} (${stop.id})"),
        subtitle: genSubtitle(context),
        trailing: genTrailing(context),
      )
    );
  }
}
