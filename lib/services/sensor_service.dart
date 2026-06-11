import 'dart:async';
import 'dart:math';
import '../models/cycling_stats.dart';
import '../models/zone_config.dart';

class SensorService {
  SensorService() : _controller = StreamController<CyclingStats>.broadcast();

  final StreamController<CyclingStats> _controller;
  Timer? _timer;
  ZoneConfig _config = ZoneConfig.defaults();

  double _hr = 140.0;
  double _cad = 85.0;
  final _rng = Random();

  Stream<CyclingStats> get stream => _controller.stream;

  void start() {
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void updateConfig(ZoneConfig config) {
    _config = config;
  }

  void _tick(Timer _) {
    _hr = (_hr + (_rng.nextDouble() - 0.5) * 20).clamp(50.0, 185.0);
    _cad = (_cad + (_rng.nextDouble() - 0.5) * 15).clamp(0.0, 120.0);

    final hr = _hr.round();
    final cad = _cad.round();
    _controller.add(CyclingStats(
      heartRate: hr,
      cadence: cad,
      zone: _config.zoneFor(hr),
      cadenceZone: _config.cadenceZoneFor(cad),
      timestamp: DateTime.now(),
    ));
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
