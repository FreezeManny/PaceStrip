class CyclingStats {
  const CyclingStats({
    required this.heartRate,
    required this.cadence,
    required this.zone,
    required this.cadenceZone,
    required this.timestamp,
  });

  final int heartRate;
  final int cadence;
  final int zone;
  final int cadenceZone;
  final DateTime timestamp;
}
