import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/zone_config.dart';

enum _HrInputMode { age, maxHr }

/// Dialog that lets the user enter their age or known max heart rate and
/// returns the resulting max HR (in bpm). Returns `null` if cancelled.
class HrCalculatorDialog extends StatefulWidget {
  const HrCalculatorDialog({super.key});

  @override
  State<HrCalculatorDialog> createState() => _HrCalculatorDialogState();
}

class _HrCalculatorDialogState extends State<HrCalculatorDialog> {
  _HrInputMode _mode = _HrInputMode.age;
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isAge => _mode == _HrInputMode.age;

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null) {
      setState(() => _error = 'Enter a number');
      return;
    }
    if (_isAge) {
      if (value < 5 || value > 120) {
        setState(() => _error = 'Age must be 5–120');
        return;
      }
      Navigator.of(context).pop(ZoneConfig.maxHrForAge(value));
    } else {
      if (value < 100 || value > 240) {
        setState(() => _error = 'Max HR must be 100–240');
        return;
      }
      Navigator.of(context).pop(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _isAge
        ? (int.tryParse(_controller.text.trim()) != null
            ? '≈ ${ZoneConfig.maxHrForAge(int.parse(_controller.text.trim()))} bpm max'
            : null)
        : null;

    return AlertDialog(
      title: const Text('Calculate zones'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<_HrInputMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _HrInputMode.age, label: Text('Age')),
                ButtonSegment(
                    value: _HrInputMode.maxHr, label: Text('Max HR')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() {
                _mode = s.first;
                _error = null;
              }),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: _isAge ? 'Age (years)' : 'Max heart rate (bpm)',
              helperText: preview,
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isAge
                ? 'Max HR is estimated with the Tanaka formula '
                    '(208 − 0.7 × age). Zones are set to 60/70/80/90 % of it.'
                : 'Zones are set to 60/70/80/90 % of your max HR.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
