import 'dart:async';

import 'package:bruss/ui/pages/map/map.dart';
import 'package:latlong2/latlong.dart';
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

  Future<dynamic> getConverted(String key) async {
    final prefs = await this.prefs;
    final c = SettingsMeta.getConverters[key];
    if (c == null) {
      throw Exception("No converter for $key");
    }
    return c(prefs.getString(key) ?? SettingsMeta.get(key));
  }

  Future<void> setConverted(String key, dynamic value) async {
    final pref = await this.prefs;
    final c = SettingsMeta.setConverters[key];
    if (c == null) {
      throw Exception("No converter for $key");
    }
    final str = c(value);
    final checked = SettingsMeta.check(key, str);
    await pref.setString(key, checked);
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
    "api.host": "https://bruss.prabo.org",
    "api.url": "/api/v1/",
    "map.position": setConverters["map.position"]!(trento),
  };

  static final Map<String, String> titles = {
    "api": "API",
  };

  static final Map<String, String> descriptions = {
    "api.url": "Development: Url of the API server to use",
    "api.host": "Development: Host of the API server to use",
  };

  static final Map<String, String Function(String)> checkers = {
    "api.host": (url) {
      try {
        final uri = Uri.parse(url);
        if (uri.scheme.isEmpty || uri.host.isEmpty) {
          throw Exception("Invalid host format");
        }
        return Uri(host: uri.host, scheme: uri.scheme, port: uri.port).toString();
      } catch (e) {
        throw Exception("Invalid host format");
      }
    },
    "api.url": (url) {
      try {
        final uri = Uri.parse(url);
        if (uri.scheme.isNotEmpty || uri.host.isNotEmpty || uri.hasPort) {
          throw Exception("Invalid url format");
        }
        var path = uri.path;
        if (!path.endsWith("/")) {
          path += "/";
        }
        if (path.startsWith("/")) {
          path = path.substring(1);
        }
        return Uri(path: uri.path).toString();
      } catch (e) {
        throw Exception("Invalid url format");
      }
    },
    "map.position": (pos) {
      final parts = pos.split(",");
      if (parts.length != 2) {
        throw Exception("Invalid position format");
      }
      final lat = double.tryParse(parts[0]);
      final lon = double.tryParse(parts[1]);
      if (lat == null || lon == null) {
        throw Exception("Invalid position format");
      }
      return "$lat,$lon";
    }
  };

  static final Map<String, String Function(dynamic)> setConverters = {
    "map.position": (pos) {
      final posConv = pos as LatLng;
      return "${posConv.latitude},${posConv.longitude}";
    }
  };

  static final Map<String, dynamic Function(String)> getConverters = {
    "map.position": (pos) {
      final parts = pos.split(",");
      return LatLng(double.parse(parts[0]), double.parse(parts[1]));
    }
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
