// Throwaway visual-preview capture; not a regression test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pacestrip/models/zone_config.dart';
import 'package:pacestrip/widgets/metric_card.dart';

void main() {
  testWidgets('preview value cards', (tester) async {
    await tester.binding.setSurfaceSize(const Size(416, 160));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4FC3F7),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Row(children: [
          Expanded(
            child: MetricCard(
              label: 'HEART RATE',
              value: '142',
              unit: 'bpm',
              zone: 3,
              zonePalette: zoneColors,
            ),
          ),
          Expanded(
            child: MetricCard(
              label: 'CADENCE',
              value: '88',
              unit: 'rpm',
              zone: 2,
              zonePalette: cadenceZoneColors,
            ),
          ),
        ]),
      ),
    ));

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/value_cards.png'),
    );
  });
}
