import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/zone_config.dart';

class ZoneBoundaryTile extends StatefulWidget {
  const ZoneBoundaryTile({
    super.key,
    required this.zoneIndex,
    required this.config,
    required this.onChanged,
  });

  final int zoneIndex;
  final ZoneConfig config;
  final ValueChanged<ZoneConfig> onChanged;

  @override
  State<ZoneBoundaryTile> createState() => _ZoneBoundaryTileState();
}

class _ZoneBoundaryTileState extends State<ZoneBoundaryTile> {
  late TextEditingController _controller;

  int get _currentValue {
    final boundaries = widget.config.mode == ZoneMode.maxHrPercent
        ? widget.config.percentBoundaries
        : widget.config.bpmBoundaries;
    return boundaries[widget.zoneIndex + 1];
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _currentValue.toString());
  }

  @override
  void didUpdateWidget(ZoneBoundaryTile old) {
    super.didUpdateWidget(old);
    final newText = _currentValue.toString();
    if (_controller.text != newText && !_controller.selection.isValid) {
      _controller.text = newText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null) {
      _controller.text = _currentValue.toString();
      return;
    }

    final isPercent = widget.config.mode == ZoneMode.maxHrPercent;
    final boundaries = List<int>.from(
      isPercent
          ? widget.config.percentBoundaries
          : widget.config.bpmBoundaries,
    );

    final prevBound = widget.zoneIndex > 0 ? boundaries[widget.zoneIndex] : 0;
    final nextBound = widget.zoneIndex < 3
        ? boundaries[widget.zoneIndex + 2]
        : (isPercent ? 100 : 220);

    final clamped = parsed.clamp(prevBound + 1, nextBound - 1);
    boundaries[widget.zoneIndex + 1] = clamped;
    _controller.text = clamped.toString();

    widget.onChanged(
      isPercent
          ? widget.config.copyWith(percentBoundaries: boundaries)
          : widget.config.copyWith(bpmBoundaries: boundaries),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fromZone = widget.zoneIndex + 1;
    final toZone = widget.zoneIndex + 2;
    final color = zoneColors[toZone] ?? Colors.white;
    final isPercent = widget.config.mode == ZoneMode.maxHrPercent;

    final bpmVal = isPercent
        ? (widget.config.maxHr * _currentValue / 100).round()
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _zoneBadge('Z$fromZone', zoneColors[fromZone] ?? Colors.white),
          const Icon(Icons.arrow_forward, size: 12, color: Colors.white30),
          _zoneBadge('Z$toZone', color),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                filled: true,
                fillColor: color.withAlpha(20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: color.withAlpha(60)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: color),
                ),
              ),
              onSubmitted: _submit,
              onEditingComplete: () => _submit(_controller.text),
              onTapOutside: (_) => _submit(_controller.text),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isPercent ? '%' : 'bpm',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          if (bpmVal != null) ...[
            const SizedBox(width: 8),
            Text(
              '= $bpmVal bpm',
              style: const TextStyle(color: Colors.white30, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _zoneBadge(String label, Color color) {
    return Container(
      width: 28,
      padding: const EdgeInsets.symmetric(vertical: 3),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
