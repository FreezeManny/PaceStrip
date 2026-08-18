import 'package:flutter_test/flutter_test.dart';
import 'package:pacestrip/models/zone_config.dart';

void main() {
  group('maxHrForAge (Tanaka 208 − 0.7 × age)', () {
    test('computes expected max HR', () {
      expect(ZoneConfig.maxHrForAge(30), 187); // 208 - 21 = 187
      expect(ZoneConfig.maxHrForAge(40), 180); // 208 - 28 = 180
      expect(ZoneConfig.maxHrForAge(20), 194); // 208 - 14 = 194
    });

    test('rounds to nearest bpm', () {
      // 208 - 0.7*25 = 190.5 -> 191 (round half up)
      expect(ZoneConfig.maxHrForAge(25), 191);
    });
  });

  group('withCalculatedZones', () {
    test('sets bpm boundaries to the percentage split of max HR', () {
      final config = ZoneConfig.defaults().withCalculatedZones(180);
      // percentBoundaries default: [0, 60, 70, 80, 90]
      expect(config.maxHr, 180);
      expect(config.bpmBoundaries, [0, 108, 126, 144, 162]);
    });

    test('honours custom percent boundaries', () {
      final base = ZoneConfig.defaults().copyWith(
        percentBoundaries: [0, 50, 65, 80, 95],
      );
      final config = base.withCalculatedZones(200);
      expect(config.bpmBoundaries, [0, 100, 130, 160, 190]);
    });

    test('does not mutate the original config', () {
      final original = ZoneConfig.defaults();
      original.withCalculatedZones(170);
      expect(original.bpmBoundaries, [0, 111, 130, 148, 167]);
    });

    test('resulting boundaries classify bpm into the right zones', () {
      final config = ZoneConfig.defaults().withCalculatedZones(180);
      expect(config.zoneFor(100), 1); // below Z2 (108)
      expect(config.zoneFor(108), 2);
      expect(config.zoneFor(130), 3);
      expect(config.zoneFor(150), 4);
      expect(config.zoneFor(170), 5);
    });
  });

  group('zoneColorsForValues', () {
    final config = ZoneConfig.defaults(); // bpm bounds [0, 111, 130, 148, 167]

    test('colors each reading by the zone it fell into', () {
      final colors = zoneColorsForValues(
        [100, 120, 135, 150, 170],
        config.zoneFor,
        zoneColors,
      );
      expect(colors, [
        zoneColors[1],
        zoneColors[2],
        zoneColors[3],
        zoneColors[4],
        zoneColors[5],
      ]);
    });

    test('rounds fractional readings before classifying', () {
      // 110.6 -> 111, the Z2 boundary; 110.4 -> 110, still Z1.
      expect(
        zoneColorsForValues([110.6, 110.4], config.zoneFor, zoneColors),
        [zoneColors[2], zoneColors[1]],
      );
    });

    test('works with the cadence classifier and palette', () {
      // cadenceBoundaries default: [0, 80, 100]
      final colors = zoneColorsForValues(
        [60, 90, 110],
        config.cadenceZoneFor,
        cadenceZoneColors,
      );
      expect(colors,
          [cadenceZoneColors[1], cadenceZoneColors[2], cadenceZoneColors[3]]);
    });

    test('is empty for an empty history', () {
      expect(zoneColorsForValues([], config.zoneFor, zoneColors), isEmpty);
    });
  });
}
