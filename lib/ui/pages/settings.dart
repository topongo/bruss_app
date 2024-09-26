import 'package:bruss/settings/init.dart';
import 'package:flutter/material.dart';
import 'package:bruss/utils/extensions.dart';

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class SettingsPage extends StatefulWidget {
  final Future<Map<String, dynamic>> settings = Settings().getAll();

  @override 
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.settings,
      builder: (context, snapshot) {
        if(snapshot.connectionState != ConnectionState.done) {
          return const CircularProgressIndicator();
        } else {
          final settings = snapshot.data!;
          print(settings.values);
          return ListView(
            children: [
              for(var category in settings.values)
                ...[
                  ListTile(
                    title: Text("${category["_title"]} Settings"),
                  ),
                  for(var setting in category.entries.where((entry) => !entry.key.startsWith("_")))
                    OverflowBar(
                      onTap: () {
                        print("Tapped ${setting.key}");
                      },
                      child: ListTile(
                      title: Text(capitalize(setting.key)),
                      subtitle: Text(SettingsDescription.get(category["_title"], setting.key)),
                    ),          
                  Divider(height: 0),
                ],
              ]
          );
        }
      }
    );
  }
}
