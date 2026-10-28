import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/rest_timer_provider.dart';
import '../providers/active_session_provider.dart';

class FloatingRestTimerBar extends ConsumerWidget {
  const FloatingRestTimerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rest = ref.watch(restTimerProvider);
    final notifier = ref.read(restTimerProvider.notifier);
    final next = ref.watch(
      activeSessionProvider.select((s) {
        final target = s.nextPendingSet(
          preferredExerciseId: rest.remainingSeconds > 0
              ? rest.exerciseId
              : s.expandedExerciseId,
        );
        if (target != null) {
          return '${target.exercise.name} · ${target.setLabel}';
        }
        return s.exercises.isEmpty ? '' : 'All sets logged';
      }),
    );

    if (next.isEmpty) return const SizedBox.shrink();

    final active = rest.remainingSeconds > 0;
    final isLowTime = rest.remainingSeconds <= 15;
    final accentColor = isLowTime ? AppColors.warning : AppColors.primary;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.25;

    final timerText = Text(
      '${(rest.remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(rest.remainingSeconds % 60).toString().padLeft(2, '0')}',
      style: AppTypography.monoMedium.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: accentColor,
      ),
    );
    final actionButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GlassActionButton(
          tooltip: 'Subtract 10 seconds',
          icon: Icons.remove_rounded,
          onPressed: () => notifier.addSeconds(-10),
        ),
        const SizedBox(width: 6),
        _GlassActionButton(
          tooltip: 'Add 10 seconds',
          icon: Icons.add_rounded,
          onPressed: () => notifier.addSeconds(10),
        ),
        const SizedBox(width: 6),
        _GlassActionButton(
          tooltip: rest.isRunning ? 'Pause rest' : 'Resume rest',
          icon: rest.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          onPressed: rest.isRunning ? notifier.pause : notifier.resume,
        ),
      ],
    );
    final skipButton = InkWell(
      onTap: notifier.skip,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.0,
          ),
        ),
        child: Text(
          'Skip',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.platinum,
          ),
        ),
      ),
    );
    final autoButton = InkWell(
      onTap: notifier.toggleAutoStart,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: rest.autoStart
              ? AppColors.primary.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: rest.autoStart
                ? AppColors.primary.withValues(alpha: 0.50)
                : Colors.white.withValues(alpha: 0.14),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rest.autoStart) ...[
              const Icon(
                Icons.check_rounded,
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              'Auto',
              style: TextStyle(
                fontFamily: AppTypography.fontBody,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: rest.autoStart ? AppColors.primary : AppColors.platinum,
              ),
            ),
          ],
        ),
      ),
    );
    final startButton = InkWell(
      onTap: () => notifier.startTimer(durationSeconds: 90),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.24),
              AppColors.primary.withValues(alpha: 0.10),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.45),
            width: 1.0,
          ),
        ),
        child: const Text(
          'Start 90s',
          style: TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          blur: true,
          glowColor: active ? accentColor.withValues(alpha: 0.18) : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = largeText || constraints.maxWidth < 290;
                    if (!compact) {
                      return Row(
                        children: [
                          timerText,
                          const Spacer(),
                          actionButtons,
                          const SizedBox(width: 8),
                          skipButton,
                        ],
                      );
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(children: [timerText, const Spacer(), skipButton]),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: actionButtons,
                        ),
                      ],
                    );
                  },
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = largeText || constraints.maxWidth < 290;
                    final controls = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        autoButton,
                        const SizedBox(width: 8),
                        startButton,
                      ],
                    );
                    if (!compact) {
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Rest timer',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          controls,
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Rest timer',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            runSpacing: 6,
                            children: [autoButton, startButton],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Next: $next',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: AppColors.platinum.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.0,
            ),
          ),
          child: Icon(icon, size: 16, color: AppColors.platinum),
        ),
      ),
    );
  }
}
