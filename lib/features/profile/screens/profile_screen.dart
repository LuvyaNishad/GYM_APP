import '../../workout_session/services/workout_cue_service.dart';
import '../../workout_session/services/native_rest_service.dart';
import '../../workout_session/services/notification_service.dart';
import '../../workout_builder/providers/splits_provider.dart';
import '../../dashboard/widgets/training_pause_sheet.dart';
import '../../dashboard/providers/workout_rotation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/persistence_feedback.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../onboarding/widgets/goal_selector_sheet.dart';
import '../models/account_profile_model.dart';
import '../providers/profile_provider.dart';
import '../widgets/edit_biometrics_dialog.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/export_data_dialog.dart';
import '../widgets/report_preview_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(accountProfileProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: BackdropGroup(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ACCOUNT', style: AppTypography.screenTitle),
                      SizedBox(height: 4),
                      Text(
                        'Personal Profile & Settings',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  AppShell.bottomPadding(context, extra: 32),
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _IdentityCard(profile: profile),
                    const SizedBox(height: 16),
                    _BiometricsCard(profile: profile),
                    const SizedBox(height: 16),
                    _GlassSectionContainer(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.monitor_heart_outlined),
                            title: const Text('Health & Measurements'),
                            onTap: () =>
                                context.push(AppConstants.routeHealthTracking),
                          ),
                          ListTile(
                            leading: const Icon(Icons.bedtime_outlined),
                            title: const Text('Recovery check-in'),
                            onTap: () =>
                                context.push(AppConstants.routeRecovery),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.pause_circle_outline_rounded,
                            ),
                            title: Text(
                              ref.watch(
                                    workoutRotationProvider.select(
                                      (state) => state.isTrainingPaused,
                                    ),
                                  )
                                  ? 'Manage training pause'
                                  : 'Pause training',
                            ),
                            onTap: () => showTrainingPauseSheet(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _TrainingPreferencesCard(profile: profile),
                    const SizedBox(height: 16),
                    _AppSettingsCard(profile: profile),
                    const SizedBox(height: 16),
                    _GlassSectionContainer(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.save_alt),
                            title: const Text('Backup & export'),
                            onTap: () => showExportDataSheet(context),
                          ),
                          ListTile(
                            leading: const Icon(Icons.picture_as_pdf_outlined),
                            title: const Text('Monthly training report'),
                            onTap: () => showReportPreviewSheet(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AccountActionsCard(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});
  final AccountProfile profile;

  @override
  Widget build(BuildContext context) {
    final initials = profile.displayName.isNotEmpty
        ? profile.displayName.characters.first.toUpperCase()
        : 'L';
    final joined = MaterialLocalizations.of(
      context,
    ).formatMonthYear(profile.memberSince);
    return _GlassSectionContainer(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surfaceSecondary,
            child: Text(initials, style: AppTypography.headlineMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName.isEmpty ? 'Guest' : profile.displayName,
                  style: AppTypography.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email.isEmpty ? 'Local profile' : profile.email,
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 4),
                Text('Profile since $joined', style: AppTypography.bodySmall),
                Text(
                  '${profile.totalWorkouts} workouts ? ${profile.formatWeight(profile.totalVolumeKg)} volume',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit profile',
            onPressed: () => showEditProfileSheet(context, profile),
            icon: const Icon(Icons.edit_outlined, size: 20),
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
  Widget build(BuildContext context) {
    return _GlassSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionHeader(
                  title: 'BIOMETRICS & GOALS',
                  icon: Icons.monitor_weight_outlined,
                ),
              ),
              TextButton(
                onPressed: () => showEditBiometricsSheet(context, profile),
                child: const Text('Update'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  constraints.maxWidth /
                          MediaQuery.textScalerOf(context).scale(1) <
                      300
                  ? 2
                  : 3;
              final width =
                  (constraints.maxWidth - (columns - 1) * 16) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final metric in [
                    ('HEIGHT', profile.formattedHeight),
                    ('CURRENT', profile.formatWeight(profile.currentWeightKg)),
                    ('GOAL', profile.formatWeight(profile.targetWeightKg)),
                  ])
                    SizedBox(
                      width: width,
                      child: _MetricBlock(label: metric.$1, value: metric.$2),
                    ),
                ],
              );
            },
          ),
          const Divider(height: 28),
          _ValueRow(
            label: 'BMI · ${profile.bmiCategory}',
            value: profile.formattedBmi,
          ),
          const SizedBox(height: 12),
          _ValueRow(
            label: 'Est. maintenance',
            value: profile.maintenanceCaloriesEstimate == null
                ? 'Not enough input'
                : '${profile.maintenanceCaloriesEstimate} kcal/day',
          ),
          Text(profile.calorieAssumptions, style: AppTypography.bodySmall),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  profile.weightDeltaKg == null
                      ? 'Set a current and goal weight'
                      : profile.weightDeltaKg == 0
                      ? 'At your goal weight'
                      : '${profile.isCutting ? 'Lose' : 'Gain'} ${profile.formatWeight(profile.weightDeltaKg)} to reach your goal',
                  style: AppTypography.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                profile.goalProgress == null
                    ? 'Not set'
                    : '${(profile.goalProgress! * 100).toInt()}%',
                style: AppTypography.dataLabel,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (profile.goalProgress != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (profile.goalProgress ?? 0).clamp(0.0, 1.0),
                minHeight: 4,
                color: AppColors.platinum,
                backgroundColor: AppColors.steel,
                semanticsLabel: 'Weight goal progress',
              ),
            ),
        ],
      ),
    );
  }
}

