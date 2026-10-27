import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/pedometer_service.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/liquid_glass_date_picker.dart';
import '../models/daily_telemetry_model.dart';
import '../providers/habit_log_provider.dart';

void _show(BuildContext context, Widget child) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  isDismissible: false,
  enableDrag: false,
  backgroundColor: Colors.transparent,
  builder: (_) => child,
);
void showStepsDetailSheet(BuildContext context, DailyTelemetry telemetry) =>
    _show(context, _StepsSheet(initial: telemetry));
void showCaloriesDetailSheet(BuildContext context, DailyTelemetry telemetry) =>
    _show(context, const _CaloriesSheet());
void showHydrationDetailSheet(BuildContext context, DailyTelemetry telemetry) =>
    _show(context, const _WaterSheet());
void showSleepDetailSheet(BuildContext context, DailyTelemetry telemetry) =>
    _show(context, const _SleepSheet());

Future<double?> _number(
  BuildContext context, {
  required String title,
  required String label,
  required double initial,
  required double min,
  required double max,
}) async {
  var input = initial == initial.roundToDouble()
        ? initial.toInt().toString()
        : initial.toString();
  final key = GlobalKey<FormState>();
  final value = await showDialog<double>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Form(
        key: key,
        child: TextFormField(
          initialValue: input,
          onChanged: (value) => input = value,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
          validator: (text) {
            final n = double.tryParse(text ?? '');
            return n == null || !n.isFinite || n < min || n > max
                ? 'Enter $min–$max'
                : null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (key.currentState!.validate()) {
              Navigator.pop(ctx, double.parse(input));
            }
          },
          child: const Text('Apply'),
        ),
      ],
    ),
  );
  return value;
}

Widget _description(String text) => Text(
  text,
  style: AppTypography.bodyMedium.copyWith(
    color: AppColors.platinum,
    height: 1.5,
  ),
);
Widget _value(String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 12),
  child: Text(text, style: AppTypography.monoLarge.copyWith(fontSize: 32)),
);
Widget _error(String? error) => error == null
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          error,
          style: const TextStyle(fontSize: 13, color: AppColors.warning),
        ),
      );

class _StepsSheet extends ConsumerStatefulWidget {
  const _StepsSheet({required this.initial});
  final DailyTelemetry initial;
  @override
  ConsumerState<_StepsSheet> createState() => _StepsSheetState();
}

