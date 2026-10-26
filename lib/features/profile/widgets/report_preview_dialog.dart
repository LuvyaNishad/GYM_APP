/// PDF Report Preview & Download Modal Sheet for LEON.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/account_profile_model.dart';
import '../services/pdf_report_service.dart';

/// Shows the Performance Report Preview & Export Sheet.
void showReportPreviewSheet(BuildContext context, AccountProfile profile) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ReportPreviewSheet(profile: profile),
  );
}

class _ReportPreviewSheet extends StatefulWidget {
  const _ReportPreviewSheet({required this.profile});

  final AccountProfile profile;

  @override
  State<_ReportPreviewSheet> createState() => _ReportPreviewSheetState();
}

class _ReportPreviewSheetState extends State<_ReportPreviewSheet> {
  bool _isGenerating = false;
  bool _isSaved = false;

  Future<void> _generateAndDownload() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await PdfReportService.generateMonthlyReportPdf(widget.profile);

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _isSaved = true;
        });
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.charcoal,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Monthly Report PDF generated successfully!',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 13.0,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _copySummaryText() {
    final summary = '''
# AEON PERFORMANCE REPORT
Athlete: ${widget.profile.displayName}
Date: ${DateTime.now().toIso8601String().substring(0, 10)}
Height: ${widget.profile.formattedHeight}
Current Weight: ${widget.profile.formatWeight(widget.profile.currentWeightKg)}
Goal Weight: ${widget.profile.formatWeight(widget.profile.targetWeightKg)}
BMI: ${widget.profile.bmi.toStringAsFixed(1)} (${widget.profile.bmiCategory})
Estimated Maintenance: ${widget.profile.maintenanceCaloriesEstimate} kcal
Workouts Logged: ${widget.profile.totalWorkouts} sessions
Total Volume Lifted: ${widget.profile.totalVolumeKg} kg
Preferred Split: ${widget.profile.preferredSplit}
Rest Timer Default: ${widget.profile.defaultRestSeconds}s
''';
    Clipboard.setData(ClipboardData(text: summary));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.charcoal,
        content: Text(
          'Report summary copied to clipboard!',
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
    final profile = widget.profile;

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
          // ── Drag Handle ──────────────────────────────────────────────────
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

          // ── Sheet Header ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('📄', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  const Text(
                    'Monthly Training Report',
                    style: TextStyle(
                      fontFamily: AppTypography.fontDisplay,
                      fontSize: 17,
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

          // ── High-Contrast Report Summary Card ────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.steel.withValues(alpha: 0.6),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      profile.displayName.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: AppTypography.fontDisplay,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PDF READY',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _reportRow(
                    'Biometrics',
                    '${profile.formattedHeight} · ${profile.formatWeight(profile.currentWeightKg)}'),
                _reportRow('BMI & Category',
                    '${profile.bmi.toStringAsFixed(1)} · ${profile.bmiCategory}'),
                _reportRow(
                    'Goal Weight', profile.formatWeight(profile.targetWeightKg)),
                _reportRow('Sessions Logged', '${profile.totalWorkouts} sessions'),
                _reportRow('Volume Lifted', '${profile.totalVolumeKg} kg total'),
                _reportRow('Active Split', profile.preferredSplit),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Action Buttons ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _copySummaryText,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.pureWhite,
                    side: BorderSide(
                      color: AppColors.steel.withValues(alpha: 0.8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Copy Summary',
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateAndDownload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSaved
                        ? const Color(0xFF2E7D32)
                        : AppColors.pureWhite,
                    foregroundColor:
                        _isSaved ? AppColors.pureWhite : AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.background),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isSaved
                                  ? Icons.check_circle_rounded
                                  : Icons.picture_as_pdf_rounded,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isSaved
                                  ? 'PDF Generated'
                                  : 'Export 1-Page PDF',
                              style: const TextStyle(
                                fontFamily: AppTypography.fontDisplay,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reportRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 12.0,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            val,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.pureWhite,
            ),
          ),
        ],
      ),
    );
  }
}
