import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// The two metric roles PaceStrip sources over BLE. Each role is identified by
/// the standard GATT service(s) a matching sensor advertises, which is how
/// devices are auto-classified during scanning.
enum SensorRole { heartRate, cadence }

/// Standard 16-bit GATT UUIDs used by fitness sensors.
class BleUuids {
  BleUuids._();

  static final heartRateService = Guid('180D');
  static final heartRateMeasurement = Guid('2A37');

  static final cscService = Guid('1816');
  static final cscMeasurement = Guid('2A5B');

  static final cyclingPowerService = Guid('1818');
  static final cyclingPowerMeasurement = Guid('2A63');
}

extension SensorRoleX on SensorRole {
  /// Service UUIDs to filter the scan by for this role.
  List<Guid> get serviceUuids => switch (this) {
        SensorRole.heartRate => [BleUuids.heartRateService],
        SensorRole.cadence => [
            BleUuids.cscService,
            BleUuids.cyclingPowerService,
          ],
      };

  String get label => switch (this) {
        SensorRole.heartRate => 'Heart Rate',
        SensorRole.cadence => 'Cadence',
      };

  /// Persistence key for the remembered device of this role.
  String get prefsKey => switch (this) {
        SensorRole.heartRate => 'hr_device',
        SensorRole.cadence => 'cadence_device',
      };
}
