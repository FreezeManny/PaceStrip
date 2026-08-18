import 'package:flutter/material.dart';
import '../models/app_theme.dart';
import 'sparkline_painter.dart';

/// Graph card: small label on top, sparkline of the metric history below,
/// colored by the metric's current zone — or, when [barColors] is given, by
/// the zone each individual reading was in.
class GraphCard extends StatelessWidget {
  const GraphCard({
    super.key,
    required this.label,
    required this.values,
    required this.minVal,
    required this.maxVal,
    required this.color,
    this.barColors,
  });

  final String label;
  final List<double> values;
  final double minVal;
  final double maxVal;
  final Color color;

  /// Optional per-reading colors, parallel to [values] (colorful graphs).
  final List<Color>? barColors;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = cardStyle(context);

    return Card(
      margin: const EdgeInsets.all(4),
      color: card.color,
      shape: card.shape,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: SparklineWidget(
                values: values,
                minVal: minVal,
                maxVal: maxVal,
                color: color,
                barColors: barColors,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
