import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

/// Bottom-sheet sub-menu for developer/debug options. Opened from the
/// "Debug Settings" entry at the bottom of [SettingsPanel].
class DebugSettingsPanel extends StatelessWidget {
  const DebugSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
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
            Text(
              'DEBUG SETTINGS',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Simulate sensor data'),
              subtitle: const Text(
                'Generate fake heart-rate and cadence values when no sensor is '
                'connected. Off by default — unconnected metrics show "---".',
              ),
              value: provider.simulateSensors,
              onChanged: provider.setSimulateSensors,
            ),
          ],
        ),
      ),
    );
  }
}
