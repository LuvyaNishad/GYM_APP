import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../dashboard/widgets/daily_workout_bento_card.dart';
import '../../dashboard/providers/workout_rotation_provider.dart';
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
    final nextDay = ref.watch(
      workoutRotationProvider.select((s) => s.selectedDay),
    );
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
                  'ACTIVE PLAN',
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
            blur: true,
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              key: PageStorageKey('active_plan_${split.id}'),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              shape: const Border(),
              collapsedShape: const Border(),
              iconColor: AppColors.primary,
              collapsedIconColor: AppColors.textSecondary,
              title: Text(split.name, style: AppTypography.headlineSmall),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${split.daysPerWeek} days per week · ${split.totalWeeklySets} sets per rotation',
                  style: AppTypography.bodySmall,
                ),
              ),
              children: [
                for (final day in split.workouts)
                  ListTile(
                    key: ValueKey(day.id),
                    contentPadding: EdgeInsets.zero,
                    selected: day.id == nextDay.id,
                    title: Text(
                      day.name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: day.id == nextDay.id
                            ? AppColors.primary
                            : AppColors.pureWhite,
                      ),
                    ),
                    subtitle: Text(
                      '${day.id == nextDay.id ? 'Next · ' : ''}${day.isRestDay ? 'Recovery day' : '${day.exercises.length} exercises · ${day.totalSets} sets'}',
                      style: AppTypography.bodySmall,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () =>
                        showWorkoutDetailSheet(context, initialDay: day),
                  ),
                const Divider(),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          showCreateRoutineSheet(context, initialSplit: split),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit plan'),
                    ),
                    TextButton.icon(
                      onPressed: () => showActiveSplitDetailSheet(context),
                      icon: const Icon(Icons.bar_chart_rounded, size: 18),
                      label: const Text('Muscle balance'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            border: false,
            blur: true,
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
          TextButton.icon(
            onPressed: () => notifier.startEmptyWorkout(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Start freestyle workout'),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
