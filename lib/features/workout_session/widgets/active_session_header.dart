import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/active_session_provider.dart';

/// Top sticky header for the Active Workout Session screen.
///
/// Displays:
/// - Split Name / Day Title
/// - Live Elapsed Stopwatch
/// - Completed Sets ratio and Progress bar
/// - Cancel & Finish Workout CTA buttons
class ActiveSessionHeader extends ConsumerWidget {
  const ActiveSessionHeader({
    super.key,
    required this.onFinishPressed,
    required this.onCancelPressed,
  });

  final VoidCallback onFinishPressed;
  final VoidCallback onCancelPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(activeSessionProvider);

    final completedSets = sessionState.completedSetCount;
    final totalSets = sessionState.totalSetCount;
    final progress = sessionState.completionRatio;
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F14),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Cancel / Back, Split Title, Finish Action
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 22),
                  onPressed: onCancelPressed,
                  tooltip: 'Cancel workout',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sessionState.splitName,
                        style: AppTypography.headlineMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: sessionState.isPaused
                                ? AppColors.warning
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sessionState.formattedElapsed,
                            style: AppTypography.monoMedium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sessionState.isPaused
                                  ? AppColors.warning
                                  : AppColors.primary,
                            ),
                          ),
                          if (sessionState.isPaused) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PAUSED',
                                style: AppTypography.monoSmall.copyWith(
                                  fontSize: 11.0,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Finish Workout CTA
                FilledButton(
                  onPressed: onFinishPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: const Size(80, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'FINISH',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Metrics Bar: Sets completed progress & Volume moved
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$completedSets / $totalSets SETS COMPLETED ($percent%)',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.0,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'VOLUME: ${sessionState.totalVolumeKg.toInt()} KG',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.0,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Progress bar track
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
