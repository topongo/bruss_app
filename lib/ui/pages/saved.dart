import 'package:bruss/data/area.dart';
import 'package:bruss/data/area_type.dart';
import 'package:bruss/data/route.dart' as br;
import 'package:bruss/data/stop.dart';
import 'package:bruss/database/database.dart';
import 'package:bruss/ui/pages/map/map.dart';
import 'package:bruss/ui/pages/map/sheet/details.dart';
import 'package:bruss/ui/pages/map/sheet/route_icon.dart';
import 'package:flutter/material.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});
  static const urbanIcon = AssetImage("assets/icons/urban_stop.png");
  static const extraurbanIcon = AssetImage("assets/icons/extraurban_stop.png");
  static const headerColor = Color.fromARGB(255, 60, 60, 60);

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  late final Future<void> _future;
  late final List<br.Route> routes;
  late final List<Stop> stops;
  late final Map<int, Area> areas;

  @override
  void initState() {
    super.initState();
    _future = Future.wait([
      BrussDB().getRoutes().then((routes) => this.routes = routes),
      BrussDB().getStops().then((stops) => this.stops = stops),
      BrussDB().getAreas().then((areas) => this.areas = {for(final a in areas) a.id: a}),
    ]).then((_) {
    });
  }

  void _removeRoute(br.Route route) {
    setState(() {
      route.isFavorite = false;
    });
    BrussDB().updateRoute(route);
  }

  void _removeStop(Stop stop) {
    setState(() {
      stop.isFavorite = false;
    });
    BrussDB().updateStop(stop);
  }

  @override
  Widget build(BuildContext context) {
    // load PNGs of stop icons
    return Scaffold(
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final favRoutes = routes.where((r) => r.isFavorite ?? false).toList();
            final favStops = stops.where((s) => s.isFavorite ?? false).toList();
            print('Routes: ${favRoutes.length}, Stops: ${favStops.length}');
            return ListView.builder(
              itemCount: favRoutes.length + favStops.length + 2,
              itemBuilder: (context, index) {
                print("indexing $index");
                if (index == 0) {
                  return const ListTile(
                    title: Text('Routes'),
                    tileColor: SavedPage.headerColor,
                  );
                } else if (index < favRoutes.length + 1) {
                  final r = favRoutes[index - 1];
                  return ListTile(
                    leading: RouteIcon.fromRoute(r),
                    title: Text(r.name),
                    subtitle: Text(areas[r.area]!.label),
                    trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _removeRoute(r)),
                    onTap: () {
                      // the tab switch is handled by the HomePage, by listening on selectedEntity changes
                      selectedEntity.value = RouteDetails(route: r);
                    }
                  );
                } else if (index == favRoutes.length + 1) {
                  return const ListTile(
                    title: Text('Stops'),
                    tileColor: SavedPage.headerColor,
                  );
                } else {
                  final s = favStops[index - favRoutes.length - 2];
                  return ListTile(
                    leading: s.type == AreaType.urban ? const Image(image: SavedPage.urbanIcon) : const Image(image: SavedPage.extraurbanIcon),
                    title: Text(s.name),
                    subtitle: Text(s.town ?? s.code),
                    trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _removeStop(s)),
                    onTap: () {
                      // the tab switch is handled by the HomePage, by listening on selectedEntity changes
                      selectedEntity.value = StopDetails(stop: s);
                    }
                  );
                }
              }
            );
          }
        },
      ),
    );
  }
}
