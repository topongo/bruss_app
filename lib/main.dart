import 'package:bruss/ui/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'ui/pages/map/map.dart';
import 'error.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // print("${await getApplicationDocumentsDirectory()}");
  FlutterError.onError = (details) {
    ErrorHandler.onFlutterError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorHandler.onPlatformError(error, stack);
    return true;
  };
  mapStyle = await StyleReader(
    uri: 'https://github.com/immich-app/immich/raw/84da9abcbcb853dd853e2995ec944fc6e934da39/server/resources/style-dark.json',
        // logger: const Logger.console()
  ).read();
  runApp(App());
}