class _TrainingPreferencesCard extends ConsumerWidget {
  const _TrainingPreferencesCard({required this.profile});
  final AccountProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalConfig = ref.watch(trainingGoalConfigProvider);
    final notifier = ref.read(accountProfileProvider.notifier);
    return _GlassSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'TRAINING PREFERENCES',
            icon: Icons.fitness_center_rounded,
          ),
          const SizedBox(height: 16),
          _PreferenceTile(
            title: 'Primary Goal',
            subtitle: '${goalConfig.displayName} · ${goalConfig.subtitle}',
            trailing: TextButton(
              onPressed: () => showGoalSelectorSheet(context, ref),
              child: const Text('Change'),
            ),
          ),
          const Divider(height: 24),
          _PreferenceTile(
            title: 'Training Split',
            subtitle:
                ref
                    .watch(splitsProvider)
                    .splits
                    .where((s) => s.id == profile.preferredSplit)
                    .firstOrNull
                    ?.name ??
                'Choose a split',
            trailing: TextButton(
              onPressed: () => showEditProfileSheet(context, profile),
              child: const Text('Change'),
            ),
          ),
          const Divider(height: 24),
          _ValueRow(
            label: 'Experience',
            value: profile.experienceLevel,
            numeric: false,
          ),
          const Divider(height: 24),
          Text(
            'Weekly frequency: ${profile.trainingDaysPerWeek ?? 'Not set'}',
            style: AppTypography.bodyMedium,
          ),
          Text(
            'Equipment: ${profile.trainingDaysPerWeek == null
                ? 'Not configured'
                : profile.equipment.isEmpty
                ? 'Bodyweight'
                : profile.equipment.join(', ')}',
            style: AppTypography.bodySmall,
          ),
          Text(
            'Injury notes: ${profile.injuries.isEmpty ? 'None entered' : profile.injuries.join(', ')}. Review your routine; these notes do not screen exercises.',
            style: AppTypography.bodySmall,
          ),
          const Divider(height: 24),
          const Text('Default Rest Timer', style: AppTypography.bodyLarge),
          const SizedBox(height: 4),
          const Text(
            'Used when an exercise has no custom rest time',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final seconds in [60, 90, 120, 180])
                ChoiceChip(
                  label: Text('${seconds}s'),
                  selected: profile.defaultRestSeconds == seconds,
                  onSelected: (_) async {
                    final success = await persistWithFeedback(
                      context,
                      () => notifier.updatePreferences(
                        defaultRestSeconds: seconds,
                      ),
                    );
                    if (success) HapticFeedback.lightImpact();
                  },
                  side: BorderSide.none,
                  selectedColor: AppColors.primary.withValues(alpha: 0.16),
                  checkmarkColor: AppColors.primary,
                  labelStyle: AppTypography.dataLabel.copyWith(
                    color: profile.defaultRestSeconds == seconds
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                ),
            ],
          ),
          const Divider(height: 24),
          _PreferenceTile(
            title: 'Barbell weight',
            subtitle: 'Base weight for plate calculations',
            trailing: TextButton(
              onPressed: () async {
                final success = await persistWithFeedback(
                  context,
                  () => notifier.updatePreferences(
                    barbellTareKg: profile.barbellTareKg == 20.0 ? 15.0 : 20.0,
                  ),
                );
                if (success) HapticFeedback.lightImpact();
              },
              child: Text(
                profile.formatWeight(profile.barbellTareKg),
                style: AppTypography.dataLabel.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppSettingsCard extends ConsumerWidget {
  const _AppSettingsCard({required this.profile});
  final AccountProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(accountProfileProvider.notifier);
    return _GlassSectionContainer(
      child: Column(
        children: [
          const _SectionHeader(title: 'APP SETTINGS', icon: Icons.tune_rounded),
          const SizedBox(height: 16),
          _PreferenceTile(
            title: 'Units of Measurement',
            subtitle: profile.weightUnit == 'kg'
                ? 'Weight: kg · Height: ${profile.heightUnit == 'cm' ? 'cm' : 'ft/in'}'
                : 'Weight: lbs · Height: ${profile.heightUnit == 'cm' ? 'cm' : 'ft/in'}',
            trailing: TextButton(
              onPressed: () async {
                final success = await persistWithFeedback(
                  context,
                  () => notifier.updateBiometrics(
                    weightUnit: profile.weightUnit == 'kg' ? 'lbs' : 'kg',
                  ),
                );
                if (success) HapticFeedback.lightImpact();
              },
              child: Text(profile.weightUnit.toUpperCase()),
            ),
          ),
          const Divider(height: 24),
          const Text('Workout alerts', style: TextStyle(fontSize: 14)),
          DropdownButton<WorkoutAlertMode>(
            isExpanded: true,
            value: ref.watch(workoutAlertModeProvider),
            items: const [
              DropdownMenuItem(
                value: WorkoutAlertMode.soundAndVibrate,
                child: Text('Sound + Vibrate'),
              ),
              DropdownMenuItem(
                value: WorkoutAlertMode.vibrateOnly,
                child: Text('Vibrate Only'),
              ),
              DropdownMenuItem(
                value: WorkoutAlertMode.silent,
                child: Text('Silent'),
              ),
            ],
            onChanged: (mode) {
              if (mode == null) return;
              persistWithFeedback(
                context,
                () => notifier.setAlertMode(
                  mode == WorkoutAlertMode.soundAndVibrate,
                  mode != WorkoutAlertMode.silent,
                ),
              );
            },
          ),
          const Text(
            'Applies to sets, countdowns, tempo cues and rest alerts. System volume, notification permissions and Do Not Disturb still apply.',
          ),
          const _AlertPermissions(),
        ],
      ),
    );
  }
}

class _AccountActionsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GlassSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'ACCOUNT ACTIONS',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 12),

          // Replay Onboarding Survey
          InkWell(
            onTap: () {
              _showConfirmDialog(
                context,
                title: 'Replay Onboarding',
                content:
                    'This will restart the onboarding survey from the very beginning so you can retake the setup questions.',
                onConfirm: () async {
                  final saved = await persistWithFeedback(
                    context,
                    () => ref.read(onboardingProvider.notifier).reset(),
                  );
                  if (!saved) return;
                  if (context.mounted) {
                    context.go(AppConstants.routeOnboarding);
                  }
                },
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.school_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Replay Onboarding Survey',
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.steel, height: 16),

          // Reset Profile Defaults
          InkWell(
            onTap: () {
              _showConfirmDialog(
                context,
                title: 'Reset Profile Data',
                content:
                    'This resets units, rest, barbell, sound and haptic defaults. Your profile and workout data stay saved.',
                onConfirm: () async {
                  final success = await persistWithFeedback(
                    context,
                    () => ref
                        .read(accountProfileProvider.notifier)
                        .resetToDefaults(),
                  );
                  if (!success) return;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.charcoal,
                        content: Text(
                          'Profile restored to default settings.',
                          style: TextStyle(
                            fontFamily: AppTypography.fontBody,
                            fontSize: 13.0,
                            color: AppColors.pureWhite,
                          ),
                        ),
                      ),
                    );
                  }
                },
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.restart_alt_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Reset Profile Defaults',
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.steel, height: 16),
        ],
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: AppTypography.fontDisplay,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.pureWhite,
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 13.5,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _GlassSectionContainer extends StatelessWidget {
  const _GlassSectionContainer({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: true,
      sharedBackdrop: true,
      repaintBoundary: true,
      border: false,
      boxShadow: const [],
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTypography.headlineSmall.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTypography.monoSmall.copyWith(
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    this.numeric = true,
  });
  final String label;
  final String value;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: AppTypography.bodySmall)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style:
                (numeric ? AppTypography.dataLabel : AppTypography.bodyMedium)
                    .copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodyLarge),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTypography.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 12),
        trailing,
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
  Future<void> request(bool exact) async {
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
        if (mounted) {
          setState(
            () => message = allowed
                ? 'Workout notifications allowed.'
                : 'Notifications are unavailable or denied. Foreground cues still follow your preferences.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => message = 'Could not change alert permission: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextButton(
        onPressed: () => request(false),
        child: const Text('Enable workout notifications'),
      ),
      if (Theme.of(context).platform == TargetPlatform.android)
        TextButton(
          onPressed: () => request(true),
          child: const Text('Allow precise rest alarms'),
        ),
      if (message != null) Text(message!),
    ],
  );
}
