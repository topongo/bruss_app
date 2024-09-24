import 'package:bruss/api.dart';
import 'package:bruss/data/route.dart' as br;
import 'package:bruss/data/stop.dart';
import 'package:bruss/data/trip.dart';
import 'package:bruss/database/database.dart';
import 'package:bruss/ui/pages/map/sheet/route_icon.dart';
import 'package:flutter/material.dart';

class TripList extends StatelessWidget {
  TripList({required this.trips, super.key});
  final List<Trip> trips;

  @override
  Widget build(BuildContext context) {
    _future ??= BrussApi.request(Trip.fromJson, "map/stop/u/${stop.id}/trips?time=16:00")
      .then((value) async {
        
      }); 

    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        
      }
    );
  }
}

// class StopTripList extends StatefulWidget {
//   const StopTripList({required this.stop, super.key});
//   final Stop stop;
// 
//   @override
//   State<StatefulWidget> createState() => _StopTripListState();
// }
// 
// class _StopTripListState extends State<StopTripList> {
//   Future<List<Trip>>? _future;
// 
//   @override
//   void initState() {
//     super.initState();
//     _future ??= BrussApi.request(Trip.fromJson, Trip.endpointStop(widget.stop))
//       .then((value) => value.data!);
//   }
// 
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//       future: _future,
//       builder: (context, snapshot) {
//         if(snapshot.connectionState != ConnectionState.done) {
//           return const CircularProgressIndicator();
//         } else {
//           return Column(
//             children: [
//               for(var t in snapshot.data!)
//                 ListTile(
//                   leading: RouteIcon(label: t.route.toString(), color: Colors.indigo),
//                   title: Text(t.headsign),
//                 )
//             ],
//           );
//         }
//       }
//     );
//   }
// }

// class StopTripList extends StatelessWidget {
//   StopTripList({/* required this.stop ,*/ super.key});
//   // final Stop stop;
//   final Future<List<Trip>> _future = BrussApi.request(Trip.fromJson, "map/stop/u/432/trips?time=16:00")
//     .then((value) {
//       return value.data!;
//     });
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//       future: _future,
//       builder: (context, snapshot) {
//         if(snapshot.connectionState != ConnectionState.done) {
//           return const CircularProgressIndicator();
//         } else {
//           return Column(
//             children: [
//               for(var t in snapshot.data!)
//                 ListTile(
//                   leading: RouteIcon(label: t.route.toString(), color: Colors.indigo),
//                   title: Text(t.headsign),
//                 )
//             ],
//           );
//         }
//       }
//     );
//   }
// }
