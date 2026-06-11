import 'package:flutter/material.dart';

/// Value card: one chrome line (label left, unit right), a number that
/// fills the remaining height, and a zone segment bar along the bottom.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.zone,
    required this.zonePalette,
  });

  final String label;
  final String value;
  final String unit;
  final int zone;

  /// Zone number -> color; its length defines the segment count.
  final Map<int, Color> zonePalette;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(
      color: scheme.onSurfaceVariant,
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );

    return Card(
      margin: const EdgeInsets.all(4),
      color: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(label, style: labelStyle),
                const Spacer(),
                Text(unit, style: labelStyle),
              ],
            ),
            Expanded(
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  heightFactor: 0.8,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    // An invisible 3-digit template sizes the box, so every
                    // card scales its number identically regardless of how
                    // many digits the current value has.
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text('888',
                            style: _numberStyle(Colors.transparent)),
                        Text(value, style: _numberStyle(scheme.onSurface)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ZoneSegmentBar(zone: zone, palette: zonePalette),
          ],
        ),
      ),
    );
  }

  static TextStyle _numberStyle(Color color) => TextStyle(
        color: color,
        fontSize: 200,
        fontWeight: FontWeight.w700,
        height: 1.0,
      );
}

/// One segment per zone, lit up to [zone], each in its own zone color.
class ZoneSegmentBar extends StatelessWidget {
  const ZoneSegmentBar({super.key, required this.zone, required this.palette});

  final int zone;
  final Map<int, Color> palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: Row(
        // Stretch, or the childless DecoratedBoxes collapse to zero height.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var z = 1; z <= palette.length; z++) ...[
            if (z > 1) const SizedBox(width: 3),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: (palette[z] ?? Colors.white)
                      .withAlpha(z <= zone ? 255 : 56),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
