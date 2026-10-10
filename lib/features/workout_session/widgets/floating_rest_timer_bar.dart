import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/rest_timer_provider.dart';

/// Floating docked Rest Timer bar.
///
/// Features:
/// - Real-time countdown (MM:SS) with circular progress ring
/// - Low-time amber warning (≤ 15s)
/// - Rapid `[-10s]`, `[+10s]`, and `[SKIP]` chips
/// - Pause / Resume controls
/// - Glassmorphism finish with Apple HIG compliant touch targets
class FloatingRestTimerBar extends ConsumerWidget {
  const FloatingRestTimerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restState = ref.watch(restTimerProvider);
    final notifier = ref.read(restTimerProvider.notifier);

    final isLowTime = restState.remainingSeconds <= 15 && restState.remainingSeconds > 0;
    final accentColor = isLowTime ? AppColors.warning : AppColors.primary;

    if (!restState.isRunning && restState.remainingSeconds == 0) {
      // Inactive / Idle Rest Bar: compact affordance to trigger rest manually
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xE6141722),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 20,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Rest Timer · Ready',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12.0,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Quick start 60s
                    _buildQuickStartChip(
                      label: '01:00',
                      onTap: () => notifier.startTimer(durationSeconds: 60),
                    ),
                    const SizedBox(width: 8),
                    // Quick start 90s
                    _buildQuickStartChip(
                      label: '01:30',
                      onTap: () => notifier.startTimer(durationSeconds: 90),
                    ),
                    const SizedBox(width: 8),
                    // Quick start 120s
                    _buildQuickStartChip(
                      label: '02:00',
                      onTap: () => notifier.startTimer(durationSeconds: 120),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Active Countdown Rest Bar
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xF210131B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Circular Countdown Ring
                      SizedBox(
                        width: 38,
                        height: 38,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: restState.progressRatio,
                              strokeWidth: 3.5,
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                            ),
                            Icon(
                              restState.isRunning
                                  ? Icons.hourglass_top_rounded
                                  : Icons.pause_rounded,
                              size: 16,
                              color: accentColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Countdown text & context description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  restState.formattedTime,
                                  style: AppTypography.monoMedium.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: accentColor,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isLowTime)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(alpha: 0.20),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'GET READY',
                                      style: AppTypography.monoSmall.copyWith(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              restState.exerciseName != null
                                  ? 'Resting: ${restState.exerciseName}'
                                  : 'Inter-set recovery',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 11.0,
                                color: const Color(0xFF94A3B8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Rapid -10s chip
                      _buildTimerActionChip(
                        label: '-10s',
                        onTap: notifier.subtractTenSeconds,
                      ),
                      const SizedBox(width: 6),

                      // Rapid +10s chip
                      _buildTimerActionChip(
                        label: '+10s',
                        onTap: notifier.addTenSeconds,
                      ),
                      const SizedBox(width: 6),

                      // Pause / Resume button
                      IconButton(
                        icon: Icon(
                          restState.isRunning ? Icons.pause : Icons.play_arrow,
                          color: accentColor,
                          size: 20,
                        ),
                        onPressed: () {
                          if (restState.isRunning) {
                            notifier.pause();
                          } else {
                            notifier.resume();
                          }
                        },
                        tooltip: restState.isRunning ? 'Pause rest' : 'Resume rest',
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 4),

                      // Skip chip
                      InkWell(
                        onTap: notifier.skip,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Text(
                            'SKIP',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStartChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.monoSmall.copyWith(
            fontSize: 11.0,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTimerActionChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.monoSmall.copyWith(
            fontSize: 11.0,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
