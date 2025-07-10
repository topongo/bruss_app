import 'dart:async';

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
                      subtitle: Text(capitalize(SettingsMeta.title(cat.key))),
                    ),
                    for(var setting in cat.value.entries.where((e) => e.key != "_title"))
                      ListTile(
                        title: Text(capitalize(setting.key)),
                        subtitle: Text(setting.value),
                        onTap: () {
                          final key = "${cat.key}.${setting.key}";

                          showSettingDialog(
                            context,
                            key,
                            setting.value,
                            (context, field) async {
                              final checked = await Settings().set(key, field.controller!.text);
                              setState(() {
                                settings[cat.key]![setting.key] = checked;
                              });
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            (context) => Navigator.of(context).pop(),
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

void showSettingDialog(BuildContext context, String key, String value, FutureOr<void> Function(BuildContext, TextField) onSave, Function(BuildContext) onCancel) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final field = TextField(
        textCapitalization: TextCapitalization.none,
        autocorrect: false,
        autofocus: true,
        keyboardType: TextInputType.url,
        controller: TextEditingController(
          text: value,
        ),
      );
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Edit value $key"),
              field,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () async => await onSave(context, field),
                    child: const Text("Save"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
