import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/zone_config.dart';
import '../providers/stats_provider.dart';
import 'graph_card.dart';
import 'metric_card.dart';
import 'settings_panel.dart';

/// Pane heights at or above this are treated as full screen; split-screen
/// panes on a phone stay well below it, so the settings button only shows
/// when the app is not split-screened.
const kFullScreenThreshold = 700.0;

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (_) => const SettingsPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    final latest = stats.latest;
    final zone = latest?.zone ?? 1;
    final cadenceZone = latest?.cadenceZone ?? 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullScreen = constraints.maxHeight >= kFullScreenThreshold;

        return Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        label: 'HEART RATE',
                        value: latest?.heartRate.toString() ?? '--',
                        unit: 'bpm',
                        zone: zone,
                        zonePalette: zoneColors,
                      ),
                    ),
                    Expanded(
                      child: MetricCard(
                        label: 'CADENCE',
                        value: latest?.cadence.toString() ?? '--',
                        unit: 'rpm',
                        zone: cadenceZone,
                        zonePalette: cadenceZoneColors,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      child: GraphCard(
                        label: 'HEART RATE',
                        values: stats.hrHistory.values,
                        minVal: 50,
                        maxVal: 185,
                        color: zoneColors[zone] ?? Colors.white,
                      ),
                    ),
                    Expanded(
                      child: GraphCard(
                        label: 'CADENCE',
                        values: stats.cadHistory.values,
                        minVal: 0,
                        maxVal: 120,
                        color: cadenceZoneColors[cadenceZone] ?? Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (fullScreen)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _openSettings(context),
                      icon: const Icon(Icons.settings),
                      label: const Text('Settings'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
