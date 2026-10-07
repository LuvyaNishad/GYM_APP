import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/leon_button.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/drum_wheel_picker.dart';
import '../widgets/onboarding_top_bar.dart';
import '../widgets/tactical_radar_widget.dart';

/// Complete 16-Screen Tactical Onboarding flow for LEON.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initialPage = ref.read(onboardingProvider).currentPage;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    FocusScope.of(context).unfocus();
    ref.read(onboardingProvider.notifier).setPage(page);
    _pageController.animateToPage(
      page,
      duration: AppConstants.animNormal,
      curve: Curves.easeInOutCubic,
    );
  }

  void _nextPage() {
    final current = ref.read(onboardingProvider).currentPage;
    if (current < OnboardingState.totalPages - 1) {
      _goToPage(current + 1);
    }
  }

  void _previousPage() {
    final current = ref.read(onboardingProvider).currentPage;
    if (current > 0) {
      _goToPage(current - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.03),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar shown only on survey steps (Pages 2 to 13)
                if (state.currentPage >= 2 && state.currentPage <= 13)
                  OnboardingTopBar(
                    stepLabel: state.stepLabel,
                    progress: state.stepProgress,
                    onBack: _previousPage,
                    onSkip: state.currentPage == 7 ? _nextPage : null,
                  ),

                // Main Page View
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) {
                      notifier.setPage(page);
                    },
                    children: [
                      // Screen 01: Splash
                      _buildSplash(context),

                      // Screen 02: Welcome
                      _buildWelcome(context),

                      // Screen 03: Identify Agent (Name)
                      _buildNameStep(context, state, notifier),

                      // Screen 04: Age
                      _buildAgeStep(context, state, notifier),

                      // Screen 05: Height
                      _buildHeightStep(context, state, notifier),

                      // Screen 06: Weight
                      _buildWeightStep(context, state, notifier),

                      // Screen 07: Goal Weight
                      _buildGoalWeightStep(context, state, notifier),

                      // Screen 08: Experience Level
                      _buildExperienceStep(context, state, notifier),

                      // Screen 09: Primary Objective
                      _buildGoalStep(context, state, notifier),

                      // Screen 10: Training Frequency
                      _buildFrequencyStep(context, state, notifier),

                      // Screen 11: Preferred Split
                      _buildSplitStep(context, state, notifier),

                      // Screen 12: Equipment Profile
                      _buildEquipmentStep(context, state, notifier),

                      // Screen 13: Limitations & Injuries
                      _buildInjuriesStep(context, state, notifier),

                      // Screen 14: Generating Programme
                      _buildGeneratingStep(context, state),

                      // Screen 15: Programme Ready
                      _buildReadyStep(context, state, notifier),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SCREEN 01: SPLASH ───────────────────────────────────────────────────────
  Widget _buildSplash(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _nextPage,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Atmospheric Glow & Logo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 90,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: Text(
                'L E O N',
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8.0,
                  fontSize: 42,
                  shadows: [
                    const Shadow(
                      color: AppColors.primary,
                      blurRadius: 24,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'OPERATIONAL FITNESS OS',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 3.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 56),

            // Pulsing Ring Indicator
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'TAP TO INITIALIZE',
              style: AppTypography.dataSmall.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 2.0,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SCREEN 02: WELCOME ──────────────────────────────────────────────────────
  Widget _buildWelcome(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Top minimal progress bar
          Container(
            height: 2,
            width: double.infinity,
            color: const Color(0xFF1E2537),
          ),
          const Spacer(),

          // Tactical Radar Graphic
          const TacticalRadarWidget(size: 220),
          const SizedBox(height: 40),

          // Titles
          Text(
            'WELCOME TO LEON',
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your operational fitness OS.\nBuilt for performance.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const Spacer(),

          // Actions
          LeonButton(
            label: 'COMMENCE OPERATION',
            icon: Icons.arrow_forward,
            onPressed: _nextPage,
            width: double.infinity,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppConstants.routeLogin),
                child: Text(
                  'Sign in',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── SCREEN 03: IDENTIFY AGENT (NAME) ───────────────────────────────────────
  Widget _buildNameStep(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Huge watermark 'A' glyph in the background
              Positioned(
                child: Text(
                  'A',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 340,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.02),
                  ),
                ),
              ),

              GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'IDENTIFY AGENT',
                      style: AppTypography.headlineMedium.copyWith(
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'What do we call you?',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Terminal-style Prompt Field
                    Text(
                      'DISPLAY_NAME_',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '> ',
                            style: AppTypography.headlineMedium.copyWith(
                              color: AppColors.primary,
                              fontFamily: 'JetBrainsMono',
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              style: AppTypography.headlineMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                hintText: 'Enter callsign',
                                hintStyle: TextStyle(
                                  color: AppColors.textMuted,
                                ),
                                border: InputBorder.none,
                              ),
                              onChanged: notifier.setAgentName,
                              onSubmitted: (val) {
                                if (val.trim().isNotEmpty) {
                                  notifier.setAgentName(val.trim());
                                  _nextPage();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    LeonButton(
                      label: 'CONFIRM IDENTITY',
                      icon: Icons.arrow_forward,
                      width: double.infinity,
                      onPressed: () {
                        if (_nameController.text.trim().isNotEmpty) {
                          notifier.setAgentName(_nameController.text.trim());
                        }
                        _nextPage();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SCREEN 04: AGE ─────────────────────────────────────────────────────────
  Widget _buildAgeStep(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'DATE OF BIRTH',
            style: AppTypography.headlineMedium.copyWith(
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How old are you?',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),

          DrumWheelPicker(
            minValue: 14,
            maxValue: 90,
            initialValue: state.age,
            unit: 'YEARS OLD',
            onChanged: notifier.setAge,
          ),

          const Spacer(),
          LeonButton(
            label: 'CONFIRM AGE',
            icon: Icons.check,
            width: double.infinity,
            onPressed: _nextPage,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── SCREEN 05: HEIGHT ──────────────────────────────────────────────────────
  Widget _buildHeightStep(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
  ) {
    final isCm = state.isHeightCm;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'PHYSICAL STATS — HEIGHT',
            style: AppTypography.headlineMedium.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Calibrating physical parameters for optimal tracking.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Unit Toggle Pill
          _buildUnitToggle(
            leftLabel: 'CM',
            rightLabel: 'FT',
            isLeftSelected: isCm,
            onLeftTap: () => notifier.setHeightUnit(true),
            onRightTap: () => notifier.setHeightUnit(false),
          ),

          const Spacer(),
          DrumWheelPicker(
            minValue: isCm ? 120 : 48,
            maxValue: isCm ? 225 : 86,
            initialValue: state.height.toInt(),
            unit: isCm ? 'CM' : 'INCHES',
            onChanged: (val) => notifier.setHeight(val.toDouble()),
          ),
          const Spacer(),

          LeonButton(
            label: 'CONFIRM HEIGHT',
            icon: Icons.check,
            width: double.infinity,
            onPressed: _nextPage,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── SCREEN 06: WEIGHT ──────────────────────────────────────────────────────
  Widget _buildWeightStep(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
  ) {
    final isKg = state.isWeightKg;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'PHYSICAL STATS — WEIGHT',
            style: AppTypography.headlineMedium.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Calibrating physical parameters for optimal performance.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Unit Toggle Pill
          _buildUnitToggle(
            leftLabel: 'KG',
            rightLabel: 'LBS',
            isLeftSelected: isKg,
            onLeftTap: () => notifier.setWeightUnit(true),
            onRightTap: () => notifier.setWeightUnit(false),
          ),

          const Spacer(),
          DrumWheelPicker(
            minValue: isKg ? 35 : 80,
            maxValue: isKg ? 180 : 400,
            initialValue: state.weight.toInt(),
            unit: isKg ? 'KG' : 'LBS',
            onChanged: (val) => notifier.setWeight(val.toDouble()),
          ),
          const Spacer(),

          LeonButton(
            label: 'CONFIRM WEIGHT',
            icon: Icons.check,
            width: double.infinity,
            onPressed: _nextPage,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── SCREEN 07: GOAL WEIGHT ─────────────────────────────────────────────────
  Widget _buildGoalWeightStep(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
  ) {
    final isKg = state.isWeightKg;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'TARGET METRICS — GOAL WEIGHT',
            style: AppTypography.headlineMedium.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Calibrating target trajectory and progressive overload curve.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Unit Toggle Pill
          _buildUnitToggle(
            leftLabel: 'KG',
            rightLabel: 'LBS',
            isLeftSelected: isKg,
            onLeftTap: () => notifier.setWeightUnit(true),
            onRightTap: () => notifier.setWeightUnit(false),
          ),

          const Spacer(),
          DrumWheelPicker(
            minValue: isKg ? 35 : 80,
            maxValue: isKg ? 180 : 400,
            initialValue: state.targetWeight.toInt(),
            unit: isKg ? 'KG' : 'LBS',
            onChanged: (val) => notifier.setTargetWeight(val.toDouble()),
          ),
          const Spacer(),

          LeonButton(
            label: 'CONFIRM TARGET',
            icon: Icons.check,
            width: double.infinity,
            onPressed: _nextPage,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── SCREEN 08: EXPERIENCE LEVEL ────────────────────────────────────────────
  Widget _buildExperienceStep(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
  ) {
    final options = [
      {
        'level': 'BEGINNER',
        'desc': 'New to structured resistance training',
        'cadence': '1-2 days/week',
        'icon': Icons.accessibility_new,
      },
      {
        'level': 'INTERMEDIATE',
        'desc': 'Consistent base fitness with lifting experience',
        'cadence': '3-4 days/week',
        'icon': Icons.fitness_center,
      },
      {
        'level': 'ADVANCED',
        'desc': 'Experienced athlete aiming for peak performance',
        'cadence': '5+ days/week',
        'icon': Icons.directions_run,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'EXPERIENCE LEVEL',
            style: AppTypography.headlineMedium.copyWith(
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select your current training level',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),

          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = options[index];
                final isSelected = state.experienceLevel == item['level'];

                return GestureDetector(
                  onTap: () => notifier.setExperienceLevel(item['level'] as String),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.04),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.15),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 16,
                              ),
                            ]
                          : null,
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.06),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['level'] as String,
                                style: AppTypography.headlineSmall.copyWith(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['desc'] as String,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.06),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            item['cadence'] as String,
                            style: AppTypography.dataSmall.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          LeonButton(
            label: 'CONFIRM EXPERIENCE',
            icon: Icons.check,
            width: double.infinity,
            onPressed: _nextPage,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── SCREEN 09: PRIMARY OBJECTIVE ───────────────────────────────────────────
  Widget _buildGoalStep(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
  ) {
    final objectives = [
      {
        'title': 'BUILD MUSCLE',
        'desc': 'Hypertrophy protocols for lean tissue acquisition.',
        'icon': Icons.fitness_center,
      },
      {
        'title': 'LOSE FAT',
        'desc': 'Metabolic conditioning and caloric deficit tracking.',
        'icon': Icons.local_fire_department,
      },
      {
        'title': 'INCREASE STRENGTH',
        'desc': 'Heavy compound lifts designed for maximal output.',
        'icon': Icons.bolt,
      },
      {
        'title': 'ATHLETIC PERFORMANCE',
        'desc': 'Explosive power and functional agility calibration.',
        'icon': Icons.speed,
      },
      {
        'title': 'GENERAL HEALTH',
        'desc': 'Cardiovascular endurance and functional longevity.',
        'icon': Icons.favorite,
      },
      {
        'title': 'REHABILITATION',
        'desc': 'Joint mobility and active recovery protocols.',
        'icon': Icons.healing,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'PRIMARY OBJECTIVE',
            style: AppTypography.headlineMedium.copyWith(
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Calibrate your core directive. Dictates algorithmic adaptations.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ListView.separated(
              itemCount: objectives.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = objectives[index];
                final isSelected = state.primaryGoal == item['title'];

                return GestureDetector(
                  onTap: () => notifier.setPrimaryGoal(item['title'] as String),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.04),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.12),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: 14,
                              ),
                            ]
                          : null,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.05),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: AppTypography.headlineSmall.copyWith(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['desc'] as String,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          LeonButton(
            label: 'CONFIRM OBJECTIVE',
            icon: Icons.check,
            width: double.infinity,
            onPressed: _nextPage,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── SCREEN 10: TRAINING FREQUENCY ──────────────────────────────────────────
  Widget _buildFrequencyStep(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
  ) {
    String getRecommendation(int days) {
      if (days <= 2) return 'Active recovery / Maintenance';
      if (days <= 4) return 'Full body or Upper/Lower split';
      if (days <= 6) return 'PPL or Bro Split recommended';
      return 'Advanced athlete / High risk of overtraining';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'TRAINING FREQUENCY',
            style: AppTypography.headlineMedium.copyWith(
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Operational cadence per weekly cycle.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),

          // Days selector: 1 to 7
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              final day = index + 1;
              final isSelected = state.trainingDaysPerWeek == day;

              return GestureDetector(
                onTap: () => notifier.setTrainingDays(day),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 42,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.15),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: AppTypography.headlineSmall.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Dynamic recommendation pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.primary.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  getRecommendation(state.trainingDaysPerWeek),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),
          LeonButton(
            label: 'CONFIRM CADENCE',
            icon: Icons.check,
            width: double.infinity,
            onPressed: _nextPage,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── SCREEN 11: PREFERRED PROTOCOL / SPLIT ──────────────────────────────────
  Widget _buildSplitStep(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
  ) {
    final splits = [
      {
        'id': 'PPL',
        'title': 'PPL',
        'subtitle': 'Push, Pull, Legs',
        'desc':
            'Highly effective split for building muscle mass and ensuring adequate recovery between muscle groups.',
        'days': '6',
      },
      {
        'id': 'Upper/Lower',
        'title': 'UPPER / LOWER',
        'subtitle': 'Anterior & Posterior Focus',
        'desc':
            'Splits workouts into alternating upper and lower sessions, ideal for strength and recovery balance.',
        'days': '4',
      },
      {
        'id': 'Full Body',
        'title': 'FULL BODY',
        'subtitle': 'Comprehensive Systemic Stimulus',
        'desc':
            'Trains all primary compound movements each session with maximum efficiency per hour.',
        'days': '3',
      },
      {
        'id': 'Bro Split',
        'title': 'BRO SPLIT',
        'subtitle': 'Isolated Muscle Targeting',
        'desc':
            'Devotes each individual training day to a single muscle group for maximal pump and isolation.',
        'days': '5',
      },
      {
        'id': 'Arnold Split',
        'title': 'ARNOLD SPLIT',
        'subtitle': 'Antagonist Pairing',
        'desc':
            'Chest/Back, Shoulders/Arms, Legs classic bodybuilding cycle for elite hypertrophy.',
        'days': '6',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'PREFERRED PROTOCOL',
            style: AppTypography.headlineMedium.copyWith(
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose your training split',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ListView.separated(
              itemCount: splits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = splits[index];
                final isSelected = state.preferredSplit == item['id'];

                return GestureDetector(
                  onTap: () => notifier.setPreferredSplit(item['id'] as String),
                  child: GlassCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(20),
                    borderColor: isSelected
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.15),
                    backgroundColor: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.glassWhite,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['title'] as String,
                              style: AppTypography.headlineSmall.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.05),
                              ),
                              child: Text(
                                '${item['days']} DAYS / WEEK',
                                style: AppTypography.dataSmall.copyWith(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['subtitle'] as String,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item['desc'] as String,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          LeonButton(
            label: 'SELECT PROTOCOL',
            icon: Icons.check,
            width: double.infinity,
            onPressed: _nextPage,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── SCREEN 12: EQUIPMENT PROFILE ───────────────────────────────────────────
  Widget _buildEquipmentStep(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
  ) {
    final categories = {
      'FREE WEIGHTS': ['Dumbbells', 'Barbell', 'Squat Rack', 'Kettlebells', 'Bench'],
      'MACHINES': ['Cable Machine', 'Smith Machine', 'Leg Press'],
      'ACCESSORIES': ['Pull-up Bar', 'Resistance Bands', 'Dip Station'],
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'EQUIPMENT PROFILE',
            style: AppTypography.headlineMedium.copyWith(
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select available arsenal for intelligent routine packing.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ListView(
              children: categories.entries.map((cat) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.key,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cat.value.map((item) {
                        final isSelected = state.equipment.contains(item);

                        return FilterChip(
                          label: Text(item),
                          selected: isSelected,
                          onSelected: (_) => notifier.toggleEquipment(item),
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          backgroundColor: Colors.white.withValues(alpha: 0.04),
                          checkmarkColor: AppColors.primary,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.15),
                          ),
                          labelStyle: AppTypography.dataSmall.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }).toList(),
            ),
          ),

          Text(
            'You can update this anytime in Settings',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          LeonButton(
            label: 'CONFIRM EQUIPMENT',
            icon: Icons.check,
            width: double.infinity,
            onPressed: _nextPage,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── SCREEN 13: LIMITATIONS & INJURIES ──────────────────────────────────────
  Widget _buildInjuriesStep(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
  ) {
    final injuryItems = [
      {'name': 'LOWER BACK', 'icon': Icons.accessibility_new},
      {'name': 'SHOULDER', 'icon': Icons.fitness_center},
      {'name': 'KNEE', 'icon': Icons.sports_gymnastics},
      {'name': 'ELBOW / WRIST', 'icon': Icons.front_hand},
      {'name': 'NONE', 'icon': Icons.sentiment_very_satisfied},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'LIMITATIONS & INJURIES',
            style: AppTypography.headlineMedium.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'We\'ll adapt your programme to keep you safe and resilient.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ListView.separated(
              itemCount: injuryItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = injuryItems[index];
                final name = item['name'] as String;
                final isNone = name == 'NONE';
                final isSelected = isNone
                    ? state.injuries.isEmpty
                    : state.injuries.contains(name);

                final activeColor = isNone ? AppColors.success : AppColors.primary;

                return GestureDetector(
                  onTap: () => notifier.toggleInjury(name),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isSelected
                          ? activeColor.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.04),
                      border: Border.all(
                        color: isSelected
                            ? activeColor
                            : Colors.white.withValues(alpha: 0.15),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: activeColor.withValues(alpha: 0.15),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              color: isSelected
                                  ? activeColor
                                  : AppColors.textSecondary,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              name,
                              style: AppTypography.headlineSmall.copyWith(
                                color: isSelected
                                    ? activeColor
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: activeColor,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          LeonButton(
            label: 'GENERATE PROGRAMME',
            icon: Icons.auto_awesome,
            width: double.infinity,
            onPressed: _nextPage,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── SCREEN 14: GENERATING PROGRAMME ────────────────────────────────────────
  Widget _buildGeneratingStep(BuildContext context, OnboardingState state) {
    return _GeneratingStepView(
      onComplete: _nextPage,
    );
  }

  // ── SCREEN 15: PROGRAMME READY ─────────────────────────────────────────────
  Widget _buildReadyStep(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
  ) {
    final schedule = [
      {'day': '01', 'name': 'Push', 'focus': 'Chest, Shoulders, Triceps', 'color': AppColors.primary},
      {'day': '02', 'name': 'Pull', 'focus': 'Back, Biceps, Rear Delts', 'color': AppColors.purple},
      {'day': '03', 'name': 'Legs', 'focus': 'Quads, Hamstrings, Calves', 'color': AppColors.secondary},
      {'day': '04', 'name': 'Active Recovery', 'focus': 'Mobility & Light Cardio', 'color': Colors.greenAccent},
      {'day': '05', 'name': 'Upper Body', 'focus': 'Compound Hypertrophy', 'color': AppColors.primary},
      {'day': '06', 'name': 'Lower Body', 'focus': 'Strength & Postural Chain', 'color': AppColors.secondary},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'PROGRAMME SYNTHESIZED',
            style: AppTypography.headlineMedium.copyWith(
              letterSpacing: 2.0,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your custom operational split is locked and loaded.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ListView.separated(
              itemCount: schedule.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = schedule[index];

                return GlassCard(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Text(
                        item['day'] as String,
                        style: AppTypography.dataMedium.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] as String,
                              style: AppTypography.headlineSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              item['focus'] as String,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: item['color'] as Color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (item['color'] as Color).withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          LeonButton(
            label: 'DEPLOY PROGRAMME',
            icon: Icons.rocket_launch,
            width: double.infinity,
            onPressed: () async {
              await notifier.complete();
              if (context.mounted) {
                context.go(AppConstants.routeDashboard);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── HELPER: Unit toggle pill ───────────────────────────────────────────────
  Widget _buildUnitToggle({
    required String leftLabel,
    required String rightLabel,
    required bool isLeftSelected,
    required VoidCallback onLeftTap,
    required VoidCallback onRightTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2537),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onLeftTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isLeftSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isLeftSelected
                    ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
                    : null,
              ),
              child: Text(
                leftLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: isLeftSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onRightTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: !isLeftSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: !isLeftSelected
                    ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
                    : null,
              ),
              child: Text(
                rightLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: !isLeftSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// View widget for Screen 14 (Generating Programme) that animates progress
/// and cycles telemetry readouts before triggering [onComplete].
class _GeneratingStepView extends StatefulWidget {
  const _GeneratingStepView({required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<_GeneratingStepView> createState() => _GeneratingStepViewState();
}

class _GeneratingStepViewState extends State<_GeneratingStepView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _sequenceIndex = 0;
  Timer? _timer;

  final _messages = [
    'Analyzing biometric profile...',
    'Calibrating recovery baseline...',
    'Synthesizing optimal split...',
    'Finalizing neural training parameters...',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..forward();

    _timer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (mounted) {
        setState(() {
          _sequenceIndex = (_sequenceIndex + 1) % _messages.length;
        });
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _timer?.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            widget.onComplete();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'LEON OS',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 4.0,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 36),

          // Tactical radar sweep with polygon data
          const TacticalRadarWidget(
            size: 240,
            showPolygon: true,
          ),
          const SizedBox(height: 48),

          // Dynamic telemetry readout
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _messages[_sequenceIndex],
              key: ValueKey(_sequenceIndex),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Animated progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: _controller.value,
                      backgroundColor: const Color(0xFF1E2537),
                      color: AppColors.primary,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_controller.value * 100).toInt()}%',
                      style: AppTypography.dataSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontFamily: 'JetBrainsMono',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
