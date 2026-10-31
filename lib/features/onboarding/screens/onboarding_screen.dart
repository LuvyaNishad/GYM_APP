import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/aeon_logo.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/leon_button.dart';
import '../providers/onboarding_provider.dart';
import '../../../models/user_model.dart';
import '../../../core/utils/measurement_units.dart';
import '../../workout_builder/models/programme_configuration.dart';
import '../../workout_builder/providers/splits_provider.dart';
import '../../../shared/widgets/persistence_feedback.dart';
import '../widgets/onboarding_top_bar.dart';
import '../widgets/tactical_radar_widget.dart';

/// Streamlined 7-Question, 4-Screen Compact Onboarding flow for LEON.
///
/// Compliant with Apple HIG & Research Standards:
/// 1. Splash Screen: Atmospheric brand intro
/// 2. Welcome Screen: Matched buttons (1-Tap "CONTINUE AS GUEST" + "CUSTOMIZE SETUP")
/// 3. Step 01 / 04: Primary Training Goal & Experience Level (Questions 1 & 2)
/// 4. Step 02 / 04: Body Biometrics (Height, Current Weight & Target Goal Weight) (Questions 3 & 4)
/// 5. Step 03 / 04: Routine Split & Training Frequency (Questions 5 & 6)
/// 6. Step 04 / 04: Physical Limitations / Injuries & Equipment Profile (Question 7 + Equipment)
/// 7. Ready Screen: Split-aware routine preview + "START WORKOUT"
///
/// All question screens are strictly designed to fit at one glance without scrolling.
/// Global "SKIP" in the top bar across all questionnaire steps.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  bool _saving = false;
  final _biometricsForm = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final initialPage = ref.read(onboardingProvider).currentPage;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _scrollableSurvey(Widget child) => SingleChildScrollView(child: child);

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

  Future<void> _completeAndNavigate() async {
    if (_saving) return;
    setState(() => _saving = true);
    final success = await persistWithFeedback(
      context,
      () => ref.read(onboardingProvider.notifier).complete(),
      message:
          'Could not save setup. Your choices are still here. Please try again.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      GoRouter.maybeOf(context)?.go(AppConstants.routeDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
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
                // Top bar shown on survey steps (Pages 2 to 5)
                if (state.currentPage >= 2 && state.currentPage <= 5)
                  OnboardingTopBar(
                    stepLabel: state.stepLabel,
                    progress: state.stepProgress,
                    onBack: _previousPage,
                    onSkip: _completeAndNavigate,
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
                      // Screen 0: Splash
                      _buildSplash(context),

                      // Screen 1: Welcome
                      _buildWelcome(context, notifier),

                      // Screen 2: Step 01 / 04: Goal & Experience
                      _scrollableSurvey(
                        _buildGoalAndExperienceStep(context, state, notifier),
                      ),

                      // Screen 3: Step 02 / 04: Biometrics (Height, Weight, Target)
                      _buildBiometricsStep(context, state, notifier),

                      // Screen 4: Step 03 / 04: Split & Schedule
                      _scrollableSurvey(
                        _buildSplitAndScheduleStep(context, state, notifier),
                      ),

                      // Screen 5: Step 04 / 04: Injuries & Equipment
                      _scrollableSurvey(
                        _buildInjuriesAndEquipmentStep(
                          context,
                          state,
                          notifier,
                        ),
                      ),

                      // Screen 6: Ready / Routine Overview
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

  // ── SCREEN 0: SPLASH ────────────────────────────────────────────────────────
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AeonLogo(size: 110, showGlow: true),
                  const SizedBox(height: 12),
                  Text(
                    'A E O N',
                    style: AppTypography.displayLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 8.0,
                      fontSize: 32,
                      shadows: [
                        const Shadow(color: AppColors.primary, blurRadius: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'PREMIUM FITNESS OS',
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
                border: Border.all(color: AppColors.primary, width: 2.0),
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
            const SizedBox(height: 16),
            Text(
              'TAP ANYWHERE TO ENTER',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 2.0,
                fontSize: 11.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SCREEN 1: WELCOME (MATCHED BUTTONS) ────────────────────────────────────
  Widget _buildWelcome(BuildContext context, OnboardingNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Top minimal accent bar
          Container(
            height: 2,
            width: double.infinity,
            color: const Color(0xFF1E2537),
          ),
          const Spacer(),

          // Radar Graphic
          const TacticalRadarWidget(size: 200),
          const SizedBox(height: 32),

          // Titles
          Text(
            'WELCOME TO AEON',
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your intelligent fitness tracker.\nBuilt for performance & seamless workout logging.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const Spacer(),

          // Primary CTA: Guided setup (Matched pill shape & 52 height)
          LeonButton(
            label: 'CUSTOMIZE SETUP (2 MIN)',
            icon: Icons.tune_rounded,
            onPressed: _nextPage,
            width: double.infinity,
          ),
          const SizedBox(height: 14),

          // Secondary CTA: Instant Guest Bypass (Exact same 52 height, padding & pill radius)
          LeonButton(
            label: 'CONTINUE AS GUEST',
            icon: Icons.bolt_rounded,
            isOutlined: true,
            onPressed: _completeAndNavigate,
            width: double.infinity,
          ),
          const SizedBox(height: 16),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── SCREEN 2: STEP 01 / 04: GOAL & EXPERIENCE (QUESTIONS 1 & 2) ───────────
  Widget _buildGoalAndExperienceStep(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
  ) {
    final objectives = [
      {
        'title': 'BUILD MUSCLE',
        'sub': 'Hypertrophy',
        'icon': Icons.fitness_center_rounded,
      },
      {'title': 'STRENGTH', 'sub': 'Maximal PRs', 'icon': Icons.bolt_rounded},
      {
        'title': 'LOSE FAT',
        'sub': 'Caloric Deficit',
        'icon': Icons.local_fire_department_rounded,
      },
      {'title': 'ATHLETIC', 'sub': 'Conditioning', 'icon': Icons.speed_rounded},
    ];

    final experienceLevels = [
      {'level': 'BEGINNER', 'freq': '< 1 YR'},
      {'level': 'INTERMEDIATE', 'freq': '1 - 3 YRS'},
      {'level': 'ADVANCED', 'freq': '3+ YRS'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header
          Center(
            child: Column(
              children: [
                Text(
                  'GOAL & EXPERIENCE',
                  style: AppTypography.headlineMedium.copyWith(
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select your fitness focus and lifting background.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Question 1: Primary Goal (2x2 Grid)
          Row(
            children: [
              const Icon(
                Icons.track_changes_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PRIMARY TRAINING GOAL',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontSize: 11.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.5,
            children: objectives.map((item) {
              final isSelected =
                  state.primaryGoal == item['title'] ||
                  (item['title'] == 'STRENGTH' &&
                      state.primaryGoal == 'INCREASE STRENGTH');
              return InkWell(
                onTap: () => notifier.setPrimaryGoal(item['title'] as String),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.03),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.12),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: AppTypography.headlineSmall.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                            Text(
                              item['sub'] as String,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Question 2: Experience Tier (3 horizontal segments)
          Row(
            children: [
              const Icon(
                Icons.military_tech_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'EXPERIENCE TIER',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontSize: 11.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: experienceLevels.map((item) {
              final isSelected = state.experienceLevel == item['level'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () =>
                        notifier.setExperienceLevel(item['level'] as String),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.03),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.12),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              item['level'] as String,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: AppTypography.headlineSmall.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['freq'] as String,
                            maxLines: 1,
                            softWrap: false,
                            style: AppTypography.monoSmall.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Continue Button
          LeonButton(
            label: 'CONTINUE',
            icon: Icons.arrow_forward_rounded,
            width: double.infinity,
            onPressed: _nextPage,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── SCREEN 3: STEP 02 / 04: BIOMETRICS & TARGET (QUESTIONS 3 & 4) ──────────
  Widget _buildBiometricsStep(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
  ) {
    final units = MeasurementUnits(
      weightUnit: state.isWeightKg ? 'kg' : 'lbs',
      heightUnit: state.isHeightCm ? 'cm' : 'ft',
    );
    Widget input(
      String label,
      String key,
      double? value,
      void Function(double) save,
      double maximum,
    ) => TextFormField(
      key: ValueKey('$key-${units.weightLabel}-${units.heightInputLabel}'),
      initialValue: value?.toStringAsFixed(1) ?? '',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, helperText: 'Optional'),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (text) {
        if (text == null || text.isEmpty) return null;
        final number = double.tryParse(text);
        return number == null ||
                !number.isFinite ||
                number <= 0 ||
                number > maximum
            ? 'Enter a valid positive value'
            : null;
      },
      onChanged: (text) {
        final number = double.tryParse(text);
        if (text.isEmpty) {
          notifier.clearBiometric(key);
          return;
        }
        if (number != null &&
            number.isFinite &&
            number > 0 &&
            number <= maximum) {
          save(number);
        }
      },
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _biometricsForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'BODY BIOMETRICS',
              style: AppTypography.headlineMedium.copyWith(letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'Leave any field empty if you do not want to provide it.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('kg / cm')),
                ButtonSegment(value: false, label: Text('lbs / ft-in')),
              ],
              selected: {state.isWeightKg},
              onSelectionChanged: (values) {
                notifier.setWeightUnit(values.first);
                notifier.setHeightUnit(values.first);
              },
            ),
            const SizedBox(height: 16),
            GlassCard(
              blur: true,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: state.ageProvided ? '${state.age}' : '',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age (optional)',
                      helperText: 'Used for calorie estimates',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final age = int.tryParse(value);
                      return age == null || age < 13 || age > 120
                          ? 'Enter age from 13 to 120'
                          : null;
                    },
                    onChanged: (value) {
                      final age = int.tryParse(value);
                      notifier.setAge(
                        age != null && age >= 13 && age <= 120 ? age : null,
                      );
                    },
                  ),
                  input(
                    'Height (${units.heightInputLabel})',
                    'height',
                    state.heightProvided
                        ? units.heightFromCm(state.height)
                        : null,
                    (value) => notifier.setHeight(units.heightToCm(value)),
                    units.heightFromCm(250),
                  ),
                  input(
                    'Current weight (${units.weightLabel})',
                    'weight',
                    state.weightProvided
                        ? units.weightFromKg(state.weight)
                        : null,
                    (value) => notifier.setWeight(units.weightToKg(value)),
                    units.weightFromKg(500),
                  ),
                  input(
                    'Goal weight (${units.weightLabel})',
                    'target',
                    state.targetProvided
                        ? units.weightFromKg(state.targetWeight)
                        : null,
                    (value) =>
                        notifier.setTargetWeight(units.weightToKg(value)),
                    units.weightFromKg(500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            LeonButton(
              label: 'CONTINUE',
              onPressed: () {
                if (_biometricsForm.currentState!.validate()) _nextPage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitAndScheduleStep(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
  ) {
    final splits = [
      {
        'id': 'PPL',
        'title': 'PUSH / PULL / LEGS',
        'desc': 'Push (Chest/Delts/Tri), Pull (Back/Bi), Legs',
        'days': '3 - 6 D',
      },
      {
        'id': 'Upper/Lower',
        'title': 'UPPER / LOWER',
        'desc': 'Alternating Upper and Lower body days',
        'days': '4 D',
      },
      {
        'id': 'Full Body',
        'title': 'FULL BODY',
        'desc': 'Total body compound stimulation per workout',
        'days': '3 D',
      },
      {
        'id': 'Arnold Split',
        'title': 'ARNOLD SPLIT',
        'desc': 'Chest/Back, Shoulders/Arms, Legs rotation',
        'days': '5 - 6 D',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header
          Center(
            child: Column(
              children: [
                Text(
                  'SPLIT & SCHEDULE',
                  style: AppTypography.headlineMedium.copyWith(
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select your weekly frequency and training split.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Question 5: Training Frequency
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DAYS PER WEEK',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ),
              Text(
                '${state.trainingDaysPerWeek} Days Target',
                style: AppTypography.monoSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [3, 4, 5, 6].map((day) {
              final isSelected = state.trainingDaysPerWeek == day;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => notifier.setTrainingDays(day),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.04),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.12),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$day',
                            style: AppTypography.headlineSmall.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'DAYS',
                            style: AppTypography.labelSmall.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontSize: 11.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Question 6: Training Split
          Row(
            children: [
              const Icon(
                Icons.dashboard_customize_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TRAINING SPLIT',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontSize: 11.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...splits.map((item) {
            final isSelected =
                resolveSplitId(state.preferredSplit) ==
                resolveSplitId(item['id'] as String);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => notifier.setPreferredSplit(item['id'] as String),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.10)
                        : Colors.white.withValues(alpha: 0.03),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.12),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              item['desc'] as String,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item['days'] as String,
                        style: AppTypography.monoSmall.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // Continue Button
          LeonButton(
            label: 'CONTINUE',
            icon: Icons.arrow_forward_rounded,
            width: double.infinity,
            onPressed: _nextPage,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── SCREEN 5: STEP 04 / 04: INJURIES & EQUIPMENT (QUESTION 7 + GEAR) ───────
  Widget _buildInjuriesAndEquipmentStep(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
  ) {
    final injuryChips = [
      'ALL CLEAR / NONE',
      'SHOULDERS',
      'LOWER BACK',
      'KNEES',
      'WRISTS / ELBOWS',
    ];

    final equipmentChips = [
      'Full Gym',
      'Barbell & Rack',
      'Dumbbells & Bench',
      'Bodyweight Only',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header
          Center(
            child: Column(
              children: [
                Text(
                  'INJURIES & EQUIPMENT',
                  style: AppTypography.headlineMedium.copyWith(
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Protect vulnerable areas and tailor routines to your gear.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Question 7: Areas to protect / Injuries
          Row(
            children: [
              const Icon(
                Icons.health_and_safety_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AREAS TO PROTECT (INJURIES / RESTRICTIONS)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontSize: 11.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: injuryChips.map((injury) {
              final isNone = injury == 'ALL CLEAR / NONE';
              final isSelected = isNone
                  ? state.injuries.isEmpty
                  : state.injuries.contains(injury);

              return InkWell(
                onTap: () {
                  if (isNone) {
                    notifier.toggleInjury('NONE');
                  } else {
                    notifier.toggleInjury(injury);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isSelected
                        ? (isNone
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.secondary.withValues(alpha: 0.15))
                        : Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: isSelected
                          ? (isNone ? AppColors.primary : AppColors.secondary)
                          : Colors.white.withValues(alpha: 0.12),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    injury,
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected
                          ? (isNone ? AppColors.primary : AppColors.secondary)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.0,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Equipment Profile
          Row(
            children: [
              const Icon(
                Icons.handyman_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AVAILABLE EQUIPMENT',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontSize: 11.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: equipmentChips.map((gear) {
              final isSelected = state.equipment.contains(gear);

              return InkWell(
                onTap: () => notifier.toggleEquipment(gear),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.12),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    gear,
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.0,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Finalize Button
          LeonButton(
            label: 'FINALIZE SETUP',
            icon: Icons.check_rounded,
            width: double.infinity,
            onPressed: _nextPage,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── SCREEN 6: READY / ROUTINE OVERVIEW ─────────────────────────────────────
  Widget _buildReadyStep(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
  ) {
    final split = ref
        .watch(splitsProvider)
        .splits
        .firstWhere(
          (s) => s.id == resolveSplitId(state.preferredSplit),
          orElse: () => fullBodySplit,
        );
    final plan = configureProgramme(
      split,
      UserModel(
        id: 'preview',
        email: '',
        displayName: '',
        createdAt: DateTime.now(),
        trainingDaysPerWeek: state.trainingDaysPerWeek,
        equipment: state.equipment,
      ),
    );
    final units = MeasurementUnits(
      weightUnit: state.isWeightKg ? 'kg' : 'lbs',
      heightUnit: state.isHeightCm ? 'cm' : 'ft',
    );
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'WORKOUT PLAN READY',
          style: AppTypography.headlineMedium.copyWith(letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        GlassCard(
          blur: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan.name, style: AppTypography.headlineSmall),
              Text(
                '${state.trainingDaysPerWeek} training days per week. Workouts rotate in the order below.',
                style: AppTypography.bodyMedium,
              ),
              Text(
                'Goal: ${state.primaryGoal}',
                style: AppTypography.bodySmall,
              ),
              Text(
                state.targetProvided
                    ? 'Target: ${units.weight(state.targetWeight)}'
                    : 'Target weight: Not set',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Injury notes are saved for your review. Exercises are not medically screened; edit the routine to suit your needs.',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        for (final day in plan.workouts)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GlassCard(
              blur: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(day.name, style: AppTypography.headlineSmall),
                  Text(
                    day.exercises.isEmpty
                        ? 'No matching equipment. Add exercises in Routines.'
                        : day.exercises.map((e) => e.exerciseName).join(', '),
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        LeonButton(
          label: 'SAVE SETUP',
          isLoading: _saving,
          onPressed: _completeAndNavigate,
        ),
      ],
    );
  }
}
