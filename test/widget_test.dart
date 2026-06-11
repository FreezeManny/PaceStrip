import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pacestrip/models/zone_config.dart';
import 'package:pacestrip/providers/settings_provider.dart';
import 'package:pacestrip/providers/stats_provider.dart';
import 'package:pacestrip/services/settings_service.dart';
import 'package:pacestrip/widgets/dashboard.dart';
import 'package:pacestrip/widgets/graph_card.dart';
import 'package:pacestrip/widgets/metric_card.dart';

Future<void> _pumpApp(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(SettingsService())
            ..updateConfig(ZoneConfig.defaults()),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, StatsProvider>(
          create: (ctx) => StatsProvider(ctx.read<SettingsProvider>().config),
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

  group('Theme', () {
    testWidgets('themeMode follows the provider and persists', (tester) async {
      await _pumpApp(tester, const Size(416, 900));

      final ctx = tester.element(find.byType(Dashboard));
      final settings = ctx.read<SettingsProvider>();
      expect(settings.themeMode, ThemeMode.dark);

      await settings.setThemeMode(ThemeMode.light);
      expect(settings.themeMode, ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'light');
    });
  });
}
