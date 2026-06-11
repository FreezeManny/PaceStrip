import 'package:flutter/material.dart';

enum ZoneMode { maxHrPercent, manualBpm }

const zoneColors = {
  1: Color(0xFF4FC3F7),
  2: Color(0xFF81C784),
  3: Color(0xFFFFD54F),
  4: Color(0xFFFF8A65),
  5: Color(0xFFEF5350),
};

const cadenceZoneColors = {
  1: Color(0xFF4FC3F7),
  2: Color(0xFF81C784),
  3: Color(0xFFEF5350),
};

class ZoneBand {
  const ZoneBand({
    required this.zone,
    required this.minBpm,
    required this.maxBpm,
  });
  final int zone;
  final int minBpm;
  final int maxBpm;

  Color get color => zoneColors[zone] ?? Colors.white;
  String get label => 'Z$zone';
}

class ZoneConfig {
  const ZoneConfig({
    required this.mode,
    required this.maxHr,
    required this.percentBoundaries,
    required this.bpmBoundaries,
    required this.cadenceBoundaries,
  });

  final ZoneMode mode;
  final int maxHr;

  /// Lower-bound percentages for each zone [Z1, Z2, Z3, Z4, Z5].
  final List<int> percentBoundaries;

  /// Lower-bound bpm for each zone [Z1, Z2, Z3, Z4, Z5].
  final List<int> bpmBoundaries;

  /// Lower-bound rpm for cadence zones [C1, C2, C3]. C1 always starts at 0.
  final List<int> cadenceBoundaries;

  factory ZoneConfig.defaults() => const ZoneConfig(
        mode: ZoneMode.manualBpm,
        maxHr: 185,
        percentBoundaries: [0, 60, 70, 80, 90],
        bpmBoundaries: [0, 111, 130, 148, 167],
        cadenceBoundaries: [0, 80, 100],
      );

  List<ZoneBand> get bands {
    final boundaries = _activeBoundaries;
    return List.generate(5, (i) {
      final min = boundaries[i];
      final max = i < 4 ? boundaries[i + 1] - 1 : 9999;
      return ZoneBand(zone: i + 1, minBpm: min, maxBpm: max);
    });
  }

  List<int> get _activeBoundaries {
    if (mode == ZoneMode.maxHrPercent) {
      return percentBoundaries
          .map((p) => (maxHr * p / 100).round())
          .toList();
    }
    return bpmBoundaries;
  }

  int zoneFor(int bpm) {
    final bounds = _activeBoundaries;
    for (var i = 4; i >= 1; i--) {
      if (bpm >= bounds[i]) return i + 1;
    }
    return 1;
  }

  int cadenceZoneFor(int rpm) {
    if (rpm >= cadenceBoundaries[2]) return 3;
    if (rpm >= cadenceBoundaries[1]) return 2;
    return 1;
  }

  ZoneConfig copyWith({
    ZoneMode? mode,
    int? maxHr,
    List<int>? percentBoundaries,
    List<int>? bpmBoundaries,
    List<int>? cadenceBoundaries,
  }) =>
      ZoneConfig(
        mode: mode ?? this.mode,
        maxHr: maxHr ?? this.maxHr,
        percentBoundaries: percentBoundaries ?? List.of(this.percentBoundaries),
        bpmBoundaries: bpmBoundaries ?? List.of(this.bpmBoundaries),
        cadenceBoundaries: cadenceBoundaries ?? List.of(this.cadenceBoundaries),
      );

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'maxHr': maxHr,
        'percentBoundaries': percentBoundaries,
        'bpmBoundaries': bpmBoundaries,
        'cadenceBoundaries': cadenceBoundaries,
      };

  factory ZoneConfig.fromJson(Map<String, dynamic> json) => ZoneConfig(
        mode: ZoneMode.values.firstWhere(
          (m) => m.name == json['mode'],
          orElse: () => ZoneMode.maxHrPercent,
        ),
        maxHr: json['maxHr'] as int,
        percentBoundaries: (json['percentBoundaries'] as List).cast<int>(),
        bpmBoundaries: (json['bpmBoundaries'] as List).cast<int>(),
        cadenceBoundaries: json.containsKey('cadenceBoundaries')
            ? (json['cadenceBoundaries'] as List).cast<int>()
            : [0, 80, 100],
      );
}
