/// Edit Biometrics & Physical Goals Bottom Sheet for LEON.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/account_profile_model.dart';
import '../providers/profile_provider.dart';

/// Shows the Edit Biometrics modal sheet.
void showEditBiometricsSheet(BuildContext context, AccountProfile profile) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _EditBiometricsSheet(profile: profile),
  );
}

class _EditBiometricsSheet extends ConsumerStatefulWidget {
  const _EditBiometricsSheet({required this.profile});

  final AccountProfile profile;

  @override
  ConsumerState<_EditBiometricsSheet> createState() =>
      _EditBiometricsSheetState();
}

class _EditBiometricsSheetState extends ConsumerState<_EditBiometricsSheet> {
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _targetWeightController;
  late String _weightUnit;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(
      text: widget.profile.heightCm.toStringAsFixed(0),
    );
    _weightUnit = widget.profile.weightUnit;
    final w = _weightUnit == 'lbs'
        ? widget.profile.currentWeightKg * 2.20462
        : widget.profile.currentWeightKg;
    final tw = _weightUnit == 'lbs'
        ? widget.profile.targetWeightKg * 2.20462
        : widget.profile.targetWeightKg;

    _weightController = TextEditingController(text: w.toStringAsFixed(1));
    _targetWeightController =
        TextEditingController(text: tw.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  void _save() {
    final h = double.tryParse(_heightController.text) ?? widget.profile.heightCm;
    var w = double.tryParse(_weightController.text) ??
        widget.profile.currentWeightKg;
    var tw = double.tryParse(_targetWeightController.text) ??
        widget.profile.targetWeightKg;

    // Normalize to kg if in lbs
    if (_weightUnit == 'lbs') {
      w = w / 2.20462;
      tw = tw / 2.20462;
    }

    ref.read(accountProfileProvider.notifier).updateBiometrics(
          heightCm: h,
          currentWeightKg: w,
          targetWeightKg: tw,
          weightUnit: _weightUnit,
        );

    HapticFeedback.lightImpact();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.charcoal,
        content: Text(
          'Biometrics updated & BMI recalculated!',
          style: TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 13.0,
            color: AppColors.pureWhite,
          ),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Update Biometrics',
                style: TextStyle(
                  fontFamily: AppTypography.fontDisplay,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pureWhite,
                  letterSpacing: 0.2,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.platinum, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Height Field
          const Text(
            'HEIGHT (CM)',
            style: TextStyle(
              fontFamily: AppTypography.fontDisplay,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontFamily: AppTypography.fontMono,
              fontSize: 15,
              color: AppColors.pureWhite,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.charcoal,
              suffixText: 'cm',
              suffixStyle: const TextStyle(color: AppColors.textSecondary),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.steel.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.steel.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Current Weight Field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CURRENT WEIGHT ($_weightUnit)'.toUpperCase(),
                style: const TextStyle(
                  fontFamily: AppTypography.fontDisplay,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              // Unit toggle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _unitChip('kg'),
                  const SizedBox(width: 4),
                  _unitChip('lbs'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontFamily: AppTypography.fontMono,
              fontSize: 15,
              color: AppColors.pureWhite,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.charcoal,
              suffixText: _weightUnit,
              suffixStyle: const TextStyle(color: AppColors.textSecondary),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.steel.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.steel.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Target Weight Field
          Text(
            'GOAL / TARGET WEIGHT ($_weightUnit)'.toUpperCase(),
            style: const TextStyle(
              fontFamily: AppTypography.fontDisplay,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _targetWeightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontFamily: AppTypography.fontMono,
              fontSize: 15,
              color: AppColors.pureWhite,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.charcoal,
              suffixText: _weightUnit,
              suffixStyle: const TextStyle(color: AppColors.textSecondary),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.steel.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.steel.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Save button
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pureWhite,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Update Biometrics',
              style: TextStyle(
                fontFamily: AppTypography.fontDisplay,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitChip(String unit) {
    final isSel = _weightUnit == unit;
    return InkWell(
      onTap: () {
        if (_weightUnit != unit) {
          setState(() {
            _weightUnit = unit;
            final current = double.tryParse(_weightController.text) ?? 78.5;
            final target =
                double.tryParse(_targetWeightController.text) ?? 74.0;
            if (unit == 'lbs') {
              _weightController.text = (current * 2.20462).toStringAsFixed(1);
              _targetWeightController.text =
                  (target * 2.20462).toStringAsFixed(1);
            } else {
              _weightController.text = (current / 2.20462).toStringAsFixed(1);
              _targetWeightController.text =
                  (target / 2.20462).toStringAsFixed(1);
            }
          });
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSel
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.charcoal,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSel
                ? AppColors.primary
                : AppColors.steel.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          unit.toUpperCase(),
          style: TextStyle(
            fontFamily: AppTypography.fontMono,
            fontSize: 11,
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
            color: isSel ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
