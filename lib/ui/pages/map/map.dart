import 'package:bruss/ui/pages/map/sheet/details.dart';
import 'package:flutter/material.dart';
import 'package:bruss/database/database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:bruss/ui/pages/map/sheet/details_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

const trento = LatLng(46.0620, 11.1294);
late Style mapStyle;

class MapPage extends StatefulWidget {
  MapPage({super.key});
  final Map<int, Marker> markers = {};

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final ValueNotifier<DetailsType?> selectedEntity = ValueNotifier<DetailsType?>(null);

  final BrussDB db = BrussDB();

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
	    // old version from conflicting commit
            // onTap: () => showBottomSheet(
            //   context: context, 
            //   builder: (context) => StopCard(stop: stop),
            // ), 
	    // newer version
            onTap: () {
              setState(() {
                selectedEntity.value = StopDetails(stop: stop);
              });
            },
          ),
        ));
      }
    });

    return PopScope(
      onPopInvokedWithResult: (x, y) async {
        print("aaaah! ($x, $y)");
      },
      child: Scaffold(
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
            DetailsSheet(selectedEntity: selectedEntity),
          ], 
        ),
        // bottomNavigationBar: BottomNavigationBar(
        //   items: [
        //     BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
        //     BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        //   ],
        // ),
      ),
    );
  }
}
