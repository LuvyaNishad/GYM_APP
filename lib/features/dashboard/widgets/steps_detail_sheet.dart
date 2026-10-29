import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/pedometer_service.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/daily_activity_chart.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/daily_telemetry_model.dart';
import '../providers/habit_log_provider.dart';
import '../providers/step_history_provider.dart';

class StepsDetailSheet extends ConsumerStatefulWidget {
  const StepsDetailSheet({super.key, required this.requestGoal});
  final Future<int?> Function(BuildContext, int) requestGoal;

  @override
  ConsumerState<StepsDetailSheet> createState() => _StepsDetailSheetState();
}

class _StepsDetailSheetState extends ConsumerState<StepsDetailSheet> {
  int _period = 7;
  int _page = 0;
  int? _selection;
  bool _refreshing = false;
  bool _saving = false;
  String? _error;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(pedometerServiceProvider).syncWithInbuiltPedometer();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _editGoal(int current) async {
    final goal = await widget.requestGoal(context, current);
    if (goal == null || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(habitLogProvider.notifier).setGoals(steps: goal);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save your goal. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final series = ref.watch(stepHistoryProvider((days: _period, page: _page)));
    final goal = ref.watch(
      dailyTelemetryProvider.select((data) => data.stepsGoal),
    );
    final status = ref.watch(stepTrackingStatusProvider);
    final sync = ref.watch(stepSyncInfoProvider);
    final selected = (_selection ?? series.values.length - 1).clamp(
      0,
      series.values.length - 1,
    );
    final date = series.dateAt(selected);
    final value = series.values[selected];
    final local = MaterialLocalizations.of(context);
    final today = DateUtils.isSameDay(date, DateTime.now());
    final first = series.start;
    final last = series.dateAt(series.values.length - 1);
    final denied = status == StepTrackingStatus.permissionDenied;

    void select(int index) {
      if (selected != index) setState(() => _selection = index);
    }

    void page(int next) => setState(() {
      _page = next;
      _selection = null;
    });

    return AppSheet(
      title: 'Steps',
      busy: _saving,
      children: [
        const SizedBox(height: 4),
        Text(
          today ? 'Today' : local.formatMediumDate(date),
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                value?.toString() ?? '—',
                key: const ValueKey('step-total'),
                style: AppTypography.monoLarge.copyWith(fontSize: 48),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'steps',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value == null
              ? 'No step record for this day'
              : '${(value * .000708).toStringAsFixed(2)} km estimated · $goal daily goal',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: 24),
        GlassCard(
          blur: true,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Daily steps',
                      style: AppTypography.headlineSmall,
                    ),
                  ),
                  for (final days in [7, 30, 0])
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          foregroundColor: _period == days
                              ? AppColors.primary
                              : AppColors.textMuted,
                          backgroundColor: _period == days
                              ? AppColors.primary.withValues(alpha: .08)
                              : Colors.transparent,
                        ),
                        onPressed: () => setState(() {
                          _period = days;
                          _page = 0;
                          _selection = null;
                        }),
                        child: Text(
                          days == 0 ? 'All' : '${days}d',
                          style: AppTypography.bodySmall.copyWith(
                            color: _period == days
                                ? AppColors.primary
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Semantics(
                label:
                    'Daily steps. ${local.formatFullDate(date)}: ${value == null ? 'not recorded' : '$value steps'}.',
                onIncrease: selected < series.values.length - 1
                    ? () => select(selected + 1)
                    : null,
                onDecrease: selected > 0 ? () => select(selected - 1) : null,
                child: ExcludeSemantics(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      DailyActivityChart(
                        key: ValueKey((first, last)),
                        paintKey: const ValueKey('step-bars'),
                        values: series.values,
                        selected: selected,
                        onSelected: select,
                      ),
                      if (!series.hasData)
                        IgnorePointer(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Your daily chart appears when phone steps are available.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_period == 7)
                Row(
                  children: List.generate(
                    series.values.length,
                    (i) => Expanded(
                      child: Center(
                        child: Text(
                          local.narrowWeekdays[series.dateAt(i).weekday % 7],
                          style: AppTypography.labelSmall.copyWith(
                            color: i == selected
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        local.formatShortMonthDay(first),
                        style: AppTypography.labelSmall,
                      ),
                    ),
                    if (first != last)
                      Expanded(
                        child: Text(
                          local.formatShortMonthDay(last),
                          textAlign: TextAlign.right,
                          style: AppTypography.labelSmall,
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    tooltip: _period == 0 ? 'Older days' : 'Previous day',
                    onPressed: _period == 0
                        ? (series.page < series.lastPage
                              ? () => page(series.page + 1)
                              : null)
                        : (selected > 0 ? () => select(selected - 1) : null),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      _period == 0
                          ? '${local.formatShortMonthDay(first)} – ${local.formatShortMonthDay(last)}'
                          : today
                          ? 'Today · ${local.formatShortMonthDay(date)}'
                          : local.formatMediumDate(date),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall,
                    ),
                  ),
                  IconButton(
                    tooltip: _period == 0 ? 'Newer days' : 'Next day',
                    onPressed: _period == 0
                        ? (series.page > 0 ? () => page(series.page - 1) : null)
                        : (selected < series.values.length - 1
                              ? () => select(selected + 1)
                              : null),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _refreshing
              ? null
              : denied
              ? () => ref.read(pedometerServiceProvider).requestPermission()
              : _refresh,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
          icon: Icon(
            denied ? Icons.directions_walk_rounded : Icons.refresh_rounded,
            size: 20,
          ),
          label: Text(
            _refreshing
                ? 'REFRESHING…'
                : denied
                ? 'ALLOW MOTION ACCESS'
                : 'REFRESH STEPS',
          ),
        ),
        if (denied ||
            status == StepTrackingStatus.sensorUnavailable ||
            status == StepTrackingStatus.syncFailed)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              denied
                  ? 'Allow motion access to count phone steps.'
                  : status == StepTrackingStatus.sensorUnavailable
                  ? 'Phone steps are unavailable. Saved history is kept.'
                  : 'Refresh failed. Saved totals are kept; sync will retry.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
            ),
          ),
        TextButton.icon(
          onPressed: _saving ? null : () => _editGoal(goal),
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: const Text('Edit step goal'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _error!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
            ),
          ),
        Text(
          '${sync.source ?? 'Phone step tracker'}${sync.updatedAt == null ? '' : ' · Updated ${local.formatTimeOfDay(TimeOfDay.fromDateTime(sync.updatedAt!.toLocal()))}'}',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall,
        ),
      ],
    );
  }
}
