import 'package:bruss/data/sample.dart';
import 'package:bruss/data/stop.dart';
import 'package:bruss/data/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'data/route.dart' as bdroute;
import 'api.dart';
import 'package:provider/provider.dart';
import 'dart:io';
// import 'database.dart';
import 'database/database.dart';

import 'ui/pages/map/map.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // print("${await getApplicationDocumentsDirectory()}");
  FlutterError.onError = (details) {
    if (kReleaseMode) exit(1);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    print(stack);
    FlutterError.presentError(FlutterErrorDetails(exception: error, stack: stack));
    return true;
  };
  mapStyle = await StyleReader(
    uri: 'https://github.com/immich-app/immich/raw/84da9abcbcb853dd853e2995ec944fc6e934da39/server/resources/style-dark.json',
        // logger: const Logger.console()
  ).read();
  runApp(App());
}

class App extends StatelessWidget {
  App({super.key});
  final BrussDB db = BrussDB();

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
        home: HomePage(),
      ),
    );
  }
}

class AppState extends ChangeNotifier {
}

class LoadingPage extends StatefulWidget {
  LoadingPage({super.key});
  final BrussDB db = BrussDB();

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
