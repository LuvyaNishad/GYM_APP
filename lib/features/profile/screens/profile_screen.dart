import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/local_date_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/persistence_feedback.dart';
import '../../dashboard/providers/workout_rotation_provider.dart';
import '../../dashboard/widgets/gym_contribution_chart.dart';
import '../../dashboard/widgets/training_pause_sheet.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../onboarding/widgets/goal_selector_sheet.dart';
import '../../workout_builder/providers/splits_provider.dart';
import '../../workout_session/services/native_rest_service.dart';
import '../../workout_session/services/notification_service.dart';
import '../../workout_session/services/workout_cue_service.dart';
import '../models/account_profile_model.dart';
import '../providers/profile_provider.dart';
import '../widgets/account_section.dart';
import '../widgets/edit_biometrics_dialog.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/avatar_editor_sheet.dart';
import '../widgets/export_data_dialog.dart';
import '../widgets/report_preview_dialog.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../../services/sync_service.dart';
import '../../../shared/widgets/sync_status_indicator.dart';
import '../../authentication/screens/sync_conflicts_screen.dart';
import '../../history/providers/history_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(accountProfileProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final inset = constraints.maxWidth > 672
                ? (constraints.maxWidth - 640) / 2
                : 16.0;
            return BackdropGroup(
              child: CustomScrollView(
                key: const PageStorageKey('account-scroll'),
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      inset,
                      20,
                      inset,
                      AppShell.bottomPadding(context, extra: 24),
                    ),
                    sliver: SliverList.list(
                      children: [
                        Semantics(
                          header: true,
                          child: const Text(
                            'ACCOUNT',
                            style: AppTypography.screenTitle,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Personal profile & settings',
                          style: AccountType.detail,
                        ),
                        const SizedBox(height: 24),
                        _IdentityCard(profile: profile),
                        const SizedBox(height: 12),
                        const _GymAttendanceCard(),
                        const SizedBox(height: 24),
                        _BiometricsCard(profile: profile),
                        const SizedBox(height: 12),
                        const _HealthCard(),
                        const SizedBox(height: 12),
                        _TrainingPreferencesCard(profile: profile),
                        const SizedBox(height: 12),
                        _AppSettingsCard(profile: profile),
                        const SizedBox(height: 12),
                        AccountSection(
                          title: 'DATA & REPORTS',
                          children: [
                            AccountRow(
                              icon: Icons.save_alt_rounded,
                              title: 'Backup & export',
                              subtitle: 'Save, share or restore your data',
                              onTap: () => showExportDataSheet(context),
                            ),
                            AccountRow(
                              icon: Icons.picture_as_pdf_outlined,
                              title: 'Monthly training report',
                              subtitle:
                                  'Workouts, progress and personal records',
                              onTap: () => showReportPreviewSheet(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const _CloudAccountCard(),
                        const SizedBox(height: 12),
                        const _AccountActionsCard(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GymAttendanceCard extends ConsumerWidget {
  const _GymAttendanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) => AccountSurface(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: GymContributionChart(
        today: ref.watch(localDateProvider),
        loggedWorkoutDates: ref
            .watch(historyWorkoutsProvider)
            .map((workout) => workout.date)
            .toSet(),
      ),
    ),
  );
}

class _IdentityCard extends ConsumerWidget {
  const _IdentityCard({required this.profile});
  final AccountProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final accountLabel = switch (auth.status) {
      AuthStatus.unknown => 'Checking account…',
      AuthStatus.unauthenticated => 'Local profile',
      AuthStatus.authenticated when auth.isAnonymous => 'Guest profile',
      AuthStatus.authenticated =>
        auth.email?.trim().isNotEmpty == true
            ? auth.email!.trim()
            : 'Cloud account',
    };
    final name = profile.displayName.isEmpty ? 'Guest' : profile.displayName;
    final joined = MaterialLocalizations.of(
      context,
    ).formatMonthYear(profile.memberSince);
    final avatar = Semantics(
      button: true,
      label: 'Change profile picture',
      child: Tooltip(
        message: 'Change profile picture',
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => showAvatarEditor(context),
            child: SizedBox.square(
              dimension: 64,
              child: Stack(
                children: [
                  ProfileAvatar(
                    reference: profile.avatarUrl,
                    name: name,
                    size: 60,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.cardBackground,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 12,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final edit = IconButton(
      tooltip: 'Edit profile',
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      onPressed: () => showEditProfileSheet(context, profile),
      icon: Icon(
        Icons.edit_outlined,
        size: 20,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: AppTypography.headlineLarge),
        const SizedBox(height: 4),
        Text(accountLabel, style: AccountType.detail),
        const SizedBox(height: 4),
        Text('Profile since $joined', style: AccountType.detail),
      ],
    );
    return AccountSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: MediaQuery.textScalerOf(context).scale(20) > 28
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [avatar, const Spacer(), edit]),
                      const SizedBox(height: 12),
                      details,
                    ],
                  )
                : Row(
                    children: [
                      avatar,
                      const SizedBox(width: 12),
                      Expanded(child: details),
                      edit,
                    ],
                  ),
          ),
          const AccountDivider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _MetricGrid(
              minimumWidth: 140,
              metrics: [
                ('WORKOUTS', '${profile.totalWorkouts}'),
                ('TOTAL VOLUME', profile.formatWeight(profile.totalVolumeKg)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BiometricsCard extends StatelessWidget {
  const _BiometricsCard({required this.profile});
  final AccountProfile profile;

  @override
  Widget build(BuildContext context) => AccountSection(
    title: 'BIOMETRICS & GOALS',
    action: TextButton(
      style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
      onPressed: () => showEditBiometricsSheet(context, profile),
      child: const Text('Update'),
    ),
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: _MetricGrid(
          minimumWidth: 98,
          metrics: [
            ('HEIGHT', profile.formattedHeight),
            ('CURRENT', profile.formatWeight(profile.currentWeightKg)),
            ('GOAL', profile.formatWeight(profile.targetWeightKg)),
          ],
        ),
      ),
      AccountRow(
        title: 'BMI',
        subtitle: profile.bmiCategory,
        value: profile.formattedBmi,
        numeric: profile.bmi != null,
      ),
      AccountRow(
        title: 'Estimated maintenance',
        value: profile.maintenanceCaloriesEstimate == null
            ? 'Not enough input'
            : '${profile.maintenanceCaloriesEstimate} kcal/day',
        numeric: profile.maintenanceCaloriesEstimate != null,
        subtitle: profile.calorieAssumptions,
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Weight goal', style: AccountType.row),
            const SizedBox(height: 4),
            Text(
              profile.weightDeltaKg == null
                  ? 'Set a current and goal weight to track progress.'
                  : profile.weightDeltaKg == 0
                  ? 'At your goal weight'
                  : '${profile.isCutting ? 'Lose' : 'Gain'} ${profile.formatWeight(profile.weightDeltaKg)} to reach your goal',
              style: AccountType.detail,
            ),
            if (profile.goalProgress != null) ...[
              const SizedBox(height: 12),
              Text(
                '${(profile.goalProgress! * 100).toInt()}% of goal',
                style: AccountType.value,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: profile.goalProgress!.clamp(0.0, 1.0),
                  minHeight: 4,
                  color: AppColors.platinum,
                  backgroundColor: AppColors.steel,
                  semanticsLabel: 'Weight goal progress',
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics, required this.minimumWidth});
  final List<(String, String)> metrics;
  final double minimumWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(18) / 18;
      final columns =
          ((constraints.maxWidth + 16) / (minimumWidth * scale + 16))
              .floor()
              .clamp(1, metrics.length);
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final metric in metrics)
            SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.$1,
                    style: AccountType.detail.copyWith(
                      fontSize: 12,
                      letterSpacing: .5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    metric.$2,
                    style: AppTypography.monoMedium.copyWith(fontSize: 18),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );
}

class _HealthCard extends ConsumerWidget {
  const _HealthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paused = ref.watch(
      workoutRotationProvider.select((state) => state.isTrainingPaused),
    );
    return AccountSection(
      title: 'HEALTH & RECOVERY',
      children: [
        AccountRow(
          icon: Icons.monitor_heart_outlined,
          title: 'Health & measurements',
          onTap: () => context.push(AppConstants.routeHealthTracking),
        ),
        AccountRow(
          icon: Icons.bedtime_outlined,
          title: 'Recovery check-in',
          onTap: () => context.push(AppConstants.routeRecovery),
        ),
        AccountRow(
          icon: Icons.pause_circle_outline_rounded,
          title: paused ? 'Manage training pause' : 'Pause training',
          subtitle: paused ? 'Your training plan is paused' : null,
          onTap: () => showTrainingPauseSheet(context),
        ),
      ],
    );
  }
}

class _TrainingPreferencesCard extends ConsumerWidget {
  const _TrainingPreferencesCard({required this.profile});
  final AccountProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(trainingGoalConfigProvider);
    final notifier = ref.read(accountProfileProvider.notifier);
    final split =
        ref
            .watch(splitsProvider)
            .splits
            .where((s) => s.id == profile.preferredSplit)
            .firstOrNull
            ?.name ??
        'Choose a split';
    return AccountSection(
      title: 'TRAINING PREFERENCES',
      children: [
        AccountRow(
          icon: Icons.flag_outlined,
          title: 'Primary goal',
          subtitle: '${goal.displayName} · ${goal.subtitle}',
          onTap: () => showGoalSelectorSheet(context, ref),
        ),
        AccountRow(
          icon: Icons.calendar_view_week_outlined,
          title: 'Training split',
          subtitle: split,
          onTap: () => showEditProfileSheet(context, profile),
        ),
        AccountChoiceRow<int>(
          icon: Icons.timer_outlined,
          title: 'Default rest timer',
          subtitle: 'Used when an exercise has no custom rest time',
          value: profile.defaultRestSeconds,
          label: '${profile.defaultRestSeconds} s',
          numeric: true,
          choices: const {
            60: '60 seconds',
            90: '90 seconds',
            120: '120 seconds',
            180: '180 seconds',
          },
          onSelected: (seconds) async {
            final success = await persistWithFeedback(
              context,
              () => notifier.updatePreferences(defaultRestSeconds: seconds),
            );
            if (success) HapticFeedback.lightImpact();
          },
        ),
        AccountChoiceRow<double>(
          icon: Icons.fitness_center_rounded,
          title: 'Barbell weight',
          subtitle: 'Base weight for plate calculations',
          value: profile.barbellTareKg,
          label: profile.formatWeight(profile.barbellTareKg),
          numeric: true,
          choices: {20: profile.formatWeight(20), 15: profile.formatWeight(15)},
          onSelected: (kg) async {
            final success = await persistWithFeedback(
              context,
              () => notifier.updatePreferences(barbellTareKg: kg),
            );
            if (success) HapticFeedback.lightImpact();
          },
        ),
        Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            listTileTheme: Theme.of(context).listTileTheme.copyWith(
              minLeadingWidth: 20,
              horizontalTitleGap: 12,
            ),
          ),
          child: ExpansionTile(
            key: const PageStorageKey('account-training-details'),
            expansionAnimationStyle: MediaQuery.disableAnimationsOf(context)
                ? AnimationStyle.noAnimation
                : null,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(48, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            leading: const Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
            minTileHeight: 56,
            iconColor: AppColors.textMuted,
            collapsedIconColor: AppColors.textMuted,
            title: Text('Training details', style: AccountType.row),
            subtitle: Text(
              'Experience, frequency, equipment & injury notes',
              style: AccountType.detail,
            ),
            children: [
              _TrainingDetail(
                label: 'Experience',
                value: profile.experienceLevel,
              ),
              const SizedBox(height: 12),
              _TrainingDetail(
                label: 'Weekly frequency',
                value: profile.trainingDaysPerWeek == null
                    ? 'Not set'
                    : '${profile.trainingDaysPerWeek} days',
              ),
              const SizedBox(height: 12),
              _TrainingDetail(
                label: 'Equipment',
                value: profile.trainingDaysPerWeek == null
                    ? 'Not configured'
                    : profile.equipment.isEmpty
                    ? 'Bodyweight'
                    : profile.equipment.join(', '),
              ),
              const SizedBox(height: 12),
              _TrainingDetail(
                label: 'Injury notes',
                value: profile.injuries.isEmpty
                    ? 'None entered'
                    : profile.injuries.join(', '),
              ),
              const SizedBox(height: 4),
              Text(
                'Review your routine; these notes do not screen exercises.',
                style: AccountType.detail,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrainingDetail extends StatelessWidget {
  const _TrainingDetail({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AccountType.detail),
      const SizedBox(height: 4),
      Text(value, style: AccountType.row),
    ],
  );
}

class _AppSettingsCard extends ConsumerWidget {
  const _AppSettingsCard({required this.profile});
  final AccountProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(accountProfileProvider.notifier);
    const modes = {
      WorkoutAlertMode.soundAndVibrate: 'Sound + vibrate',
      WorkoutAlertMode.vibrateOnly: 'Vibrate only',
      WorkoutAlertMode.silent: 'Silent',
    };
    final mode = ref.watch(workoutAlertModeProvider);
    return AccountSection(
      title: 'APP SETTINGS',
      children: [
        AccountChoiceRow<String>(
          icon: Icons.scale_outlined,
          title: 'Weight unit',
          value: profile.weightUnit,
          label: profile.weightUnit,
          choices: const {'kg': 'Kilograms (kg)', 'lbs': 'Pounds (lbs)'},
          onSelected: (unit) => persistWithFeedback(
            context,
            () => notifier.updateUnits(weightUnit: unit),
          ),
        ),
        AccountChoiceRow<String>(
          icon: Icons.straighten_rounded,
          title: 'Height unit',
          value: profile.heightUnit,
          label: profile.heightUnit == 'cm' ? 'cm' : 'ft / in',
          choices: const {
            'cm': 'Centimeters (cm)',
            'ft': 'Feet & inches (ft / in)',
          },
          onSelected: (unit) => persistWithFeedback(
            context,
            () => notifier.updateUnits(heightUnit: unit),
          ),
        ),
        AccountChoiceRow<WorkoutAlertMode>(
          icon: Icons.volume_up_outlined,
          title: 'Workout alerts',
          subtitle:
              'Sets, countdowns, tempo and rest. System volume and Do Not Disturb apply.',
          value: mode,
          label: modes[mode]!,
          choices: modes,
          onSelected: (next) => persistWithFeedback(
            context,
            () => notifier.setAlertMode(
              next == WorkoutAlertMode.soundAndVibrate,
              next != WorkoutAlertMode.silent,
            ),
          ),
        ),
        const _AlertPermissions(),
      ],
    );
  }
}

class _AlertPermissions extends ConsumerStatefulWidget {
  const _AlertPermissions();

  @override
  ConsumerState<_AlertPermissions> createState() => _AlertPermissionsState();
}

class _AlertPermissionsState extends ConsumerState<_AlertPermissions> {
  String? message;
  bool _pending = false;

  Future<void> request(bool exact) async {
    if (_pending) return;
    setState(() => _pending = true);
    var unavailable = false;
    try {
      if (exact) {
        await ref.read(nativeRestServiceProvider).requestExactAlarms();
        if (mounted) {
          setState(
            () => message =
                'Precise alarms use your system permission. Without it Android may delay rest alerts.',
          );
        }
      } else {
        final allowed = await ref
            .read(workoutNotificationServiceProvider)
            .requestPermissions();
        unavailable = !allowed;
        if (mounted) {
          setState(
            () => message = allowed
                ? 'Workout notifications allowed.'
                : 'Notifications are unavailable or denied. Foreground cues still follow your preferences.',
          );
        }
      }
      if (mounted && message != null) {
        showAppFeedback(context, message!, isError: unavailable);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Could not open permission settings. Try again.',
        );
        showAppFeedback(context, message!);
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AccountRow(
        icon: Icons.notifications_outlined,
        title: 'Workout notifications',
        subtitle: 'Allow rest alerts outside the app',
        onTap: _pending ? null : () => request(false),
      ),
      if (Theme.of(context).platform == TargetPlatform.android) ...[
        const AccountDivider(),
        AccountRow(
          icon: Icons.alarm_on_outlined,
          title: 'Precise rest alarms',
          subtitle: 'Manage Android permission for timely alerts',
          onTap: _pending ? null : () => request(true),
        ),
      ],
      if (message != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Semantics(
            liveRegion: true,
            child: Text(message!, style: AccountType.detail),
          ),
        ),
    ],
  );
}

class _CloudAccountCard extends ConsumerWidget {
  const _CloudAccountCard();

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    await ref.read(syncServiceProvider.notifier).syncAll();
    if (!context.mounted) return;
    final sync = ref.read(syncServiceProvider);
    final message = switch (sync.status) {
      SyncStatus.synced => 'Cloud sync is up to date.',
      SyncStatus.local => 'Sign in to sync. Your data is saved on this device.',
      SyncStatus.offline =>
        'You’re offline. Saved changes will sync when connected.',
      SyncStatus.conflict => 'Review the sync conflicts to finish syncing.',
      SyncStatus.error =>
        sync.errorMessage ?? 'Cloud sync could not finish. Try again.',
      _ => '${sync.pendingCount} changes are waiting to sync.',
    };
    showAppFeedback(
      context,
      message,
      isError: sync.status != SyncStatus.synced,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isAuthenticated =
        authState.status == AuthStatus.authenticated && !authState.isAnonymous;
    final sync = ref.watch(syncServiceProvider);

    return AccountSection(
      title: 'CLOUD & SYNC',
      action: const SyncStatusIndicator(showLabel: true),
      children: [
        if (isAuthenticated) ...[
          AccountRow(
            icon: Icons.cloud_done_outlined,
            title: 'Account',
            subtitle: authState.email,
            accessory: TextButton(
              onPressed: authState.isLoading
                  ? null
                  : () async {
                      final confirmed = await const _AccountActionsCard()._confirm(
                        context,
                        title: 'Sign out?',
                        content:
                            '${sync.pendingCount} changes are waiting for cloud sync. Your account data and unsynced changes stay in this account’s local workspace. Sign in again to access them.',
                        action: 'Sign out',
                      );
                      if (!confirmed || !context.mounted) return;
                      await persistWithFeedback(
                        context,
                        () => ref.read(authProvider.notifier).signOut(),
                      );
                    },
              child: const Text('Sign out'),
            ),
          ),
          AccountRow(
            icon: Icons.sync_rounded,
            title: 'Sync now',
            subtitle:
                sync.errorMessage ??
                '${sync.pendingCount} pending changes · uploads and downloads',
            onTap: sync.status == SyncStatus.syncing
                ? null
                : () => _sync(context, ref),
          ),
        ] else ...[
          AccountRow(
            icon: Icons.cloud_upload_outlined,
            title: authState.isAnonymous
                ? 'Link an account'
                : 'Sign in to Cloud',
            subtitle: 'Back up workouts and sync across devices',
            onTap: () => context.push(AppConstants.routeLogin),
          ),
          AccountRow(
            icon: Icons.sync_rounded,
            title: 'Sync now',
            subtitle: authState.isAnonymous
                ? 'Guest cloud saves need a linked account for recovery after reinstall'
                : 'Guest data is saved on this device until connected',
            onTap: sync.status == SyncStatus.syncing
                ? null
                : () => _sync(context, ref),
          ),
        ],
        if (sync.conflicts.isNotEmpty)
          AccountRow(
            icon: Icons.compare_arrows_rounded,
            title: 'Review ${sync.conflicts.length} sync conflicts',
            subtitle: 'Both versions are retained until you choose',
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(
                builder: (_) => const SyncConflictsScreen(),
              ),
            ),
          ),
      ],
    );
  }
}

class _AccountActionsCard extends ConsumerWidget {
  const _AccountActionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) => AccountSection(
    title: 'SETUP & PREFERENCES',
    children: [
      AccountRow(
        icon: Icons.school_outlined,
        title: 'Redo setup',
        subtitle: 'Retake the training setup questions',
        onTap: () async {
          final confirmed = await _confirm(
            context,
            title: 'Redo setup?',
            content:
                'Retake the setup questions from the beginning. Your profile and saved workouts remain available.',
            action: 'Redo setup',
          );
          if (!confirmed || !context.mounted) return;
          final saved = await persistWithFeedback(
            context,
            () => ref.read(onboardingProvider.notifier).reset(),
          );
          if (saved && context.mounted) {
            context.go(AppConstants.routeOnboarding);
          }
        },
      ),
      AccountRow(
        icon: Icons.restart_alt_rounded,
        title: 'Reset preferences',
        subtitle: 'Restore units, timers and alert defaults',
        onTap: () async {
          final confirmed = await _confirm(
            context,
            title: 'Reset preferences?',
            content:
                'Reset units, rest time, barbell weight, sound and haptics to their defaults. Your profile and workout data stay saved.',
            action: 'Reset preferences',
          );
          if (!confirmed || !context.mounted) return;
          final success = await persistWithFeedback(
            context,
            () => ref.read(accountProfileProvider.notifier).resetToDefaults(),
          );
          if (success && context.mounted) {
            showAppFeedback(
              context,
              'Preferences restored to defaults.',
              isError: false,
            );
          }
        },
      ),
    ],
  );

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String content,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(title, style: AppTypography.headlineLarge),
          content: Text(content, style: AppTypography.bodyMedium),
          actions: [
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(44, 44)),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
}
