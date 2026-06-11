import 'package:flutter/material.dart';

class SparklinePainter extends CustomPainter {
  SparklinePainter({
    required this.values,
    required this.minVal,
    required this.maxVal,
    required this.color,
  });

  final List<double> values;
  final double minVal;
  final double maxVal;
  final Color color;

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

    for (var i = 0; i < n; i++) {
      final normalized = ((values[i] - lo) / range).clamp(0.0, 1.0);
      final barH = (size.height * normalized).clamp(2.0, size.height);
      final x = i * (barW + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - barH, barW, barH),
        const Radius.circular(2),
      );
      paint.color = color.withAlpha((80 + (normalized * 175).round()));
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class SparklineWidget extends StatelessWidget {
  const SparklineWidget({
    super.key,
    required this.values,
    required this.minVal,
    required this.maxVal,
    required this.color,
  });

  final List<double> values;
  final double minVal;
  final double maxVal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: SparklinePainter(
          values: values,
          minVal: minVal,
          maxVal: maxVal,
          color: color,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
