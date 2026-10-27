import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/active_session_state.dart';

/// Review completed work before committing it to history.
class WorkoutSummaryDialog extends StatefulWidget {
  const WorkoutSummaryDialog({
    super.key,
    required this.session,
    required this.onConfirmedSave,
  });
  final ActiveSessionState session;
  final FutureOr<void> Function() onConfirmedSave;
  @override
  State<WorkoutSummaryDialog> createState() => _WorkoutSummaryDialogState();
}

class _WorkoutSummaryDialogState extends State<WorkoutSummaryDialog> {
  bool _saving = false;
  String? _error;
  Future<void> _save() async {
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
    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .88,
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
              Text(
                'WORKOUT RECAP',
                style: AppTypography.headlineSmall.copyWith(letterSpacing: 1.5),
              ),
              const SizedBox(height: 6),
              Text(session.splitName, style: AppTypography.bodyMedium),
              const SizedBox(height: 20),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _metric(
                    'DURATION',
                    '${session.elapsedSeconds ~/ 60}m ${session.elapsedSeconds % 60}s',
                  ),
                  _metric(
                    'VOLUME',
                    '${session.totalVolumeKg.toStringAsFixed(0)} kg',
                  ),
                  _metric('LOGGED', '${session.completedSetCount} sets'),
                ],
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
              Flexible(
                child: SingleChildScrollView(
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (final ex in session.exercises)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ex.name,
                                    style: AppTypography.bodyMedium,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${ex.completedSetsCount}/${ex.totalSetsCount} sets',
                                  style: AppTypography.monoSmall.copyWith(
                                    color: AppColors.platinum,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (session.exercises.isEmpty)
                          const Text('No exercises added yet.'),
                      ],
                    ),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
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
    );
  }

  Widget _metric(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTypography.monoSmall.copyWith(color: AppColors.platinum),
      ),
      const SizedBox(height: 6),
      Text(value, style: AppTypography.monoMedium),
    ],
  );
}
