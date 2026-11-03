import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/local_date_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/measurement_units.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/leon_button.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/persistence_feedback.dart';
import '../../dashboard/providers/habit_log_provider.dart';
import '../providers/recovery_provider.dart';

const recoveryExplanation =
    'A self-check estimate, not a medical evaluation or a test that an illness has resolved. Sleep, hydration and soreness are required. Authorized sleep imports can fill missing sleep; your manual sleep entry takes precedence. Hydration and soreness are logged manually. The score starts at 100: sleep deducts 5 points per hour below your target (up to 40), hydration deducts up to 15 below your target, and soreness deducts 3 per rating point. A workout today deducts 25, yesterday deducts 5; longer rest adds up to 10. Volume above your previous three-week average deducts up to 30 and needs four weeks of history. The result is limited to 0–100; missing inputs are never treated as good recovery.';

Future<void> showRecoveryExplanation(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Consumer(
        builder: (context, ref, child) =>
            _RecoveryExplanation(summary: ref.watch(recoverySummaryProvider)),
      ),
    );

class RecoveryScreen extends ConsumerWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(recoverySummaryProvider);
    final units = ref.watch(measurementUnitsProvider);
    final today = ref.watch(localDateProvider);
    final goals = ref.watch(
      habitLogProvider.select((log) => (log.sleepGoalHours, log.waterGoalMl)),
    );
    final habits = summary.habits;
    final numbers = MaterialLocalizations.of(context);
    void checkIn() => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // The route's drag handler sits outside the form's pending-write guards.
      // Use Close/back so a failed save always keeps the entered check-in here.
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecoveryCheckIn(date: today),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('RECOVERY', style: AppTypography.headlineLarge),
        actions: [
          IconButton(
            tooltip: 'How recovery is estimated',
            icon: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.platinum,
            ),
            onPressed: () => showRecoveryExplanation(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: BackdropGroup(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    'TODAY · ${MaterialLocalizations.of(context).formatMediumDate(today).toUpperCase()}',
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CheckInSummary(summary: summary, onCheckIn: checkIn),
                  const SizedBox(height: 24),
                  const _RecoverySectionTitle("TODAY'S INPUTS"),
                  const SizedBox(height: 10),
                  _RecoveryCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _RecoveryInputRow(
                          title: 'Sleep',
                          icon: Icons.bedtime_outlined,
                          value: habits.sleepLogged
                              ? habits.sleepHours.toStringAsFixed(1)
                              : '—',
                          unit: habits.sleepLogged ? 'h' : '',
                          detail:
                              '${habits.sleepLogged ? summary.sleepSource ?? 'Manual log' : 'Not logged'} · Goal ${goals.$1.toStringAsFixed(1)} h',
                        ),
                        const Divider(height: 1),
                        _RecoveryInputRow(
                          title: 'Hydration',
                          icon: Icons.water_drop_outlined,
                          value: habits.water.isEmpty
                              ? '—'
                              : numbers.formatDecimal(habits.waterMl),
                          unit: habits.water.isEmpty ? '' : 'ml',
                          detail:
                              '${habits.water.isEmpty ? 'Not logged' : 'Logged today'} · Goal ${numbers.formatDecimal(goals.$2)} ml',
                        ),
                        const Divider(height: 1),
                        _RecoveryInputRow(
                          title: 'Soreness',
                          icon: Icons.accessibility_new_rounded,
                          value: habits.soreness == null
                              ? '—'
                              : '${habits.soreness}',
                          unit: habits.soreness == null ? '' : '/10',
                          detail: habits.soreness == null
                              ? 'Not logged · How your muscles feel'
                              : habits.soreness == 0
                              ? 'No muscle soreness'
                              : 'Your muscle soreness today',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _RecoverySectionTitle('RECENT TRAINING'),
                  const SizedBox(height: 10),
                  _RecentTraining(summary: summary, units: units),
                  const SizedBox(height: 16),
                  Text(
                    'A personal self-check, not a medical assessment.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.platinum,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => GlassCard(
    blur: true,
    sharedBackdrop: true,
    repaintBoundary: true,
    border: false,
    boxShadow: const [],
    borderRadius: 20,
    padding: padding,
    gradient: MediaQuery.highContrastOf(context)
        ? const LinearGradient(
            colors: [AppColors.cardBackground, AppColors.cardBackground],
          )
        : null,
    child: child,
  );
}

class _RecoverySectionTitle extends StatelessWidget {
  const _RecoverySectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      title,
      style: AppTypography.headlineSmall.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.platinum,
      ),
    ),
  );
}