class _StepsSheetState extends ConsumerState<_StepsSheet> {
  int _period = 1;
  String? _errorText;
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dailyTelemetryProvider);
    final status = ref.watch(stepTrackingStatusProvider);
    final unavailable =
        status == StepTrackingStatus.permissionDenied ||
        status == StepTrackingStatus.sensorUnavailable;
    final now = DateUtils.dateOnly(DateTime.now());
    final count = _period == 1 ? 24 : _period;
    final start = now.subtract(Duration(days: count - 1));
    final values = List<int?>.generate(
      count,
      (i) => _period == 1
          ? (i < data.hourlySteps.length ? data.hourlySteps[i] : null)
          : i == count - 1
          ? (unavailable ? null : data.steps)
          : data.historicalDays[habitDateKey(start.add(Duration(days: i)))],
    );
    final hasData = values.any((v) => v != null && v > 0);
    final maxValue = values.fold<int>(1, (a, b) => b != null && b > a ? b : a);
    final local = MaterialLocalizations.of(context);
    return AppSheet(
      title: 'Steps',
      children: [
        _description(
          _period == 1
              ? local.formatFullDate(now)
              : '${local.formatMediumDate(start)} – ${local.formatMediumDate(now)}',
        ),
        _value(unavailable ? 'Unavailable' : '${data.steps} steps'),
        _description(
          unavailable
              ? (status == StepTrackingStatus.permissionDenied
                    ? 'Allow motion access to count steps on this phone.'
                    : 'This device does not provide a step sensor. Previously recorded days remain in your history.')
              : '${data.distanceKm.toStringAsFixed(2)} km estimated · ${data.stepsGoal} step daily goal',
        ),
        if (status == StepTrackingStatus.permissionDenied)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: FilledButton(
              onPressed: () =>
                  ref.read(pedometerServiceProvider).requestPermission(),
              child: const Text('ALLOW MOTION ACCESS'),
            ),
          ),
        const SizedBox(height: 20),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('Today')),
            ButtonSegment(value: 7, label: Text('7 days')),
            ButtonSegment(value: 30, label: Text('30 days')),
          ],
          selected: {_period},
          onSelectionChanged: (s) => setState(() => _period = s.first),
        ),
        const SizedBox(height: 20),
        if (!hasData || (_period == 1 && unavailable))
          GlassCard(
            child: _description(
              unavailable && _period == 1
                  ? 'Step distribution is unavailable on this device.'
                  : 'No recorded activity in this period. Your chart will appear when steps are recorded.',
            ),
          )
        else
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$maxValue steps',
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.platinum,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 130,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < count; i++)
                        Expanded(
                          child: Tooltip(
                            triggerMode: TooltipTriggerMode.tap,
                            message: _period == 1
                                ? '${i.toString().padLeft(2, '0')}:00 · ${values[i] ?? 0} steps'
                                : '${local.formatMediumDate(start.add(Duration(days: i)))} · ${values[i] == null ? 'Not recorded' : '${values[i]} steps'}',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: (values[i] ?? 0) / maxValue * 130,
                                  decoration: BoxDecoration(
                                    color: AppColors.platinum,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _period == 1 ? '00:00' : local.formatShortDate(start),
                      style: AppTypography.monoSmall,
                    ),
                    Text(
                      _period == 1 ? '23:00' : local.formatShortDate(now),
                      style: AppTypography.monoSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _description(
                  'Touch a bar for its count. Missing days have no bar.',
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () async {
            final n = await _number(
              context,
              title: 'Daily step goal',
              label: 'Steps',
              initial: data.stepsGoal.toDouble(),
              min: 500,
              max: 100000,
            );
            if (n == null) return;
            try {
              await ref
                  .read(habitLogProvider.notifier)
                  .setGoals(steps: n.round());
            } catch (_) {
              if (mounted) {
                setState(
                  () => _errorText = 'Could not save your goal. Try again.',
                );
              }
            }
          },
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Edit step goal'),
        ),
        _error(_errorText),
        _description(
          'Source: phone step sensor. Distance uses an average stride length and is an estimate.',
        ),
      ],
    );
  }
}

class _CaloriesSheet extends ConsumerStatefulWidget {
  const _CaloriesSheet();
  @override
  ConsumerState<_CaloriesSheet> createState() => _CaloriesSheetState();
}

class _CaloriesSheetState extends ConsumerState<_CaloriesSheet> {
  bool _busy = false;
  String? _errorText;
  @override
  Widget build(BuildContext context) {
    final calories = ref.watch(
      dailyTelemetryProvider.select((t) => t.calories),
    );
    return AppSheet(
      title: 'Active calories',
      busy: _busy,
      children: [
        _description(
          MaterialLocalizations.of(context).formatFullDate(DateTime.now()),
        ),
        _value(calories == 0 ? 'No data yet' : '$calories kcal'),
        _description(
          'Active burn entered by you. Resting calories are not tracked, and workout sets are not converted into a calorie estimate.',
        ),
        const SizedBox(height: 20),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MANUAL LOG', style: AppTypography.monoSmall),
              const SizedBox(height: 10),
              _description(
                'Enter active calories from your watch or another activity tracker.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy
              ? null
              : () async {
                  final n = await _number(
                    context,
                    title: 'Log active calories',
                    label: 'kcal',
                    initial: 100,
                    min: 1,
                    max: 10000,
                  );
                  if (n == null || !mounted) return;
                  setState(() {
                    _busy = true;
                    _errorText = null;
                  });
                  try {
                    await ref
                        .read(habitLogProvider.notifier)
                        .addCalories(n.round());
                  } catch (_) {
                    if (mounted) {
                      setState(() => _errorText = 'Could not save. Try again.');
                    }
                  }
                  if (mounted) setState(() => _busy = false);
                },
          child: Text(_busy ? 'SAVING…' : 'LOG ACTIVE CALORIES'),
        ),
        _error(_errorText),
      ],
    );
  }
}

class _WaterSheet extends ConsumerStatefulWidget {
  const _WaterSheet();
  @override
  ConsumerState<_WaterSheet> createState() => _WaterSheetState();
}

