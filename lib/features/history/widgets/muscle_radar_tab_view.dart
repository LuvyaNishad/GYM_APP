import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/workout_model.dart';
import '../../../shared/widgets/glass_card.dart';

import '../models/muscle_workload.dart';
import '../providers/muscle_workload_provider.dart';
import 'muscle_workload_chart.dart';
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
    final scope = ref.watch(muscleWorkloadScopeProvider);
    final isWeek = scope == MuscleWorkloadScope.week;
    final index = ref.watch(trainingCoverageIndexProvider);
    final summaries = [
      for (final workout in workouts)
        ref.watch(sessionMuscleWorkloadProvider(workout)),
    ];
    final anchor = date ?? selected?.date ?? DateTime.now();
    final monday = DateTime(
      anchor.year,
      anchor.month,
      anchor.day - anchor.weekday + 1,
    );
    final end = monday.add(const Duration(days: 7));
    final now = DateTime.now();
    final currentWeek = !now.isBefore(monday) && now.isBefore(end);
    final weeklyTargets = currentWeek ? weeklyWorkloadTargets(index) : null;
    final weeks = <DateTime, List<MuscleWorkload>>{};
    for (var i = 0; i < workouts.length; i++) {
      final date = workouts[i].date;
      final start = DateTime(
        date.year,
        date.month,
        date.day - date.weekday + 1,
      );
      weeks.putIfAbsent(start, () => []).add(summaries[i]);
    }
    final weekly = MuscleWorkload.combine(
      weeks[monday] ?? [],
      targets: weeklyTargets,
    );
    final workload = isWeek
        ? weekly
        : selected == null
        ? MuscleWorkload.combine([])
        : summaries[workouts.indexOf(selected)];
    final chartScale = isWeek
        ? muscleWorkloadScale([
            weekly,
            for (final sessions in weeks.values)
              MuscleWorkload.combine(sessions),
          ], minimum: 60)
        : muscleWorkloadScale(summaries);
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
                    child: Text('MUSCLE WORKLOAD', style: _heading),
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
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<MuscleWorkloadScope>(
                  segments: const [
                    ButtonSegment(
                      value: MuscleWorkloadScope.workout,
                      label: Text('This workout'),
                    ),
                    ButtonSegment(
                      value: MuscleWorkloadScope.week,
                      label: Text('This week'),
                    ),
                  ],
                  selected: {scope},
                  showSelectedIcon: false,
                  onSelectionChanged: (values) => ref
                      .read(muscleWorkloadScopeProvider.notifier)
                      .select(values.first),
                ),
              ),
              const SizedBox(height: 12),
              if (isWeek)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${MaterialLocalizations.of(context).formatShortDate(monday)} – ${MaterialLocalizations.of(context).formatShortDate(end.subtract(const Duration(days: 1)))} · ${weekly.workoutCount} workouts',
                    style: _caption,
                  ),
                )
              else if (selected != null)
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
              if (!isWeek && coverage?.plan != null)
                Text(
                  coverage!.usesSavedPlan
                      ? 'Saved session targets'
                      : 'Targets from your current routine',
                  style: _caption,
                ),
              const SizedBox(height: 12),
              _WorkloadMetrics(workload: workload),
              const SizedBox(height: 6),
              if (workload.workingSets == 0)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'No working sets logged in this view.',
                    style: _caption,
                  ),
                ),
              MuscleWorkloadChart(
                key: ValueKey(
                  '${scope.name}:${isWeek ? monday : selected?.id}',
                ),
                workload: workload,
                maxSets: chartScale,
                paintKey: const ValueKey('training-coverage-web'),
                weekly: isWeek,
              ),
              if (isWeek) ...[
                const SizedBox(height: 10),
                Text(
                  currentWeek
                      ? 'Targets show your full-week routine. Supporting work is included.'
                      : 'Logged work for this week. Current routine targets are not applied to past weeks.',
                  style: _caption,
                ),
              ],
            ],
          ),
        ),
        if (coverage != null && !isWeek) ...[
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
                  'Detailed muscles can share a set. The chart counts each broad muscle category once.',
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
          'The filled sectors show work performed, not just plan completion. Primary work counts as 1 set equivalent, supporting work as 0.35. A set counts at most once per broad category. Warmups and zero-rep sets are excluded. Tap a muscle for direct work, supporting work, and its target.\n\n'
          'Sector area is proportional to set equivalents. Comparable workouts share a scale; weeks use a separate scale. Dashed arcs show planned targets. Historical weeks show logged work without applying your current routine retrospectively. Lifting volume is external weight multiplied by repetitions, excluding warmups.\n\n'
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

class _WorkloadMetrics extends StatelessWidget {
  const _WorkloadMetrics({required this.workload});
  final MuscleWorkload workload;
  @override
  Widget build(BuildContext context) {
    final minutes = workload.durationSeconds ~/ 60;
    final duration = workload.durationSeconds <= 0
        ? '—'
        : minutes >= 60
        ? '${minutes ~/ 60}h ${minutes % 60}m'
        : '${minutes}m';
    final volume = workload.volumeKg >= 1000
        ? '${(workload.volumeKg / 1000).toStringAsFixed(1)}k'
        : workload.volumeKg.round().toString();
    return Row(
      children: [
        for (final metric in [
          (
            MediaQuery.textScalerOf(context).scale(12) > 16
                ? 'Sets'
                : 'Working sets',
            workload.workingSets.toString(),
          ),
          ('Volume · kg', volume),
          ('Duration', duration),
        ])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(metric.$1, style: _caption),
                  const SizedBox(height: 4),
                  Text(
                    metric.$2,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
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