class _CheckInSummary extends StatelessWidget {
  const _CheckInSummary({required this.summary, required this.onCheckIn});
  final RecoverySummary summary;
  final VoidCallback onCheckIn;

  String get missingDescription {
    final inputs = summary.missingInputs
        .map((input) => input.toLowerCase())
        .toList();
    final list = inputs.length < 2
        ? inputs.join()
        : '${inputs.take(inputs.length - 1).join(', ')} and ${inputs.last}';
    return 'Add $list to see your estimate.';
  }

  @override
  Widget build(BuildContext context) {
    final score = summary.score;
    return _RecoveryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'SELF-CHECK ESTIMATE',
                  style: AppTypography.labelSmall.copyWith(letterSpacing: 1.5),
                ),
              ),
              Icon(
                Icons.insights_outlined,
                size: 20,
                color: AppColors.platinum,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (score == null)
            Text("Finish today's check-in", style: AppTypography.headlineLarge)
          else
            Semantics(
              label: 'Self-check estimate: ${score.value} out of 100',
              excludeSemantics: true,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${score.value}',
                      style: AppTypography.monoLarge.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(
                      text: ' / 100',
                      style: AppTypography.monoSmall,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            score == null
                ? missingDescription
                : "Based on today's sleep, hydration and soreness.",
            style: AppTypography.bodyMedium,
          ),
          if (score == null) ...[
            const SizedBox(height: 8),
            Text(
              '${3 - summary.missingInputs.length} of 3 inputs logged',
              style: AppTypography.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          LeonButton(
            key: const ValueKey('recovery-check-in-action'),
            onPressed: onCheckIn,
            icon: Icons.edit_outlined,
            label: score == null ? 'LOG CHECK-IN' : 'UPDATE CHECK-IN',
          ),
        ],
      ),
    );
  }
}

class _RecoveryInputRow extends StatelessWidget {
  const _RecoveryInputRow({
    required this.title,
    required this.icon,
    required this.value,
    required this.unit,
    required this.detail,
  });
  final String title, value, unit, detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth / MediaQuery.textScalerOf(context).scale(1) <
              260;
          final metric = Text.rich(
            key: ValueKey('recovery-input-value-$title'),
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTypography.monoMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: unit.isEmpty ? '' : ' $unit',
                  style: AppTypography.monoSmall,
                ),
              ],
            ),
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ExcludeSemantics(
                  child: Icon(icon, size: 22, color: AppColors.platinum),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (stacked) ...[
                      Text(
                        title,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      metric,
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          metric,
                        ],
                      ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 13,
                        color: AppColors.platinum,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _RecentTraining extends StatelessWidget {
  const _RecentTraining({required this.summary, required this.units});
  final RecoverySummary summary;
  final MeasurementUnits units;

  @override
  Widget build(BuildContext context) {
    final number = MaterialLocalizations.of(context);
    return _RecoveryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              const Text('Last workout', style: AppTypography.bodyMedium),
              Text(
                summary.lastWorkout == null
                    ? 'None logged'
                    : MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(summary.lastWorkout!),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final metrics = [
                _TrainingMetric(
                  value: '${summary.recentSessions}',
                  label: 'Workouts · last 7 days',
                ),
                _TrainingMetric(
                  value: number.formatDecimal(
                    units.weightFromKg(summary.recentVolumeKg).round(),
                  ),
                  label: '${units.weightLabel} volume · last 7 days',
                ),
              ];
              if (constraints.maxWidth /
                      MediaQuery.textScalerOf(context).scale(1) <
                  260) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    metrics[0],
                    const SizedBox(height: 16),
                    metrics[1],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: metrics[0]),
                  const SizedBox(width: 16),
                  Expanded(child: metrics[1]),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            summary.baselineVolumeKg == null
                ? 'Volume comparison needs four weeks of history.'
                : 'Previous weekly average: ${units.weight(summary.baselineVolumeKg, decimals: 0)}.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.platinum),
          ),
        ],
      ),
    );
  }
}

