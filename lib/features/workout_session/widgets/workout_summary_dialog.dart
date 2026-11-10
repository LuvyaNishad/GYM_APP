import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/measurement_units.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/active_session_state.dart';

/// Review completed work before committing it to history.
class WorkoutSummaryDialog extends ConsumerStatefulWidget {
  const WorkoutSummaryDialog({
    super.key,
    required this.session,
    required this.onConfirmedSave,
  });
  final ActiveSessionState session;
  final FutureOr<void> Function() onConfirmedSave;

  @override
  ConsumerState<WorkoutSummaryDialog> createState() =>
      _WorkoutSummaryDialogState();
}

class _WorkoutSummaryDialogState extends ConsumerState<WorkoutSummaryDialog> {
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onConfirmedSave();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Could not save. Your workout is still here. Try again or resume.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final remaining = session.totalSetCount - session.completedSetCount;
    final units = ref.watch(measurementUnitsProvider);
    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .88,
              maxWidth: 640,
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            decoration: const BoxDecoration(
              color: AppColors.onyx,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.steel,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'WORKOUT RECAP',
                          style: AppTypography.headlineSmall.copyWith(
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          session.splitName,
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns =
                                constraints.maxWidth >= 300 &&
                                    MediaQuery.textScalerOf(context).scale(14) <
                                        22
                                ? 3
                                : 1;
                            final width =
                                (constraints.maxWidth - (columns - 1) * 8) /
                                columns;
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                SizedBox(
                                  width: width,
                                  child: _metric(
                                    'DURATION',
                                    '${session.elapsedSeconds ~/ 60}m ${session.elapsedSeconds % 60}s',
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _metric(
                                    'VOLUME',
                                    units.weight(
                                      session.totalVolumeKg,
                                      decimals: 0,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _metric(
                                    'LOGGED',
                                    '${session.completedSetCount} sets',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          remaining > 0
                              ? '${session.completedSetCount} sets logged · $remaining remaining. Only completed sets will be saved.'
                              : 'All ${session.completedSetCount} sets logged. Ready to save.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.platinum,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GlassCard(
                          blur: true,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (
                                var i = 0;
                                i < session.exercises.length;
                                i++
                              ) ...[
                                if (i > 0)
                                  const Divider(
                                    height: 24,
                                    color: AppColors.steel,
                                  ),
                                Text(
                                  session.exercises[i].name,
                                  style: AppTypography.bodyMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${session.exercises[i].completedSetsCount}/${session.exercises[i].totalSetsCount} sets',
                                  style: AppTypography.monoSmall.copyWith(
                                    color: AppColors.platinum,
                                  ),
                                ),
                              ],
                              if (session.exercises.isEmpty)
                                Text(
                                  'No exercises added yet.',
                                  style: AppTypography.bodyMedium,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _error!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _saving || session.completedSetCount == 0
                      ? null
                      : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Text('SAVE WORKOUT'),
                ),
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('RESUME WORKOUT'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value) => GlassCard(
    blur: true,
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.monoSmall.copyWith(color: AppColors.platinum),
        ),
        const SizedBox(height: 6),
        Text(value, style: AppTypography.monoMedium),
      ],
    ),
  );
}