class _WaterSheetState extends ConsumerState<_WaterSheet> {
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  bool _busy = false;
  String? _errorText;
  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _errorText = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorText =
              'Could not save. Your entries have not changed. Try again.',
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final log = ref.watch(habitLogProvider);
    final day = log.day(_date);
    final notifier = ref.read(habitLogProvider.notifier);
    final local = MaterialLocalizations.of(context);
    return AppSheet(
      title: 'Hydration',
      busy: _busy,
      children: [
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () async {
                  final date = await showLiquidGlassDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null && mounted) setState(() => _date = date);
                },
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: Text(local.formatFullDate(_date)),
        ),
        _value('${day.waterMl} ml'),
        _description('Daily goal: ${log.waterGoalMl} ml'),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: (day.waterMl / log.waterGoalMl).clamp(0, 1),
          minHeight: 5,
          borderRadius: BorderRadius.circular(3),
          color: AppColors.platinum,
          backgroundColor: AppColors.steel,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final amount in [250, 500])
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => _run(() => notifier.addWater(amount, date: _date)),
                child: Text('+$amount ml'),
              ),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () async {
                      final n = await _number(
                        context,
                        title: 'Log water',
                        label: 'Milliliters',
                        initial: 350,
                        min: 1,
                        max: 5000,
                      );
                      if (n != null && mounted) {
                        await _run(
                          () => notifier.addWater(n.round(), date: _date),
                        );
                      }
                    },
              child: const Text('Custom'),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: _busy || day.water.isEmpty
              ? null
              : () => _run(() => notifier.undoWater(date: _date)),
          icon: const Icon(Icons.undo_rounded),
          label: Text(
            day.water.isEmpty
                ? 'Nothing to undo'
                : 'Undo last ${day.water.last.ml} ml',
          ),
        ),
        _error(_errorText),
        const SizedBox(height: 8),
        Text(
          'ENTRIES',
          style: AppTypography.monoSmall.copyWith(letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),
        if (day.water.isEmpty)
          _description('No water logged for this date.')
        else
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (final entry in day.water.reversed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.water_drop_outlined,
                      color: AppColors.platinum,
                    ),
                    title: Text(
                      '${entry.ml} ml',
                      style: AppTypography.monoMedium,
                    ),
                    trailing: Text(
                      local.formatTimeOfDay(TimeOfDay.fromDateTime(entry.time)),
                      style: AppTypography.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _busy
              ? null
              : () async {
                  final n = await _number(
                    context,
                    title: 'Daily water goal',
                    label: 'Milliliters',
                    initial: log.waterGoalMl.toDouble(),
                    min: 250,
                    max: 10000,
                  );
                  if (n != null && mounted) {
                    await _run(() => notifier.setGoals(waterMl: n.round()));
                  }
                },
          child: const Text('Edit water goal'),
        ),
      ],
    );
  }
}

class _SleepSheet extends ConsumerStatefulWidget {
  const _SleepSheet();
  @override
  ConsumerState<_SleepSheet> createState() => _SleepSheetState();
}

class _SleepSheetState extends ConsumerState<_SleepSheet> {
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  TimeOfDay _bed = const TimeOfDay(hour: 23, minute: 0),
      _wake = const TimeOfDay(hour: 7, minute: 0);
  final _duration = TextEditingController();
  bool _times = true, _busy = false;
  String? _feeling, _errorText;
  double get _hoursFromTimes {
    final minutes =
        (_wake.hour * 60 + _wake.minute - _bed.hour * 60 - _bed.minute + 1440) %
        1440;
    return minutes / 60;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final day = ref.read(habitLogProvider).day(_date);
    _times = day.bedtime != null || day.sleepHours == 0;
    _bed = day.bedtime == null
        ? const TimeOfDay(hour: 23, minute: 0)
        : TimeOfDay.fromDateTime(day.bedtime!);
    _wake = day.wakeTime == null
        ? const TimeOfDay(hour: 7, minute: 0)
        : TimeOfDay.fromDateTime(day.wakeTime!);
    _duration.text = (day.sleepHours > 0 ? day.sleepHours : _hoursFromTimes)
        .toStringAsFixed(2);
    _feeling = day.feeling;
    _errorText = null;
  }

  @override
  void dispose() {
    _duration.dispose();
    super.dispose();
  }

