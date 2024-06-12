import 'package:bruss/data/stop.dart';
import 'package:bruss/data/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'data/area.dart';
import 'api.dart';
import 'package:provider/provider.dart';
import 'dart:io';
// import 'database.dart';
import 'database/database.dart';


const trento = LatLng(46.0620, 11.1294);
late Style mapStyle;

void main() async {
  print("${await getApplicationDocumentsDirectory()}");
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    if (kReleaseMode) exit(1);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.presentError(FlutterErrorDetails(exception: error, stack: stack));
    return true;
  };
  mapStyle = await StyleReader(
    uri: 'https://github.com/immich-app/immich/raw/84da9abcbcb853dd853e2995ec944fc6e934da39/server/resources/style-dark.json',
        // logger: const Logger.console()
  ).read();
  runApp(App(db: BrussDB()));
}

class App extends StatelessWidget {
  const App({required this.db, super.key});
  final BrussDB db;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        // builder: (context, child) {
        //   Widget error = const Center(child: Text("An error occurred"));
        //   if(child is Scaffold || child is Navigator) {
        //     error = Scaffold(body: error);
        //   }
        //   ErrorWidget.builder = (details) => error;
        //   if (child != null) return child;
        //   throw StateError('widget is null');
        // },
        // title: 'Bruss',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange, brightness: Brightness.dark),
          fontFamily: "Fira Sans",
        ),
        home: HomePage(db: db),
      ),
    );
  }
}

class AppState extends ChangeNotifier {
}

class HomePage extends StatefulWidget {
  const HomePage({required this.db, super.key});
  final BrussDB db;

  @override
  State<HomePage> createState() => _HomePageState();
}

class RouteIcon extends StatelessWidget {
  const RouteIcon({required this.label, required this.color, super.key});
  final String label;
  final Color color;

  @override 
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(12.0)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Text(label, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
      ),
    );
  }
}

class StopTripList extends StatelessWidget {
  StopTripList({/* required this.stop ,*/ super.key});
  // final Stop stop;
  final Future<List<Trip>> _future = BrussApi.request(Trip.fromJson, "map/stop/u/432/trips?time=16:00")
    .then((value) {
      return value.data!;
    });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if(snapshot.connectionState != ConnectionState.done) {
          return CircularProgressIndicator();
        } else {
          return Column(
            children: [
              for(var t in snapshot.data!)
                ListTile(
                  leading: RouteIcon(label: t.route.toString(), color: Colors.indigo),
                  title: Text(t.headsign),
                )
            ],
          );
        }
      }
    );
  }
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  late Future<void> _future;
  var selectedIndex = 2;

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
        page = StopTripList();
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

class MapPage extends StatelessWidget {
  const MapPage({required this.db, super.key});

  final BrussDB db;

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];
    db.getStops().then((stops) {
      for(var stop in stops) {
        if((const Distance()).as(LengthUnit.Kilometer, trento, stop.position) > 2) continue;
        markers.add(Marker(
          width: 200,
          height: 50,
          point: stop.position,
          child: GestureDetector(
            child: const Column(
              children: [
                // Text(stop.name, style: const TextStyle(color: Colors.red)),
                Icon(Icons.location_on, color: Colors.red),
              ],
            ),
            onTap: () => showModalBottomSheet(
              context: context, 
              builder: (context) => StopCard(stop: stop, db: db),
            ), 
          ),
        ));
      }
    });

    return Scaffold(
      body: FlutterMap(
        options: const MapOptions(
          initialCenter:  trento,
          initialZoom: 15.0,
          interactionOptions: InteractionOptions(
            // flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            rotationThreshold: 100.0,
            enableMultiFingerGestureRace: false,
          ),
            // interactiveFlags: InteractiveFlag.rotate,
        ),
        children: [
          VectorTileLayer(
            theme: mapStyle.theme,
            tileProviders: mapStyle.providers,
            sprites: mapStyle.sprites,
            layerMode: VectorTileLayerMode.vector,
            // urlTemplate: 'https://api-l.cofractal.com/v0/maps/vt/overture/{z}/{x}/{y}',
            // userAgentPackageName: '',
            // Plenty of other options available!
          ),
          MouseRegion(
            hitTestBehavior: HitTestBehavior.deferToChild,
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                
              },
              child: MarkerLayer(
                markers: markers,
                rotate: true,
                
              )
            ),
          ),
          RichAttributionWidget(
            animationConfig: const ScaleRAWA(), // Or `FadeRAWA` as is default
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
              ),
            ],
          ),
        ], 
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   items: [
      //     BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
      //     BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
      //   ],
      // ),
    );
  }
}

class LoadingPage extends StatefulWidget {
  const LoadingPage({required this.db, super.key});
  final BrussDB db;

  @override
  State<StatefulWidget> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  static const Image icon = Image(image: AssetImage('assets/images/icon.png'), width: 200);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          SizedBox(height: 20),
          CircularProgressIndicator(),
        ],
      ))
    );
  }
}

class StopCard extends StatefulWidget {
  const StopCard({required this.stop, required this.db, super.key});
  final Stop stop;
  final BrussDB db;

  void favorite() {
    if(stop.isFavorite == null || !stop.isFavorite!) {
      stop.isFavorite = true;
    } else {
      stop.isFavorite = false;
    }
    db.updateStop(stop);
  }

  @override
  State<StatefulWidget> createState() => _StopCardState();
}

class _StopCardState extends State<StopCard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.stop.name, style: const TextStyle(fontSize: 20))),
                IconButton(
                  icon: Icon(widget.stop.isFavorite == null || !widget.stop.isFavorite! ? Icons.favorite_border : Icons.favorite),
                  onPressed: () => setState(() { widget.favorite(); }),
                ),
              ]
            ),
            // Icon(Icons.directions_bus),
            StopTripList(),
          ]
        ),
      ),
      persistentFooterButtons: [
        Center(child: Text("ID: ${widget.stop.id}")),
      ],
    );
  }
}

