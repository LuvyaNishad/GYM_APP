import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/aeon_logo.dart';
import '../../../core/widgets/entry_widgets.dart';
import '../../../core/utils/measurement_units.dart';
import '../../../models/user_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/persistence_feedback.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../workout_builder/models/programme_configuration.dart';
import '../../workout_builder/providers/splits_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_top_bar.dart';

/// Opening, four focused setup steps, then the actual routine preview.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _saving = false;
  final _biometricsForm = GlobalKey<FormState>();

  Duration get _pageTransitionDuration =>
      MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 280);

  Future<void> _goToPage(int page) async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    // A tap on the outgoing screen must not activate the incoming Continue.
    final transition = Future<void>.delayed(_pageTransitionDuration);
    await persistWithFeedback(
      context,
      () => ref.read(onboardingProvider.notifier).saveProgress(page),
      message:
          'Could not save your progress. Your choices are still here. Try again.',
    );
    await transition;
    if (mounted) setState(() => _saving = false);
  }

  void _nextPage() {
    final page = ref.read(onboardingProvider).currentPage;
    if (page == 2 && !(_biometricsForm.currentState?.validate() ?? true)) {
      return;
    }
    if (page < OnboardingState.totalPages - 1) _goToPage(page + 1);
  }

  void _previousPage() {
    final page = ref.read(onboardingProvider).currentPage;
    if (page == 1 && ref.read(onboardingCompleteProvider)) {
      GoRouter.maybeOf(context)?.go(AppConstants.routeProfile);
      return;
    }
    if (page > 0) _goToPage(page - 1);
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
      final auth = ref.read(authProvider);
      final needsAccount =
          ref.read(accountChoicePendingProvider) &&
          !(auth.status == AuthStatus.authenticated && !auth.isAnonymous);
      GoRouter.maybeOf(context)?.go(
        needsAccount ? AppConstants.routeLogin : AppConstants.routeDashboard,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final page = state.currentPage;
    final content = switch (page) {
      0 => _buildSplash(context),
      1 => _goals(state, notifier),
      2 => _buildBiometricsStep(context, state, notifier),
      3 => _schedule(state, notifier),
      4 => _equipment(state, notifier),
      _ => _ready(state),
    };
    return PopScope(
      canPop: page == 0 && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _previousPage();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: page == 0 && !_saving ? () => _goToPage(1) : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1, -.8),
                radius: 1.4,
                colors: [
                  page == 0 ? AppColors.background : const Color(0xFF1C2735),
                  AppColors.background,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      if (page > 0)
                        OnboardingTopBar(
                          stepLabel: page == 5 ? 'YOUR PLAN' : state.stepLabel,
                          progress: state.stepProgress,
                          onBack: _saving ? null : _previousPage,
                          onSkip: page < 5 && !_saving
                              ? () => _goToPage(5)
                              : null,
                        ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: _pageTransitionDuration,
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween(
                                    begin: const Offset(.035, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.topCenter,
                            fit: StackFit.expand,
                            children: [
                              for (final outgoing in previous)
                                IgnorePointer(
                                  child: ExcludeSemantics(child: outgoing),
                                ),
                              if (current != null) current,
                            ],
                          ),
                          child: AbsorbPointer(
                            key: ValueKey(page),
                            absorbing: _saving,
                            child: page == 0
                                ? content
                                : SingleChildScrollView(
                                    key: PageStorageKey('setup-step-$page'),
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      28,
                                      24,
                                      24,
                                    ),
                                    child: BackdropGroup(child: content),
                                  ),
                          ),
                        ),
                      ),
                      if (!ref.watch(onboardingCompleteProvider))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: TextButton(
                            onPressed: _saving
                                ? null
                                : () {
                                    FocusScope.of(context).unfocus();
                                    context.push(AppConstants.routeLogin);
                                  },
                            child: const Text(
                              'Already have an account? Sign in',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      if (page > 0)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                          child: EntryButton(
                            label: page == 5
                                ? (ref.watch(onboardingCompleteProvider)
                                      ? 'Save setup'
                                      : 'Save & continue')
                                : page == 4
                                ? 'See my plan'
                                : 'Continue',
                            busy: _saving,
                            primary: true,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                            ),
                            onPressed: page == 5
                                ? _completeAndNavigate
                                : _nextPage,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: EntryStyle.heading)),
        const SizedBox(height: 12),
        Text(subtitle, style: AppTypography.bodyMedium),
      ],
    ),
  );

  Widget _label(String title) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      title,
      style: AppTypography.labelSmall.copyWith(letterSpacing: 2),
    ),
  );

  Widget _goals(OnboardingState state, OnboardingNotifier notifier) {
    const goals = [
      (
        'BUILD MUSCLE',
        'Build muscle',
        'Size & definition',
        Icons.fitness_center_rounded,
      ),
      ('STRENGTH', 'Get stronger', 'Lift with confidence', Icons.bolt_rounded),
      (
        'LOSE FAT',
        'Lose fat',
        'Train consistently',
        Icons.local_fire_department_outlined,
      ),
      (
        'ATHLETIC',
        'Stay athletic',
        'Move & feel better',
        Icons.motion_photos_on_rounded,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'What moves you?',
          'Choose your focus. We can adjust it as you grow.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final single =
                MediaQuery.textScalerOf(context).scale(16) > 22 ||
                constraints.maxWidth < 290;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final goal in goals)
                  SizedBox(
                    width: single
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 12) / 2,
                    child: _SetupChoice(
                      title: goal.$2,
                      description: goal.$3,
                      icon: goal.$4,
                      selected:
                          state.primaryGoal == goal.$1 ||
                          (goal.$1 == 'STRENGTH' &&
                              state.primaryGoal == 'INCREASE STRENGTH'),
                      onTap: () => notifier.setPrimaryGoal(goal.$1),
                      spacious: true,
                    ),
                  ),
              ],
            );
          },
        ),
        _label('YOUR EXPERIENCE'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in [
              ('BEGINNER', 'New to lifting'),
              ('INTERMEDIATE', 'Some experience'),
              ('ADVANCED', 'Experienced'),
            ])
              _chip(
                item.$2,
                state.experienceLevel.toUpperCase() == item.$1,
                () => notifier.setExperienceLevel(item.$1),
              ),
          ],
        ),
      ],
    );
  }

  Widget _schedule(
    OnboardingState state,
    OnboardingNotifier notifier,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(
        'Make room for you.',
        'Build a weekly rhythm that fits your life.',
      ),
      const Text('Training days per week', style: AppTypography.bodyLarge),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final day in [3, 4, 5, 6])
            _chip(
              '$day days',
              state.trainingDaysPerWeek == day,
              () => notifier.setTrainingDays(day),
              numeric: true,
            ),
        ],
      ),
      _label('TRAINING SPLIT'),
      for (final routine in ref.watch(splitsProvider).customSplits)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SetupChoice(
            title: routine.name,
            description:
                'Keep the exercises and workout days in your saved routine.',
            selected: state.preferredSplit == routine.id,
            onTap: () => notifier.setPreferredSplit(routine.id),
          ),
        ),
      for (final split in [
        ('PPL', 'Push / Pull / Legs', 'A different muscle group each session.'),
        (
          'Upper/Lower',
          'Upper / Lower',
          'Alternate upper and lower body sessions.',
        ),
        ('Full Body', 'Full Body', 'Train across muscle groups each session.'),
        ('Bro Split', 'Bro Split', 'Focus on one body part each session.'),
        (
          'Arnold Split',
          'Arnold Split',
          'Chest & back, shoulders & arms, then legs.',
        ),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SetupChoice(
            title: split.$2,
            description: split.$3,
            selected:
                resolveSplitId(state.preferredSplit) ==
                resolveSplitId(split.$1),
            onTap: () => notifier.setPreferredSplit(split.$1),
          ),
        ),
    ],
  );

  Widget _equipment(
    OnboardingState state,
    OnboardingNotifier notifier,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(
        'Your space. Your pace.',
        'Your available equipment shapes the exercises in your plan.',
      ),
      const Text(
        'What can you train with?',
        style: AppTypography.headlineSmall,
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 10,
        children: [
          for (final item in [
            'Full Gym',
            'Barbell',
            'Dumbbells',
            'Bench',
            'Pull-up Bar',
            'Bodyweight Only',
          ])
            _chip(
              item,
              state.equipment.contains(item),
              () => notifier.toggleEquipment(item),
            ),
        ],
      ),
      _label('ANY AREAS TO BE MINDFUL OF?'),
      const Text(
        'Optional notes for your review. These do not automatically filter exercises.',
        style: AppTypography.bodyMedium,
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 10,
        children: [
          _chip(
            'None',
            state.injuries.isEmpty,
            () => notifier.toggleInjury('NONE'),
          ),
          for (final item in [
            'SHOULDERS',
            'LOWER BACK',
            'KNEES',
            'WRISTS / ELBOWS',
          ])
            _chip(
              item.toLowerCase(),
              state.injuries.contains(item),
              () => notifier.toggleInjury(item),
            ),
        ],
      ),
    ],
  );

  Widget _chip(
    String title,
    bool selected,
    VoidCallback onTap, {
    bool numeric = false,
  }) => ChoiceChip(
    label: Text(title),
    selected: selected,
    onSelected: (_) {
      HapticFeedback.selectionClick();
      onTap();
    },
    selectedColor: const Color(0xFF163740),
    backgroundColor: const Color(0xFF1C2530),
    checkmarkColor: EntryStyle.accent,
    side: BorderSide(
      color: selected ? EntryStyle.accent : const Color(0xFF46515F),
    ),
    labelStyle: (numeric ? AppTypography.monoSmall : AppTypography.bodyMedium)
        .copyWith(
          color: selected ? Colors.white : AppColors.textSecondary,
          fontSize: 14,
        ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  Widget _ready(OnboardingState state) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          'A starting point.\nMade for you.',
          'Here is your routine. You can change it anytime.',
        ),
        GlassCard(
          blur: true,
          sharedBackdrop: true,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.fitness_center_rounded,
                color: EntryStyle.accent,
                size: 28,
              ),
              const SizedBox(height: 18),
              Text(plan.name, style: AppTypography.headlineLarge),
              const SizedBox(height: 8),
              Text(
                '${state.trainingDaysPerWeek} training days per week',
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                state.equipment.isEmpty
                    ? 'Bodyweight exercises'
                    : state.equipment.join(' · '),
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
        _label('YOUR SESSIONS'),
        for (final day in plan.workouts.where((d) => !d.isRestDay))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              blur: true,
              sharedBackdrop: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(day.name, style: AppTypography.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    day.exercises.isEmpty
                        ? 'No matching equipment. Add exercises in Routines.'
                        : day.exercises.map((e) => e.exerciseName).join(' · '),
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        if (state.injuries.isNotEmpty)
          const Text(
            'Injury notes are saved for your review. Exercises are not medically screened; edit the routine to suit your needs.',
            style: AppTypography.bodySmall,
          ),
      ],
    );
  }

  Widget _buildSplash(BuildContext context) {
    return Center(
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
    );
  }

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
      decoration: EntryStyle.input(label, helper: 'Optional'),
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
      padding: EdgeInsets.zero,
      child: Form(
        key: _biometricsForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your starting point.', style: EntryStyle.heading),
            const SizedBox(height: 8),
            const Text(
              'Leave any field empty if you do not want to provide it.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final metric in [true, false])
                  _chip(
                    metric ? 'kg / cm' : 'lbs / ft-in',
                    state.isWeightKg == metric,
                    () {
                      notifier.setWeightUnit(metric);
                      notifier.setHeightUnit(metric);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(
              blur: true,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: state.ageProvided ? '${state.age}' : '',
                    keyboardType: TextInputType.number,
                    decoration: EntryStyle.input(
                      'Age (optional)',
                      helper: 'Used for calorie estimates',
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
                  const SizedBox(height: 20),
                  input(
                    'Height (${units.heightInputLabel})',
                    'height',
                    state.heightProvided
                        ? units.heightFromCm(state.height)
                        : null,
                    (value) => notifier.setHeight(units.heightToCm(value)),
                    units.heightFromCm(250),
                  ),
                  const SizedBox(height: 20),
                  input(
                    'Current weight (${units.weightLabel})',
                    'weight',
                    state.weightProvided
                        ? units.weightFromKg(state.weight)
                        : null,
                    (value) => notifier.setWeight(units.weightToKg(value)),
                    units.weightFromKg(500),
                  ),
                  const SizedBox(height: 20),
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
          ],
        ),
      ),
    );
  }
}

class _SetupChoice extends StatelessWidget {
  const _SetupChoice({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    this.icon,
    this.spacious = false,
  });
  final String title, description;
  final bool selected, spacious;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: GlassCard(
      blur: true,
      sharedBackdrop: true,
      borderRadius: 20,
      padding: EdgeInsets.all(spacious ? 18 : 20),
      backgroundColor: selected
          ? const Color(0xFF16313B)
          : const Color(0xFF202A36),
      borderColor: selected ? EntryStyle.accent : const Color(0xFF667180),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (spacious) ...[
            Row(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: selected ? EntryStyle.accent : AppColors.platinum,
                ),
                const Spacer(),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 18,
                  color: selected ? EntryStyle.accent : AppColors.platinum,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headlineSmall.copyWith(fontSize: 15),
                ),
              ),
              if (!spacious && selected)
                const Icon(
                  Icons.check_rounded,
                  color: EntryStyle.accent,
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(description, style: AppTypography.bodySmall),
        ],
      ),
    ),
  );
}
