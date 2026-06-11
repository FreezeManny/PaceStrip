import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cycling_stats.dart';
import '../models/ring_buffer.dart';
import '../models/zone_config.dart';
import '../services/sensor_service.dart';

class StatsProvider extends ChangeNotifier {
  StatsProvider(ZoneConfig initialConfig) : _sensor = SensorService() {
    _sensor.updateConfig(initialConfig);
    _sensor.start();
    _sub = _sensor.stream.listen(_onData);
  }

  final SensorService _sensor;
  late final StreamSubscription<CyclingStats> _sub;

  final hrHistory = RingBuffer<double>(60);
  final cadHistory = RingBuffer<double>(60);

  CyclingStats? latest;

  void updateSettings(ZoneConfig config) {
    _sensor.updateConfig(config);
  }

  void _onData(CyclingStats stats) {
    latest = stats;
    hrHistory.add(stats.heartRate.toDouble());
    cadHistory.add(stats.cadence.toDouble());
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    _sensor.dispose();
    super.dispose();
  }
}
