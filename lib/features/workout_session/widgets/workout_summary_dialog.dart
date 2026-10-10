import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/active_session_state.dart';

/// Modal dialog displaying post-workout telemetry and performance summary.
class WorkoutSummaryDialog extends StatelessWidget {
  const WorkoutSummaryDialog({
    super.key,
    required this.session,
    required this.onConfirmedSave,
  });

  final ActiveSessionState session;
  final VoidCallback onConfirmedSave;

  String _formatVolume(double volume) {
    final intVol = volume.toInt();
    if (intVol >= 1000) {
      final thousands = intVol ~/ 1000;
      final remainder = intVol % 1000;
      return '$thousands,${remainder.toString().padLeft(3, '0')} KG';
    }
    return '$intVol KG';
  }

  @override
  Widget build(BuildContext context) {
    final minutes = session.elapsedSeconds ~/ 60;
    final seconds = session.elapsedSeconds % 60;
    final durationStr = '${minutes}m ${seconds}s';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF141722),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WORKOUT RECAP',
                    style: AppTypography.headlineSmall.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.splitName,
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 12.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  'COMPLETED',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3-Metric Glass Bento Grid
          Row(
            children: [
              // 1. Duration
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.timer_outlined,
                  label: 'DURATION',
                  value: durationStr,
                ),
              ),
              const SizedBox(width: 8),
              // 2. Volume
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.fitness_center,
                  label: 'VOLUME',
                  value: _formatVolume(session.totalVolumeKg),
                ),
              ),
              const SizedBox(width: 8),
              // 3. Sets
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.check_circle_outline,
                  label: 'SETS COMPLETED',
                  value: '${session.completedSetCount} / ${session.totalSetCount} SETS',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Exercise Tally List Preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXERCISE SUMMARY',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                for (final ex in session.exercises)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ex.name,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${ex.completedSetsCount}/${ex.totalSetsCount} Sets · ${ex.totalVolumeKg.toInt()} kg',
                          style: AppTypography.monoSmall.copyWith(
                            fontSize: 11.0,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Save Workout CTA
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirmedSave();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'SAVE WORKOUT',
              style: AppTypography.labelSmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Resume Workout text button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'RESUME WORKOUT',
              style: AppTypography.monoSmall.copyWith(
                fontSize: 12.0,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.monoSmall.copyWith(
              fontSize: 11.0,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.monoSmall.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
