import 'package:flutter/material.dart';

class SparklinePainter extends CustomPainter {
  SparklinePainter({
    required this.values,
    required this.minVal,
    required this.maxVal,
    required this.color,
    this.barColors,
  });

  final List<double> values;
  final double minVal;
  final double maxVal;
  final Color color;

  /// Per-bar colors, parallel to [values] — used for the "colorful graphs"
  /// option so each bar shows the zone that reading was in. When null (or
  /// shorter than [values]) bars fall back to the single [color].
  final List<Color>? barColors;

  static const _kMinRange = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    // Auto-scale to the current data window
    var lo = values.reduce((a, b) => a < b ? a : b);
    var hi = values.reduce((a, b) => a > b ? a : b);
    final span = (hi - lo).clamp(_kMinRange, double.infinity);
    // Add 10% headroom top and bottom so bars don't butt against edges
    final pad = span * 0.1;
    lo -= pad;
    hi += pad;
    final range = hi - lo;

    final n = values.length;
    const gap = 1.5;
    final barW = (size.width - gap * (n - 1)) / n;

    final paint = Paint()..style = PaintingStyle.fill;
    final colors = barColors;

    for (var i = 0; i < n; i++) {
      final normalized = ((values[i] - lo) / range).clamp(0.0, 1.0);
      final barH = (size.height * normalized).clamp(2.0, size.height);
      final x = i * (barW + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - barH, barW, barH),
        const Radius.circular(2),
      );
      final barColor =
          (colors != null && i < colors.length) ? colors[i] : color;
      // Bars fade with height for depth. With per-bar zone colors the ramp
      // starts much higher, so a low bar's hue still reads as its zone.
      final floor = colors == null ? 80 : 190;
      paint.color =
          barColor.withAlpha(floor + (normalized * (255 - floor)).round());
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(SparklinePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.barColors != barColors;
}

class SparklineWidget extends StatelessWidget {
  const SparklineWidget({
    super.key,
    required this.values,
    required this.minVal,
    required this.maxVal,
    required this.color,
    this.barColors,
  });

  final List<double> values;
  final double minVal;
  final double maxVal;
  final Color color;
  final List<Color>? barColors;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: SparklinePainter(
          values: values,
          minVal: minVal,
          maxVal: maxVal,
          color: color,
          barColors: barColors,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
