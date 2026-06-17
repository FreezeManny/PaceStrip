/// Pure, dependency-free decoders for the standard BLE GATT payloads PaceStrip
/// reads. Kept free of any `flutter_blue_plus` imports so they can be unit
/// tested against raw byte lists without a device.
library;

/// Decodes a Heart Rate Measurement (characteristic `0x2A37`).
///
/// Byte 0 is a flags field; bit 0 selects the value format: 0 = uint8 (byte 1),
/// 1 = uint16 little-endian (bytes 1-2). Returns 0 for malformed/empty input.
int parseHeartRate(List<int> value) {
  if (value.isEmpty) return 0;
  final flags = value[0];
  final isUint16 = flags & 0x01 != 0;
  if (isUint16) {
    if (value.length < 3) return 0;
    return value[1] | (value[2] << 8);
  }
  return value.length < 2 ? 0 : value[1];
}

/// Computes cadence (rpm) from successive *cumulative crank revolution* +
/// *last crank event time* samples, as carried by both CSC Measurement and
/// Cycling Power Measurement.
///
/// The crank event time is a 16-bit rolling counter in units of 1/1024 s, and
/// the cumulative crank revolutions field is a 16-bit rolling counter — both
/// can wrap, which is handled with masked subtraction. Coasting (no new crank
/// event, so the event time is unchanged) yields `null` rather than 0; callers
/// decide how long to hold the last value before decaying to zero.
class CrankCadenceDecoder {
  int? _lastRevs;
  int? _lastTime;

  /// Feeds one sample. Returns the computed rpm, or `null` when no rpm can be
  /// derived yet (first sample) or no new crank event has occurred.
  int? update(int cumulativeCrankRevs, int lastCrankEventTime) {
    final prevRevs = _lastRevs;
    final prevTime = _lastTime;
    if (prevRevs == null || prevTime == null) {
      _lastRevs = cumulativeCrankRevs;
      _lastTime = lastCrankEventTime;
      return null;
    }

    final dTime = (lastCrankEventTime - prevTime) & 0xFFFF;
    if (dTime == 0) {
      // No new crank event since the previous notification (coasting). Keep
      // the existing baseline so the next real event averages correctly.
      return null;
    }

    final dRevs = (cumulativeCrankRevs - prevRevs) & 0xFFFF;
    _lastRevs = cumulativeCrankRevs;
    _lastTime = lastCrankEventTime;

    // dRevs revolutions occurred over dTime/1024 seconds.
    return (dRevs * 1024 * 60 / dTime).round();
  }

  void reset() {
    _lastRevs = null;
    _lastTime = null;
  }
}

/// Decodes cadence from a CSC Measurement (characteristic `0x2A5B`).
///
/// Flags (byte 0): bit 0 = wheel revolution data present (4-byte cumulative +
/// 2-byte event time), bit 1 = crank revolution data present (2-byte cumulative
/// + 2-byte event time). Crank fields follow the optional wheel fields. Returns
/// `null` when no crank data is present (e.g. speed-only sensors).
int? parseCscCadence(List<int> value, CrankCadenceDecoder decoder) {
  if (value.isEmpty) return null;
  final flags = value[0];
  final crankPresent = flags & 0x02 != 0;
  if (!crankPresent) return null;

  final wheelPresent = flags & 0x01 != 0;
  final offset = 1 + (wheelPresent ? 6 : 0);
  if (value.length < offset + 4) return null;

  final cumulativeCrankRevs = value[offset] | (value[offset + 1] << 8);
  final lastCrankEventTime = value[offset + 2] | (value[offset + 3] << 8);
  return decoder.update(cumulativeCrankRevs, lastCrankEventTime);
}

/// Decodes cadence from a Cycling Power Measurement (characteristic `0x2A63`).
///
/// Flags is a 16-bit little-endian field (bytes 0-1); instantaneous power
/// occupies bytes 2-3. Optional fields appear in flag order before the crank
/// data: pedal power balance (bit 0, 1 byte), accumulated torque (bit 2,
/// 2 bytes), wheel revolution data (bit 4, 6 bytes), then crank revolution data
/// (bit 5, 2-byte cumulative + 2-byte event time). Returns `null` when no crank
/// data is present.
int? parseCyclingPowerCadence(List<int> value, CrankCadenceDecoder decoder) {
  if (value.length < 4) return null;
  final flags = value[0] | (value[1] << 8);
  final crankPresent = flags & 0x20 != 0;
  if (!crankPresent) return null;

  var offset = 4; // flags (2) + instantaneous power (2)
  if (flags & 0x01 != 0) offset += 1; // pedal power balance
  if (flags & 0x04 != 0) offset += 2; // accumulated torque
  if (flags & 0x10 != 0) offset += 6; // wheel revolution data
  if (value.length < offset + 4) return null;

  final cumulativeCrankRevs = value[offset] | (value[offset + 1] << 8);
  final lastCrankEventTime = value[offset + 2] | (value[offset + 3] << 8);
  return decoder.update(cumulativeCrankRevs, lastCrankEventTime);
}
