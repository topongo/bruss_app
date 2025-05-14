import 'package:bruss/data/schedule.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bruss/data/stop.dart';
import 'package:bruss/data/route.dart' as br;

class ScheduleStopTile extends StatelessWidget {
  final Schedule sched;
  final br.Route route;
  final Stop stop;
  final bool? passed;
  final Function() onTap;
  final bool highlight;
  static final DateFormat fmt = DateFormat("HH:mm");
  ScheduleStopTile({required this.sched, required this.route, required this.stop, required this.passed, required this.onTap, this.highlight = false, super.key});

  int get delay => sched.trip.delay ?? 0;
  bool get hasUpdates => sched.trip.busId != null;

  DateTime arriveAt() {
    return sched.arriveAtStop(stop).toLocal().add(Duration(minutes: delay));
  }

  Duration timeUntil() {
    final now = DateTime.now().toUtc();
    return arriveAt().difference(now);
  }

  String localizeAndFmtTime(DateTime time) {
    return fmt.format(time.toLocal());
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
      const spacer = WidgetSpan(child: SizedBox(width: 5));
      return RichText(text: TextSpan(
        children: [
          keywordSpan,
          spacer,
          if (delay != 0)
            TextSpan(text: "${delay.abs()} min.", /* style: Theme.of(context).textTheme.labelSmall */),
          spacer,
          const TextSpan(text: "•"),
          spacer,
          delay != 0 ? 
            TextSpan(
              children: [
                TextSpan(
                  text: localizeAndFmtTime(sched.arriveAtStop(stop)), 
                  style: Theme.of(context).textTheme.labelMedium!.merge(const TextStyle(decoration: TextDecoration.lineThrough))
                ),
                spacer,
                TextSpan(text: localizeAndFmtTime(arriveAt()), style: Theme.of(context).textTheme.labelMedium),
              ],
            )
          : TextSpan(text: localizeAndFmtTime(sched.arriveAtStop(stop)), style: Theme.of(context).textTheme.labelMedium),
        ],
      ));
    } else {
      return Text("Scheduled - No updates - ${localizeAndFmtTime(sched.arriveAtStop(stop))}");
    }
  }

  Widget genTrailing(BuildContext context) {
    final s = StringBuffer();
    Duration delta = timeUntil();
    if (delta.isNegative) {
      s.write("-");
      delta = delta.abs();
    }
    final m = delta.inMinutes % 60;
    final h = delta.inHours % 24;
    final d = delta.inDays;
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
        Text(localizeAndFmtTime(arriveAt())),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ListTile(
        leading: Icon(passed == null ? Icons.question_mark : passed! ? Icons.check_circle : Icons.circle_outlined), 
        title: Text("${stop.name} (${stop.id})"),
        subtitle: genSubtitle(context),
        trailing: genTrailing(context),
      )
    );
  }
}
