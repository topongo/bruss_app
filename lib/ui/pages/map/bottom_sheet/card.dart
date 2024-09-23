import 'package:bruss/data/stop.dart';
import 'package:bruss/database/database.dart';
import 'package:flutter/material.dart';



class StopCard extends DetailsCard {
  StopCard({required this.stop, super.key});
  final Stop stop;

  @override
  void favorite() {
    if(stop.isFavorite == null || !stop.isFavorite!) {
      stop.isFavorite = true;
    } else {
      stop.isFavorite = false;
    }
    db.updateStop(stop);
  }
  
  @override
  bool isFavorite() => stop.isFavorite ?? false;

  @override
  void title() => stop.name;
}


abstract class DetailsCard extends StatefulWidget {
  DetailsCard({super.key});
  final BrussDB db = BrussDB();
  
  void favorite();
  void title();
  bool isFavorite();

  @override
  State<StatefulWidget> createState() => _DetailsCardState();
}

class _DetailsCardState extends State<StopCard> {
  @override
  Widget build(BuildContext context) {
    print("building StopCard");
    return Padding(
        padding: const EdgeInsets.all(15.0),
        child: ListView(
          // mainAxisSize: MainAxisSize.max,
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
            StopTripList(stop: widget.stop),
          ]
        ),
    );
  }
}
