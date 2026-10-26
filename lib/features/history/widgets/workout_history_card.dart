/// Expandable workout session history card for LEON.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/workout_model.dart';
import '../../workout_session/models/active_session_state.dart';
import '../../workout_session/providers/active_session_provider.dart';
import '../../workout_session/screens/workout_session_screen.dart';
import 'edit_workout_sheet.dart';

class WorkoutHistoryCard extends ConsumerStatefulWidget {
  const WorkoutHistoryCard({
    super.key,
    required this.workout,
    this.initiallyExpanded = false,
  });

  final WorkoutModel workout;
  final bool initiallyExpanded;

  @override
  ConsumerState<WorkoutHistoryCard> createState() => _WorkoutHistoryCardState();
}

class _WorkoutHistoryCardState extends ConsumerState<WorkoutHistoryCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  String _formatDate(DateTime dt) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    return '${mins}M';
  }

  String _formatTonnage(double volume) {
    final intVol = volume.toInt();
    if (intVol >= 1000) {
      final k = (intVol / 1000).toStringAsFixed(1);
      return '$k' 'K KG';
    }
    return '$intVol KG';
  }

  String _generateWorkoutSummary(WorkoutModel w) {
    final buffer = StringBuffer();
    buffer.writeln('AEON WORKOUT SUMMARY 🏋️');
    buffer.writeln(w.name.toUpperCase());
    buffer.writeln('${_formatDate(w.date)} • ${_formatDuration(w.durationSeconds)}');
    final totalSets = w.exercises.fold<int>(0, (s, e) => s + e.sets.length);
    buffer.writeln('Volume: ${_formatTonnage(w.totalVolumeKg ?? 0)} • Sets: $totalSets');
    buffer.writeln('');
    buffer.writeln('EXERCISES:');
    for (final ex in w.exercises) {
      buffer.writeln('• ${ex.exerciseName} (${ex.muscleGroup})');
      for (int i = 0; i < ex.sets.length; i++) {
        final s = ex.sets[i];
        final warmupTag = s.isWarmup ? ' [Warmup]' : '';
        final prTag = s.isPr ? ' 🏆 PR' : '';
        buffer.writeln('  Set ${i + 1}: ${s.weightKg}kg × ${s.reps}$warmupTag$prTag');
      }
      buffer.writeln('');
    }
    buffer.write('Tracked with AEON');
    return buffer.toString();
  }

  void _shareWorkoutSummary(BuildContext context) {
    HapticFeedback.lightImpact();
    final summary = _generateWorkoutSummary(widget.workout);
    Clipboard.setData(ClipboardData(text: summary));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.charcoal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.steel, width: 1),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.pureWhite, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Workout summary copied to clipboard!',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pureWhite,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _repeatWorkout(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final activeSession = ref.read(activeSessionProvider);
    if (activeSession.isActive) {
      final shouldReplace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.charcoal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.steel),
          ),
          title: Text(
            'ACTIVE WORKOUT IN PROGRESS',
            style: AppTypography.titleLarge.copyWith(
              fontFamily: AppTypography.fontDisplay,
              fontSize: 16.0,
              fontWeight: FontWeight.w800,
              color: AppColors.pureWhite,
            ),
          ),
          content: Text(
            'A workout session is currently active. Discard it and repeat this workout?',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 13.0,
              color: AppColors.platinum,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'CANCEL',
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 12.0,
                  color: AppColors.platinum,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.pureWhite,
                foregroundColor: AppColors.onyx,
              ),
              child: Text(
                'REPEAT WORKOUT',
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onyx,
                ),
              ),
            ),
          ],
        ),
      );

      if (shouldReplace != true) return;
    }

    final mappedExercises = widget.workout.exercises.map((ex) {
      return ActiveExerciseState(
        exerciseId: ex.exerciseId,
        name: ex.exerciseName,
        muscleGroup: ex.muscleGroup,
        sets: ex.sets.asMap().entries.map((entry) {
          final idx = entry.key;
          final s = entry.value;
          return ActiveSetState(
            setNumber: idx + 1,
            weightKg: s.weightKg,
            reps: s.reps,
            previousWeightKg: s.weightKg,
            previousReps: s.reps,
            isCompleted: false,
            setType: s.isWarmup ? ActiveSetType.warmup : ActiveSetType.normal,
          );
        }).toList(),
      );
    }).toList();

    ref.read(activeSessionProvider.notifier).startSession(
      splitName: widget.workout.name,
      initialExercises: mappedExercises,
    );

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const WorkoutSessionScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.workout;
    final prCount = w.exercises.fold<int>(
      0,
      (sum, ex) => sum + ex.sets.where((s) => s.isPr).length,
    );
    final totalSets = w.exercises.fold<int>(
      0,
      (sum, ex) => sum + ex.sets.where((s) => !s.isWarmup).length,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.steel.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _isExpanded = !_isExpanded);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Date and Stats Row ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date badge
                    Text(
                      _formatDate(w.date),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),

                    // PR Highlight or Duration tag
                    Row(
                      children: [
                        if (prCount > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF00E676),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🏆 ', style: TextStyle(fontSize: 11)),
                                Text(
                                  '$prCount PR${prCount > 1 ? 'S' : ''}',
                                  style: const TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF00E676),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.steel.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDuration(w.durationSeconds),
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.platinum,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Workout Title ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        w.name.toUpperCase(),
                        style: AppTypography.headlineSmall.copyWith(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pureWhite,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Sub-metrics Pill Row ────────────────────────────────────────
                Row(
                  children: [
                    _buildSubTag('${w.exercises.length} EXERCISES'),
                    const SizedBox(width: 6),
                    _buildSubTag('$totalSets SETS'),
                    const SizedBox(width: 6),
                    _buildSubTag(_formatTonnage(w.totalVolumeKg ?? 0)),
                  ],
                ),

                // ── Expandable Exercise Set Breakdown ─────────────────────────
                if (_isExpanded) ...[
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.steel, height: 1),
                  const SizedBox(height: 12),
                  for (final ex in w.exercises)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ex.exerciseName,
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontBody,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.pureWhite,
                                ),
                              ),
                              Text(
                                ex.muscleGroup.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              for (int i = 0; i < ex.sets.length; i++)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: ex.sets[i].isPr
                                        ? const Color(0xFF00E676).withValues(alpha: 0.15)
                                        : AppColors.steel.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(6),
                                    border: ex.sets[i].isPr
                                        ? Border.all(
                                            color: const Color(0xFF00E676),
                                            width: 0.8,
                                          )
                                        : null,
                                  ),
                                  child: Text(
                                    '${ex.sets[i].weightKg}kg × ${ex.sets[i].reps}',
                                    style: TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.w600,
                                      color: ex.sets[i].isPr
                                          ? const Color(0xFF00E676)
                                          : AppColors.platinum,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  // ── Action Row: REPEAT WORKOUT • SHARE • EDIT ──────────
                  Row(
                    children: [
                      // 1. REPEAT WORKOUT CTA (Primary)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _repeatWorkout(context),
                          icon: const Icon(
                            Icons.play_arrow_rounded,
                            size: 16,
                            color: AppColors.onyx,
                          ),
                          label: Text(
                            'REPEAT WORKOUT',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onyx,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.pureWhite,
                            foregroundColor: AppColors.onyx,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            minimumSize: const Size(0, 38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 2. SHARE Summary (Secondary)
                      OutlinedButton.icon(
                        onPressed: () => _shareWorkoutSummary(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.steel),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          minimumSize: const Size(0, 38),
                        ),
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: AppColors.pureWhite,
                        ),
                        label: Text(
                          'SHARE',
                          style: AppTypography.monoSmall.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pureWhite,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 3. EDIT Session (Tertiary)
                      OutlinedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          EditWorkoutSheet.show(context, widget.workout);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.steel),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          minimumSize: const Size(0, 38),
                        ),
                        child: Text(
                          'EDIT',
                          style: AppTypography.monoSmall.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.platinum,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.steel.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
          color: AppColors.platinum,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
