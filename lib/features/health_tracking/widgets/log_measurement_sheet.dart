/// Log Body Measurement Bottom Sheet for AEON.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/measurement_units.dart';
import '../models/body_measurement_model.dart';
import '../providers/body_measurements_provider.dart';
import '../../../shared/widgets/persistence_feedback.dart';
import '../../../shared/widgets/app_sheet.dart';

class LogMeasurementSheet extends ConsumerStatefulWidget {
  const LogMeasurementSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LogMeasurementSheet(),
    );
  }

  @override
  ConsumerState<LogMeasurementSheet> createState() =>
      _LogMeasurementSheetState();
}

class _LogMeasurementSheetState extends ConsumerState<LogMeasurementSheet> {
  final _entryId = 'm_${DateTime.now().microsecondsSinceEpoch}';
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _waistController = TextEditingController();
  final _chestController = TextEditingController();
  final _armsController = TextEditingController();
  final _thighsController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _waistController.dispose();
    _chestController.dispose();
    _armsController.dispose();
    _thighsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _isSaving = false;

  Future<void> _save() async {
    if (_isSaving) return;
    final weight = double.tryParse(_weightController.text);
    if (weight == null || !weight.isFinite || weight <= 0) {
      await persistWithFeedback(context, () async {
        throw const FormatException();
      }, message: 'Enter a valid positive weight.');
      return;
    }
    for (final (controller, label, isPercent) in [
      (_bodyFatController, 'body fat percentage', true),
      (_waistController, 'waist measurement', false),
      (_chestController, 'chest measurement', false),
      (_armsController, 'arm measurement', false),
      (_thighsController, 'thigh measurement', false),
    ]) {
      final text = controller.text.trim();
      if (text.isEmpty) continue;
      final value = double.tryParse(text);
      if (value == null ||
          !value.isFinite ||
          (isPercent ? value < 0 || value > 100 : value <= 0)) {
        await persistWithFeedback(context, () async {
          throw const FormatException();
        }, message: 'Enter a valid $label or leave it empty.');
        return;
      }
    }
    final bf = double.tryParse(_bodyFatController.text);
    final waist = double.tryParse(_waistController.text);
    final chest = double.tryParse(_chestController.text);
    final arms = double.tryParse(_armsController.text);
    final thighs = double.tryParse(_thighsController.text);
    final notes = _notesController.text.trim();

    final units = ref.read(measurementUnitsProvider);
    final entry = BodyMeasurementEntry(
      id: _entryId,
      date: DateTime.now(),
      weightKg: units.weightToKg(weight),
      bodyFatPercent: bf,
      waistCm: waist == null ? null : units.heightToCm(waist),
      chestCm: chest == null ? null : units.heightToCm(chest),
      armsCm: arms == null ? null : units.heightToCm(arms),
      thighsCm: thighs == null ? null : units.heightToCm(thighs),
      notes: notes.isNotEmpty ? notes : null,
    );

    setState(() => _isSaving = true);
    final success = await persistWithFeedback(
      context,
      () => ref.read(bodyMeasurementsProvider.notifier).addMeasurement(entry),
      message:
          'Could not save measurements. Your input is still here. Please try again.',
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!success) return;
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Body measurements recorded.',
          style: TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 12.0,
            color: AppColors.pureWhite,
          ),
        ),
        backgroundColor: AppColors.charcoal,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(measurementUnitsProvider);
    return PersistenceForm(
      pending: _isSaving,
      child: AppSheet(
        title: 'RECORD MEASUREMENTS',
        busy: _isSaving,
        children: [
          _pair(
            _buildInputField(
              label: 'WEIGHT',
              suffix: units.weightLabel.toUpperCase(),
              controller: _weightController,
            ),
            _buildInputField(
              label: 'BODY FAT',
              suffix: '%',
              controller: _bodyFatController,
            ),
          ),
          const SizedBox(height: 12),
          _pair(
            _buildInputField(
              label: 'WAIST',
              suffix: units.heightInputLabel.toUpperCase(),
              controller: _waistController,
            ),
            _buildInputField(
              label: 'CHEST',
              suffix: units.heightInputLabel.toUpperCase(),
              controller: _chestController,
            ),
          ),
          const SizedBox(height: 12),
          _pair(
            _buildInputField(
              label: 'ARMS (FLEXED)',
              suffix: units.heightInputLabel.toUpperCase(),
              controller: _armsController,
            ),
            _buildInputField(
              label: 'THIGHS',
              suffix: units.heightInputLabel.toUpperCase(),
              controller: _thighsController,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          const SizedBox(height: 16),
          if (_isSaving) const Text('Saving measurements…'),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: const Text('SAVE MEASUREMENTS'),
          ),
        ],
      ),
    );
  }

  Widget _pair(Widget first, Widget second) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(13) > 18) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, const SizedBox(height: 12), second],
        );
      }
      return Row(
        children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second),
        ],
      );
    },
  );

  Widget _buildInputField({
    required String label,
    required String suffix,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(
        fontFamily: AppTypography.fontMono,
        fontSize: 13.0,
        fontWeight: FontWeight.w700,
        color: AppColors.pureWhite,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: AppTypography.fontMono,
          fontSize: 11.0,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
        suffixText: suffix,
        suffixStyle: const TextStyle(
          fontFamily: AppTypography.fontMono,
          fontSize: 11.0,
          color: AppColors.primary,
        ),
        filled: true,
        fillColor: AppColors.charcoal,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.steel),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.steel.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
