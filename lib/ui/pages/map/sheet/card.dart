import 'package:bruss/api.dart';
import 'package:bruss/data/route.dart' as br;
import 'package:bruss/data/stop.dart';
import 'package:bruss/data/trip.dart';
import 'package:bruss/database/database.dart';
import 'package:bruss/error.dart';
import 'package:bruss/ui/pages/map/sheet/route_icon.dart';
import 'package:flutter/material.dart';


abstract class DetailsCard extends StatefulWidget {
  DetailsCard({super.key});
  final BrussDB db = BrussDB();
  final Future<TripBundle>? trips = null;
  Key attemptKey = UniqueKey();
  
  void favorite();
  String title();
  bool isFavorite();
  Future<TripBundle>? future();

  @override
  State<StatefulWidget> createState() => _DetailsCardState();
}

class TripBundle {
  TripBundle({required this.routes, required this.trips});
  Map<int, br.Route> routes = {};
  List<Trip> trips;

  static Future<TripBundle> fromRequest(BrussRequest<Trip> request, int Function(Trip, Trip)? sorter) {
    return BrussApi.request(request)
      .then((trips) async {
        final Set<int> neededRoutes = trips.data!.map((t) => t.route).toSet();
        final getters = neededRoutes.map((r) => BrussDB().getRoute(r));
        final it = (await Future.wait(getters)).map((r) => r).iterator;
        Map<int, br.Route> routes = {};
        while(it.moveNext()) {
          routes[it.current.id] = it.current;
        }
        trips.data!.sort(sorter);
        return TripBundle(routes: routes, trips: trips.data!);
      });
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
  Future<TripBundle>? future() {
    print("StopCard.future()");
    return TripBundle.fromRequest(Trip.apiGetByStop(stop), Trip.sortByTimesStop(stop));
  }

  @override
  String title() => stop.name;
}

class _DetailsCardState extends State<DetailsCard> {
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
        FutureBuilder( 
          key: widget.attemptKey,
          future: widget.future(),
          builder: (context, snapshot) {
            if(snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            } else if(snapshot.hasError) {
              ErrorHandler.onPlatformError(snapshot.error!, snapshot.stackTrace!);
              return FutureBuilderError("Error loading trips", () => setState(() {
                // print("Retrying...");
                // attemptKey = UniqueKey();
              }), snapshot.error!, snapshot.stackTrace!);
            } else {
              final routes = snapshot.data!.routes;
              final trips = snapshot.data!.trips;
              return Column(
                children: [
                  for(var t in trips)
                    ListTile(
                      leading: RouteIcon(label: routes[t.route]!.code, color: routes[t.route]!.color),
                      title: Text(t.headsign),
                    ),
                ],
              );
            }
          },
        ),
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
