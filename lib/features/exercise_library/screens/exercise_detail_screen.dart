import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../workout_session/providers/active_session_provider.dart';
import '../../workout_session/providers/exercise_favorites_provider.dart';
import '../models/exercise_library_item.dart';
import '../providers/exercise_library_provider.dart';
import '../widgets/add_to_routine_dialog.dart';

/// Full-screen Exercise Detail and Form Guide screen.
///
/// Features:
/// - Movement breakdown and equipment profile
/// - Primary & secondary muscle anatomy tags
/// - Step-by-step execution guide with coaching cues
/// - Personal best & 1RM metric highlights
/// - Direct 1-tap "ADD TO ROUTINE" or "START WORKOUT" actions
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({
    super.key,
    this.exercise,
    this.exerciseId,
    this.fromSession = false,
  });

  final ExerciseLibraryItem? exercise;
  final String? exerciseId;
  final bool fromSession;

  static const ExerciseLibraryItem _fallbackExercise = ExerciseLibraryItem(
    id: 'barbell-bench-press',
    name: 'Barbell Bench Press',
    category: 'Chest',
    description:
        'Horizontal compound barbell pressing movement for chest, front deltoids, and triceps.',
    primaryMuscles: ['pectoralis major', 'pectoralis minor'],
    secondaryMuscles: ['anterior deltoids', 'triceps brachii'],
    equipment: ['barbell', 'flat bench'],
    primaryEquipment: 'barbell',
    movementPattern: 'horizontal_push',
    exerciseType: 'compound',
    difficulty: 'intermediate',
    tags: ['chest', 'strength', 'compound'],
    instructions: [
      'Lie flat on the bench with eyes positioned directly under the barbell.',
      'Grip the bar slightly wider than shoulder-width with wrists straight.',
      'Unrack with locked arms and settle the bar directly over mid-chest.',
      'Lower the bar with controlled tempo until light contact with sternum.',
      'Drive powerfully upward pressing feet into the floor until lock.',
    ],
    coachingNotes:
        'Retract and depress shoulder blades throughout the entire set. Never flare elbows to 90 degrees.',
    defaultRestSeconds: 120,
    alternatives: ['dumbbell-bench-press', 'incline-dumbbell-press'],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve exercise from argument, repository, or fallback
    ExerciseLibraryItem resolved = exercise ?? _fallbackExercise;
    if (exercise == null && exerciseId != null) {
      final catalog = ref.watch(exerciseLibraryProvider);
      final found = catalog.allExercises.firstWhere(
        (e) => e.id == exerciseId,
        orElse: () => _fallbackExercise,
      );
      resolved = found;
    }

    final alternatives = ref
        .read(exerciseLibraryProvider.notifier)
        .getAlternatives(resolved.id);
    final favorite = ref.watch(exerciseFavoritesProvider).contains(resolved.name);
    final activeSession = ref.watch(
      activeSessionProvider.select(
        (s) => (
          s.isActive,
          s.exercises.any(
            (e) => e.name.toLowerCase() == resolved.name.toLowerCase(),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.pureWhite,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'EXERCISE GUIDE',
          style: AppTypography.titleLarge.copyWith(
            fontFamily: AppTypography.fontDisplay,
            fontSize: 15.0,
            fontWeight: FontWeight.w800,
            color: AppColors.pureWhite,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: favorite ? 'Remove favorite' : 'Add favorite',
            icon: Icon(
              favorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: AppColors.platinum,
              size: 22,
            ),
            onPressed: () async {
              try {
                await ref.read(exerciseFavoritesProvider.notifier).toggle(resolved.name);
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.charcoal,
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    'Could not save favorite. Try again.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.pureWhite,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              );
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── 1. Hero Title & Movement Pattern Card ───────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.steel.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              resolved.category.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: AppTypography.fontMono,
                                fontSize: 11.0,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              resolved.exerciseType.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: AppTypography.fontMono,
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                color: AppColors.platinum,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${resolved.defaultRestSeconds}s REST',
                              style: const TextStyle(
                                fontFamily: AppTypography.fontMono,
                                fontSize: 11.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.platinum,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        resolved.name,
                        style: AppTypography.headlineLarge.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pureWhite,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        resolved.description,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 13.0,
                          color: AppColors.platinum,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── 2. Muscle Anatomy Targets ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.steel.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ANATOMICAL TARGETS',
                        style: AppTypography.titleLarge.copyWith(
                          fontFamily: AppTypography.fontDisplay,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pureWhite,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PRIMARY',
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontBody,
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: resolved.primaryMuscles.map((m) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        m.toUpperCase(),
                                        style: const TextStyle(
                                          fontFamily: AppTypography.fontMono,
                                          fontSize: 11.0,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SECONDARY',
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontBody,
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.platinum,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: resolved.secondaryMuscles.map((m) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.06,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        m.toUpperCase(),
                                        style: const TextStyle(
                                          fontFamily: AppTypography.fontMono,
                                          fontSize: 11.0,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.platinum,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── 3. Step-by-Step Form Execution ─────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.steel.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'FORM EXECUTION CHECKLIST',
                            style: AppTypography.titleLarge.copyWith(
                              fontFamily: AppTypography.fontDisplay,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w800,
                              color: AppColors.pureWhite,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      for (
                        int i = 0;
                        i < resolved.instructions.length;
                        i++
                      ) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.steel,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontMono,
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.pureWhite,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                resolved.instructions[i],
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 13.0,
                                  color: AppColors.pureWhite,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (i < resolved.instructions.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: AppColors.steel),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── 4. Coaching Notes / Pro Cues ────────────────────────────
                if (resolved.coachingNotes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.tips_and_updates_outlined,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'COACHING TIP ● KEY CUE',
                              style: AppTypography.titleLarge.copyWith(
                                fontFamily: AppTypography.fontDisplay,
                                fontSize: 12.0,
                                fontWeight: FontWeight.w800,
                                color: AppColors.warning,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          resolved.coachingNotes,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 13.0,
                            color: AppColors.pureWhite,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),

                // ── 5. 1RM Calculator ─────────────────────────────────────────
                const Exercise1RmCalculatorCard(),
                const SizedBox(height: 14),

                // ── 6. Equipment Variations / Alternatives ───────────────────
                if (alternatives.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.charcoal,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.steel.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EQUIPMENT ALTERNATIVES',
                          style: AppTypography.titleLarge.copyWith(
                            fontFamily: AppTypography.fontDisplay,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w800,
                            color: AppColors.pureWhite,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: alternatives.map((alt) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.steel,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alt.name,
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                fontSize: 13.0,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.pureWhite,
                                              ),
                                        ),
                                        Text(
                                          alt.equipmentDisplay.toUpperCase(),
                                          style: const TextStyle(
                                            fontFamily: AppTypography.fontMono,
                                            fontSize: 11.0,
                                            color: AppColors.platinum,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ExerciseDetailScreen(
                                            exercise: alt,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'VIEW',
                                      style: AppTypography.labelSmall.copyWith(
                                        fontSize: 11.0,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          border: const Border(
            top: BorderSide(color: AppColors.steel, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Add to routine
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  showDialog(
                    context: context,
                    builder: (ctx) => AddToRoutineDialog(exercise: resolved),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.steel),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(0, 46),
                ),
                child: Text(
                  'ADD TO ROUTINE',
                  style: AppTypography.labelSmall.copyWith(
                    fontFamily: AppTypography.fontDisplay,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pureWhite,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Start Now
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  if (fromSession && activeSession.$2) {
                    Navigator.of(context).pop();
                    return;
                  }
                  final session = ref.read(activeSessionProvider);
                  final notifier = ref.read(activeSessionProvider.notifier);

                  if (!session.isActive) {
                    notifier.startEmptySession(splitName: 'Custom Workout');
                  }

                  final activeEx = resolved.toActiveExercise(
                    defaultWeightKg: 0,
                  );
                  notifier.addExercise(activeEx);

                  if (fromSession) {
                    Navigator.of(context).pop();
                  } else {
                    context.push(AppConstants.routeWorkoutSession);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onyx,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(0, 46),
                ),
                child: Text(
                  fromSession && activeSession.$2
                      ? 'RETURN TO WORKOUT'
                      : activeSession.$1
                      ? 'ADD TO WORKOUT'
                      : 'START WORKOUT',
                  style: AppTypography.labelSmall.copyWith(
                    fontFamily: AppTypography.fontDisplay,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onyx,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Interactive 1RM Calculator widget based on Epley Formula.
class Exercise1RmCalculatorCard extends StatefulWidget {
  const Exercise1RmCalculatorCard({
    super.key,
    this.initialWeight = 100.0,
    this.initialReps = 10,
  });

  final double initialWeight;
  final int initialReps;

  @override
  State<Exercise1RmCalculatorCard> createState() =>
      _Exercise1RmCalculatorCardState();
}

class _Exercise1RmCalculatorCardState extends State<Exercise1RmCalculatorCard> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  double _calculated1Rm = 133.3;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.initialWeight.toStringAsFixed(0),
    );
    _repsController = TextEditingController(
      text: widget.initialReps.toString(),
    );
    _recalculate();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final reps = int.tryParse(_repsController.text) ?? 0;
    if (weight > 0 && reps > 0) {
      if (reps == 1) {
        setState(() => _calculated1Rm = weight);
      } else {
        setState(() => _calculated1Rm = weight * (1.0 + (reps / 30.0)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.steel.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calculate_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'ESTIMATED 1RM CALCULATOR',
                style: AppTypography.titleLarge.copyWith(
                  fontFamily: AppTypography.fontDisplay,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.pureWhite,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Epley Formula: 1RM = Weight × (1 + Reps / 30)',
            style: const TextStyle(
              fontFamily: AppTypography.fontMono,
              fontSize: 11.0,
              color: AppColors.platinum,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight (kg)',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 11.5,
                        color: AppColors.platinum,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => _recalculate(),
                      style: const TextStyle(
                        fontFamily: AppTypography.fontMono,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pureWhite,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.steel),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.steel),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reps Completed',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 11.5,
                        color: AppColors.platinum,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _recalculate(),
                      style: const TextStyle(
                        fontFamily: AppTypography.fontMono,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pureWhite,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.steel),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.steel),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ESTIMATED 1RM:',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontMono,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '${_calculated1Rm.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontMono,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
