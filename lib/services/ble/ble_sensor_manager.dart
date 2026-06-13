import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../settings_service.dart';
import 'ble_constants.dart';
import 'sensor_decoders.dart';

enum SensorConnectionStatus { disconnected, connecting, connected }

/// Live state for one [SensorRole]: what device is assigned, whether it is
/// connected, and the most recent decoded value.
class SensorConnection {
  SensorConnectionStatus status = SensorConnectionStatus.disconnected;
  String? deviceId;
  String? deviceName;
  int? latestValue;

  /// When [latestValue] last changed — used to decay cadence to 0 while coasting.
  DateTime? lastValueAt;

  bool get hasDevice => deviceId != null;
  bool get isConnected => status == SensorConnectionStatus.connected;
}

/// Owns all `flutter_blue_plus` interaction: scanning, connecting, decoding
/// notifications, persistence of the chosen device, and reconnection. A single
/// instance is shared between the data pipeline ([SensorHub]) and the
/// device-management UI (`SensorProvider`).
class BleSensorManager extends ChangeNotifier {
  BleSensorManager(this._settings);

  final SettingsService _settings;

  final Map<SensorRole, SensorConnection> _conns = {
    for (final role in SensorRole.values) role: SensorConnection(),
  };
  final Map<SensorRole, BluetoothDevice> _devices = {};
  final Map<SensorRole, StreamSubscription<BluetoothConnectionState>?>
      _connSubs = {};
  final Map<SensorRole, StreamSubscription<List<int>>?> _valueSubs = {};

  // Cadence is computed from successive crank samples, so it needs state that
  // survives across notifications. Reset whenever the cadence device changes.
  final CrankCadenceDecoder _crankDecoder = CrankCadenceDecoder();

  bool _disposed = false;

  SensorConnection connection(SensorRole role) => _conns[role]!;

  /// Live scan results from `flutter_blue_plus`.
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.onScanResults;
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;
  bool get isScanningNow => FlutterBluePlus.isScanningNow;

  // --- Scanning ---------------------------------------------------------------

  Future<bool> _ensurePermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  /// Starts a service-filtered scan for [role]. Throws if BLE permissions are
  /// denied so the UI can surface the problem.
  Future<void> startScan(SensorRole role) async {
    final granted = await _ensurePermissions();
    if (!granted) {
      throw Exception('Bluetooth permission denied');
    }
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
    await FlutterBluePlus.startScan(
      withServices: role.serviceUuids,
      timeout: const Duration(seconds: 15),
    );
  }

  Future<void> stopScan() async {
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
  }

  // --- Connecting -------------------------------------------------------------

  String _displayName(BluetoothDevice device) {
    if (device.platformName.isNotEmpty) return device.platformName;
    if (device.advName.isNotEmpty) return device.advName;
    return device.remoteId.str;
  }

  /// Connects [device] for [role] (user-initiated, from a scan result) and
  /// remembers it for future auto-reconnect.
  Future<void> connect(SensorRole role, BluetoothDevice device) async {
    await stopScan();
    await _assign(role, device);
    if (role == SensorRole.cadence) _crankDecoder.reset();
    await _settings.saveSensorDevice(
      role.prefsKey,
      device.remoteId.str,
      _displayName(device),
    );
    try {
      await device.connect(license: License.nonprofit);
    } catch (_) {
      // The connectionState listener reflects failure; nothing more to do here.
    }
  }

  /// Reconnects a previously remembered device on app start. Uses `autoConnect`
  /// so the OS links up whenever the sensor next powers on / comes in range.
  Future<void> reconnectRemembered(SensorRole role) async {
    final saved = await _settings.loadSensorDevice(role.prefsKey);
    if (saved == null) return;
    final device = BluetoothDevice.fromId(saved.id);
    final conn = _conns[role]!;
    conn.deviceId = saved.id;
    conn.deviceName = saved.name;
    _devices[role] = device;
    if (role == SensorRole.cadence) _crankDecoder.reset();
    _listenConnection(role, device);
    _safeNotify();
    try {
      await device.connect(
        license: License.nonprofit,
        autoConnect: true,
        mtu: null,
      );
    } catch (_) {}
  }

