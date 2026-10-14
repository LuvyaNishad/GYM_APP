/// Muscle Balance, Spider Radar, and Lagging Muscle Diagnosis Tab for LEON.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/radar_chart.dart';
import '../models/muscle_balance_model.dart';
import '../providers/history_provider.dart';

class MuscleRadarTabView extends ConsumerWidget {
  const MuscleRadarTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(muscleBalanceProvider);

    const cyan = Color(0xFF00E5FF);

    // Build 6 spokes for LeonRadarChart
    final axes = [
      RadarAxis(
        label: 'CHEST',
        value: balance.chestVolume,
        color: cyan,
      ),
      RadarAxis(
        label: 'BACK',
        value: balance.backVolume,
        color: cyan,
      ),
      RadarAxis(
        label: 'DELTS',
        value: balance.shouldersVolume,
        color: cyan,
      ),
      RadarAxis(
        label: 'QUADS',
        value: balance.quadsVolume,
        color: cyan,
      ),
      RadarAxis(
        label: 'HAMS',
        value: balance.hamstringsVolume,
        color: const Color(0xFFFFB300), // Amber highlighting lagging volume
      ),
      RadarAxis(
        label: 'ARMS',
        value: balance.armsVolume,
        color: cyan,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Spider Radar Chart Card ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.steel.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'MUSCLE SYMMETRY RADAR',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 12.0,
                              fontWeight: FontWeight.w800,
                              color: AppColors.pureWhite,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _showMuscleRadarInfoDialog(context),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              size: 15,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cumulative 30-Day Training Volume',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontBody,
                          fontSize: 11.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.steel.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '6 AXES',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.platinum,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Animated Spider Radar Chart
              SizedBox(
                height: 230,
                child: Center(
                  child: LeonRadarChart(
                    axes: axes,
                    weakThreshold: 0.45,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Chart legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(
                    color: const Color(0xFF00E5FF),
                    label: 'Balanced Volume',
                  ),
                  const SizedBox(width: 16),
                  _buildLegendItem(
                    color: const Color(0xFFFFB300),
                    label: 'Lagging Deficit',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── 2. Lagging Muscle Diagnostic Advisory Card ────────────────────────
        if (balance.laggingAdvisories.isNotEmpty) ...[
          for (final adv in balance.laggingAdvisories)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.6),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFFB300),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LAGGING DETECTED: ${adv.muscleName.toUpperCase()}',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12.0,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFFB300),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    adv.rationale,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                      color: AppColors.pureWhite,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'RECOMMENDED EXERCISES:',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final ex in adv.recommendedExercises)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.onyx,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.steel.withValues(alpha: 0.6),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            ex,
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.platinum,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],

        // ── 3. Muscle Recovery & Primed Readiness State ───────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.steel.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('⚡ ', style: TextStyle(fontSize: 15)),
                      Text(
                        'MUSCLE READINESS STATE',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12.0,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pureWhite,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'HOURS SINCE HIT',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              for (final state in balance.recoveryStates)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.onyx,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getStatusColor(state.status),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.muscleName,
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontBody,
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.pureWhite,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getStatusLabel(state.status),
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w700,
                                    color: _getStatusColor(state.status),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '${state.hoursSinceLastTrained}H AGO',
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.platinum,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 11.0,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(RecoveryStatus status) {
    switch (status) {
      case RecoveryStatus.ready:
        return const Color(0xFF00E676);
      case RecoveryStatus.recovering:
        return const Color(0xFFFFB300);
      case RecoveryStatus.overdue:
        return const Color(0xFFFF5252);
    }
  }

  String _getStatusLabel(RecoveryStatus status) {
    switch (status) {
      case RecoveryStatus.ready:
        return 'READY & PRIMED';
      case RecoveryStatus.recovering:
        return 'RECOVERING';
      case RecoveryStatus.overdue:
        return 'OVERDUE / DEFICIT';
    }
  }

  void _showMuscleRadarInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.onyx,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.steel),
        ),
        title: Row(
          children: [
            const Icon(Icons.hub_outlined, color: Color(0xFF00E5FF), size: 20),
            const SizedBox(width: 8),
            Text(
              'MUSCLE BALANCE SCIENCE',
              style: AppTypography.headlineSmall.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.pureWhite,
              ),
            ),
          ],
        ),
        content: const Text(
          'Calculated from total direct sets completed across Push, Pull, and Leg muscle groups over the past 7 days.\n\nBalanced training volume prevents joint impingement, promotes postural stability, and ensures proportional physique development.',
          style: TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 12.5,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'UNDERSTOOD',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00E5FF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
