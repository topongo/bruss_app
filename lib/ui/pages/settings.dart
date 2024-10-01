import 'package:bruss/settings/init.dart';
import 'package:flutter/material.dart';

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
          return Scaffold(
            body: ListView(
              children: [
                for(var cat in settings.entries)
                  ...[
                    ListTile( 
                      subtitle: Text(capitalize(cat.value["_title"])),
                    ),
                    for(var setting in cat.value.entries.where((e) => e.key != "_title"))
                      ListTile(
                        title: Text(capitalize(setting.key)),
                        subtitle: Text(setting.value),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("Edit value ${setting.key}"),
                                      TextField(
                                        textCapitalization: TextCapitalization.none,
                                        autocorrect: false,
                                        autofocus: true,
                                        keyboardType: TextInputType.url,
                                        controller: TextEditingController(
                                          text: setting.value,
                                        ),
                                      ), 
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        trailing: null,
                      ),
                  ],
              ],
            ),
          );
        }
      }
    );
  }
}
