import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../dashboard/widgets/daily_workout_bento_card.dart';
import '../../dashboard/widgets/workout_detail_sheet.dart';
import '../providers/splits_provider.dart';
import '../widgets/active_split_detail_sheet.dart';
import '../widgets/create_routine_sheet.dart';
import '../widgets/switch_split_bottom_sheet.dart';

class WorkoutBuilderScreen extends ConsumerWidget {
  const WorkoutBuilderScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(splitsProvider);
    final split = state.activeSplit;
    final notifier = ref.read(splitsProvider.notifier);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('WORKOUTS', style: AppTypography.headlineMedium),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          AppShell.bottomPadding(context),
        ),
        children: [
          const DailyWorkoutBentoCard(useCalendarDate: false),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'YOUR PLAN',
                  style: AppTypography.monoSmall.copyWith(letterSpacing: 1.5),
                ),
              ),
              TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => SwitchSplitBottomSheet(
                    splits: state.splits,
                    activeSplitId: state.activeSplitId,
                    onSplitSelected: notifier.switchActiveSplit,
                  ),
                ),
                child: const Text('Switch'),
              ),
            ],
          ),
          GlassCard(
            border: false,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(split.name, style: AppTypography.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  '${split.daysPerWeek} days per week · ${split.totalWeeklySets} sets per rotation',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 12),
                for (final day in split.workouts)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      day.name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.pureWhite,
                      ),
                    ),
                    subtitle: Text(
                      day.isRestDay
                          ? 'Recovery day'
                          : '${day.exercises.length} exercises · ${day.totalSets} sets',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () =>
                        showWorkoutDetailSheet(context, initialDay: day),
                  ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => showCreateRoutineSheet(
                          context,
                          initialSplit: split,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit plan'),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => showActiveSplitDetailSheet(context),
                        icon: const Icon(Icons.bar_chart_rounded, size: 18),
                        label: const Text('Muscle balance'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            border: false,
            padding: const EdgeInsets.all(4),
            child: ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Routine library'),
              subtitle: const Text('Browse templates and your saved routines'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppConstants.routeRoutineLibrary),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => notifier.startEmptyWorkout(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('START FREESTYLE WORKOUT'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}
