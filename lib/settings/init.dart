import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  Settings._({required this.prefs});
  static final Settings _instance = Settings._(prefs: SharedPreferences.getInstance());
  final Future<SharedPreferences> prefs;

  factory Settings() {
    return _instance;
  }

  static Record<String, String> splitKey(String key) {
    final List<String> path = key.split(".");
    if (path.length != 2) {
      throw Exception("Invalid key format: $key");
    }
    return Record(path[0], path[1]);
  }

  Future<void> setApiUrl(String url) async {
    final prefs = await this.prefs;
    prefs.setString("api.url", url);
  }

  Future<String> get(String key) async {
    final prefs = await this.prefs;
    return prefs.getString(key) ?? DefaultSettings.get(key);
  }

  Future<Map<String, dynamic>> getAll() async {
    final prefs = await this.prefs;
    final Map<String, dynamic> acc = DefaultSettings.defaults;
    prefs.getKeys().map((key) async {
      final List<String> path = key.split(".");
      if (path.length != 2) {
        return;
      } else {
        if (!acc.containsKey(path[0])) {
          acc[path[0]] = {};
        }
        acc[path[0]][path[1]] = prefs.get(key);
      }
    });
    return acc;
  }
}

class DefaultSettings {
  static final Map<String, dynamic> defaults = {
    "api": {
      "url": "http://127.0.0.1:8000/api/v1/",
      "_title": "API",
    },
  };

  static String get(String key) {
    final List<String> path = key.split(".");
    final val = DefaultSettings.defaults[key];
    if (val == null) {
      throw Exception("Setting with key $key doesn't exists");
    }
    return val;
  }
}

class SettingsDescription {
  static final Map<String, String> descriptions = {
    "api.url": "DEV: Url of the API server to use",
  };

  static String get(String category, String setting) {
    return SettingsDescription.descriptions["$category.$setting"] ?? "DESCRIPTION NOT FOUND";
  }
}
