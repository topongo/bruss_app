import 'dart:collection';

import 'package:bruss/api.dart';
import 'package:bruss/data/direction.dart';
import 'package:bruss/data/route.dart' as br;
import 'package:bruss/data/stop.dart';
import 'package:bruss/data/trip.dart';
import 'package:bruss/data/trip_updates.dart';
import 'package:bruss/database/database.dart';
import 'package:bruss/ui/pages/map/map.dart';
import 'package:bruss/ui/pages/map/sheet/details.dart';
import 'package:bruss/ui/pages/map/sheet/route_icon.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/area_type.dart';
import 'stop_trip_list.dart';
import 'route_trip_list.dart';


abstract class DetailsCard extends StatefulWidget {
  DetailsCard({super.key, required this.sizeController});
  final BrussDB db = BrussDB();
  final trips = TripBundle(routes: {}, stops: {}, trips: LinkedHashMap<String, Trip>());
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
  TripBundle({required this.routes, required this.stops, required this.trips, this.total});
  Map<int, br.Route> routes = {};
  Map<(int, AreaType), Stop> stops = {};
  LinkedHashMap<String, Trip> trips;
  int? total;
  bool hasMore() { return total == null || trips.length < total!; }

  static Future<TripBundle> fromRequest(BrussRequest<Trip> request) {
    return BrussApi.request(request)
      .then((trips) async {
        final Set<int> neededRoutes = trips.data!.map((t) => t.route).toSet();
        final getters = neededRoutes.map((r) => BrussDB().getRoute(r));
        final it = (await Future.wait(getters)).map((r) => r).iterator;
        Map<int, br.Route> routes = {};
        while(it.moveNext()) {
          routes[it.current.id] = it.current;
        }
        final tripsH = LinkedHashMap<String, Trip>.fromIterable(trips.data!, key: (t) => t.id, value: (t) => t);
        final stopIds = trips.data!.map((t) => t.times.keys).expand((e) => e).toSet();
        final stops = {
          for(final s in await BrussDB().getStopsById(stopIds))
            (s.id, s.type): s
        };
        return TripBundle(routes: routes, trips: tripsH, stops: stops, total: trips.total);
      });
  }

  Future<void> getRtUpdates() async {
    final ids = trips.keys.toList();
    if(ids.isEmpty) return;
    final req = TripUpdates.apiGet(ids);
    final updates = await BrussApi.request(req);
    if(updates.data == null) {
      throw ApiException("No updates found");
    }
    for(var u in updates.data!) {
      if(trips.containsKey(u.id)) {
        trips[u.id]!.update(u);
      }
    }
  }

  // merge to another TripBundle
  void merge(TripBundle other) {
    routes.addAll(other.routes);
    trips.addAll(other.trips);
    stops.addAll(other.stops);
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
    var req = Trip.apiGetByStop(stop);
    final DateFormat fmt = DateFormat("HH:mm");
    req.query = "?limit=10&skip=${trips.trips.length}&time=${fmt.format(referenceTime)}";
    trips.merge(await TripBundle.fromRequest(req));
  }

  @override
  Widget cardContent(BuildContext context, bool isLoading, int total, Function() loadMore) {
    return Column(
      children: [
        for(var t in trips.trips.values)
          TripStopTile(trip: t, stop: stopReference()!, route: trips.routes[t.route]!, onTap: () {
            selectedEntity.value = RouteDetails(route: trips.routes[t.route]!, direction: t.direction, sizeController: sizeController);
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
    var req = Trip.apiGetByRoute(route);
    final DateFormat fmt = DateFormat("HH:mm");
    req.query = "?limit=9&skip=${trips.trips.length}&time=${fmt.format(referenceTime)}";
    trips.merge(await TripBundle.fromRequest(req));
  }

  @override
  Widget cardContent(BuildContext context, bool isLoading, int total, Function() loadMore) {
    final fmt = DateFormat("HH:mm");
    bool passed = true;
    return isLoading ? const CircularProgressIndicator() :
      DefaultTabController(
        initialIndex: 0,
        length: trips.trips.length + 1,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            TabBar(
              isScrollable: true,
              tabs: [
                for(var t in trips.trips.values)
                  Tab(text: "${t.headsign} (${t.id})"),
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
                    for(var t in trips.trips.values)
                      ListView.builder(
                        itemCount: t.times.length,
                        itemBuilder: (context, index) {
                          final currentStop = (t.times.keys.elementAt(index));
                          // print("currentStop: ${route.areaType}/$currentStop");
                          if (currentStop == t.nextStop && t.lastStop != t.nextStop) {
                            print("currentStop: ${route.areaType}/$currentStop");
                            passed = false;
                          } else if (index == 0) {
                            passed = true;
                          }
                          return TripRouteTile(trip: t, route: route, passed: passed, stop: trips.stops[(currentStop, route.areaType)]!, onTap: () {});
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
