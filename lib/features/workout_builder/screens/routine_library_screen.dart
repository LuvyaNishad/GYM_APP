import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/split_model.dart';
import '../providers/splits_provider.dart';
import '../widgets/create_routine_sheet.dart';

class RoutineLibraryScreen extends ConsumerStatefulWidget {
  const RoutineLibraryScreen({super.key});
  @override
  ConsumerState<RoutineLibraryScreen> createState() =>
      _RoutineLibraryScreenState();
}

class _RoutineLibraryScreenState extends ConsumerState<RoutineLibraryScreen> {
  bool _mine = false;
  String? _expanded;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(splitsProvider);
    final splits = _mine ? state.customSplits : state.presetSplits;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('ROUTINE LIBRARY', style: AppTypography.headlineSmall),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<bool>(
              segments: [
                const ButtonSegment(value: false, label: Text('Templates')),
                ButtonSegment(
                  value: true,
                  label: Text('My routines (${state.customSplits.length})'),
                ),
              ],
              selected: {_mine},
              onSelectionChanged: (s) => setState(() => _mine = s.first),
            ),
          ),
          Expanded(
            child: splits.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.folder_open_outlined,
                            size: 42,
                            color: AppColors.platinum,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your routines live here',
                            style: AppTypography.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create an empty routine or customize a template. Changes are saved only when you choose Save.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: splits.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) =>
                        _card(splits[i], state.activeSplitId),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: () => showCreateRoutineSheet(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('CREATE ROUTINE'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(TrainingSplitModel split, String activeId) {
    final expanded = _expanded == split.id;
    return GlassCard(
      border: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = expanded ? null : split.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(split.name, style: AppTypography.headlineSmall),
                        const SizedBox(height: 6),
                        Text(
                          '${split.daysPerWeek} days/week · ${split.totalWorkouts} workouts${activeId == split.id ? ' · Active' : ''}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.platinum,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 14),
            Text(split.description, style: AppTypography.bodyMedium),
            const SizedBox(height: 12),
            for (final day in split.workouts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  '${day.name} · ${day.isRestDay ? 'Rest' : '${day.exercises.length} exercises, ${day.totalSets} sets'}',
                  style: AppTypography.bodySmall,
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () =>
                      showCreateRoutineSheet(context, initialSplit: split),
                  child: Text(split.isCustom ? 'EDIT' : 'CUSTOMIZE'),
                ),
                if (activeId != split.id)
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(splitsProvider.notifier)
                          .switchActiveSplit(split.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${split.name} is now active.')),
                      );
                    },
                    child: const Text('MAKE ACTIVE'),
                  ),
                if (split.isCustom)
                  TextButton(
                    onPressed: () => _delete(split),
                    child: const Text('Delete'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _delete(TrainingSplitModel split) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete routine?'),
        content: Text(
          'Delete “${split.name}”? Your completed workouts will stay in History.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(splitsProvider.notifier).deleteCustomSplit(split.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete the routine. Try again.'),
          ),
        );
      }
    }
  }
}
