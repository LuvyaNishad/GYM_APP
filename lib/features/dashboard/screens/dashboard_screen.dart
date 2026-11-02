import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../state/app_providers.dart';
import '../../../services/pedometer_service.dart';
import '../../history/providers/history_provider.dart';
import '../../recovery/providers/recovery_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/home_workout_view_provider.dart';
import '../widgets/calories_bento_card.dart';
import '../widgets/daily_workout_bento_card.dart';
import '../widgets/recovery_status_widget.dart';
import '../widgets/retractable_calendar_header.dart';
import '../widgets/sleep_bento_card.dart';
import '../widgets/steps_bento_card.dart';
import '../widgets/training_recommendation_card.dart';
import '../widgets/water_bento_card.dart';

/// A compact daily overview with space for context-specific workout guidance.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(pedometerServiceProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final loggedWorkoutDates = ref.watch(loggedWorkoutDatesProvider);
    final scheduledWorkoutDates = ref.watch(scheduledWorkoutDatesProvider);
    final pausedWorkoutDates = ref.watch(pausedWorkoutDatesProvider);
    final selectedCalendarDate = ref.watch(selectedCalendarDateProvider);
    final userName = (userProfile?.displayName.isNotEmpty ?? false)
        ? userProfile!.displayName
        : 'Leon';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          // Normal phone layouts fit the viewport. Larger accessibility text
          // can scroll without shrinking text or obscuring the navigation.
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RetractableCalendarHeader(
                  userName: userName,
                  avatarUrl: userProfile?.avatarUrl,
                  selectedDate: selectedCalendarDate,
                  onDateSelected: (date) {
                    ref
                        .read(selectedCalendarDateProvider.notifier)
                        .select(date);
                  },
                  loggedWorkoutDates: loggedWorkoutDates,
                  scheduledWorkoutDates: scheduledWorkoutDates,
                  pausedWorkoutDates: pausedWorkoutDates,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    AppShell.bottomPadding(context, extra: 0),
                  ),
                  child: BackdropGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const DailyWorkoutBentoCard(compact: true),
                        const SizedBox(height: 8),
                        Text(
                          "TODAY'S ACTIVITY",
                          style: AppTypography.monoSmall.copyWith(
                            color: AppColors.platinum,
                            letterSpacing: 1.5,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        IntrinsicHeight(
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: StepsBentoCard()),
                              SizedBox(width: 10),
                              Expanded(child: CaloriesBentoCard()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        IntrinsicHeight(
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: WaterBentoCard()),
                              SizedBox(width: 10),
                              Expanded(child: SleepBentoCard()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const _DailyGuidance(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyGuidance extends ConsumerWidget {
  const _DailyGuidance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(homeWorkoutViewProvider);
    // Check-ins describe today. Inspecting another calendar date should not
    // attach today's recovery score or workout guidance to that date.
    if (!view.isToday) return const SizedBox.shrink();
    if (view.isPaused || view.day?.isRestDay == true) {
      return RecoveryStatusWidget(
        readinessScore: ref.watch(recoveryScoreProvider),
      );
    }
    return const TrainingRecommendationCard();
  }
}
