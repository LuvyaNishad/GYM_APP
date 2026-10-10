import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'muscle_radar_chart.dart';

/// Bento card housing the Muscle Radar balance system with diagnostics and auto-tune actions.
class MuscleBalanceCard extends StatelessWidget {
  const MuscleBalanceCard({
    super.key,
    required this.plannedVolume,
    required this.loggedVolume,
    this.onAutoTuneMuscle,
  });

  final Map<String, int> plannedVolume;
  final Map<String, int> loggedVolume;
  final void Function(String muscle)? onAutoTuneMuscle;

  @override
  Widget build(BuildContext context) {
    // Identify thriving vs lacking muscles
    final List<String> thriving = [];
    final List<String> lacking = [];

    for (final muscle in MuscleRadarChart.kAxes) {
      final logged = loggedVolume[muscle] ?? 0;
      final planned = plannedVolume[muscle] ?? 12;
      if (logged < 8 || logged < (planned * 0.5)) {
        lacking.add(muscle);
      } else {
        thriving.add(muscle);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.steel, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Icon(Icons.radar, size: 18, color: AppColors.pureWhite),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'MUSCLE BALANCE RADAR',
                  style: AppTypography.headlineSmall.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.pureWhite,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.onyx,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.steel),
                ),
                child: Text(
                  '14-DAY LOGGED',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.platinum,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Target vs actual sets across major muscle groups.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.platinum,
              fontSize: 12.0,
            ),
          ),

          const SizedBox(height: 16),

          // Radar Chart Centered
          Center(
            child: MuscleRadarChart(
              plannedVolume: plannedVolume,
              loggedVolume: loggedVolume,
              size: 260,
            ),
          ),

          const SizedBox(height: 16),

          // Legend Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.platinum.withValues(alpha: 0.3),
                      border: Border.all(color: AppColors.platinum, width: 1.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Planned Split',
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 11.0,
                      color: AppColors.platinum,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.pureWhite,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Actual Logged',
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.steel, height: 1),
          const SizedBox(height: 14),

          // Diagnostics Summary
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thriving Muscles
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.pureWhite,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'OPTIMAL VOLUME',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pureWhite,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final m in thriving)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.onyx,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: AppColors.steel),
                            ),
                            child: Text(
                              '$m (${loggedVolume[m] ?? 0}s)',
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 11.0,
                                color: AppColors.platinum,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Lacking / Deficit Muscles
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFB300),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'NEEDS ATTENTION',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFB300),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (lacking.isEmpty)
                      Text(
                        'All muscles in balance',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11.5,
                          color: AppColors.platinum,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final m in lacking)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB300).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                '$m (${loggedVolume[m] ?? 0}s)',
                                style: AppTypography.monoSmall.copyWith(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFFB300),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Auto-tune button if lacking muscles exist
          if (lacking.isNotEmpty && onAutoTuneMuscle != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onAutoTuneMuscle!(lacking.first),
                icon: const Icon(Icons.auto_fix_high, size: 16, color: AppColors.pureWhite),
                label: Text(
                  'AUTO-BALANCE ${lacking.first.toUpperCase()} DEFICIT',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.pureWhite,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.steel),
                  backgroundColor: AppColors.onyx,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
