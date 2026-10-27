/// Export Workout & Profile Data Modal Sheet for LEON.
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/account_profile_model.dart';

/// Shows the Data Export modal sheet.
void showExportDataSheet(BuildContext context, AccountProfile profile) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ExportDataSheet(profile: profile),
  );
}

class _ExportDataSheet extends StatefulWidget {
  const _ExportDataSheet({required this.profile});

  final AccountProfile profile;

  @override
  State<_ExportDataSheet> createState() => _ExportDataSheetState();
}

class _ExportDataSheetState extends State<_ExportDataSheet> {
  String _format = 'JSON';

  String _generateData() {
    final p = widget.profile;
    if (_format == 'JSON') {
      final map = <String, dynamic>{
        'athlete': {
          'id': p.id,
          'display_name': p.displayName,
          'email': p.email,
          'member_since': p.memberSince.toIso8601String(),
        },
        'biometrics': {
          'height_cm': p.heightCm,
          'current_weight_kg': p.currentWeightKg,
          'target_weight_kg': p.targetWeightKg,
          'bmi': double.parse(p.bmi.toStringAsFixed(1)),
          'bmi_category': p.bmiCategory,
          'bmr_estimate_kcal': p.bmrEstimate,
          'maintenance_tdee_kcal': p.maintenanceCaloriesEstimate,
        },
        'training_summary': {
          'preferred_split': p.preferredSplit,
          'experience_level': p.experienceLevel,
          'default_rest_seconds': p.defaultRestSeconds,
          'total_workouts_logged': p.totalWorkouts,
          'total_volume_lifted_kg': p.totalVolumeKg,
        },
        'recent_prs': [
          {'exercise': 'Barbell Bench Press', 'weight_kg': 100.0, 'reps': 5},
          {'exercise': 'Barbell Back Squat', 'weight_kg': 140.0, 'reps': 5},
          {'exercise': 'Conventional Deadlift', 'weight_kg': 180.0, 'reps': 3},
          {'exercise': 'Overhead Press', 'weight_kg': 65.0, 'reps': 6},
        ],
      };
      return const JsonEncoder.withIndent('  ').convert(map);
    } else {
      // CSV format
      return '''date,category,metric,value,unit
${DateTime.now().toIso8601String().substring(0, 10)},Biometrics,Height,${p.heightCm},cm
${DateTime.now().toIso8601String().substring(0, 10)},Biometrics,CurrentWeight,${p.currentWeightKg},kg
${DateTime.now().toIso8601String().substring(0, 10)},Biometrics,TargetWeight,${p.targetWeightKg},kg
${DateTime.now().toIso8601String().substring(0, 10)},Biometrics,BMI,${p.bmi.toStringAsFixed(1)},pts
${DateTime.now().toIso8601String().substring(0, 10)},Training,TotalWorkouts,${p.totalWorkouts},sessions
${DateTime.now().toIso8601String().substring(0, 10)},Training,TotalVolume,${p.totalVolumeKg},kg
${DateTime.now().toIso8601String().substring(0, 10)},PR,BenchPress,100,kg
${DateTime.now().toIso8601String().substring(0, 10)},PR,Squat,140,kg
${DateTime.now().toIso8601String().substring(0, 10)},PR,Deadlift,180,kg''';
    }
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _generateData()));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.charcoal,
        content: Text(
          '$_format data copied to clipboard!',
          style: const TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 13.0,
            color: AppColors.pureWhite,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _generateData();

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
              Row(
                children: [
                  const Text('💾', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  const Text(
                    'Export Workout Data',
                    style: TextStyle(
                      fontFamily: AppTypography.fontDisplay,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pureWhite,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.platinum, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Format toggle
          Row(
            children: ['JSON', 'CSV'].map((fmt) {
              final isSel = _format == fmt;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _format = fmt),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.charcoal,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel
                              ? AppColors.primary
                              : AppColors.steel.withValues(alpha: 0.4),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        fmt,
                        style: TextStyle(
                          fontFamily: AppTypography.fontMono,
                          fontSize: 12.0,
                          fontWeight:
                              isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Data preview box
          Container(
            height: 160,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.steel.withValues(alpha: 0.5),
              ),
            ),
            child: SingleChildScrollView(
              child: Text(
                data,
                style: const TextStyle(
                  fontFamily: AppTypography.fontMono,
                  fontSize: 11.5,
                  color: AppColors.platinum,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Copy button
          ElevatedButton(
            onPressed: _copy,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pureWhite,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.copy_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Copy $_format to Clipboard',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontDisplay,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
