import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/local_date_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/measurement_units.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/persistence_feedback.dart';
import '../../dashboard/providers/habit_log_provider.dart';
import '../providers/recovery_provider.dart';

const recoveryExplanation =
    'A self-check estimate, not a medical evaluation or a test that an illness has resolved. All three manual inputs are required. The score starts at 100: sleep deducts 5 points per hour below your target (up to 40), hydration deducts up to 15 below your target, and soreness deducts 3 per rating point. A workout today deducts 25, yesterday deducts 5; longer rest adds up to 10. Volume above your previous three-week average deducts up to 30 and needs four weeks of history. The result is limited to 0–100; missing inputs are never treated as good recovery.';

class RecoveryScreen extends ConsumerWidget {
  const RecoveryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(recoverySummaryProvider);
    final units = ref.watch(measurementUnitsProvider);
    final today = ref.watch(localDateProvider);
    final habits = summary.habits;
    return Scaffold(
      appBar: AppBar(title: const Text('RECOVERY')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            blur: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SELF-CHECK ESTIMATE', style: AppTypography.headlineSmall),
                Text(
                  summary.score == null
                      ? 'More input needed'
                      : '${summary.score!.value}/100',
                  style: AppTypography.monoLarge,
                ),
                Text(
                  summary.missingInputs.isEmpty
                      ? 'Based on today\'s logged inputs.'
                      : 'Not logged today: ${summary.missingInputs.join(', ')}.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => _RecoveryCheckIn(date: today),
                  ),
                  child: const Text('LOG RECOVERY CHECK-IN'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            blur: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TODAY\'S INPUTS', style: AppTypography.headlineSmall),
                Text(
                  habits.sleepLogged
                      ? 'Sleep: ${habits.sleepHours.toStringAsFixed(1)} h'
                      : 'Sleep: Not logged',
                  style: AppTypography.monoMedium,
                ),
                Text(
                  habits.water.isEmpty
                      ? 'Hydration: Not logged'
                      : 'Hydration: ${habits.waterMl} ml',
                  style: AppTypography.monoMedium,
                ),
                Text(
                  habits.soreness == null
                      ? 'Soreness: Not logged'
                      : 'Soreness: ${habits.soreness}/10',
                  style: AppTypography.monoMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            blur: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WORKOUT HISTORY', style: AppTypography.headlineSmall),
                Text(
                  'Last workout: ${summary.lastWorkout == null ? 'None logged' : MaterialLocalizations.of(context).formatMediumDate(summary.lastWorkout!)}',
                  style: AppTypography.bodyMedium,
                ),
                Text(
                  '${summary.recentSessions} sessions in the last 7 days · ${units.weight(summary.recentVolumeKg)} volume',
                  style: AppTypography.bodyMedium,
                ),
                Text(
                  summary.baselineVolumeKg == null
                      ? 'Not enough history for a volume comparison.'
                      : 'Previous three-week average: ${units.weight(summary.baselineVolumeKg)} per week.',
                  style: AppTypography.bodySmall,
                ),
                for (final factor in summary.score?.factors ?? [])
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${factor.label}: ${factor.insight ?? 'Contribution ${factor.delta().toStringAsFixed(0)}'}',
                      style: AppTypography.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const GlassCard(
            blur: true,
            child: Text(recoveryExplanation, style: AppTypography.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _RecoveryCheckIn extends ConsumerStatefulWidget {
  const _RecoveryCheckIn({required this.date});
  final DateTime date;
  @override
  ConsumerState<_RecoveryCheckIn> createState() => _RecoveryCheckInState();
}

class _RecoveryCheckInState extends ConsumerState<_RecoveryCheckIn> {
  late final TextEditingController _sleep;
  final _water = TextEditingController();
  late int? _soreness;
  bool _pending = false;
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
    if (_pending) return;
    setState(() => _pending = true);
    final success = await persistWithFeedback(
      context,
      () async {
        final sleep = _sleep.text.trim().isEmpty
            ? null
            : double.tryParse(_sleep.text);
        final water = _water.text.trim().isEmpty
            ? null
            : int.tryParse(_water.text);
        if ((_sleep.text.isNotEmpty && sleep == null) ||
            (_water.text.isNotEmpty && water == null)) {
          throw const FormatException();
        }
        await ref
            .read(habitLogProvider.notifier)
            .saveRecoveryCheckIn(
              date: widget.date,
              hours: sleep,
              waterToAdd: water,
              soreness: _soreness,
            );
      },
      message:
          'Could not save. Check your values and try again. Your input is still here.',
    );
    if (!mounted) return;
    setState(() => _pending = false);
    if (success) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => PersistenceForm(
    pending: _pending,
    child: AppSheet(
      title: 'Recovery check-in',
      children: [
        Text(
          MaterialLocalizations.of(context).formatMediumDate(widget.date),
          style: AppTypography.bodySmall,
        ),
        TextField(
          controller: _sleep,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTypography.monoMedium,
          decoration: const InputDecoration(
            labelText: 'Sleep (hours)',
            helperText: 'Leave empty if not logged.',
          ),
        ),
        TextField(
          controller: _water,
          keyboardType: TextInputType.number,
          style: AppTypography.monoMedium,
          decoration: const InputDecoration(
            labelText: 'Add hydration (ml)',
            helperText: 'Adds to the water already logged today.',
          ),
        ),
        DropdownButtonFormField<int>(
          initialValue: _soreness,
          decoration: const InputDecoration(labelText: 'Soreness (0–10)'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Not logged')),
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
          onChanged: (value) => setState(() => _soreness = value),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _pending ? null : _save,
          child: const Text('SAVE CHECK-IN'),
        ),
      ],
    ),
  );
}
