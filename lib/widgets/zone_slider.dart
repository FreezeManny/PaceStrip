import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/zone_config.dart';

const _kTrackH = 20.0;
const _kHandleR = 11.0;
const _kTrackY = _kHandleR; // track center y — handles sit exactly on track
const _kLabelGap = 5.0;
const _kLabelH = 22.0; // two lines of 9pt
const _kTotalH = _kTrackY + _kHandleR + _kLabelGap + _kLabelH + 4;

class ZoneSlider extends StatefulWidget {
  const ZoneSlider({
    super.key,
    required this.config,
    required this.onChanged,
  });

  final ZoneConfig config;
  final ValueChanged<ZoneConfig> onChanged;

  @override
  State<ZoneSlider> createState() => _ZoneSliderState();
}

class _ZoneSliderState extends State<ZoneSlider> {
  int? _activeHandle;

  bool get _isPercent => widget.config.mode == ZoneMode.maxHrPercent;

  // Track range. The track starts above 0 so the usable zone range gets the
  // full width; anything below the first handle is still Z1.
  int get _rangeMin => _isPercent ? 50 : 80;
  int get _rangeMax => _isPercent ? 100 : 220;

  List<int> get _boundaries => _isPercent
      ? widget.config.percentBoundaries
      : widget.config.bpmBoundaries;

  double _toFrac(int v) =>
      ((v - _rangeMin) / (_rangeMax - _rangeMin)).clamp(0.0, 1.0);
  int _fromFrac(double f) => (_rangeMin + f * (_rangeMax - _rangeMin)).round();

  List<double> get _fractions =>
      [1, 2, 3, 4].map((i) => _toFrac(_boundaries[i])).toList();

  List<String> _labels() {
    final b = _boundaries;
    return List.generate(4, (i) => '${b[i + 1]} bpm');
  }

  void _onPanStart(DragStartDetails d, double width) {
    final tap = d.localPosition.dx / width;
    final fracs = _fractions;
    int? best;
    double bestDist = double.infinity;
    for (var i = 0; i < fracs.length; i++) {
      final dist = (tap - fracs[i]).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    if (best != null && bestDist * width < 48) {
      setState(() => _activeHandle = best);
    }
  }

  void _onPanUpdate(DragUpdateDetails d, double width) {
    final h = _activeHandle;
    if (h == null) return;

    final frac = (d.localPosition.dx / width).clamp(0.0, 1.0);
    final raw = _fromFrac(frac);
    final bounds = List<int>.from(_boundaries);
    final gap = _isPercent ? 2 : 5;
    final lo = h == 0 ? _rangeMin : bounds[h] + gap;
    final hi = h == 3 ? _rangeMax - gap : bounds[h + 2] - gap;

    bounds[h + 1] = raw.clamp(lo, hi);
    widget.onChanged(
      _isPercent
          ? widget.config.copyWith(percentBoundaries: bounds)
          : widget.config.copyWith(bpmBoundaries: bounds),
    );
  }

  void _onPanEnd(DragEndDetails _) => setState(() => _activeHandle = null);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onPanStart: (d) => _onPanStart(d, width),
          onPanUpdate: (d) => _onPanUpdate(d, width),
          onPanEnd: _onPanEnd,
          child: SizedBox(
            height: _kTotalH,
            width: width,
            child: CustomPaint(
              painter: _ZoneSliderPainter(
                fractions: _fractions,
                activeHandle: _activeHandle,
                labels: _labels(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ZoneSliderPainter extends CustomPainter {
  _ZoneSliderPainter({
    required this.fractions,
    required this.activeHandle,
    required this.labels,
  });

  final List<double> fractions;
  final int? activeHandle;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const cy = _kTrackY;
    final allFracs = [0.0, ...fractions, 1.0];

    // ── Zone segments ─────────────────────────────────────────────────────
    for (var z = 0; z < 5; z++) {
      final left = allFracs[z] * w;
      final right = allFracs[z + 1] * w;
      final color = zoneColors[z + 1]!;
      final rect = Rect.fromLTWH(left, cy - _kTrackH / 2, right - left, _kTrackH);
      final paint = Paint()..color = color;

      if (z == 0 && z == 4) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);
      } else if (z == 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(rect,
              topLeft: const Radius.circular(8),
              bottomLeft: const Radius.circular(8)),
          paint,
        );
      } else if (z == 4) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(rect,
              topRight: const Radius.circular(8),
              bottomRight: const Radius.circular(8)),
          paint,
        );
      } else {
        canvas.drawRect(rect, paint);
      }

      // Zone label on track
      final segW = right - left;
      if (segW > 18) {
        _drawText(
          canvas,
          'Z${z + 1}',
          Offset((left + right) / 2, cy),
          fontSize: 9,
          color: Colors.black.withAlpha(100),
          bold: true,
          centerVertically: true,
        );
      }
    }

    // ── Handles ───────────────────────────────────────────────────────────
    for (var i = 0; i < fractions.length; i++) {
      final x = fractions[i] * w;
      final isActive = i == activeHandle;
      final zoneColor = zoneColors[i + 2]!;
      final r = isActive ? _kHandleR + 2 : _kHandleR;

      // Drop shadow
      canvas.drawCircle(
        Offset(x + 1, cy + 1.5),
        r,
        Paint()..color = Colors.black.withAlpha(80),
      );

      // White ring
      canvas.drawCircle(Offset(x, cy), r, Paint()..color = Colors.white);

      // Zone colour fill
      canvas.drawCircle(
          Offset(x, cy), r - 3.5, Paint()..color = zoneColor);

      // Label below handle
      _drawText(
        canvas,
        labels[i],
        Offset(x, cy + r + _kLabelGap),
        fontSize: 9,
        color: isActive ? Colors.white : Colors.white60,
        bold: isActive,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset topCenter, {
    double fontSize = 10,
    Color color = Colors.white,
    bool bold = false,
    bool centerVertically = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          height: 1.3,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout(maxWidth: 60);
    final offset = centerVertically
        ? topCenter - Offset(tp.width / 2, tp.height / 2)
        : topCenter - Offset(tp.width / 2, 0);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_ZoneSliderPainter old) =>
      old.fractions != fractions || old.activeHandle != activeHandle;
}
