import 'package:flutter/material.dart';
import 'package:bruss/database/database.dart';
import 'package:bruss/api.dart';
import 'package:bruss/data/area.dart';
import 'package:bruss/data/stop.dart';
import 'package:bruss/data/route.dart' as br;

class HomePage extends StatefulWidget {
  HomePage({super.key});
  final BrussDB db = BrussDB();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  late Future<void> _future;
  var selectedIndex = 0;


  @override
  void initState() {
    _future = initDB(widget.db).then((value) {
      setState(() {
        loading = false; 
      });
    });
    super.initState();
  }

  static Future<void> initDB(BrussDB db) async {
    final areas = await db.getAreas();
    final stops = await db.getStops();
    final routes = await db.getRoutes();

    final toFetch = <Future<void>>[];
    if(areas.isEmpty) {
      toFetch.add(BrussApi.request(Area.fromJson, Area.endpoint).then((value) {
        return db.insertAreas(value.data!);
      }));
    }

    if(stops.isEmpty) {
      toFetch.add(BrussApi.request(Stop.fromJson, Stop.endpoint).then((value) {
        return db.insertStops(value.data!);
      }));
    }

    if(routes.isEmpty) {
      toFetch.add(BrussApi.request(br.Route.fromJson, br.Route.endpoint).then((value) {
        return db.insertRoutes(value.data!);
      }));
    }

    return Future.wait(toFetch).then((_) {});
  }

  Widget _loadingPage(BuildContext context) {
    return LoadingPage(db: widget.db);
  }

  Widget _mainPage(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = MapPage(db: widget.db);
        break;
      case 1:
        page = const Text("Settings");
        break;
      case 2:
        page = BottomSheet(
          selectedEntity: ValueNotifier<DetailsType?>(StopDetails(stop: ApiSampleData.stop, db: widget.db))
        );
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }


    return LayoutBuilder(builder: (context, constraints) { return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Bruss"),
      ),
      drawer: Drawer(
        child: SafeArea(child: NavigationRail(
          extended: true,
          destinations: const [
            // NavigationRailDestination(icon: Icon(Icons.home), label: Text("Generator")),
            // NavigationRailDestination(icon: Icon(Icons.favorite), label: Text("Favorites")),
            NavigationRailDestination(icon: Icon(Icons.map), label: Text("Map")),
            NavigationRailDestination(icon: Icon(Icons.settings), label: Text("Settings")),
            NavigationRailDestination(icon: Icon(Icons.science), label: Text("Testing")),
          ],
          selectedIndex: selectedIndex,
          onDestinationSelected: (value) => { 
            setState(() {
              selectedIndex = value;
              Navigator.pop(context);
            })
          },
        ))
      ),
      body: Row(
        children: [
          Expanded(child: Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: page,
          ))
        ],
      ),
    ); });
  }

  Widget _errorPage(BuildContext context, Object error, Object stack) {
    return Scaffold(
      body: Center(child: Column(children: [
        const Text("An error occurred:"),
        Text(error.toString()),
        const SizedBox(height: 10),
        Text(stack.toString()),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () { setState(() { _future = initDB(widget.db); }); },
          child: const Text("Retry"),
        ),
      ]))
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting) {
          return _loadingPage(context);
        } else if(snapshot.hasError) {
          return _errorPage(context, snapshot.error!, snapshot.stackTrace!);
        } else {
          return _mainPage(context);
        }
      }
    );
  }
}
