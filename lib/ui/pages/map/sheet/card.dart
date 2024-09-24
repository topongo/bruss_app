import 'package:bruss/api.dart';
import 'package:bruss/data/route.dart' as br;
import 'package:bruss/data/stop.dart';
import 'package:bruss/data/trip.dart';
import 'package:bruss/database/database.dart';
import 'package:bruss/ui/pages/map/bottom_sheet/route_icon.dart';
import 'package:bruss/ui/pages/map/sheet/stop_trip_list.dart';
import 'package:flutter/material.dart';


abstract class DetailsCard extends StatefulWidget {
  DetailsCard({super.key});
  final BrussDB db = BrussDB();
  final Future<TripBundle> trips;
  
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

  Future<TripBundle> fromRequest(BrussRequest<Trip> request, int Function(Trip, Trip)? sorter) {
    return BrussApi.request(request)
      .then((value) async {
        final Set<int> neededRoutes = value.data!.map((t) => t.route).toSet();
        final getters = neededRoutes.map((r) => BrussDB().getRoute(r));
        final it = (await Future.wait(getters)).map((r) => r).iterator;
        Map<int, br.Route> routes = {};
        while(it.moveNext()) {
          routes[it.current.id] = it.current;
        }
        value.data!.sort(sorter);
        return TripBundle(routes: routes, trips: trips);
      });
  }
}

class StopCard extends DetailsCard {
  Map<int, br.Route> routes = {};
  Future<List<Trip>> _future = TripBundle.fromRequest(BrussRequest(Trip.endpointStop(stop)));

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
  Future<List<Trip>>? future() => _future;

  @override
  String title() => stop.name;
}

class _DetailsCardState extends State<DetailsCard> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder( 
      future: widget.future(),
      builder: (context, snapshot) {
        if(snapshot.connectionState != ConnectionState.done) {
          return const CircularProgressIndicator();
        } else {
          return Column(
            children: [
              for(var t in snapshot.data!)
                ListTile(
                  leading: RouteIcon(label: routes[t.route]!.code, color: routes[t.route]!.color),
                  title: Text(t.headsign),
                ),
            ],
          );
        }
      }

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
