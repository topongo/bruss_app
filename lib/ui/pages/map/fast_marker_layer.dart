import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:bruss/ui/pages/map/markers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';


double markerScaleFromMapZoom(double mapZoom) {
  return 10 + 17.0 * (mapZoom < 16.0 ? pow(2.0, mapZoom - 16.0) : pow(mapZoom - 15.0, 0.7));
}

class FastMarkersLayer extends StatefulWidget {
  final Iterable<FastMarker> markers;
  final void Function()? onLoad;

  const FastMarkersLayer(this.markers, {super.key, this.onLoad});

  @override
  State<FastMarkersLayer> createState() => _FastMarkersLayerState();
}

const int atlasImageSize = 1024;
const double atlasImageSizeDouble = 1024.0;

class _FastMarkersLayerState extends State<FastMarkersLayer> {
  ui.Image? atlasImage;
  late Future<void> _atlasFuture;

  @override
  void initState() {
    super.initState();
    _atlasFuture =  prepareAtlasImage().then((_) => widget.onLoad?.call());
  }

  Future<void> prepareAtlasImage() async {
    var pictureRecorder = ui.PictureRecorder();
    var canvas = Canvas(pictureRecorder);

    for (int i = 0; i < MarkerType.values.length; ++i) {
      final markerType = MarkerType.values[i];

      final data = await rootBundle.load(markerType.asset);
      final bytes = data.buffer.asUint8List();
      final image = await decodeImageFromList(bytes);
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      assert(imageSize.width == imageSize.height && imageSize.width == atlasImageSizeDouble, 
          "Image size ${imageSize.width} is not equal to atlas image size $atlasImageSizeDouble");


      canvas.drawImage(image, Offset(atlasImageSizeDouble * i, 0), Paint());
    }

    var picture = pictureRecorder.endRecording();
    final imageWithoutShadow =
        await picture.toImage(atlasImageSize * MarkerType.values.length, atlasImageSize);

    if (kDebugMode) {
      // dump atlas image to file
      try {
        final file = File("atlas_image.png");
        final byteData = await imageWithoutShadow.toByteData(format: ui.ImageByteFormat.png);
        final buffer = byteData!.buffer.asUint8List();
        await file.writeAsBytes(buffer);
        debugPrint("Atlas image saved to ${file.path}");
      } catch (e) {
        debugPrint("Error dumping atlas image: $e");
      }
    }

    // pictureRecorder = ui.PictureRecorder();
    // canvas = Canvas(pictureRecorder);

    // canvas.drawImage(
    //   imageWithoutShadow,
    //   Offset.zero,
    //   Paint()
    //     ..colorFilter = const ColorFilter.mode(Colors.grey, BlendMode.srcIn)
    //     ..imageFilter = ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
    // );
    // canvas.drawImage(
    //   imageWithoutShadow,
    //   Offset.zero,
    //   Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
    // );
    //
    // picture = pictureRecorder.endRecording();
    // final imageWithShadow =
    //     await picture.toImage(atlasImageSize * MarkerType.values.length, atlasImageSize);

    atlasImage = imageWithoutShadow;
  }

  @override
  Widget build(BuildContext context) {
    final mapState = MapCamera.of(context);
    final markerScale = markerScaleFromMapZoom(mapState.zoom);
    
    return FutureBuilder(
      future: _atlasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && atlasImage != null) {
          return RepaintBoundary(
            child: CustomPaint(
              painter: _FastMarkerPainter(atlasImage!, mapState, widget.markers, markerScale),
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.done && snapshot.hasError) {
          throw snapshot.error!;
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class FastMarker {
  final LatLng position;
  final MarkerType type;
  final double? rotation;

  FastMarker({required this.position, required this.type, this.rotation});

  factory FastMarker.fromMapMarker(MapMarker marker) {
    return FastMarker(position: marker.position, type: marker.type);
  }
}

class _FastMarkerPainter extends CustomPainter {
  final MapCamera mapState;
  final Iterable<FastMarker> markers;
  final ui.Image atlasImage;
  final double scale;

  const _FastMarkerPainter(this.atlasImage, this.mapState, this.markers, this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    // print("===> redrawing atlas!");
    canvas.drawAtlas(
      atlasImage,
      markers.map((marker) {
        final pos = mapState.project(marker.position) -
            mapState.pixelOrigin.toDoublePoint();
        final rotationInRadians = (marker.rotation ?? 0) * (pi / 180);
        return RSTransform.fromComponents(
          rotation: rotationInRadians,
          scale: scale / atlasImageSizeDouble / 0.8,
          anchorX: atlasImageSizeDouble / 2,
          anchorY: atlasImageSizeDouble / 2,
          translateX: pos.x,
          translateY: pos.y,
        );
      }).toList(),
      markers.map((marker) {
        // print("drawing marker ${marker.type.name} at ${marker.position} (position in atlas is ${marker.type.index * atlasImageSizeDouble})");
        return Rect.fromLTWH(
          atlasImageSizeDouble * marker.type.index,
          0,
          atlasImageSizeDouble,
          atlasImageSizeDouble,
        );
      }).toList(),
      null,
      null,
      null,
      Paint()..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_FastMarkerPainter oldDelegate) => true;
}
