class CyclingStats {
  const CyclingStats({
    required this.heartRate,
    required this.cadence,
    required this.zone,
    required this.cadenceZone,
    required this.timestamp,
  });

  /// `null` when no real reading is available (sensor not connected and the
  /// debug simulator is off) — the UI renders this as `---`.
  final int? heartRate;
  final int? cadence;

  /// Zone for the current value, or `null` when there is no value to classify.
  final int? zone;
  final int? cadenceZone;
  final DateTime timestamp;
}
