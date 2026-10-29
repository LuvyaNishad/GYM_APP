import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/calorie_history_provider.dart';
import '../providers/habit_log_provider.dart';
import '../../../shared/widgets/daily_activity_chart.dart';

class CaloriesDetailSheet extends ConsumerStatefulWidget {
  const CaloriesDetailSheet({super.key, required this.requestCalories});
  final Future<int?> Function(BuildContext) requestCalories;
  @override
  ConsumerState<CaloriesDetailSheet> createState() =>
      _CaloriesDetailSheetState();
}

class _CaloriesDetailSheetState extends ConsumerState<CaloriesDetailSheet> {
  int _period = 7;
  int? _selection;
  bool _busy = false;
  String? _error;

  Future<void> _log() async {
    final value = await widget.requestCalories(context);
    if (value == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(habitLogProvider.notifier).addCalories(value);
      if (mounted) setState(() => _selection = null);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final series = ref.watch(calorieHistoryProvider(_period));
    final selected = (_selection ?? _period - 1).clamp(0, _period - 1);
    final date = series.dateAt(selected);
    final value = series.values[selected];
    final local = MaterialLocalizations.of(context);
    final today = selected == _period - 1;
    final first = series.start;
    final last = series.dateAt(_period - 1);

    void select(int index) {
      if (selected != index) setState(() => _selection = index);
    }

    return AppSheet(
      title: 'Calories',
      busy: _busy,
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
                key: const ValueKey('calorie-total'),
                style: AppTypography.monoLarge.copyWith(fontSize: 48),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'kcal',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value == null
              ? 'No active calories logged'
              : 'Active calories · manual log',
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
                      'Daily burn',
                      style: AppTypography.headlineSmall,
                    ),
                  ),
                  for (final days in [7, 30])
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          foregroundColor: _period == days
                              ? AppColors.primary
                              : AppColors.textMuted,
                          backgroundColor: _period == days
                              ? AppColors.primary.withValues(alpha: .08)
                              : Colors.transparent,
                        ),
                        onPressed: () => setState(() {
                          _period = days;
                          _selection = null;
                        }),
                        child: Text(
                          '${days}d',
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
                    'Daily active calories. ${local.formatFullDate(date)}: ${value == null ? 'not logged' : '$value kcal'}.',
                onIncrease: selected < _period - 1
                    ? () => select(selected + 1)
                    : null,
                onDecrease: selected > 0 ? () => select(selected - 1) : null,
                child: ExcludeSemantics(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      DailyActivityChart(
                        paintKey: const ValueKey('calorie-bars'),
                        values: series.values,
                        selected: selected,
                        onSelected: select,
                      ),
                      if (!series.hasData)
                        IgnorePointer(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Log your first activity to see your daily burn.',
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
                    7,
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
                    Text(
                      local.formatShortMonthDay(first),
                      style: AppTypography.labelSmall,
                    ),
                    Text(
                      local.formatShortMonthDay(series.dateAt(14)),
                      style: AppTypography.labelSmall,
                    ),
                    Text(
                      local.formatShortMonthDay(last),
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Previous day',
                    onPressed: selected > 0 ? () => select(selected - 1) : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      today
                          ? 'Today · ${local.formatShortMonthDay(date)}'
                          : local.formatMediumDate(date),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next day',
                    onPressed: selected < _period - 1
                        ? () => select(selected + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _busy ? null : _log,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(_busy ? 'SAVING…' : 'LOG CALORIES'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _error!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Use the active burn from your watch or activity tracker.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall,
        ),
      ],
    );
  }
}