class _TrainingMetric extends StatelessWidget {
  const _TrainingMetric({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: AppTypography.monoMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: AppTypography.bodySmall.copyWith(color: AppColors.platinum),
      ),
    ],
  );
}

class _RecoveryExplanation extends StatelessWidget {
  const _RecoveryExplanation({required this.summary});
  final RecoverySummary summary;

  @override
  Widget build(BuildContext context) => AppSheet(
    title: 'How recovery is estimated',
    children: [
      const Text(
        'This is a personal self-check, not a medical evaluation or confirmation that an illness has resolved.',
        style: AppTypography.bodyMedium,
      ),
      const SizedBox(height: 20),
      const _RecoverySectionTitle('YOUR INPUTS'),
      const SizedBox(height: 8),
      const _ExplanationGroup(
        children: [
          _EstimateRule(
            title: 'Three inputs, one check-in',
            detail:
                'Log sleep, hydration and soreness to see an estimate. Missing inputs never count as good recovery.',
          ),
          _EstimateRule(
            title: 'Your sleep entry comes first',
            detail:
                'Authorized sleep imports can fill missing sleep. A manual entry takes precedence.',
          ),
        ],
      ),
      const SizedBox(height: 20),
      const _RecoverySectionTitle('THE SCORE'),
      const SizedBox(height: 8),
      const Text(
        'The estimate starts at 100 and stays between 0 and 100.',
        style: AppTypography.bodyMedium,
      ),
      const SizedBox(height: 12),
      const _ExplanationGroup(
        children: [
          _EstimateRule(
            title: 'Sleep',
            detail:
                '5 points deducted per hour below your sleep goal, up to 40 points.',
          ),
          _EstimateRule(
            title: 'Hydration',
            detail:
                'Up to 15 points deducted when your logged water is below your goal.',
          ),
          _EstimateRule(
            title: 'Soreness',
            detail: '3 points deducted per point on your 0–10 soreness rating.',
          ),
          _EstimateRule(
            title: 'Recent workouts',
            detail:
                'A workout today deducts 25 points; yesterday deducts 5. Two days off adds 5; longer rest adds 10.',
          ),
          _EstimateRule(
            title: 'Training volume',
            detail:
                'Up to 30 points deducted above your previous three-week average. This comparison needs four weeks of history.',
          ),
        ],
      ),
      if (summary.score != null) ...[
        const SizedBox(height: 24),
        const _RecoverySectionTitle("TODAY'S CONTRIBUTIONS"),
        const SizedBox(height: 12),
        _ExplanationGroup(
          children: [
            for (final factor in summary.score!.factors)
              _EstimateRule(
                title: switch (factor.label) {
                  'REST DAYS' => 'Rest days',
                  'VOLUME LOAD' => 'Training volume',
                  'SLEEP' => 'Sleep',
                  'HYDRATION' => 'Hydration',
                  'SORENESS' => 'Soreness',
                  _ => factor.label,
                },
                // Half-point contributions remain visible, so displayed factors
                // do not misleadingly add up to a different score.
                value:
                    '${factor.delta() > 0 ? '+' : ''}${factor.delta().toStringAsFixed(factor.delta() == factor.delta().roundToDouble() ? 0 : 1)} pts',
                detail: factor.insight ?? 'Included in today’s estimate.',
              ),
          ],
        ),
      ],
    ],
  );
}

class _ExplanationGroup extends StatelessWidget {
  const _ExplanationGroup({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.subtleBorder),
            children[i],
          ],
        ],
      ),
    ),
  );
}

class _EstimateRule extends StatelessWidget {
  const _EstimateRule({required this.title, required this.detail, this.value});
  final String title, detail;
  final String? value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: [
            Text(
              title,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (value != null) Text(value!, style: AppTypography.monoSmall),
          ],
        ),
        const SizedBox(height: 4),
        Text(detail, style: AppTypography.bodyMedium.copyWith(fontSize: 13)),
      ],
    ),
  );
}

class _RecoveryCheckIn extends ConsumerStatefulWidget {
  const _RecoveryCheckIn({required this.date});
  final DateTime date;
  @override
  ConsumerState<_RecoveryCheckIn> createState() => _RecoveryCheckInState();
}

