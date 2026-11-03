import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/measurement_units.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/persistence_feedback.dart';
import '../models/account_profile_model.dart';
import '../providers/profile_provider.dart';
import 'account_section.dart';

void showEditBiometricsSheet(BuildContext context, AccountProfile profile) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => _BiometricsEditor(profile: profile),
    );

class _BiometricsEditor extends ConsumerStatefulWidget {
  const _BiometricsEditor({required this.profile});
  final AccountProfile profile;
  @override
  ConsumerState<_BiometricsEditor> createState() => _BiometricsEditorState();
}

class _BiometricsEditorState extends ConsumerState<_BiometricsEditor> {
  late final TextEditingController _height, _weight, _target, _age;
  late MeasurementUnits _units;
  late String? _sex;
  bool _pending = false;
  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _units = p.units;
    _sex = p.sex;
    _height = TextEditingController(
      text: p.heightCm == null
          ? ''
          : _units.heightFromCm(p.heightCm!).toStringAsFixed(1),
    );
    _weight = TextEditingController(
      text: p.currentWeightKg == null
          ? ''
          : _units.weightFromKg(p.currentWeightKg!).toStringAsFixed(1),
    );
    _target = TextEditingController(
      text: p.targetWeightKg == null
          ? ''
          : _units.weightFromKg(p.targetWeightKg!).toStringAsFixed(1),
    );
    _age = TextEditingController(text: p.age?.toString() ?? '');
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _target.dispose();
    _age.dispose();
    super.dispose();
  }

  void _changeUnits(MeasurementUnits next) {
    for (final field in [_weight, _target]) {
      final value = double.tryParse(field.text);
      if (value != null) {
        field.text = next
            .weightFromKg(_units.weightToKg(value))
            .toStringAsFixed(1);
      }
    }
    final height = double.tryParse(_height.text);
    if (height != null) {
      _height.text = next
          .heightFromCm(_units.heightToCm(height))
          .toStringAsFixed(1);
    }
    setState(() => _units = next);
  }

  Future<void> _save() async {
    if (_pending) return;
    setState(() => _pending = true);
    final saved = await persistWithFeedback(
      context,
      () async {
        double? number(TextEditingController field) {
          if (field.text.trim().isEmpty) return null;
          final value = double.tryParse(field.text);
          if (value == null || !value.isFinite || value <= 0) {
            throw const FormatException();
          }
          return value;
        }

        final h = number(_height), w = number(_weight), t = number(_target);
        final age = _age.text.trim().isEmpty ? null : int.tryParse(_age.text);
        if (_age.text.isNotEmpty && (age == null || age < 13 || age > 120)) {
          throw const FormatException();
        }
        await ref
            .read(accountProfileProvider.notifier)
            .updateBiometrics(
              age: age,
              sex: _sex,
              heightCm: h == null ? null : _units.heightToCm(h),
              currentWeightKg: w == null ? null : _units.weightToKg(w),
              targetWeightKg: t == null ? null : _units.weightToKg(t),
              weightUnit: _units.weightLabel,
              heightUnit: _units.heightUnit,
              replace: true,
            );
      },
      message:
          'Could not save biometrics. Check your values and try again. Your edits are still here.',
    );
    if (!mounted) return;
    setState(() => _pending = false);
    if (saved) Navigator.of(context).pop();
  }

  Widget _input(TextEditingController field, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: field,
      style: AppTypography.monoMedium.copyWith(fontSize: 18),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    ),
  );
  @override
  Widget build(BuildContext context) => PersistenceForm(
    pending: _pending,
    child: AppSheet(
      title: 'Update Biometrics',
      busy: _pending,
      children: [
        Text(
          'Personal values are optional. Empty fields stay unset.',
          style: AccountType.detail,
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'cm', label: Text('cm')),
            ButtonSegment(value: 'ft', label: Text('ft / in')),
          ],
          selected: {_units.heightUnit},
          onSelectionChanged: (s) => _changeUnits(
            MeasurementUnits(
              weightUnit: _units.weightUnit,
              heightUnit: s.first,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _input(_height, 'Height (${_units.heightInputLabel})'),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'kg', label: Text('kg')),
            ButtonSegment(value: 'lbs', label: Text('lbs')),
          ],
          selected: {_units.weightLabel},
          onSelectionChanged: (s) => _changeUnits(
            MeasurementUnits(
              weightUnit: s.first,
              heightUnit: _units.heightUnit,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _input(_weight, 'Current weight (${_units.weightLabel})'),
        _input(_target, 'Goal weight (${_units.weightLabel})'),
        _input(_age, 'Age'),
        DropdownButtonFormField<String>(
          initialValue: _sex,
          isExpanded: true,
          isDense: false,
          itemHeight: null,
          style: AccountType.row,
          decoration: const InputDecoration(
            labelText: 'Sex (for calorie estimate)',
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('Not set')),
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
          ],
          onChanged: (value) => setState(() => _sex = value),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _pending ? null : _save,
          child: const Text('Update Biometrics'),
        ),
      ],
    ),
  );
}
