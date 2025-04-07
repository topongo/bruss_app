import 'dart:collection';

import 'package:bruss/api.dart';
import 'package:bruss/data/direction.dart';
import 'package:bruss/data/route.dart' as br;
import 'package:bruss/data/schedule.dart';
import 'package:bruss/data/stop.dart';
import 'package:bruss/data/trip.dart';
import 'package:bruss/data/trip_updates.dart';
import 'package:bruss/database/database.dart';
import 'package:bruss/ui/pages/map/map.dart';
import 'package:bruss/ui/pages/map/sheet/details.dart';
import 'package:bruss/ui/pages/map/sheet/route_icon.dart';
import 'package:bruss/data/path.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/area_type.dart';
import 'stop_trip_list.dart';
import 'route_trip_list.dart';


abstract class DetailsCard extends StatefulWidget {
  DetailsCard({super.key, required this.sizeController});
  final BrussDB db = BrussDB();
  final trips = TripBundle(routes: {}, stops: {}, paths: {}, scheds: LinkedHashMap<(String, DateTime), Schedule>());
  final ValueNotifier<double> sizeController;
  DateTime referenceTime = DateTime.now();
  Key attemptKey = UniqueKey();
  
  Stop? stopReference();
  
  void favorite();
  Widget title();
  bool isFavorite();
  Future<void> loadMore();
  bool hasMore() => trips.hasMore();
  Widget cardContent(BuildContext context, bool isLoading, int total, Function() loadMore);

  @override
  State<StatefulWidget> createState() => _DetailsCardState();
}

class TripBundle {
  TripBundle({required this.routes, required this.stops, required this.scheds, required this.paths, this.total});
  Map<int, br.Route> routes = {};
  Map<(int, AreaType), Stop> stops = {};
  Map<String, Path> paths = {};
  LinkedHashMap<(String, DateTime), Schedule> scheds;
  int? total;
  bool hasMore() { return total == null || scheds.length < total!; }

  static Future<TripBundle> fromRequest(BrussRequest<Schedule> request) {
    return BrussApi.request(request)
      .then((trips) async {
        final Set<int> neededRoutes = trips.data!.map((t) => t.trip.route).toSet();
        final Set<String> neededPaths = trips.data!.map((t) => t.trip.path).toSet();
        final getters = neededRoutes.map((r) => BrussDB().getRoute(r));
        final it = (await Future.wait(getters)).map((r) => r).iterator;
        Map<int, br.Route> routes = {};
        while(it.moveNext()) {
          routes[it.current.id] = it.current;
        }
        final paths = await Path.getPathsCached(neededPaths);
        final pathsH = {for(final p in paths) p.id: p};
        final tripsH = LinkedHashMap<(String, DateTime), Schedule>.fromIterable(trips.data!, key: (t) => (t.trip.id, t.departure), value: (t) => t);
        final stopIds = trips.data!.map((t) => t.trip.times.keys).expand((e) => e).toSet();
        final stops = {
          for(final s in await BrussDB().getStopsById(stopIds))
            (s.id, s.type): s
        };
        return TripBundle(routes: routes, scheds: tripsH, stops: stops, total: trips.total, paths: pathsH);
      });
  }

  Future<void> getRtUpdates() async {
    final ids = scheds.keys.map((v) => v.$1).toList();
    if(ids.isEmpty) return;
    // this is a workaround, since the API doesn't distinguish a trip that departed now and a trip that
    // will depart next week, with the same id. we internally keep this data to being able to keep a
    // schedule, but in the end the tracking will be broken (aka: trips scheduled for monday at 7:00 from
    // a certain stop will receive rt updates even if it will depart next month or year...)
    final Map<String, DateTime> idsToDt = {for (final v in scheds.keys) v.$1: v.$2};
    final req = TripUpdates.apiGet(ids);
    final updates = await BrussApi.request(req);
    if(updates.data == null) {
      throw ApiException("No updates found");
    }
    for(var u in updates.data!) {
      if(idsToDt.containsKey(u.id) && scheds.containsKey((u.id, idsToDt[u.id]!))) {
        scheds[(u.id, idsToDt[u.id]!)]!.trip.update(u);
      }
    }
  }

  // merge to another TripBundle
  void merge(TripBundle other) {
    routes.addAll(other.routes);
    scheds.addAll(other.scheds);
    stops.addAll(other.stops);
    paths.addAll(other.paths);
    total = other.total;
  }
}

class StopCard extends DetailsCard {
  Map<int, br.Route> routes = {};

  StopCard({required this.stop, required super.sizeController, super.key});
  final Stop stop;

  @override
  void favorite() {
    if(stop.isFavorite == null || !stop.isFavorite!) {
      stop.isFavorite = true;
    } else {
      stop.isFavorite = false;
    }
    db.updateStop(stop);
  }
  
  @override
  bool isFavorite() => stop.isFavorite ?? false;

  @override
  Stop? stopReference() => stop;

  @override
  Future<void> loadMore() async {
    print("StopCard.future()");
    var req = Schedule.apiGetByStop(stop);
    final DateFormat fmt = DateFormat("HH:mm");
    req.query = "?limit=10&skip=${trips.scheds.length}&time=${fmt.format(referenceTime)}";
    trips.merge(await TripBundle.fromRequest(req));
  }

