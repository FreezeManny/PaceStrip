import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/zone_config.dart';

class SettingsService {
  static const _key = 'zone_config';
  static const _themeKey = 'theme_mode';
  static const _simulateKey = 'debug_simulate_sensors';

  Future<ZoneConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return ZoneConfig.defaults();
    try {
      return ZoneConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return ZoneConfig.defaults();
    }
  }

  Future<void> save(ZoneConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(config.toJson()));
  }

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) == 'light'
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _themeKey, mode == ThemeMode.light ? 'light' : 'dark');
  }

  /// Whether to simulate sensor data when no sensor is connected (debug only).
  /// Defaults to off, so unconnected metrics read `---`.
  Future<bool> loadSimulateSensors() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_simulateKey) ?? false;
  }

  Future<void> saveSimulateSensors(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_simulateKey, value);
  }

  /// Remembers the BLE sensor chosen for a role, stored as `{id, name}` JSON
  /// under [key] (see `SensorRoleX.prefsKey`).
  Future<void> saveSensorDevice(String key, String id, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode({'id': id, 'name': name}));
  }

  Future<({String id, String name})?> loadSensorDevice(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return (id: map['id'] as String, name: map['name'] as String);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSensorDevice(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
