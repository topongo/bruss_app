import 'package:bruss/data/sample.dart';
import 'package:bruss/error.dart';
import 'package:bruss/ui/pages/loading.dart';
import 'package:bruss/ui/pages/map/map.dart';
import 'package:bruss/ui/pages/map/sheet/details.dart';
import 'package:bruss/ui/pages/map/sheet/details_sheet.dart';
import 'package:bruss/ui/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:bruss/database/database.dart';
import 'package:bruss/api.dart';
import 'package:bruss/data/area.dart';
import 'package:bruss/data/stop.dart';
import 'package:bruss/data/route.dart' as br;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  late Future<void> _future;
  var selectedIndex = 0;

  @override
  void initState() {
    _future = checkApiConnection().then(
      (_) => initDB().then(
        (_) => setState(() { loading = false; })
      )
    );
    super.initState();
  }

  static Future<void> checkApiConnection() async {
    BrussApi.request(BrussRequest.status).then((value) async {
      if(value.isError) {
        throw ApiException.fromResponse(value);
      }
    }).catchError((error, stack) {
      if (error is ApiException) {
        ErrorHandler.onPlatformError(error.attachRetry(checkApiConnection), stack);
      }
    });
  } 

  static Future<void> initDB() async {
    final db = BrussDB();
    final areas = await db.getAreas();
    final stops = await db.getStops();
    final routes = await db.getRoutes();

    final toFetch = <Future<void>>[];
    if(areas.isEmpty) {
      toFetch.add(BrussApi.request(Area.apiGetAll).then((value) {
        return db.insertAreas(value.data!);
      }));
    }

    if(stops.isEmpty) {
      toFetch.add(BrussApi.request(Stop.apiGetAll).then((value) {
        return db.insertStops(value.data!);
      }));
    }

    if(routes.isEmpty) {
      toFetch.add(BrussApi.request(br.Route.apiGetAll).then((value) {
        return db.insertRoutes(value.data!);
      }));
    }

    return Future.wait(toFetch).then((_) {});
  }

  Widget _loadingPage(BuildContext context) {
    return LoadingPage();
  }

  Widget _mainPage(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = MapPage();
        break;
      case 1:
        page = SettingsPage();
        break;
      case 2:
        page = Placeholder();
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
          onPressed: () { initState(); },
          child: const Text("Retry"),
        ),
      ]))
    );
  }
  
  @override
  Widget build(BuildContext context) {
    ErrorHandler.registerContext(context);
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
