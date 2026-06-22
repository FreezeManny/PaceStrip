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
}
