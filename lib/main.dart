import 'dart:convert';
import 'dart:io';

import 'package:bruss/api.dart';
import 'package:bruss/ui/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
import 'error.dart';
import 'ui/pages/map/map.dart';

late Style mapStyle;

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
  // mapStyle = await StyleReader(
  //   uri: 'https://github.com/immich-app/immich/raw/84da9abcbcb853dd853e2995ec944fc6e934da39/server/resources/style-dark.json',
  //       // logger: const Logger.console()
  // ).read();

  final rawStyle = await rootBundle.loadString("assets/map_style.json");
  final Map<String, dynamic> dataStyle = jsonDecode(rawStyle);
  final style = Style(
    theme: ThemeReader().read(dataStyle),
    providers: TileProviders(
      {"immich-map": NetworkVectorTileProvider(
        type: TileProviderType.vector,
        urlTemplate: "https://api-l.cofractal.com/v0/maps/vt/overture/{z}/{x}/{y}",
        maximumZoom: 15,
        minimumZoom: 7,
      )}
    ),
  );
  mapStyle = style;

  MapInteractor.init();

  runApp(App());
}

