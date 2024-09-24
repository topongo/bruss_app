import 'package:bruss/database/database.dart';
import 'package:bruss/ui/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
