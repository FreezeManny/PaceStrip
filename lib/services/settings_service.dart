import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/zone_config.dart';

class SettingsService {
  static const _key = 'zone_config';
  static const _themeKey = 'theme_mode';

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
}
