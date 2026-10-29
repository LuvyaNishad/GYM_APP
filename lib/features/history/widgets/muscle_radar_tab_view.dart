import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/workout_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/training_coverage_radar.dart';
import '../models/training_coverage.dart';
import '../providers/history_provider.dart';
import '../providers/training_coverage_provider.dart';

const _caption = TextStyle(
  fontFamily: 'Outfit',
  fontSize: 12,
  color: AppColors.textMuted,
);
const _heading = TextStyle(
  fontFamily: 'Outfit',
  fontSize: 15,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.5,
  color: AppColors.textPrimary,
);

class MuscleRadarTabView extends ConsumerStatefulWidget {
  const MuscleRadarTabView({super.key});
  @override
  ConsumerState<MuscleRadarTabView> createState() => _MuscleRadarTabViewState();
}

class _MuscleRadarTabViewState extends ConsumerState<MuscleRadarTabView> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedCalendarDateProvider, (previous, next) {
      if (previous != next) setState(() => _selectedId = null);
    });
    final date = ref.watch(selectedCalendarDateProvider);
    final workouts =
        ref
            .watch(historyWorkoutsProvider)
            .where((w) => !w.date.isAfter(DateTime.now()))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final WorkoutModel? selected =
        workouts.where((w) => w.id == _selectedId).firstOrNull ??
        workouts
            .where((w) => date != null && DateUtils.isSameDay(w.date, date))
            .firstOrNull ??
        workouts.firstOrNull;
    final coverage = selected == null
        ? null
        : ref.watch(sessionCoverageProvider(selected));
    final gaps = coverage?.gaps.toList() ?? <MuscleCoverage>[];
    gaps.sort((a, b) => a.fraction.compareTo(b.fraction));
    final priority = gaps.firstOrNull;
    final exercise = priority == null
        ? null
        : coverage!.plan?.exercises
              .where((e) => (e.weights[priority.name] ?? 0) == 1 && e.sets > 0)
              .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          blur: true,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('TRAINING COVERAGE', style: _heading),
                  ),
                  IconButton(
                    tooltip: 'About training coverage',
                    onPressed: () => _info(context),
                    icon: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              if (selected == null) ...[
                const TrainingCoverageRadar(muscles: [], hasPlan: false),
                const Text(
                  'Log a workout to see its muscle coverage.',
                  style: _caption,
                ),
              ] else ...[
                DropdownButton<String>(
                  value: selected.id,
                  isExpanded: true,
                  dropdownColor: AppColors.cardBackground,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  items: workouts
                      .map(
                        (w) => DropdownMenuItem(
                          value: w.id,
                          child: Text(
                            '${MaterialLocalizations.of(context).formatShortDate(w.date)} · ${w.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (id) => setState(() => _selectedId = id),
                ),
                Text(
                  coverage!.plan == null
                      ? 'Logged working sets · routine day not identified'
                      : '${coverage.plan!.dayName} · ${coverage.usesSavedPlan ? 'Saved session targets' : 'Compared with current routine'}',
                  style: _caption,
                ),
                TrainingCoverageRadar(
                  key: ValueKey(selected.id),
                  muscles: coverage.muscles,
                  hasPlan: coverage.plan != null,
                ),
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    const _Legend(color: AppColors.primary, label: 'Completed'),
                    if (coverage.plan != null)
                      const _Legend(
                        color: AppColors.platinum,
                        label: 'Planned target',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  coverage.plan == null
                      ? 'Relative logged sets. No missing-muscle assessment without a matched routine.'
                      : 'Working sets against this day’s targets. Extra spokes are visual guides.',
                  style: _caption,
                ),
              ],
            ],
          ),
        ),
        if (coverage != null) ...[
          const SizedBox(height: 12),
          GlassCard(
            blur: true,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MUSCLE BREAKDOWN', style: _heading),
                const SizedBox(height: 6),
                Text(
                  coverage.plan == null
                      ? 'Logged set equivalents'
                      : 'Completed / planned set equivalents',
                  style: _caption,
                ),
                const SizedBox(height: 14),
                if (coverage.muscles.isEmpty)
                  const Text(
                    'No mapped working sets for this session.',
                    style: _caption,
                  ),
                for (final muscle in coverage.muscles)
                  _MuscleRow(muscle: muscle, hasPlan: coverage.plan != null),
                const Text(
                  'Primary muscle: 1 per set · supporting muscle: 0.35.',
                  style: _caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            blur: true,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✨ RECOMMENDATION', style: _heading),
                const SizedBox(height: 10),
                if (coverage.plan == null)
                  const Text(
                    'Match this workout to a routine before assessing missed targets. Add your exercises to the routine for future sessions.',
                    style: _caption,
                  )
                else if (coverage.gaps.isEmpty)
                  const Text(
                    'Your logged sets covered this day’s planned muscle targets.',
                    style: _caption,
                  )
                else ...[
                  Text(
                    '${priority!.name}: ${_sets(priority.planned - priority.completed)} below this session’s target.',
                    style: _caption,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exercise == null
                        ? 'Prioritize ${priority.name} next ${coverage.plan!.dayName}.'
                        : 'Prioritize ${exercise.name} next ${coverage.plan!.dayName}, within your planned ${exercise.sets} sets.',
                    style: _caption.copyWith(color: AppColors.textPrimary),
                  ),
                  if (gaps.length > 1) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Also below target: ${gaps.skip(1).map((g) => g.name).join(', ')}.',
                      style: _caption,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _info(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: const Text('ABOUT TRAINING COVERAGE', style: _heading),
      content: const SingleChildScrollView(
        child: Text(
          'Coverage compares logged working sets with the exercises planned for that routine day. Muscle assignments follow your routine: shoulder work on Push does not become a missing target on Pull.\n\n'
          'New sessions save their original targets. Older sessions are compared with your current routine when a day can be identified. Unmatched workouts show logged coverage without invented gaps.\n\n'
          'Primary muscles receive 1 set equivalent; supporting muscles receive 0.35. Warmups and zero-rep sets are excluded. The chart caps each spoke at 100%; the rows retain the full amounts.\n\n'
          'Recommendations carry forward to compatible workouts and clear after a newer session meets the targets. This measures plan completion, not muscle growth or recovery.',
          style: _caption,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CLOSE'),
        ),
      ],
    ),
  );
}

String _sets(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 16,
        height: 3,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: _caption),
    ],
  );
}

class _MuscleRow extends StatelessWidget {
  const _MuscleRow({required this.muscle, required this.hasPlan});
  final MuscleCoverage muscle;
  final bool hasPlan;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                muscle.name,
                style: _caption.copyWith(color: AppColors.textPrimary),
              ),
            ),
            Text(
              hasPlan
                  ? '${_sets(muscle.completed)} / ${_sets(muscle.planned)}'
                  : _sets(muscle.completed),
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 12,
                color: muscle.hasGap
                    ? AppColors.amber
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (hasPlan) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: muscle.fraction,
              minHeight: 3,
              backgroundColor: AppColors.steel,
              color: AppColors.platinum,
            ),
          ),
        ],
      ],
    ),
  );
}
