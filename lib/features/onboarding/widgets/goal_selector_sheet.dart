import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/persistence_feedback.dart';
import '../providers/onboarding_provider.dart';

void showGoalSelectorSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => const _GoalSelectorSheet(),
  );
}

class _GoalSelectorSheet extends ConsumerStatefulWidget {
  const _GoalSelectorSheet();
  @override
  ConsumerState<_GoalSelectorSheet> createState() => _GoalSelectorSheetState();
}

class _GoalSelectorSheetState extends ConsumerState<_GoalSelectorSheet> {
  bool _saving = false;
  Future<void> _select(String goal) async {
    if (_saving) return;
    setState(() => _saving = true);
    final success = await persistWithFeedback(
      context,
      () => ref.read(onboardingProvider.notifier).updatePrimaryGoal(goal),
      message: 'Could not save your training goal. Please try again.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(trainingGoalProvider);
    return PersistenceForm(
      pending: _saving,
      child: AppSheet(
        title: 'CHANGE TRAINING GOAL',
        busy: _saving,
        children: [
          const Text(
            'Choose the focus for your training guidance. Your saved routines and rest preferences keep their own settings.',
          ),
          const SizedBox(height: 16),
          for (final (title, description) in [
            ('BUILD MUSCLE', 'Build muscle with progressive training.'),
            ('STRENGTH', 'Focus on strength and personal bests.'),
            (
              'LOSE FAT',
              'Support your weight-loss goal with regular training.',
            ),
            ('ATHLETIC', 'Focus on conditioning and general fitness.'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(title),
                subtitle: Text(description),
                selected: title == selected,
                trailing: title == selected
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: _saving ? null : () => _select(title),
              ),
            ),
          if (_saving) const Text('Saving your training goal…'),
        ],
      ),
    );
  }
}
