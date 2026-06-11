import 'package:flutter/material.dart';
import '../models/zone_config.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._service);

  final SettingsService _service;
  ZoneConfig _config = ZoneConfig.defaults();
  ThemeMode _themeMode = ThemeMode.dark;

  ZoneConfig get config => _config;
  ThemeMode get themeMode => _themeMode;

  Future<void> initialize() async {
    _config = await _service.load();
    _themeMode = await _service.loadThemeMode();
    notifyListeners();
  }

  Future<void> updateConfig(ZoneConfig config) async {
    _config = config;
    notifyListeners();
    await _service.save(config);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _service.saveThemeMode(mode);
  }
}
