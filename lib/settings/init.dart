import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  Settings._({required this.prefs});
  static final Settings _instance = Settings._(prefs: SharedPreferences.getInstance());
  final Future<SharedPreferences> prefs;

  factory Settings() {
    return _instance;
  }

  static (String, String) splitKey(String key) {
    final List<String> path = key.split(".");
    if (path.length != 2) {
      throw Exception("Invalid key format: $key");
    }
    return (path[0], path[1]);
  }

  Future<String> get(String key) async {
    final prefs = await this.prefs;
    return prefs.getString(key) ?? SettingsMeta.get(key);
  }

  Future<Map<String, dynamic>> getAll() async {
    final prefs = await this.prefs;
    final Map<String, dynamic> acc = {};
    for (final e in SettingsMeta.defaults.entries) {
      final keys = Settings.splitKey(e.key);
      if (!acc.containsKey(keys.$1)) {
        acc[keys.$1] = {};
      }
      if (!acc[keys.$1].containsKey(keys.$2)) {
        acc[keys.$1][keys.$2] = e.value;
      }
    }
    for(final key in prefs.getKeys()) {
      final List<String> path = key.split(".");
      if (path.length != 2) {
        continue;
      } else {
        if (!acc.containsKey(path[0])) {
          acc[path[0]] = {};
        }
        acc[path[0]][path[1]] = prefs.get(key);
      }
    }
    return acc;
  }

  Future<String> set(String key, String value) async {
    final prefs = await this.prefs;
    final checked = SettingsMeta.check(key, value);
    prefs.setString(key, checked);
    return checked;
  }
}

class SettingsMeta {
  static final Map<String, String> defaults = {
    "api.url": "http://127.0.0.1:8000/api/v1/",
  };

  static final Map<String, String> titles = {
    "api": "API",
  };

  static final Map<String, String> descriptions = {
    "api.url": "DEV: Url of the API server to use",
  };

  static final Map<String, String Function(String)> checkers = {
    "api.url": (url) {
      if (!url.startsWith("http")) {
        throw Exception("Invalid url format");
      }
      if (!url.endsWith("/")) {
        url += "/";
      }
      return url;
    },
  };

  static String title(String sub) {
    return SettingsMeta.titles[sub] ?? "Unknown";
  }

  static String get(String key) {
    final (String, String) keys = Settings.splitKey(key);
    if (keys.$1.startsWith("_")) {
      throw Exception("Setting with key $key is private");
    }
    final val = SettingsMeta.defaults[key];
    if (val == null) {
      throw Exception("Setting with key $key doesn't exists");
    }
    return val;
  }

  static String check(String key, String value) {
    final check = SettingsMeta.checkers[key];
    if (check != null) {
      return check(value);
    }
    print("!!!WARNING!!!: No check for $key");
    return value;
  }

  static String description(String key) {
    return SettingsMeta.descriptions[key] ?? "";
  }
}
