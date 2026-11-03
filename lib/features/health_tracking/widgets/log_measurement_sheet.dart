/// Log Body Measurement Bottom Sheet for LEON.
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

class LogMeasurementSheet extends ConsumerStatefulWidget {
  const LogMeasurementSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PersistenceForm(
      pending: _isSaving,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.onyx,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.steel, width: 1.0)),
        ),
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.steel.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.straighten_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'RECORD MEASUREMENTS',
                      style: AppTypography.headlineSmall.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.pureWhite,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'WEIGHT',
                            suffix: units.weightLabel.toUpperCase(),
                            controller: _weightController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputField(
                            label: 'BODY FAT',
                            suffix: '%',
                            controller: _bodyFatController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'WAIST',
                            suffix: units.heightInputLabel.toUpperCase(),
                            controller: _waistController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputField(
                            label: 'CHEST',
                            suffix: units.heightInputLabel.toUpperCase(),
                            controller: _chestController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'ARMS (FLEXED)',
                            suffix: units.heightInputLabel.toUpperCase(),
                            controller: _armsController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputField(
                            label: 'THIGHS',
                            suffix: units.heightInputLabel.toUpperCase(),
                            controller: _thighsController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontSize: 12.5,
                        color: AppColors.pureWhite,
                      ),
                      decoration: InputDecoration(
                        labelText: 'CHECK-IN NOTES (OPTIONAL)',
                        labelStyle: const TextStyle(
                          fontFamily: AppTypography.fontMono,
                          fontSize: 11.0,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                        filled: true,
                        fillColor: AppColors.charcoal,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.steel),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onyx,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text(
                  'SAVE MEASUREMENTS',
                  style: TextStyle(
                    fontFamily: AppTypography.fontBody,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