  Future<void> _assign(SensorRole role, BluetoothDevice device) async {
    await _teardown(role, disconnect: true);
    _devices[role] = device;
    final conn = _conns[role]!;
    conn
      ..status = SensorConnectionStatus.connecting
      ..deviceId = device.remoteId.str
      ..deviceName = _displayName(device)
      ..latestValue = null
      ..lastValueAt = null;
    _listenConnection(role, device);
    _safeNotify();
  }

  void _listenConnection(SensorRole role, BluetoothDevice device) {
    _connSubs[role]?.cancel();
    _connSubs[role] = device.connectionState.listen(
      (state) => _onConnectionState(role, device, state),
    );
  }

  Future<void> _onConnectionState(
    SensorRole role,
    BluetoothDevice device,
    BluetoothConnectionState state,
  ) async {
    // Ignore events from a device that is no longer assigned to this role.
    if (_devices[role]?.remoteId != device.remoteId) return;
    final conn = _conns[role]!;

    if (state == BluetoothConnectionState.connected) {
      await _discoverAndSubscribe(role, device);
      conn.status = SensorConnectionStatus.connected;
      _safeNotify();
    } else if (state == BluetoothConnectionState.disconnected) {
      conn
        ..status = SensorConnectionStatus.disconnected
        ..latestValue = null
        ..lastValueAt = null;
      await _valueSubs[role]?.cancel();
      _valueSubs[role] = null;
      _safeNotify();
      // Still our device? Ask the OS to reconnect whenever it returns.
      if (!_disposed && _devices[role]?.remoteId == device.remoteId) {
        device
            .connect(license: License.nonprofit, autoConnect: true, mtu: null)
            .catchError((_) {});
      }
    }
  }

  Future<void> _discoverAndSubscribe(
    SensorRole role,
    BluetoothDevice device,
  ) async {
    await _valueSubs[role]?.cancel();
    _valueSubs[role] = null;

    final services = await device.discoverServices();
    for (final service in services) {
      final handled = await _subscribeService(role, service);
      if (handled) return;
    }
  }

  /// Subscribes to the characteristic for [role] within [service] if present.
  /// Returns true when a matching characteristic was found and notifications
  /// were enabled.
  Future<bool> _subscribeService(
    SensorRole role,
    BluetoothService service,
  ) async {
    int? Function(List<int>)? decode;
    Guid? wantChar;

    if (role == SensorRole.heartRate &&
        service.uuid == BleUuids.heartRateService) {
      wantChar = BleUuids.heartRateMeasurement;
      decode = parseHeartRate;
    } else if (role == SensorRole.cadence &&
        service.uuid == BleUuids.cscService) {
      wantChar = BleUuids.cscMeasurement;
      decode = (v) => parseCscCadence(v, _crankDecoder);
    } else if (role == SensorRole.cadence &&
        service.uuid == BleUuids.cyclingPowerService) {
      wantChar = BleUuids.cyclingPowerMeasurement;
      decode = (v) => parseCyclingPowerCadence(v, _crankDecoder);
    }
    if (wantChar == null || decode == null) return false;

    for (final chr in service.characteristics) {
      if (chr.uuid != wantChar) continue;
      _valueSubs[role] = chr.onValueReceived.listen((value) {
        final decoded = decode!(value);
        if (decoded == null) return;
        final conn = _conns[role]!;
        conn
          ..latestValue = decoded
          ..lastValueAt = DateTime.now();
        _safeNotify();
      });
      await chr.setNotifyValue(true);
      return true;
    }
    return false;
  }

  /// Disconnects and forgets the device for [role].
  Future<void> forget(SensorRole role) async {
    await _teardown(role, disconnect: true);
    final conn = _conns[role]!;
    conn
      ..status = SensorConnectionStatus.disconnected
      ..deviceId = null
      ..deviceName = null
      ..latestValue = null
      ..lastValueAt = null;
    await _settings.clearSensorDevice(role.prefsKey);
    _safeNotify();
  }

  Future<void> _teardown(SensorRole role, {bool disconnect = false}) async {
    await _connSubs[role]?.cancel();
    _connSubs[role] = null;
    await _valueSubs[role]?.cancel();
    _valueSubs[role] = null;
    final old = _devices.remove(role);
    if (disconnect && old != null) {
      try {
        await old.disconnect();
      } catch (_) {}
    }
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final sub in _connSubs.values) {
      sub?.cancel();
    }
    for (final sub in _valueSubs.values) {
      sub?.cancel();
    }
    for (final device in _devices.values) {
      device.disconnect().catchError((_) {});
    }
    super.dispose();
  }
}
