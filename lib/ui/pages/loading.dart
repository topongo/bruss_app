import 'package:flutter/material.dart';
import 'package:bruss/database/database.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingPage extends StatefulWidget {
  LoadingPage({super.key});
  final BrussDB db = BrussDB();

  @override
  State<StatefulWidget> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  static const SvgAssetLoader icon = SvgAssetLoader('assets/images/logo.svg');

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture(
            icon,
            width: 200,
            height: 200,
          ),
          SizedBox(height: 20),
          CircularProgressIndicator(),
        ],
      ))
    );
  }
}