  @override
  Widget cardContent(BuildContext context, bool isLoading, int total, Function() loadMore) {
    return Column(
      children: [
        for(var t in trips.scheds.values)
          TripStopTile(sched: t, stop: stopReference()!, route: trips.routes[t.trip.route]!, onTap: () {
            selectedEntity.value = RouteDetails(route: trips.routes[t.trip.route]!, direction: t.trip.direction, sizeController: sizeController);
          }),
        hasMore() ? ElevatedButton(
          onPressed: loadMore, 
          child: isLoading ? const CircularProgressIndicator()
            : const Text("Load more")
        ) : total == 0 ? const Text("No trips") : const Text("No more trips")
      ],
    );
  }

  @override
  Widget title() => Text(stop.name, style: const TextStyle(fontSize: 20));
}

class _DetailsCardState extends State<DetailsCard> {
  int _count = 0;
  bool _init = false;
  bool _loading = false;
  bool _error = false;

  Future<void> loadMoreInner() async {
    if(_loading || !widget.trips.hasMore()) return;
    if (_init) {
      setState(() {
        _loading = true;
      });
    }
    await widget.loadMore();
    await widget.trips.getRtUpdates();
    setState(() {
      print("finished loading");
      _loading = false;
      _init = true;
    });
  }

  Future<void> loadMore() {
    return loadMoreInner().catchError((e, stack) {
      if (e is ApiException) {
        throw ApiException(e.error, stack: e.stack, retry: () => loadMore());
      } else {
        throw e;
      }
    }); 
  }

  @override
  void didUpdateWidget(covariant DetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    loadMore();
  }

  @override
  initState() {
    super.initState();
    loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            widget.title(),
            IconButton(
              icon: Icon(!widget.isFavorite() ? Icons.favorite_border : Icons.favorite),
              onPressed: () => setState(() { widget.favorite(); }),
            ),
          ]
        ),
        !_init ?
          const CircularProgressIndicator() :
          _error ?
            const Text("Error loading data") :
              widget.cardContent(context, _loading, widget.trips.total ?? 0, () {
                setState(() {
                  loadMore()
                    .catchError((e, stack) {
                      if (e is ApiException) {
                        throw ApiException(e.error, stack: e.stack, retry: () => loadMore());
                      } else {
                        throw e;
                      }
                    });
                });
              }),
          ],
    );
  }
}

class RouteCard extends DetailsCard {
  RouteCard({required this.route, required this.direction, required super.sizeController, this.stop, super.key});
  final br.Route route;
  final Direction direction;
  final Stop? stop;

  @override
  void favorite() {
    if(route.isFavorite == null || !route.isFavorite!) {
      route.isFavorite = true;
    } else {
      route.isFavorite = false;
    }
    db.updateRoute(route);
  }
  
  @override
  bool isFavorite() => route.isFavorite ?? false;

  @override
  Stop? stopReference() => stop;

  @override
  Future<void> loadMore() async {
    print("RouteCard.future()");
    var req = Schedule.apiGetByRoute(route);
    final DateFormat fmt = DateFormat("HH:mm");
    req.query = "?limit=9&skip=${trips.scheds.length}&time=${fmt.format(referenceTime)}";
    trips.merge(await TripBundle.fromRequest(req));
  }

  @override
  Widget cardContent(BuildContext context, bool isLoading, int total, Function() loadMore) {
    bool passed = true;
    return isLoading ? const CircularProgressIndicator() :
      DefaultTabController(
        initialIndex: 0,
        length: trips.scheds.length,
        animationDuration: const Duration(milliseconds: 1000),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            TabBar(
              isScrollable: true,
              tabs: [
                for(var t in trips.scheds.values)
                  Tab(text: "${t.trip.headsign} (${t.trip.id})"),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    print("loadMore, value:");
                    print("controller: ${DefaultTabController.of(context)}");
                  },
                  child: const Tab(text: "Load more")
                )
              ],
            ),
            LayoutBuilder(
              builder: (context, constraints) => ValueListenableBuilder(
                valueListenable: sizeController,
                builder: (context, double size, child) {
                  // print("Trip sequence at index 0:");
                  // for (var t in trips.trips.values.first.times.entries) {
                  //   print("${t.key} (${trips.stops[(t.key, route.areaType)]!.name}): ${fmt.format(t.value.arrival)}");
                  // }
                  // print("size: $size");
                  return SizedBox(
                    width: constraints.maxWidth - 48,
                    height: sizeController.value - 100,
                    child: child,
                  ); 
                },
                child: TabBarView(
                  children: [
                    for(var t in trips.scheds.values)
                      ListView.builder(
                        itemCount: trips.paths[t.trip.path]?.sequence.length ?? 1,
                        itemBuilder: (context, index) {
                          if (!trips.paths.containsKey(t.trip.path)) {
                            return const Center(child: Text("No path found"));
                          }
                          final currentStop = trips.paths[t.trip.path]!.sequence[index];
                          // print("currentStop: ${route.areaType}/$currentStop");
                          if (currentStop == t.trip.nextStop && t.trip.lastStop != t.trip.nextStop) {
                            print("currentStop: ${route.areaType}/$currentStop");
                            passed = false;
                          } else if (index == 0) {
                            passed = true;
                          }
                          return TripRouteTile(sched: t, route: route, passed: passed, stop: trips.stops[(currentStop, route.areaType)]!, onTap: () {});
                        }
                      ),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ),
              )
            ),
          ]
        )
      );
  }

  @override
  Widget title() => Expanded(child: SizedBox(height: 70, child: ListView(children: [ListTile(
    leading: RouteIcon(label: route.code, color: route.color),
    title: Text(route.name, style: const TextStyle(fontSize: 20)),
    subtitle: Text("Direction: $direction"),
  )])));
}
