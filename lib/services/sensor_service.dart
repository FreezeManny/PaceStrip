import 'dart:async';
import 'dart:math';
import '../models/cycling_stats.dart';
import '../models/zone_config.dart';
import 'ble/ble_constants.dart';
import 'ble/ble_sensor_manager.dart';

/// Random-walk fallback used per-metric when no real sensor is connected,
/// keeping the demo experience the app shipped with.
class SimulatedSensorSource {
  final _rng = Random();
  double _hr = 140.0;
  double _cad = 85.0;

  int nextHr() {
    _hr = (_hr + (_rng.nextDouble() - 0.5) * 20).clamp(50.0, 185.0);
    return _hr.round();
  }

  int nextCadence() {
    _cad = (_cad + (_rng.nextDouble() - 0.5) * 15).clamp(0.0, 120.0);
    return _cad.round();
  }
}

/// Combines live BLE sensor data with an optional simulated fallback into a
/// single [CyclingStats] stream. Emits once per second so the rolling 60-sample
/// history buffers in `StatsProvider` stay evenly spaced, regardless of how
/// often the individual BLE sensors notify. Each metric independently uses its
/// connected sensor; when no sensor is connected it emits `null` (rendered as
/// `---`) unless [simulateWhenIdle] is enabled via the debug setting.
class SensorHub {
  SensorHub(this._ble)
      : _controller = StreamController<CyclingStats>.broadcast();

  final BleSensorManager _ble;
  final StreamController<CyclingStats> _controller;
  final SimulatedSensorSource _sim = SimulatedSensorSource();

  /// When true, metrics without a connected sensor are filled with simulated
  /// values instead of `null`. Driven by the "Simulate sensor data" debug
  /// toggle in settings.
  bool simulateWhenIdle = false;

  Timer? _timer;
  ZoneConfig _config = ZoneConfig.defaults();

  /// How long a cadence reading is held before decaying to 0 while coasting
  /// (CSC/power sensors stop reporting new crank events when not pedalling).
  static const _cadenceTimeout = Duration(seconds: 3);

  Stream<CyclingStats> get stream => _controller.stream;

  void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void updateConfig(ZoneConfig config) {
    _config = config;
  }

  void _tick(Timer _) {
    final hr = _readHeartRate();
    final cad = _readCadence();
    _controller.add(CyclingStats(
      heartRate: hr,
      cadence: cad,
      zone: hr == null ? null : _config.zoneFor(hr),
      cadenceZone: cad == null ? null : _config.cadenceZoneFor(cad),
      timestamp: DateTime.now(),
    ));
  }

  int? _readHeartRate() {
    final conn = _ble.connection(SensorRole.heartRate);
    if (conn.isConnected) return conn.latestValue;
    return simulateWhenIdle ? _sim.nextHr() : null;
  }

  int? _readCadence() {
    final conn = _ble.connection(SensorRole.cadence);
    if (!conn.isConnected) return simulateWhenIdle ? _sim.nextCadence() : null;
    final at = conn.lastValueAt;
    if (at == null || DateTime.now().difference(at) > _cadenceTimeout) {
      return 0; // coasting / no recent crank event
    }
    return conn.latestValue;
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
