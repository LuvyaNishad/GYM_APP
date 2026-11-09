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
      enableDrag: false,
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
  final _canonicalValues = <TextEditingController, double?>{};
  final _displayedValues = <TextEditingController, String>{};
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
    _canonicalValues.addAll({
      _height: p.heightCm,
      _weight: p.currentWeightKg,
      _target: p.targetWeightKg,
    });
    for (final field in _canonicalValues.keys) {
      _displayedValues[field] = field.text;
    }
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
    for (final field in _canonicalValues.keys) {
      final entered = double.tryParse(field.text.trim());
      if (field.text.trim().isNotEmpty &&
          (entered == null || !entered.isFinite || entered <= 0)) {
        continue;
      }
      final canonical = _value(field);
      _canonicalValues[field] = canonical;
      field.text = canonical == null
          ? ''
          : (field == _height
                    ? next.heightFromCm(canonical)
                    : next.weightFromKg(canonical))
                .toStringAsFixed(1);
      _displayedValues[field] = field.text;
    }
    setState(() => _units = next);
  }

  // Formatting an existing measurement must not round the stored measurement.
  double? _value(TextEditingController field) {
    if (field.text == _displayedValues[field]) return _canonicalValues[field];
    if (field.text.trim().isEmpty) return null;
    final entered = double.tryParse(field.text.trim());
    if (entered == null || !entered.isFinite || entered <= 0) {
      throw const FormatException();
    }
    return field == _height
        ? _units.heightToCm(entered)
        : _units.weightToKg(entered);
  }

  Future<void> _save() async {
    if (_pending) return;
    setState(() => _pending = true);
    final saved = await persistWithFeedback(
      context,
      () async {
        final h = _value(_height), w = _value(_weight), t = _value(_target);
        final ageText = _age.text.trim();
        final age = ageText.isEmpty ? null : int.tryParse(ageText);
        if (ageText.isNotEmpty && (age == null || age < 13 || age > 120)) {
          throw const FormatException();
        }
        await ref
            .read(accountProfileProvider.notifier)
            .updateBiometrics(
              age: age,
              sex: _sex,
              heightCm: h,
              currentWeightKg: w,
              targetWeightKg: t,
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
