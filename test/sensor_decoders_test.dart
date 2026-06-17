import 'package:flutter_test/flutter_test.dart';
import 'package:pacestrip/services/ble/sensor_decoders.dart';

/// Little-endian uint16 split into [low, high].
List<int> _u16(int v) => [v & 0xFF, (v >> 8) & 0xFF];

void main() {
  group('parseHeartRate', () {
    test('uint8 format (flags bit0 = 0)', () {
      expect(parseHeartRate([0x00, 72]), 72);
    });

    test('uint16 format (flags bit0 = 1)', () {
      expect(parseHeartRate([0x01, ..._u16(300)]), 300);
    });

    test('malformed/empty returns 0', () {
      expect(parseHeartRate([]), 0);
      expect(parseHeartRate([0x00]), 0);
      expect(parseHeartRate([0x01, 0x10]), 0);
    });
  });

  group('parseCscCadence', () {
    test('first sample yields null, then computes rpm (crank-only)', () {
      final d = CrankCadenceDecoder();
      // flags = 0x02 (crank present), revs, last-crank-event-time (1/1024 s).
      final f1 = [0x02, ..._u16(10), ..._u16(1024)];
      final f2 = [0x02, ..._u16(11), ..._u16(2048)]; // +1 rev over 1.0 s
      expect(parseCscCadence(f1, d), isNull);
      expect(parseCscCadence(f2, d), 60);
    });

    test('handles 16-bit wraparound of revs and event time', () {
      final d = CrankCadenceDecoder();
      final f1 = [0x02, ..._u16(65535), ..._u16(65000)];
      // revs 65535 -> 0 (=+1), time 65000 -> 488 (=+1024 ticks = 1.0 s)
      final f2 = [0x02, ..._u16(0), ..._u16(488)];
      expect(parseCscCadence(f1, d), isNull);
      expect(parseCscCadence(f2, d), 60);
    });

    test('skips wheel-revolution fields when both are present', () {
      final d = CrankCadenceDecoder();
      // flags = 0x03: wheel (4-byte cumulative + 2-byte time) then crank.
      List<int> frame(int crankRevs, int crankTime) => [
            0x03,
            0, 0, 0, 0, // wheel cumulative (ignored)
            ..._u16(5000), // wheel event time (ignored)
            ..._u16(crankRevs),
            ..._u16(crankTime),
          ];
      expect(parseCscCadence(frame(20, 1024), d), isNull);
      expect(parseCscCadence(frame(22, 2048), d), 120); // +2 rev / 1.0 s
    });

    test('returns null when no crank data present (speed-only)', () {
      final d = CrankCadenceDecoder();
      final wheelOnly = [0x01, 0, 0, 0, 0, ..._u16(1024)];
      expect(parseCscCadence(wheelOnly, d), isNull);
    });

    test('coasting (unchanged event time) yields null', () {
      final d = CrankCadenceDecoder();
      final f1 = [0x02, ..._u16(10), ..._u16(1024)];
      final coast = [0x02, ..._u16(10), ..._u16(1024)];
      expect(parseCscCadence(f1, d), isNull);
      expect(parseCscCadence(coast, d), isNull);
    });
  });

  group('parseCyclingPowerCadence', () {
    test('crank-only power frame computes rpm', () {
      final d = CrankCadenceDecoder();
      // flags = 0x0020 (crank present), instantaneous power (2 bytes), crank.
      final f1 = [..._u16(0x0020), ..._u16(150), ..._u16(5), ..._u16(1024)];
      final f2 = [..._u16(0x0020), ..._u16(150), ..._u16(6), ..._u16(1536)];
      // +1 rev over 512 ticks (0.5 s) => 120 rpm
      expect(parseCyclingPowerCadence(f1, d), isNull);
      expect(parseCyclingPowerCadence(f2, d), 120);
    });

    test('locates crank data after pedal/torque/wheel fields', () {
      final d = CrankCadenceDecoder();
      // flags = 0x35: pedal balance (0x01), torque (0x04), wheel (0x10), crank (0x20).
      List<int> frame(int crankRevs, int crankTime) => [
            ..._u16(0x0035),
            ..._u16(150), // instantaneous power
            7, // pedal power balance (1 byte)
            ..._u16(123), // accumulated torque (2 bytes)
            0, 0, 0, 0, ..._u16(2048), // wheel rev data (6 bytes)
            ..._u16(crankRevs),
            ..._u16(crankTime),
          ];
      expect(parseCyclingPowerCadence(frame(5, 1024), d), isNull);
      expect(parseCyclingPowerCadence(frame(8, 2048), d), 180); // +3 rev / 1.0 s
    });

    test('returns null when crank flag is unset', () {
      final d = CrankCadenceDecoder();
      final noCrank = [..._u16(0x0000), ..._u16(150)];
      expect(parseCyclingPowerCadence(noCrank, d), isNull);
    });
  });
}