  Future<void> _pick(bool bed) async {
    final time = await showTimePicker(
      context: context,
      initialTime: bed ? _bed : _wake,
    );
    if (time != null && mounted) {
      setState(() {
        if (bed) {
          _bed = time;
        } else {
          _wake = time;
        }
        _duration.text = _hoursFromTimes.toStringAsFixed(2);
      });
    }
  }

  Future<void> _save() async {
    final hours = _times ? _hoursFromTimes : double.tryParse(_duration.text);
    if (hours == null || !hours.isFinite || hours <= 0 || hours > 24) {
      setState(
        () =>
            _errorText = 'Enter a duration greater than 0 and up to 24 hours.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final wake = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _wake.hour,
      _wake.minute,
    );
    final bed = wake.subtract(Duration(minutes: (hours * 60).round()));
    try {
      await ref
          .read(habitLogProvider.notifier)
          .saveSleep(
            date: _date,
            hours: hours,
            bedtime: _times ? bed : null,
            wakeTime: _times ? wake : null,
            feeling: _feeling ?? 'Not set',
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _errorText =
              'Could not save sleep. Your entry is still here; try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = ref.watch(habitLogProvider.select((s) => s.sleepGoalHours));
    final local = MaterialLocalizations.of(context);
    final hours = _times
        ? _hoursFromTimes
        : double.tryParse(_duration.text) ?? 0;
    return AppSheet(
      title: 'Log sleep',
      busy: _busy,
      children: [
        _description('Night ending on'),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () async {
                  final date = await showLiquidGlassDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null && mounted) {
                    setState(() {
                      _date = date;
                      _load();
                    });
                  }
                },
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: Text(local.formatFullDate(_date)),
        ),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Bed & wake times')),
            ButtonSegment(value: false, label: Text('Duration')),
          ],
          selected: {_times},
          onSelectionChanged: _busy
              ? null
              : (s) => setState(() {
                  if (s.first) {
                    final total = ((double.tryParse(_duration.text) ?? 8) * 60)
                        .round()
                        .clamp(1, 1439);
                    final bedMinutes =
                        (_wake.hour * 60 + _wake.minute - total + 1440) % 1440;
                    _bed = TimeOfDay(
                      hour: bedMinutes ~/ 60,
                      minute: bedMinutes % 60,
                    );
                  } else {
                    _duration.text = _hoursFromTimes.toStringAsFixed(2);
                  }
                  _times = s.first;
                }),
        ),
        const SizedBox(height: 18),
        if (_times)
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _pick(true),
                icon: const Icon(Icons.bedtime_outlined),
                label: Text('Bedtime ${local.formatTimeOfDay(_bed)}'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _pick(false),
                icon: const Icon(Icons.wb_sunny_outlined),
                label: Text('Wake ${local.formatTimeOfDay(_wake)}'),
              ),
            ],
          )
        else
          TextField(
            controller: _duration,
            enabled: !_busy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Hours slept',
              helperText: 'For example, 7.5 means 7 hours 30 minutes',
            ),
          ),
        _value('${hours.toStringAsFixed(1)} hours'),
        _description(
          'Goal: ${goal.toStringAsFixed(1)} hours. Manual sleep logs do not measure sleep stages or sleep quality.',
        ),
        const SizedBox(height: 20),
        Text('HOW DID YOU FEEL? (OPTIONAL)', style: AppTypography.monoSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final feeling in ['Rested', 'Okay', 'Tired'])
              ChoiceChip(
                label: Text(feeling),
                selected: _feeling == feeling,
                onSelected: _busy
                    ? null
                    : (selected) =>
                          setState(() => _feeling = selected ? feeling : null),
              ),
          ],
        ),
        _error(_errorText),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'SAVING…' : 'SAVE SLEEP'),
        ),
        TextButton(
          onPressed: _busy
              ? null
              : () async {
                  final n = await _number(
                    context,
                    title: 'Sleep goal',
                    label: 'Hours',
                    initial: goal,
                    min: 1,
                    max: 16,
                  );
                  if (n != null) {
                    try {
                      await ref
                          .read(habitLogProvider.notifier)
                          .setGoals(sleepHours: n);
                    } catch (_) {
                      if (mounted) {
                        setState(
                          () => _errorText = 'Could not save goal. Try again.',
                        );
                      }
                    }
                  }
                },
          child: const Text('Edit sleep goal'),
        ),
      ],
    );
  }
}
