import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pacestrip/models/app_theme.dart';
import 'package:pacestrip/models/zone_config.dart';
import 'package:pacestrip/providers/settings_provider.dart';
import 'package:pacestrip/providers/stats_provider.dart';
import 'package:pacestrip/services/ble/ble_constants.dart';
import 'package:pacestrip/services/ble/ble_sensor_manager.dart';
import 'package:pacestrip/services/settings_service.dart';
import 'package:pacestrip/widgets/dashboard.dart';
import 'package:pacestrip/widgets/graph_card.dart';
import 'package:pacestrip/widgets/metric_card.dart';

Future<void> _pumpApp(
  WidgetTester tester,
  Size size, {
  bool sensorConnected = false,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final settingsService = SettingsService();
  final ble = BleSensorManager(settingsService);
  if (sensorConnected) {
    ble.connection(SensorRole.heartRate).status =
        SensorConnectionStatus.connected;
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(settingsService)
            ..updateConfig(ZoneConfig.defaults()),
        ),
        ChangeNotifierProvider<BleSensorManager>.value(value: ble),
        ChangeNotifierProxyProvider<SettingsProvider, StatsProvider>(
          create: (ctx) => StatsProvider(
            ctx.read<SettingsProvider>().config,
            ble: ctx.read<BleSensorManager>(),
          ),
          update: (_, settings, stats) =>
              stats!..updateSettings(settings.config),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: Dashboard()),
      ),
    ),
  );
  await tester.pump();
}

/// The dashboard's "no sensor connected" hint.
final _noSensorBanner = find.textContaining('No sensor connected');

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Dashboard layout', () {
    testWidgets('full screen: 2 value + 2 graph cards, settings button',
        (tester) async {
      await _pumpApp(tester, const Size(416, 900));

      expect(find.byType(MetricCard), findsNWidgets(2));
      expect(find.byType(GraphCard), findsNWidgets(2));
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(Scrollable), findsNothing);
    });

    testWidgets('split-screen sizes: no settings button, no scrolling',
        (tester) async {
      for (final size in const [Size(416, 270), Size(416, 500)]) {
        await _pumpApp(tester, size);

        expect(find.byType(MetricCard), findsNWidgets(2),
            reason: 'at $size');
        expect(find.byType(GraphCard), findsNWidgets(2), reason: 'at $size');
        expect(find.text('Settings'), findsNothing, reason: 'at $size');
        expect(find.byType(Scrollable), findsNothing, reason: 'at $size');
        expect(tester.takeException(), isNull, reason: 'at $size');
      }
    });

    testWidgets('cadence segment bar uses cadence palette (3 segments)',
        (tester) async {
      await _pumpApp(tester, const Size(416, 900));

      final bars =
          tester.widgetList<ZoneSegmentBar>(find.byType(ZoneSegmentBar));
      expect(bars.map((b) => b.palette),
          containsAll([zoneColors, cadenceZoneColors]));

      // Segments must actually be visible (Row children without stretch
      // once collapsed to zero height).
      final segment = find
          .descendant(
              of: find.byType(ZoneSegmentBar),
              matching: find.byType(DecoratedBox))
          .first;
      expect(tester.getSize(segment).height, greaterThan(0));
    });
  });

  group('Sensor connectivity banner', () {
    testWidgets('shows the no-sensor hint when nothing is connected',
        (tester) async {
      await _pumpApp(tester, const Size(416, 900));

      expect(_noSensorBanner, findsOneWidget);
    });

    testWidgets('hides the hint once a sensor is connected', (tester) async {
      await _pumpApp(tester, const Size(416, 900), sensorConnected: true);

      expect(_noSensorBanner, findsNothing);
      // Cards still render regardless of banner state.
      expect(find.byType(MetricCard), findsNWidgets(2));
      expect(find.byType(GraphCard), findsNWidgets(2));
    });

    testWidgets('split-screen still renders without overflow while banner shows',
        (tester) async {
      for (final size in const [Size(416, 270), Size(416, 500)]) {
        await _pumpApp(tester, size);

        expect(_noSensorBanner, findsOneWidget, reason: 'at $size');
        expect(tester.takeException(), isNull, reason: 'at $size');
      }
    });
  });

  group('Theme', () {
    testWidgets('appTheme follows the provider and persists', (tester) async {
      await _pumpApp(tester, const Size(416, 900));

      final ctx = tester.element(find.byType(Dashboard));
      final settings = ctx.read<SettingsProvider>();
      expect(settings.appTheme, AppTheme.dark);

      await settings.setAppTheme(AppTheme.black);
      expect(settings.appTheme, AppTheme.black);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'black');
    });
  });
}
