import 'package:flutter/material.dart';
import 'sparkline_painter.dart';

/// Graph card: small label on top, sparkline of the metric history below,
/// colored by the metric's current zone.
class GraphCard extends StatelessWidget {
  const GraphCard({
    super.key,
    required this.label,
    required this.values,
    required this.minVal,
    required this.maxVal,
    required this.color,
  });

  final String label;
  final List<double> values;
  final double minVal;
  final double maxVal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.all(4),
      color: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
