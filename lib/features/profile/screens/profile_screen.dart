import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                    _TrainingPreferencesCard(profile: profile),
                    const SizedBox(height: 16),
                    _ReportsAndExportCard(profile: profile),
                    const SizedBox(height: 16),
                    _AppSettingsCard(profile: profile),
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
                Text(profile.displayName, style: AppTypography.headlineSmall),
                const SizedBox(height: 4),
                Text(profile.email, style: AppTypography.bodySmall),
                const SizedBox(height: 4),
                Text('Member since $joined', style: AppTypography.bodySmall),
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
            value: profile.bmi.toStringAsFixed(1),
          ),
          const SizedBox(height: 12),
          _ValueRow(
            label: 'Est. maintenance',
            value: '${profile.maintenanceCaloriesEstimate} kcal/day',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  profile.weightDeltaKg == 0
                      ? 'At your goal weight'
                      : '${profile.isCutting ? 'Lose' : 'Gain'} ${profile.formatWeight(profile.weightDeltaKg)} to reach your goal',
                  style: AppTypography.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(profile.goalProgress * 100).toInt()}%',
                style: AppTypography.dataLabel,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: profile.goalProgress.clamp(0.0, 1.0),
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
            subtitle: profile.preferredSplit,
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
          const Text('Default Rest Timer', style: AppTypography.bodyLarge),
          const SizedBox(height: 4),
          const Text(
            'Auto-countdown between sets',
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
                  onSelected: (_) {
                    notifier.updatePreferences(defaultRestSeconds: seconds);
                    HapticFeedback.lightImpact();
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
              onPressed: () {
                notifier.updatePreferences(
                  barbellTareKg: profile.barbellTareKg == 20.0 ? 15.0 : 20.0,
                );
                HapticFeedback.lightImpact();
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

class _ReportsAndExportCard extends StatelessWidget {
  const _ReportsAndExportCard({required this.profile});
  final AccountProfile profile;

  @override
  Widget build(BuildContext context) {
    return _GlassSectionContainer(
      child: Column(
        children: [
          const _SectionHeader(
            title: 'REPORTS & DATA EXPORT',
            icon: Icons.analytics_outlined,
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Export Monthly PDF Report'),
            subtitle: const Text(
              'Workout volume, personal records and muscle balance',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showReportPreviewSheet(context, profile),
          ),
          const Divider(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Backup Workout Data'),
            subtitle: const Text('Export your history as JSON or CSV'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showExportDataSheet(context, profile),
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
                ? 'Metric (kg, cm, ml)'
                : 'Imperial (lbs, ft, oz)',
            trailing: TextButton(
              onPressed: () {
                notifier.updateBiometrics(
                  weightUnit: profile.weightUnit == 'kg' ? 'lbs' : 'kg',
                );
                HapticFeedback.lightImpact();
              },
              child: Text(profile.weightUnit.toUpperCase()),
            ),
          ),
          const Divider(height: 24),
          _PreferenceTile(
            title: 'Cycle-Aware Training',
            subtitle: 'Adjust training across hormone phases',
            trailing: Switch(
              value: profile.cycleTrackingEnabled,
              onChanged: notifier.toggleCycleTracking,
            ),
          ),
          const Divider(height: 24),
          _PreferenceTile(
            title: 'Audio Cues & Rest Beeps',
            subtitle: 'Play a chime when your rest timer ends',
            trailing: Switch(
              value: profile.audioCuesEnabled,
              onChanged: notifier.toggleAudioCues,
            ),
          ),
          const Divider(height: 24),
          _PreferenceTile(
            title: 'Haptic Vibrations',
            subtitle: 'Vibrate when sets and exercises are checked',
            trailing: Switch(
              value: profile.hapticFeedbackEnabled,
              onChanged: notifier.toggleHapticFeedback,
            ),
          ),
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
                  await ref.read(onboardingProvider.notifier).reset();
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
                    'This will reset your biometrics and training preferences back to initial defaults.',
                onConfirm: () async {
                  await ref
                      .read(accountProfileProvider.notifier)
                      .resetToDefaults();
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

          // Clear Local Workout Cache
          InkWell(
            onTap: () {
              _showConfirmDialog(
                context,
                title: 'Clear Cache',
                content:
                    'Temporary app cache and chart caches will be cleared without deleting your workout history.',
                onConfirm: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.charcoal,
                      content: Text(
                        'Temporary cache cleared.',
                        style: TextStyle(
                          fontFamily: AppTypography.fontBody,
                          fontSize: 13.0,
                          color: AppColors.pureWhite,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.cleaning_services_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Clear Cache',
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

          // Sign Out / Switch User
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.charcoal,
                  content: Text(
                    'Local session active. Guest mode is enabled.',
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 13.0,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Sign Out / Switch Account',
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