class _RecoveryCheckInState extends ConsumerState<_RecoveryCheckIn> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _sleep;
  final _water = TextEditingController();
  late int? _soreness;
  bool _pending = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final day = ref.read(habitLogProvider).day(widget.date);
    _sleep = TextEditingController(
      text: day.sleepLogged ? day.sleepHours.toString() : '',
    );
    _soreness = day.soreness;
  }

  @override
  void dispose() {
    _sleep.dispose();
    _water.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_pending || !_form.currentState!.validate()) return;
    setState(() {
      _pending = true;
      _saveError = null;
    });
    try {
      await ref
          .read(habitLogProvider.notifier)
          .saveRecoveryCheckIn(
            date: widget.date,
            hours: _sleep.text.trim().isEmpty
                ? null
                : double.parse(_sleep.text.trim()),
            waterToAdd: _water.text.trim().isEmpty
                ? null
                : int.parse(_water.text.trim()),
            soreness: _soreness,
          );
      if (!mounted) return;
      setState(() => _pending = false);
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pending = false;
        _saveError = 'Could not save. Try again. Your input is still here.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final waterToday = ref.watch(
      habitLogProvider.select((log) => log.day(widget.date).waterMl),
    );
    return PersistenceForm(
      pending: _pending,
      child: Form(
        key: _form,
        child: AppSheet(
          title: 'Recovery check-in',
          busy: _pending,
          children: [
            Text(
              MaterialLocalizations.of(context).formatMediumDate(widget.date),
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 20),
            _CheckInField(
              title: 'Sleep',
              detail: "Last night's total. Leave blank to keep saved sleep.",
              child: TextFormField(
                enabled: !_pending,
                controller: _sleep,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                style: AppTypography.monoMedium.copyWith(fontSize: 18),
                validator: (text) {
                  final input = text?.trim() ?? '';
                  if (input.isEmpty) return null;
                  final hours = double.tryParse(input);
                  return hours == null ||
                          !hours.isFinite ||
                          hours < 0 ||
                          hours > 24
                      ? 'Enter sleep between 0 and 24 hours.'
                      : null;
                },
                decoration: const InputDecoration(
                  hintText: 'e.g. 8.0',
                  suffixText: 'h',
                  errorMaxLines: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _CheckInField(
              title: 'Add hydration',
              detail:
                  'Today: ${MaterialLocalizations.of(context).formatDecimal(waterToday)} ml. Adds to your logged water; leave blank to keep it.',
              child: TextFormField(
                enabled: !_pending,
                controller: _water,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                style: AppTypography.monoMedium.copyWith(fontSize: 18),
                validator: (text) {
                  final input = text?.trim() ?? '';
                  if (input.isEmpty) return null;
                  final water = int.tryParse(input);
                  return water == null || water < 0 || water > 10000
                      ? 'Enter water between 0 and 10,000 ml.'
                      : null;
                },
                decoration: const InputDecoration(
                  hintText: 'e.g. 250',
                  suffixText: 'ml',
                  errorMaxLines: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _CheckInField(
              title: 'Soreness (0–10)',
              detail:
                  'How your muscles feel today. 0 means no soreness; 10 means severe.',
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                isDense: false,
                itemHeight: null,
                style: AppTypography.bodyLarge,
                initialValue: _soreness,
                decoration: const InputDecoration(),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Not logged'),
                  ),
                  for (var i = 0; i <= 10; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        '$i${i == 0
                            ? ' · None'
                            : i == 10
                            ? ' · Severe'
                            : ''}',
                      ),
                    ),
                ],
                onChanged: _pending
                    ? null
                    : (value) => setState(() => _soreness = value),
              ),
            ),
            const SizedBox(height: 24),
            LeonButton(
              label: 'SAVE CHECK-IN',
              isLoading: _pending,
              onPressed: _save,
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  _saveError!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CheckInField extends StatelessWidget {
  const _CheckInField({
    required this.title,
    required this.detail,
    required this.child,
  });
  final String title, detail;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        title,
        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 4),
      Text(detail, style: AppTypography.bodyMedium.copyWith(fontSize: 13)),
      const SizedBox(height: 10),
      Semantics(label: title, child: child),
    ],
  );
}
