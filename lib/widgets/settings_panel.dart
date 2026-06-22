import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_theme.dart';
import '../providers/settings_provider.dart';
import 'debug_settings_panel.dart';
import 'hr_calculator_dialog.dart';
import 'sensor_section.dart';
import 'zone_slider.dart';
import 'cadence_slider.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  Future<void> _openHrCalculator(BuildContext context) async {
    final provider = context.read<SettingsProvider>();
    final maxHr = await showDialog<int>(
      context: context,
      builder: (_) => const HrCalculatorDialog(),
    );
    if (maxHr != null) {
      provider.updateConfig(provider.config.withCalculatedZones(maxHr));
    }
  }

  void _openDebugSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (_) => const DebugSettingsPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final config = provider.config;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _sectionLabel(context, 'SENSORS'),
            const SizedBox(height: 4),
            const SensorSection(),
            const SizedBox(height: 16),
            _sectionLabel(context, 'THEME'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<AppTheme>(
                showSelectedIcon: false,
                segments: [
                  for (final theme in AppTheme.values)
                    ButtonSegment(
                      value: theme,
                      label: Text(theme.label),
                    ),
                ],
                selected: {provider.appTheme},
                onSelectionChanged: (s) => provider.setAppTheme(s.first),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _sectionLabel(context, 'HEART RATE ZONES'),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _openHrCalculator(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.calculate_outlined, size: 18),
                  label: const Text('Calculate'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ZoneSlider(
              config: config,
              onChanged: provider.updateConfig,
            ),
            const SizedBox(height: 28),
            _sectionLabel(context, 'CADENCE ZONES'),
            const SizedBox(height: 16),
            CadenceSlider(
              config: config,
              onChanged: provider.updateConfig,
            ),
            const SizedBox(height: 28),
            _sectionLabel(context, 'ADVANCED'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Debug Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openDebugSettings(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      );
}
