import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/active_session_state.dart';
import '../providers/active_session_provider.dart';
import 'tempo_pacer_overlay.dart';

/// Clean, high-contrast Set Table for an active workout exercise.
///
/// Features:
/// - 4 uncluttered columns: SET, KG, REPS, LOG
/// - Direct numeric keyboard input (no fiddly + / - steppers)
/// - Auto-fills weights and reps from previous session baseline
/// - Subtle micro-subtext displaying previous baseline under input fields (min 11.0 pt)
/// - Single-tap text selection on focus for instant frictionless overwriting
/// - Option A two-stage unilateral logging with 1-tap L->R sync
/// - Clean bottom actions: + ADD SET and + WARMUP (Plate Calc & Tempo in 3-dot menu)
class ExerciseSetTable extends ConsumerWidget {
  const ExerciseSetTable({
    super.key,
    required this.exercise,
  });

  final ActiveExerciseState exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(activeSessionProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Table Header: 4 Clean Columns (No excess chips, no clutter)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.charcoal,
            border: Border(
              bottom: BorderSide(
                color: AppColors.steel,
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: exercise.isUnilateral ? 64 : 40,
                child: Text(
                  exercise.isUnilateral ? 'SET/SIDE' : 'SET',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.platinum,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: Center(
                  child: Text(
                    'KG',
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.platinum,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Center(
                  child: Text(
                    'REPS',
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.platinum,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(
                width: 44,
                child: Center(
                  child: Text(
                    'LOG',
                    style: TextStyle(
                      fontFamily: AppTypography.fontMono,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.platinum,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Set Rows
        for (int i = 0; i < exercise.sets.length; i++) ...[
          if (i > 0)
            const Divider(
              height: 1,
              color: AppColors.steel,
            ),
          if (exercise.isUnilateral)
            _UnilateralSetRowWidget(
              key: ValueKey('${exercise.exerciseId}_uni_$i'),
              exerciseId: exercise.exerciseId,
              set: exercise.sets[i],
              setIndex: i,
              notifier: notifier,
              onShowSetOptions: () => _showSetOptionsSheet(context, i, notifier),
            )
          else
            _BilateralSetRowWidget(
              key: ValueKey('${exercise.exerciseId}_bi_$i'),
              exerciseId: exercise.exerciseId,
              set: exercise.sets[i],
              setIndex: i,
              notifier: notifier,
              onShowSetOptions: () => _showSetOptionsSheet(context, i, notifier),
            ),
        ],

        // Bottom Action Controls (Clean + ADD SET & + WARMUP)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => notifier.addSet(exercise.exerciseId),
                  icon: const Icon(Icons.add, size: 18, color: AppColors.pureWhite),
                  label: Text(
                    'ADD SET',
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pureWhite,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.steel, width: 1.2),
                    backgroundColor: AppColors.charcoal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(0, 46),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showWarmupOptionsSheet(context, exercise.exerciseId, notifier),
                icon: const Icon(Icons.fitness_center, size: 16, color: AppColors.platinum),
                label: Text(
                  '+ WARMUP',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.platinum,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.steel),
                  backgroundColor: AppColors.charcoal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  minimumSize: const Size(0, 46),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSetOptionsSheet(
    BuildContext context,
    int setIndex,
    ActiveSessionNotifier notifier,
  ) {
    final set = exercise.sets[setIndex];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.onyx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.steel),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SET ${set.setNumber} OPTIONS',
                      style: AppTypography.titleLarge.copyWith(
                        fontFamily: AppTypography.fontDisplay,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pureWhite,
                        letterSpacing: 0.8,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.platinum, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'SET TYPE CLASSIFICATION',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.platinum,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSetTypeChip(
                      label: 'Normal (${set.setNumber})',
                      isSelected: set.setType == ActiveSetType.normal,
                      onTap: () {
                        notifier.updateSetValues(
                          exerciseId: exercise.exerciseId,
                          setIndex: setIndex,
                          setType: ActiveSetType.normal,
                        );
                        Navigator.of(ctx).pop();
                      },
                    ),
                    _buildSetTypeChip(
                      label: 'Warm-up (W)',
                      isSelected: set.setType == ActiveSetType.warmup,
                      onTap: () {
                        notifier.updateSetValues(
                          exerciseId: exercise.exerciseId,
                          setIndex: setIndex,
                          setType: ActiveSetType.warmup,
                        );
                        Navigator.of(ctx).pop();
                      },
                    ),
                    _buildSetTypeChip(
                      label: 'Drop Set (D)',
                      isSelected: set.setType == ActiveSetType.dropSet,
                      onTap: () {
                        notifier.updateSetValues(
                          exerciseId: exercise.exerciseId,
                          setIndex: setIndex,
                          setType: ActiveSetType.dropSet,
                        );
                        Navigator.of(ctx).pop();
                      },
                    ),
                    _buildSetTypeChip(
                      label: 'Failure (F)',
                      isSelected: set.setType == ActiveSetType.failure,
                      onTap: () {
                        notifier.updateSetValues(
                          exerciseId: exercise.exerciseId,
                          setIndex: setIndex,
                          setType: ActiveSetType.failure,
                          rir: 0.0,
                          rpe: 10.0,
                        );
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.steel),
                ListTile(
                  leading: const Icon(Icons.speed, color: Color(0xFF00E5FF)),
                  title: Text(
                    'Start Tempo Pacer for Set ${set.setNumber}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Hands-free sine wave • ${set.reps} reps',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 11.5,
                      color: AppColors.platinum,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    TempoPacerOverlay.show(
                      context,
                      exerciseName: exercise.name,
                      exerciseId: exercise.exerciseId,
                      setIndex: setIndex,
                      targetReps: set.reps,
                      weightKg: set.weightKg,
                    );
                  },
                ),
                if (exercise.sets.length > 1)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                    title: Text(
                      'Delete Set ${set.setNumber}',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.danger),
                    ),
                    onTap: () {
                      notifier.removeSet(exercise.exerciseId, setIndex);
                      Navigator.of(ctx).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSetTypeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.pureWhite.withValues(alpha: 0.15)
              : AppColors.charcoal,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.pureWhite : AppColors.steel,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.monoSmall.copyWith(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.pureWhite : AppColors.platinum,
          ),
        ),
      ),
    );
  }

  void _showWarmupOptionsSheet(
    BuildContext context,
    String exerciseId,
    ActiveSessionNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.onyx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.steel),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ADD WARMUP SETS',
                      style: AppTypography.titleLarge.copyWith(
                        fontFamily: AppTypography.fontDisplay,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pureWhite,
                        letterSpacing: 0.8,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.platinum, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.charcoal,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.steel),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '1x',
                      style: TextStyle(
                        fontFamily: AppTypography.fontMono,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pureWhite,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                  title: Text(
                    'Quick Warmup (50% Load)',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    '1 set • 10 reps at half working weight',
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 11.5,
                      color: AppColors.platinum,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    notifier.addSingleWarmupSet(exerciseId);
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.charcoal,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.steel),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '3x',
                      style: TextStyle(
                        fontFamily: AppTypography.fontMono,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pureWhite,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                  title: Text(
                    '3-Stage Ramp Up (40% • 60% • 80%)',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    '3 sets • Progressive neuromuscular ramp',
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 11.5,
                      color: AppColors.platinum,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    notifier.addWarmupSets(exerciseId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Bilateral Set Row with direct numeric typing & subtle previous baselines.
class _BilateralSetRowWidget extends StatefulWidget {
  const _BilateralSetRowWidget({
    super.key,
    required this.exerciseId,
    required this.set,
    required this.setIndex,
    required this.notifier,
    required this.onShowSetOptions,
  });

  final String exerciseId;
  final ActiveSetState set;
  final int setIndex;
  final ActiveSessionNotifier notifier;
  final VoidCallback onShowSetOptions;

  @override
  State<_BilateralSetRowWidget> createState() => _BilateralSetRowWidgetState();
}

class _BilateralSetRowWidgetState extends State<_BilateralSetRowWidget> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late FocusNode _weightFocusNode;
  late FocusNode _repsFocusNode;

  @override
  void initState() {
    super.initState();
    _weightFocusNode = FocusNode();
    _repsFocusNode = FocusNode();

    // Auto-fill initial values from last session if unassigned
    final initialWeight = widget.set.weightKg > 0
        ? widget.set.weightKg
        : (widget.set.previousWeightKg ?? 20.0);
    final initialReps = widget.set.reps > 0
        ? widget.set.reps
        : (widget.set.previousReps ?? 10);

    if (widget.set.weightKg <= 0 && widget.set.previousWeightKg != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.notifier.updateSetValues(
          exerciseId: widget.exerciseId,
          setIndex: widget.setIndex,
          weightKg: initialWeight,
          reps: initialReps,
        );
      });
    }

    _weightController = TextEditingController(text: _formatWeight(initialWeight));
    _repsController = TextEditingController(text: '$initialReps');

    _weightFocusNode.addListener(() {
      if (_weightFocusNode.hasFocus) {
        _weightController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _weightController.text.length,
        );
      }
    });

    _repsFocusNode.addListener(() {
      if (_repsFocusNode.hasFocus) {
        _repsController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _repsController.text.length,
        );
      }
    });
  }

  String _formatWeight(double w) {
    if (w >= 10 && w % 1 == 0) {
      return '${w.toInt()}';
    }
    return w.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }

  @override
  void didUpdateWidget(covariant _BilateralSetRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_weightFocusNode.hasFocus && widget.set.weightKg > 0) {
      final formatted = _formatWeight(widget.set.weightKg);
      if (_weightController.text != formatted) {
        _weightController.text = formatted;
      }
    }
    if (!_repsFocusNode.hasFocus && widget.set.reps > 0) {
      final formattedReps = '${widget.set.reps}';
      if (_repsController.text != formattedReps) {
        _repsController.text = formattedReps;
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _weightFocusNode.dispose();
    _repsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final set = widget.set;
    final isCompleted = set.isCompleted;

    final prevWeightText = set.previousWeightKg != null
        ? '${_formatWeight(set.previousWeightKg!)} kg'
        : '—';
    final prevRepsText = set.previousReps != null ? '${set.previousReps}' : '—';

    return Container(
      color: isCompleted
          ? AppColors.steel.withValues(alpha: 0.15)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SET Index badge
          SizedBox(
            width: 40,
            height: 46,
            child: InkWell(
              onTap: widget.onShowSetOptions,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: set.setType == ActiveSetType.failure
                        ? AppColors.pureWhite
                        : (set.setType == ActiveSetType.dropSet
                            ? const Color(0xFF00E5FF)
                            : (set.isWarmup ? AppColors.platinum : AppColors.steel)),
                    width: set.setType == ActiveSetType.failure ||
                            set.setType == ActiveSetType.dropSet
                        ? 1.5
                        : 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  set.setType == ActiveSetType.warmup
                      ? 'W'
                      : (set.setType == ActiveSetType.dropSet
                          ? 'D'
                          : (set.setType == ActiveSetType.failure
                              ? 'F'
                              : '${set.setNumber}')),
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                    color: set.setType == ActiveSetType.dropSet
                        ? const Color(0xFF00E5FF)
                        : (set.isWarmup
                            ? AppColors.platinum
                            : AppColors.pureWhite),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 2. KG Direct Numeric Input
          Expanded(
            flex: 5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.charcoal,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _weightFocusNode.hasFocus
                          ? const Color(0xFF00E5FF)
                          : (isCompleted
                              ? AppColors.pureWhite.withValues(alpha: 0.4)
                              : AppColors.steel),
                      width: _weightFocusNode.hasFocus ? 1.5 : 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: _weightController,
                    focusNode: _weightFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    textAlign: TextAlign.center,
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pureWhite,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontFamily: AppTypography.fontMono,
                        fontSize: 15.0,
                        color: AppColors.platinum.withValues(alpha: 0.4),
                      ),
                    ),
                    onTap: () {
                      _weightController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _weightController.text.length,
                      );
                    },
                    onChanged: (text) {
                      final parsed = double.tryParse(text);
                      if (parsed != null) {
                        widget.notifier.updateSetValues(
                          exerciseId: widget.exerciseId,
                          setIndex: widget.setIndex,
                          weightKg: parsed,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 3),
                // Subtle previous baseline text (min 11.0 pt, tap to autofill)
                InkWell(
                  onTap: () {
                    if (set.previousWeightKg != null) {
                      final formatted = _formatWeight(set.previousWeightKg!);
                      _weightController.text = formatted;
                      widget.notifier.updateSetValues(
                        exerciseId: widget.exerciseId,
                        setIndex: widget.setIndex,
                        weightKg: set.previousWeightKg!,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    child: Text(
                      'prev: $prevWeightText',
                      style: AppTypography.monoSmall.copyWith(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.platinum,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 3. REPS Direct Numeric Input
          Expanded(
            flex: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.charcoal,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _repsFocusNode.hasFocus
                          ? const Color(0xFF00E5FF)
                          : (isCompleted
                              ? AppColors.pureWhite.withValues(alpha: 0.4)
                              : AppColors.steel),
                      width: _repsFocusNode.hasFocus ? 1.5 : 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: _repsController,
                    focusNode: _repsFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textAlign: TextAlign.center,
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pureWhite,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontFamily: AppTypography.fontMono,
                        fontSize: 15.0,
                        color: AppColors.platinum.withValues(alpha: 0.4),
                      ),
                    ),
                    onTap: () {
                      _repsController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _repsController.text.length,
                      );
                    },
                    onChanged: (text) {
                      final parsed = int.tryParse(text);
                      if (parsed != null) {
                        widget.notifier.updateSetValues(
                          exerciseId: widget.exerciseId,
                          setIndex: widget.setIndex,
                          reps: parsed,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 3),
                // Subtle previous baseline text (min 11.0 pt, tap to autofill)
                InkWell(
                  onTap: () {
                    if (set.previousReps != null) {
                      _repsController.text = '${set.previousReps}';
                      widget.notifier.updateSetValues(
                        exerciseId: widget.exerciseId,
                        setIndex: widget.setIndex,
                        reps: set.previousReps!,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    child: Text(
                      'prev: $prevRepsText',
                      style: AppTypography.monoSmall.copyWith(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.platinum,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 4. LOG Checkmark Button (Min 44x44 pt touch target)
          SizedBox(
            width: 44,
            height: 46,
            child: Center(
              child: IconButton(
                onPressed: () {
                  try {
                    HapticFeedback.mediumImpact();
                  } catch (_) {}
                  widget.notifier.logSet(
                    exerciseId: widget.exerciseId,
                    setIndex: widget.setIndex,
                  );
                },
                icon: AnimatedScale(
                  scale: isCompleted ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                    color: isCompleted ? AppColors.primary : AppColors.platinum,
                    size: 26,
                  ),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                tooltip: isCompleted ? 'Mark incomplete' : 'Log set',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Unilateral Set Row with side sub-rows (L & R), direct numeric typing, and 1-tap L->R sync.
class _UnilateralSetRowWidget extends StatefulWidget {
  const _UnilateralSetRowWidget({
    super.key,
    required this.exerciseId,
    required this.set,
    required this.setIndex,
    required this.notifier,
    required this.onShowSetOptions,
  });

  final String exerciseId;
  final ActiveSetState set;
  final int setIndex;
  final ActiveSessionNotifier notifier;
  final VoidCallback onShowSetOptions;

  @override
  State<_UnilateralSetRowWidget> createState() => _UnilateralSetRowWidgetState();
}

class _UnilateralSetRowWidgetState extends State<_UnilateralSetRowWidget> {
  late TextEditingController _leftWeightController;
  late TextEditingController _leftRepsController;
  late TextEditingController _rightWeightController;
  late TextEditingController _rightRepsController;

  late FocusNode _leftWeightFocus;
  late FocusNode _leftRepsFocus;
  late FocusNode _rightWeightFocus;
  late FocusNode _rightRepsFocus;

  @override
  void initState() {
    super.initState();
    _leftWeightFocus = FocusNode();
    _leftRepsFocus = FocusNode();
    _rightWeightFocus = FocusNode();
    _rightRepsFocus = FocusNode();

    final leftW = widget.set.weightKg > 0
        ? widget.set.weightKg
        : (widget.set.previousWeightKg ?? 20.0);
    final leftR = widget.set.reps > 0
        ? widget.set.reps
        : (widget.set.previousReps ?? 10);

    final rightW = (widget.set.weightKgRight ?? widget.set.weightKg) > 0
        ? (widget.set.weightKgRight ?? widget.set.weightKg)
        : (widget.set.previousWeightKgRight ?? widget.set.previousWeightKg ?? leftW);
    final rightR = (widget.set.repsRight ?? widget.set.reps) > 0
        ? (widget.set.repsRight ?? widget.set.reps)
        : (widget.set.previousRepsRight ?? widget.set.previousReps ?? leftR);

    _leftWeightController = TextEditingController(text: _formatWeight(leftW));
    _leftRepsController = TextEditingController(text: '$leftR');
    _rightWeightController = TextEditingController(text: _formatWeight(rightW));
    _rightRepsController = TextEditingController(text: '$rightR');

    _leftWeightFocus.addListener(() {
      if (_leftWeightFocus.hasFocus) {
        _leftWeightController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _leftWeightController.text.length,
        );
      }
    });
    _leftRepsFocus.addListener(() {
      if (_leftRepsFocus.hasFocus) {
        _leftRepsController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _leftRepsController.text.length,
        );
      }
    });
    _rightWeightFocus.addListener(() {
      if (_rightWeightFocus.hasFocus) {
        _rightWeightController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _rightWeightController.text.length,
        );
      }
    });
    _rightRepsFocus.addListener(() {
      if (_rightRepsFocus.hasFocus) {
        _rightRepsController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _rightRepsController.text.length,
        );
      }
    });
  }

  String _formatWeight(double w) {
    if (w >= 10 && w % 1 == 0) {
      return '${w.toInt()}';
    }
    return w.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }

  @override
  void didUpdateWidget(covariant _UnilateralSetRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_leftWeightFocus.hasFocus && widget.set.weightKg > 0) {
      final f = _formatWeight(widget.set.weightKg);
      if (_leftWeightController.text != f) _leftWeightController.text = f;
    }
    if (!_leftRepsFocus.hasFocus && widget.set.reps > 0) {
      final f = '${widget.set.reps}';
      if (_leftRepsController.text != f) _leftRepsController.text = f;
    }
    final rW = widget.set.weightKgRight ?? widget.set.weightKg;
    if (!_rightWeightFocus.hasFocus && rW > 0) {
      final f = _formatWeight(rW);
      if (_rightWeightController.text != f) _rightWeightController.text = f;
    }
    final rR = widget.set.repsRight ?? widget.set.reps;
    if (!_rightRepsFocus.hasFocus && rR > 0) {
      final f = '$rR';
      if (_rightRepsController.text != f) _rightRepsController.text = f;
    }
  }

  @override
  void dispose() {
    _leftWeightController.dispose();
    _leftRepsController.dispose();
    _rightWeightController.dispose();
    _rightRepsController.dispose();
    _leftWeightFocus.dispose();
    _leftRepsFocus.dispose();
    _rightWeightFocus.dispose();
    _rightRepsFocus.dispose();
    super.dispose();
  }

  void _syncLeftToRight() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
    _rightWeightController.text = _leftWeightController.text;
    _rightRepsController.text = _leftRepsController.text;
    widget.notifier.updateSetValues(
      exerciseId: widget.exerciseId,
      setIndex: widget.setIndex,
      weightKgRight: widget.set.weightKg,
      repsRight: widget.set.reps,
    );
  }

  @override
  Widget build(BuildContext context) {
    final set = widget.set;
    final isFullyCompleted = set.isLeftCompleted && set.isRightCompleted;

    final prevLeftW = set.previousWeightKg != null ? _formatWeight(set.previousWeightKg!) : '—';
    final prevLeftR = set.previousReps != null ? '${set.previousReps}' : '—';

    final prevRightW = (set.previousWeightKgRight ?? set.previousWeightKg) != null
        ? _formatWeight((set.previousWeightKgRight ?? set.previousWeightKg)!)
        : '—';
    final prevRightR = (set.previousRepsRight ?? set.previousReps) != null
        ? '${(set.previousRepsRight ?? set.previousReps)!}'
        : '—';

    return Container(
      color: isFullyCompleted
          ? AppColors.steel.withValues(alpha: 0.15)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Spanning SET Index Badge
          SizedBox(
            width: 36,
            height: 104,
            child: InkWell(
              onTap: widget.onShowSetOptions,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: set.setType == ActiveSetType.failure
                        ? AppColors.pureWhite
                        : (set.setType == ActiveSetType.dropSet
                            ? const Color(0xFF00E5FF)
                            : (set.isWarmup ? AppColors.platinum : AppColors.steel)),
                    width: set.setType == ActiveSetType.failure ||
                            set.setType == ActiveSetType.dropSet
                        ? 1.5
                        : 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  set.setType == ActiveSetType.warmup
                      ? 'W'
                      : (set.setType == ActiveSetType.dropSet
                          ? 'D'
                          : (set.setType == ActiveSetType.failure
                              ? 'F'
                              : '${set.setNumber}')),
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                    color: set.setType == ActiveSetType.dropSet
                        ? const Color(0xFF00E5FF)
                        : (set.isWarmup
                            ? AppColors.platinum
                            : AppColors.pureWhite),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Sub-rows for L and R
          Expanded(
            child: Column(
              children: [
                // ── LEFT SUB-ROW ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // L Badge
                    Container(
                      width: 26,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: set.isLeftCompleted
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                            : AppColors.charcoal,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: set.isLeftCompleted
                              ? const Color(0xFF00E5FF)
                              : AppColors.steel,
                        ),
                      ),
                      child: Text(
                        'L',
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w800,
                          color: set.isLeftCompleted
                              ? const Color(0xFF00E5FF)
                              : AppColors.pureWhite,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Left Weight (KG)
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.charcoal,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _leftWeightFocus.hasFocus
                                    ? const Color(0xFF00E5FF)
                                    : (set.isLeftCompleted
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
                                        : AppColors.steel),
                                width: _leftWeightFocus.hasFocus ? 1.5 : 1.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: TextField(
                              controller: _leftWeightController,
                              focusNode: _leftWeightFocus,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                              textAlign: TextAlign.center,
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pureWhite,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                                hintText: '0',
                              ),
                              onTap: () {
                                _leftWeightController.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: _leftWeightController.text.length,
                                );
                              },
                              onChanged: (text) {
                                final p = double.tryParse(text);
                                if (p != null) {
                                  widget.notifier.updateSetValues(
                                    exerciseId: widget.exerciseId,
                                    setIndex: widget.setIndex,
                                    weightKg: p,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'prev: $prevLeftW kg',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                              color: AppColors.platinum,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Left Reps
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.charcoal,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _leftRepsFocus.hasFocus
                                    ? const Color(0xFF00E5FF)
                                    : (set.isLeftCompleted
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
                                        : AppColors.steel),
                                width: _leftRepsFocus.hasFocus ? 1.5 : 1.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: TextField(
                              controller: _leftRepsController,
                              focusNode: _leftRepsFocus,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              textAlign: TextAlign.center,
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pureWhite,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                                hintText: '0',
                              ),
                              onTap: () {
                                _leftRepsController.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: _leftRepsController.text.length,
                                );
                              },
                              onChanged: (text) {
                                final p = int.tryParse(text);
                                if (p != null) {
                                  widget.notifier.updateSetValues(
                                    exerciseId: widget.exerciseId,
                                    setIndex: widget.setIndex,
                                    reps: p,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'prev: $prevLeftR',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                              color: AppColors.platinum,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Left Log Checkmark
                    SizedBox(
                      width: 44,
                      height: 46,
                      child: Center(
                        child: IconButton(
                          onPressed: () {
                            try {
                              HapticFeedback.mediumImpact();
                            } catch (_) {}
                            widget.notifier.logSetSide(
                              exerciseId: widget.exerciseId,
                              setIndex: widget.setIndex,
                              isLeft: true,
                            );
                          },
                          icon: AnimatedScale(
                            scale: set.isLeftCompleted ? 1.08 : 1.0,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutBack,
                            child: Icon(
                              set.isLeftCompleted
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color: set.isLeftCompleted
                                  ? const Color(0xFF00E5FF)
                                  : AppColors.platinum,
                              size: 26,
                            ),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          tooltip: 'Log Left side',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── RIGHT SUB-ROW ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // R Badge with Sync Button Stacked
                    InkWell(
                      onTap: _syncLeftToRight,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 26,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: set.isRightCompleted
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                              : AppColors.charcoal,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: set.isRightCompleted
                                ? const Color(0xFF00E5FF)
                                : AppColors.steel,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'R',
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: set.isRightCompleted
                                    ? const Color(0xFF00E5FF)
                                    : AppColors.pureWhite,
                              ),
                            ),
                            const Icon(
                              Icons.sync_rounded,
                              size: 11,
                              color: Color(0xFF00E5FF),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Right Weight (KG)
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.charcoal,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _rightWeightFocus.hasFocus
                                    ? const Color(0xFF00E5FF)
                                    : (set.isRightCompleted
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
                                        : AppColors.steel),
                                width: _rightWeightFocus.hasFocus ? 1.5 : 1.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: TextField(
                              controller: _rightWeightController,
                              focusNode: _rightWeightFocus,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                              textAlign: TextAlign.center,
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pureWhite,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                                hintText: '0',
                              ),
                              onTap: () {
                                _rightWeightController.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: _rightWeightController.text.length,
                                );
                              },
                              onChanged: (text) {
                                final p = double.tryParse(text);
                                if (p != null) {
                                  widget.notifier.updateSetValues(
                                    exerciseId: widget.exerciseId,
                                    setIndex: widget.setIndex,
                                    weightKgRight: p,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'prev: $prevRightW kg',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                              color: AppColors.platinum,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Right Reps
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.charcoal,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _rightRepsFocus.hasFocus
                                    ? const Color(0xFF00E5FF)
                                    : (set.isRightCompleted
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
                                        : AppColors.steel),
                                width: _rightRepsFocus.hasFocus ? 1.5 : 1.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: TextField(
                              controller: _rightRepsController,
                              focusNode: _rightRepsFocus,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              textAlign: TextAlign.center,
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pureWhite,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                                hintText: '0',
                              ),
                              onTap: () {
                                _rightRepsController.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: _rightRepsController.text.length,
                                );
                              },
                              onChanged: (text) {
                                final p = int.tryParse(text);
                                if (p != null) {
                                  widget.notifier.updateSetValues(
                                    exerciseId: widget.exerciseId,
                                    setIndex: widget.setIndex,
                                    repsRight: p,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'prev: $prevRightR',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                              color: AppColors.platinum,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Right Log Checkmark
                    SizedBox(
                      width: 44,
                      height: 46,
                      child: Center(
                        child: IconButton(
                          onPressed: () {
                            try {
                              HapticFeedback.mediumImpact();
                            } catch (_) {}
                            widget.notifier.logSetSide(
                              exerciseId: widget.exerciseId,
                              setIndex: widget.setIndex,
                              isLeft: false,
                            );
                          },
                          icon: AnimatedScale(
                            scale: set.isRightCompleted ? 1.08 : 1.0,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutBack,
                            child: Icon(
                              set.isRightCompleted
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color: set.isRightCompleted
                                  ? const Color(0xFF00E5FF)
                                  : AppColors.platinum,
                              size: 26,
                            ),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          tooltip: 'Log Right side',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone Rest Duration Picker Sheet callable from anywhere (e.g. 3-dot menu or quick action).
void showRestDurationPicker(
  BuildContext context,
  ActiveExerciseState exercise,
  ActiveSessionNotifier notifier,
) {
  const durations = [30, 45, 60, 90, 120, 150, 180, 240];
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.onyx,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      side: BorderSide(color: AppColors.steel),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'REST INTERVAL FOR ${exercise.name.toUpperCase()}',
                      style: AppTypography.titleLarge.copyWith(
                        fontFamily: AppTypography.fontDisplay,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pureWhite,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.platinum, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: durations.map((seconds) {
                  final isSelected = exercise.restDurationSeconds == seconds;
                  final minutes = seconds ~/ 60;
                  final rem = seconds % 60;
                  final timeLabel = minutes > 0
                      ? (rem > 0 ? '$minutes min $rem s' : '$minutes min')
                      : '$seconds s';

                  return InkWell(
                    onTap: () {
                      notifier.updateExerciseRestDuration(exercise.exerciseId, seconds);
                      Navigator.of(ctx).pop();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.pureWhite.withValues(alpha: 0.15)
                            : AppColors.charcoal,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.pureWhite : AppColors.steel,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Text(
                        timeLabel,
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 12.0,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? AppColors.pureWhite : AppColors.platinum,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    },
  );
}
