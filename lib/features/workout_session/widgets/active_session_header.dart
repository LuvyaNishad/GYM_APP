import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/active_session_provider.dart';

class ActiveSessionHeader extends ConsumerWidget {
  const ActiveSessionHeader({
    super.key,
    required this.onFinishPressed,
    required this.onCancelPressed,
    this.onMinimizePressed,
    this.onAddExercisePressed,
  });
  final VoidCallback onFinishPressed;
  final VoidCallback onCancelPressed;
  final VoidCallback? onMinimizePressed;
  final VoidCallback? onAddExercisePressed;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(activeSessionProvider.select((s) => s.splitName));
    final counts = ref.watch(
      activeSessionProvider.select(
        (s) => (s.completedSetCount, s.totalSetCount, s.totalVolumeKg),
      ),
    );
    return ColoredBox(
      color: AppColors.onyx,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed:
                        onMinimizePressed ??
                        () => Navigator.of(context).maybePop(),
                    tooltip: 'Minimize workout',
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headlineSmall.copyWith(
                        fontSize: 16,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: counts.$1 > 0 ? onFinishPressed : null,
                    child: const Text('Finish'),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Workout options',
                    onSelected: (value) {
                      if (value == 'discard') onCancelPressed();
                      if (value == 'add') onAddExercisePressed?.call();
                    },
                    itemBuilder: (_) => [
                      if (onAddExercisePressed != null)
                        const PopupMenuItem(
                          value: 'add',
                          child: Text('Add exercises'),
                        ),
                      const PopupMenuItem(
                        value: 'discard',
                        child: Text('Discard workout'),
                      ),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const _SessionClock(),
                    const Spacer(),
                    if (counts.$2 > 0)
                      Flexible(
                        child: Text(
                          '${counts.$1}/${counts.$2} sets · ${counts.$3.toStringAsFixed(0)} kg',
                          textAlign: TextAlign.end,
                          style: AppTypography.monoSmall.copyWith(
                            color: AppColors.platinum,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (counts.$2 > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  child: LinearProgressIndicator(
                    value: counts.$1 / counts.$2,
                    minHeight: 3,
                    backgroundColor: AppColors.charcoal,
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionClock extends ConsumerWidget {
  const _SessionClock();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clock = ref.watch(
      activeSessionProvider.select((s) => (s.formattedElapsed, s.isPaused)),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: ref.read(activeSessionProvider.notifier).togglePause,
          tooltip: clock.$2 ? 'Resume timer' : 'Pause timer',
          icon: Icon(
            clock.$2 ? Icons.play_arrow_rounded : Icons.pause_rounded,
            color: clock.$2 ? AppColors.warning : AppColors.primary,
          ),
        ),
        Text(
          clock.$2 ? '${clock.$1} · Paused' : clock.$1,
          style: AppTypography.monoMedium.copyWith(
            fontSize: 14,
            color: clock.$2 ? AppColors.warning : AppColors.platinum,
          ),
        ),
      ],
    );
  }
}
