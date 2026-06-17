import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import '../services/ble/ble_constants.dart';
import '../services/ble/ble_sensor_manager.dart';

/// Settings section for picking and managing the BLE heart-rate and cadence
/// sensors. Sensors are auto-classified by the GATT service they advertise, so
/// each role only lists devices of the matching type.
class SensorSection extends StatelessWidget {
  const SensorSection({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<BleSensorManager>();
    return Column(
      children: [
        for (final role in SensorRole.values)
          _SensorTile(role: role, manager: manager),
      ],
    );
  }
}

class _SensorTile extends StatelessWidget {
  const _SensorTile({required this.role, required this.manager});

  final SensorRole role;
  final BleSensorManager manager;

  IconData get _icon => switch (role) {
        SensorRole.heartRate => Icons.favorite,
        SensorRole.cadence => Icons.directions_bike,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final conn = manager.connection(role);

    final String subtitle;
    if (!conn.hasDevice) {
      subtitle = 'Not connected';
    } else {
      final state = switch (conn.status) {
        SensorConnectionStatus.connected => 'Connected',
        SensorConnectionStatus.connecting => 'Connecting…',
        SensorConnectionStatus.disconnected => 'Reconnecting…',
      };
      subtitle = '${conn.deviceName} • $state';
    }

    final Widget trailing;
    if (conn.status == SensorConnectionStatus.connecting) {
      trailing = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (conn.hasDevice) {
      trailing = IconButton(
        icon: const Icon(Icons.link_off),
        tooltip: 'Forget',
        onPressed: () => manager.forget(role),
      );
    } else {
      trailing = const Icon(Icons.add);
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        _icon,
        color: conn.isConnected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(role.label),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: () => _showScanPicker(context, manager, role),
    );
  }
}

Future<void> _showScanPicker(
  BuildContext context,
  BleSensorManager manager,
  SensorRole role,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (_) => _ScanSheet(manager: manager, role: role),
  );
}

class _ScanSheet extends StatefulWidget {
  const _ScanSheet({required this.manager, required this.role});

  final BleSensorManager manager;
  final SensorRole role;

  @override
  State<_ScanSheet> createState() => _ScanSheetState();
}

class _ScanSheetState extends State<_ScanSheet> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() => _error = null);
    try {
      await widget.manager.startScan(widget.role);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    widget.manager.stopScan();
    super.dispose();
  }

  Future<void> _connect(BluetoothDevice device) async {
    await widget.manager.connect(widget.role, device);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select ${widget.role.label} sensor',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StreamBuilder<bool>(
                  stream: widget.manager.isScanning,
                  initialData: widget.manager.isScanningNow,
                  builder: (_, snap) => (snap.data ?? false)
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Scan again',
                          onPressed: _startScan,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: scheme.error),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: StreamBuilder<List<ScanResult>>(
                  stream: widget.manager.scanResults,
                  initialData: const [],
                  builder: (_, snap) {
                    final results = (snap.data ?? [])
                        .where((r) =>
                            r.device.platformName.isNotEmpty ||
                            r.advertisementData.advName.isNotEmpty)
                        .toList()
                      ..sort((a, b) => b.rssi.compareTo(a.rssi));
                    if (results.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('Searching for sensors…'),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final r = results[i];
                        final name = r.device.platformName.isNotEmpty
                            ? r.device.platformName
                            : r.advertisementData.advName;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.bluetooth),
                          title: Text(name),
                          subtitle: Text(r.device.remoteId.str),
                          trailing: Text('${r.rssi} dBm'),
                          onTap: () => _connect(r.device),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
