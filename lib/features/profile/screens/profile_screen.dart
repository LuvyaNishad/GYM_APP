/// LEON Account & User Profile Screen.
///
/// Features:
/// 1. Identity & Profile (Avatar, Name, Email, Member Since)
/// 2. Biometrics & Goal Delta (Height, Weight, Target, BMI, Calorie maintenance)
/// 3. Training & Routine Preferences (Split, Experience tier, Rest timer, Barbell tare)
/// 4. Athletic Reports & Data Export (1-Page Monthly PDF Report, JSON/CSV Export)
/// 5. App Preferences & Inclusivity (Units toggle, Menstrual cycle recovery, Audio/Haptics)
/// 6. Account Actions & Reset
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../onboarding/widgets/goal_selector_sheet.dart';
import '../models/account_profile_model.dart';
import '../providers/profile_provider.dart';
import '../widgets/edit_biometrics_dialog.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/export_data_dialog.dart';
import '../widgets/report_preview_dialog.dart';

/// Main Account Screen for managing user identity, physical biometrics,
/// training split preferences, and PDF reports.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(accountProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top Header ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACCOUNT',
                            style: TextStyle(
                              fontFamily: AppTypography.fontDisplay,
                              fontSize: 22.0,
                              fontWeight: FontWeight.w800,
                              color: AppColors.pureWhite,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Personal Profile & Settings',
                            style: TextStyle(
                              fontFamily: AppTypography.fontBody,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded,
                              size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'ACTIVE LIFTER',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Main Content Cards ─────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                AppShell.reservedBottomSpace + 24,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 1. User Identity Card
                  _IdentityCard(profile: profile),
                  const SizedBox(height: 14),

                  // 2. Biometrics & Goal Progress Card
                  _BiometricsCard(profile: profile),
                  const SizedBox(height: 14),

                  // 3. Training & Routine Preferences Card
                  _TrainingPreferencesCard(profile: profile),
                  const SizedBox(height: 14),

                  // 4. Reports & Data Export Card
                  _ReportsAndExportCard(profile: profile),
                  const SizedBox(height: 14),

                  // 5. App Settings & Inclusivity Card
                  _AppSettingsCard(profile: profile),
                  const SizedBox(height: 14),

                  // 6. Account Actions Card
                  _AccountActionsCard(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. User Identity Card
// ─────────────────────────────────────────────────────────────────────────────
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});

  final AccountProfile profile;

  @override
  Widget build(BuildContext context) {
    final initials = profile.displayName.isNotEmpty
        ? profile.displayName.substring(0, 1).toUpperCase()
        : 'L';

    return _GlassSectionContainer(
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with Electric Cyan halo
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.charcoal,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.8),
                    width: 2.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontDisplay,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.pureWhite,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name, Email, Member date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontDisplay,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pureWhite,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.email,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontSize: 12.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member since ${_formatMonthYear(profile.memberSince)}',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11.0,
                        color: AppColors.platinum,
                      ),
                    ),
                  ],
                ),
              ),

              // Edit Button
              InkWell(
                onTap: () => showEditProfileSheet(context, profile),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.steel.withValues(alpha: 0.6),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined,
                          size: 14, color: AppColors.pureWhite),
                      SizedBox(width: 5),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontFamily: AppTypography.fontBody,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.pureWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMonthYear(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Biometrics & Goal Progress Card
// ─────────────────────────────────────────────────────────────────────────────
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionHeader(
                title: 'BIOMETRICS & GOALS',
                icon: Icons.monitor_weight_outlined,
              ),
              InkWell(
                onTap: () => showEditBiometricsSheet(context, profile),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Text(
                    'Update',
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3-Column Metrics Grid
          Row(
            children: [
              _MetricBlock(
                label: 'HEIGHT',
                value: profile.formattedHeight,
              ),
              const SizedBox(width: 8),
              _MetricBlock(
                label: 'CURRENT',
                value: profile.formatWeight(profile.currentWeightKg),
              ),
              const SizedBox(width: 8),
              _MetricBlock(
                label: 'GOAL',
                value: profile.formatWeight(profile.targetWeightKg),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // BMI & Maintenance Row
          Row(
            children: [
              // BMI Chip
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.steel.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BMI SCORE',
                              style: TextStyle(
                                fontFamily: AppTypography.fontDisplay,
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${profile.bmi.toStringAsFixed(1)} · ${profile.bmiCategory}',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 12.0,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pureWhite,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Maintenance Calories
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.steel.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EST. MAINTENANCE',
                        style: TextStyle(
                          fontFamily: AppTypography.fontDisplay,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${profile.maintenanceCaloriesEstimate} kcal/day',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pureWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Goal Delta Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    profile.isCutting
                        ? 'Cutting: ${profile.weightDeltaKg.toStringAsFixed(1)} kg remaining to goal'
                        : 'Building: ${profile.weightDeltaKg.toStringAsFixed(1)} kg to goal',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pureWhite,
                    ),
                  ),
                  Text(
                    '${(profile.goalProgress * 100).toInt()}%',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  height: 6,
                  width: double.infinity,
                  color: Colors.white.withValues(alpha: 0.12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: profile.goalProgress.clamp(0.0, 1.0),
                      child: Container(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Training Preferences Card
// ─────────────────────────────────────────────────────────────────────────────
class _TrainingPreferencesCard extends ConsumerWidget {
  const _TrainingPreferencesCard({required this.profile});

  final AccountProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalConfig = ref.watch(trainingGoalConfigProvider);

    return _GlassSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'TRAINING PREFERENCES',
            icon: Icons.fitness_center_rounded,
          ),
          const SizedBox(height: 12),

          // Primary Training Goal Row
          _PreferenceTile(
            title: 'Primary Goal',
            subtitle: '${goalConfig.displayName} · ${goalConfig.subtitle}',
            trailing: InkWell(
              onTap: () => showGoalSelectorSheet(context, ref),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: goalConfig.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: goalConfig.accentColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  'CHANGE',
                  style: TextStyle(
                    fontFamily: AppTypography.fontDisplay,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: goalConfig.accentColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          const Divider(color: AppColors.steel, height: 18),

          // Preferred Split Row
          _PreferenceTile(
            title: 'Training Split',
            subtitle: profile.preferredSplit,
            trailing: InkWell(
              onTap: () => showEditProfileSheet(context, profile),
              child: const Text(
                'Change',
                style: TextStyle(
                  fontFamily: AppTypography.fontBody,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const Divider(color: AppColors.steel, height: 18),

          // Experience Tier
          _PreferenceTile(
            title: 'Experience Tier',
            subtitle: profile.experienceLevel,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                profile.experienceLevel.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.platinum,
                ),
              ),
            ),
          ),
          const Divider(color: AppColors.steel, height: 18),

          // Default Rest Timer Selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Default Rest Timer',
                style: TextStyle(
                  fontFamily: AppTypography.fontDisplay,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pureWhite,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Auto-countdown between sets',
                style: TextStyle(
                  fontFamily: AppTypography.fontBody,
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [60, 90, 120, 180].map((sec) {
                  final isSel = profile.defaultRestSeconds == sec;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () {
                          ref
                              .read(accountProfileProvider.notifier)
                              .updatePreferences(defaultRestSeconds: sec);
                          HapticFeedback.lightImpact();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.charcoal,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.primary
                                  : AppColors.steel.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            '${sec}s',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11.5,
                              fontWeight:
                                  isSel ? FontWeight.w800 : FontWeight.w500,
                              color: isSel
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const Divider(color: AppColors.steel, height: 18),

          // Barbell Tare weight
          _PreferenceTile(
            title: 'Olympic Barbell Tare',
            subtitle: 'Base bar weight for plate calculations',
            trailing: InkWell(
              onTap: () {
                final nextTare = profile.barbellTareKg == 20.0 ? 15.0 : 20.0;
                ref
                    .read(accountProfileProvider.notifier)
                    .updatePreferences(barbellTareKg: nextTare);
                HapticFeedback.lightImpact();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.steel.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  '${profile.barbellTareKg.toStringAsFixed(0)} kg',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pureWhite,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Reports & Data Export Card ("PDF etc.")
// ─────────────────────────────────────────────────────────────────────────────
class _ReportsAndExportCard extends StatelessWidget {
  const _ReportsAndExportCard({required this.profile});

  final AccountProfile profile;

  @override
  Widget build(BuildContext context) {
    return _GlassSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'REPORTS & DATA EXPORT',
            icon: Icons.analytics_outlined,
          ),
          const SizedBox(height: 12),

          // Generate 1-Page PDF Report Button
          InkWell(
            onTap: () => showReportPreviewSheet(context, profile),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Monthly PDF Report',
                          style: TextStyle(
                            fontFamily: AppTypography.fontDisplay,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pureWhite,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '1-page athletic report with volume, PRs & radar',
                          style: TextStyle(
                            fontFamily: AppTypography.fontBody,
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.platinum,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Export Raw Data Button
          InkWell(
            onTap: () => showExportDataSheet(context, profile),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.steel.withValues(alpha: 0.6),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.file_download_outlined,
                      color: AppColors.pureWhite,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Backup Workout Data',
                          style: TextStyle(
                            fontFamily: AppTypography.fontDisplay,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pureWhite,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Export personal history as JSON or CSV',
                          style: TextStyle(
                            fontFamily: AppTypography.fontBody,
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.platinum,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. App Settings & Inclusivity Card
// ─────────────────────────────────────────────────────────────────────────────
class _AppSettingsCard extends ConsumerWidget {
  const _AppSettingsCard({required this.profile});

  final AccountProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GlassSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'APP SETTINGS & INCLUSIVITY',
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: 12),

          // Units Toggle (Metric vs Imperial)
          _PreferenceTile(
            title: 'Units of Measurement',
            subtitle: profile.weightUnit == 'kg'
                ? 'Metric (kg, cm, ml)'
                : 'Imperial (lbs, ft, oz)',
            trailing: InkWell(
              onTap: () {
                final next = profile.weightUnit == 'kg' ? 'lbs' : 'kg';
                ref
                    .read(accountProfileProvider.notifier)
                    .updateBiometrics(weightUnit: next);
                HapticFeedback.lightImpact();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.steel.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  profile.weightUnit.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pureWhite,
                  ),
                ),
              ),
            ),
          ),
          const Divider(color: AppColors.steel, height: 18),

          // Menstrual Cycle Recovery Tracking
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cycle-Aware Training',
                      style: TextStyle(
                        fontFamily: AppTypography.fontDisplay,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.pureWhite,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Adjust routine intensity across hormone phases',
                      style: TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: profile.cycleTrackingEnabled,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primaryDim.withValues(alpha: 0.4),
                inactiveThumbColor: AppColors.steel,
                inactiveTrackColor: AppColors.charcoal,
                onChanged: (val) {
                  ref
                      .read(accountProfileProvider.notifier)
                      .toggleCycleTracking(val);
                },
              ),
            ],
          ),
          const Divider(color: AppColors.steel, height: 18),

          // Audio Cues
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio Cues & Rest Beeps',
                      style: TextStyle(
                        fontFamily: AppTypography.fontDisplay,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.pureWhite,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Audio chime upon rest timer countdown completion',
                      style: TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: profile.audioCuesEnabled,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primaryDim.withValues(alpha: 0.4),
                inactiveThumbColor: AppColors.steel,
                inactiveTrackColor: AppColors.charcoal,
                onChanged: (val) {
                  ref
                      .read(accountProfileProvider.notifier)
                      .toggleAudioCues(val);
                },
              ),
            ],
          ),
          const Divider(color: AppColors.steel, height: 18),

          // Haptic Feedback
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Haptic Vibrations',
                      style: TextStyle(
                        fontFamily: AppTypography.fontDisplay,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.pureWhite,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tactile pulse when sets and exercises are checked',
                      style: TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: profile.hapticFeedbackEnabled,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primaryDim.withValues(alpha: 0.4),
                inactiveThumbColor: AppColors.steel,
                inactiveTrackColor: AppColors.charcoal,
                onChanged: (val) {
                  ref
                      .read(accountProfileProvider.notifier)
                      .toggleHapticFeedback(val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Account Actions Card
// ─────────────────────────────────────────────────────────────────────────────
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
                  Icon(Icons.school_outlined,
                      color: AppColors.primary, size: 20),
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
                  Icon(Icons.restart_alt_rounded,
                      color: AppColors.textSecondary, size: 20),
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
                  Icon(Icons.cleaning_services_rounded,
                      color: AppColors.textSecondary, size: 20),
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
                  Icon(Icons.logout_rounded,
                      color: AppColors.danger, size: 20),
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
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
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
            child: const Text('Confirm',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Section Building Blocks
// ─────────────────────────────────────────────────────────────────────────────
class _GlassSectionContainer extends StatelessWidget {
  const _GlassSectionContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.steel.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
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
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTypography.fontDisplay,
            fontSize: 12.0,
            fontWeight: FontWeight.w800,
            color: AppColors.platinum,
            letterSpacing: 1.0,
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.steel.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTypography.fontDisplay,
                fontSize: 11.0,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppColors.pureWhite,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTypography.fontDisplay,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pureWhite,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: AppTypography.fontBody,
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
