import 'package:flutter/foundation.dart';
import '../models/app_theme.dart';
import '../models/zone_config.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._service);

  final SettingsService _service;
  ZoneConfig _config = ZoneConfig.defaults();
  AppTheme _appTheme = AppTheme.dark;
  bool _simulateSensors = false;
  bool _colorfulGraphs = false;

  ZoneConfig get config => _config;
  AppTheme get appTheme => _appTheme;
  bool get simulateSensors => _simulateSensors;
  bool get colorfulGraphs => _colorfulGraphs;

  Future<void> initialize() async {
    _config = await _service.load();
    _appTheme = await _service.loadAppTheme();
    _simulateSensors = await _service.loadSimulateSensors();
    _colorfulGraphs = await _service.loadColorfulGraphs();
    notifyListeners();
  }

  Future<void> updateConfig(ZoneConfig config) async {
    _config = config;
    notifyListeners();
    await _service.save(config);
  }

  Future<void> setAppTheme(AppTheme theme) async {
    _appTheme = theme;
    notifyListeners();
    await _service.saveAppTheme(theme);
  }

  Future<void> setSimulateSensors(bool value) async {
    _simulateSensors = value;
    notifyListeners();
    await _service.saveSimulateSensors(value);
  }

  Future<void> setColorfulGraphs(bool value) async {
    _colorfulGraphs = value;
    notifyListeners();
    await _service.saveColorfulGraphs(value);
  }
}
