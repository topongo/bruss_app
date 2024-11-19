import 'dart:collection';

import 'package:bruss/api.dart';
import 'package:bruss/data/route.dart' as br;
import 'package:bruss/data/stop.dart';
import 'package:bruss/data/trip.dart';
import 'package:bruss/data/trip_updates.dart';
import 'package:bruss/database/database.dart';
import 'package:bruss/error.dart';
import 'package:bruss/ui/pages/map/sheet/route_icon.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'trip_details.dart';


abstract class DetailsCard extends StatefulWidget {
  DetailsCard({super.key});
  final BrussDB db = BrussDB();
  final trips = TripBundle(routes: {}, trips: LinkedHashMap<String, Trip>());
  Key attemptKey = UniqueKey();
  
  Stop? stopReference();
  
  void favorite();
  String title();
  bool isFavorite();
  Future<void> loadMore();
  bool hasMore() => trips.hasMore();

  @override
  State<StatefulWidget> createState() => _DetailsCardState();
}

class TripBundle {
  TripBundle({required this.routes, required this.trips, this.total});
  Map<int, br.Route> routes = {};
  LinkedHashMap<String, Trip> trips;
  int? total;
  bool hasMore() { print(total); return total == null || trips.length < total!; }

  static Future<TripBundle> fromRequest(BrussRequest<Trip> request, int Function(Trip, Trip)? sorter) {
    return BrussApi.request(request)
      .then((trips) async {
        print("Got response from API, total count is ${trips.total}");
        final Set<int> neededRoutes = trips.data!.map((t) => t.route).toSet();
        final getters = neededRoutes.map((r) => BrussDB().getRoute(r));
        final it = (await Future.wait(getters)).map((r) => r).iterator;
        Map<int, br.Route> routes = {};
        while(it.moveNext()) {
          routes[it.current.id] = it.current;
        }
        // done by the API by now
        // trips.data!.sort(sorter);
        final tripsH = LinkedHashMap<String, Trip>.fromIterable(trips.data!, key: (t) => t.id, value: (t) => t);
        return TripBundle(routes: routes, trips: tripsH, total: trips.total);
      });
  }

  Future<void> getRtUpdates() async {
    final ids = trips.keys.toList();
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
    total = other.total;
  }
}

class StopCard extends DetailsCard {
  Map<int, br.Route> routes = {};

  StopCard({required this.stop, super.key});
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
    final now = DateTime.now();
    final DateFormat fmt = DateFormat("HH:mm");
    req.query = "?limit=10&skip=${trips.trips.length}&time=${fmt.format(DateTime.now())}";
    trips.merge(await TripBundle.fromRequest(req, Trip.sortByTimesStop(stop)));
  }

  @override
  String title() => stop.name;
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
  void initState() {
    super.initState();
    loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title(), style: const TextStyle(fontSize: 20)),
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
              Column(
                children: [
                  for(var t in widget.trips.trips.values)
                    TripStopTile(trip: t, route: widget.trips.routes[t.route]!, stop: widget.stopReference()!),
                  widget.hasMore() ? ElevatedButton(
                    onPressed: () {
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
                    }, 
                    child: const Text("Load more")
                  ) : const Text("No more trips")
                ],
              )
      ],
    );

    // return Padding(
    //     padding: const EdgeInsets.all(15.0),
    //     child: Column(
    //       children: [
    //         Row(
    //           children: [
    //             Expanded(child: Text(widget.title(), style: const TextStyle(fontSize: 20))),
    //             IconButton(
    //               icon: Icon(widget.isFavorite() ? Icons.favorite_border : Icons.favorite),
    //               onPressed: () => setState(() { widget.favorite(); }),
    //             ),
    //           ]
    //         ),
    //         // Icon(Icons.directions_bus),
    //         TripList(widget.trips),
    //       ]
    //     ),
    // );
  }
}
