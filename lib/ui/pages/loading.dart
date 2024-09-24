import 'package:flutter/material.dart';
import 'package:bruss/database/database.dart';

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
