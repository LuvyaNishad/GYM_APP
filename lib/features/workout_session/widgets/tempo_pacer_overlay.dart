import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/tempo_pacer_state.dart';
import '../providers/tempo_pacer_provider.dart';
import 'tempo_sine_wave_painter.dart';

/// Fullscreen, distraction-free OLED tempo pacer overlay designed for
/// hands-free gym operation with dynamic pulsating outer HUD lines,
/// real-time biomechanical wave visualizer, and non-interfering audio/haptic cues.
class TempoPacerOverlay extends ConsumerWidget {
  const TempoPacerOverlay({super.key});

  /// Static helper to display the tempo pacer modal.
  static void show(
    BuildContext context, {
    required String exerciseName,
    required String exerciseId,
    required int setIndex,
    required int targetReps,
    double? weightKg,
    TempoPreset preset = TempoPreset.controlled,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false, // Fullscreen for immersive outer pulsing lines
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      enableDrag: false,
      isDismissible: false,
      builder: (ctx) => _TempoPacerModalLauncher(
        exerciseName: exerciseName,
        exerciseId: exerciseId,
        setIndex: setIndex,
        targetReps: targetReps,
        weightKg: weightKg,
        preset: preset,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tempoPacerProvider);
    final notifier = ref.read(tempoPacerProvider.notifier);

    ref.listen<TempoPacerState>(tempoPacerProvider, (previous, next) {
      if (previous != null && previous.isActive && !next.isActive) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });

    if (!state.isActive) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
        ),
      );
    }

    final isCountdown = state.phase == TempoPhase.countdown;
    final isCompleted = state.phase == TempoPhase.completed;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) notifier.cancel();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── 1. The Dynamic Pulsating Outer Tactical HUD Lines ───────────
            Positioned.fill(
              child: _TacticalPerimeterPulse(state: state),
            ),

            // ── 2. Main Content ──────────────────────────────────────────────
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Navigation & Split Status
                  _buildTopBar(context, state, notifier),

                  const Spacer(flex: 1),

                  // Center Stage: Countdown, Biomechanical Sine Wave, or Complete
                  if (isCountdown)
                    _buildCountdownStage(state, notifier)
                  else if (isCompleted)
                    _buildCompletedStage(state)
                  else
                    _buildActiveWaveStage(context, state),

                  const Spacer(flex: 1),

                  // Bottom Action Bar & Cadence Controls — flush to screen bottom
                  _buildBottomBar(context, state, notifier),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Navigation & Meta Bar ─────────────────────────────────────────────
  Widget _buildTopBar(
    BuildContext context,
    TempoPacerState state,
    TempoPacerNotifier notifier,
  ) {
    final view = View.of(context);
    final physicalTop = view.padding.top / view.devicePixelRatio;
    final safeTop = physicalTop > 0 ? physicalTop : 48.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, safeTop + 10, 16, 8),
      child: Row(
        children: [
          // Close button
          IconButton(
            onPressed: () {
              notifier.cancel();
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.close, color: AppColors.pureWhite, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.charcoal,
              minimumSize: const Size(40, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.steel, width: 1.0),
              ),
            ),
            tooltip: 'Exit tempo pacer',
          ),
          const SizedBox(width: 10),

          // Exercise Title & Load
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.exerciseName?.toUpperCase() ?? 'EXERCISE',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontDisplay,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    height: 1.15,
                    color: AppColors.pureWhite,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  state.weightKg != null
                      ? '${state.weightKg!.toInt()} KG • SET ${(state.setIndex ?? 0) + 1} OF 3'
                      : 'SET ${(state.setIndex ?? 0) + 1} OF 3',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontMono,
                    fontSize: 11.0,
                    color: AppColors.platinum,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Interactive Preset Pill with Selector (2-line layout)
          InkWell(
            onTap: () => _showPresetPicker(context, state, notifier),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.50),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.speed_rounded,
                    size: 15,
                    color: Color(0xFF00E5FF),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.preset.shortTag,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontMono,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00E5FF),
                          letterSpacing: 0.6,
                          height: 1.15,
                        ),
                      ),
                      Text(
                        '${state.preset.eccentricSeconds} ${state.preset.bottomHoldSeconds} ${state.preset.concentricSeconds}',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontMono,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.platinum,
                          letterSpacing: 1.2,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: Color(0xFF00E5FF),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5-Second Get-Ready Countdown Stage ────────────────────────────────────
  Widget _buildCountdownStage(
    TempoPacerState state,
    TempoPacerNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, size: 14, color: Color(0xFF00E5FF)),
                SizedBox(width: 6),
                Text(
                  'HANDS-FREE PREPARATION',
                  style: TextStyle(
                    fontFamily: AppTypography.fontMono,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pureWhite,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Glowing Countdown Digits Ring
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (state.countdownRemaining / 5.0).clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: AppColors.steel.withValues(alpha: 0.35),
                  color: const Color(0xFF00E5FF),
                ),
                Text(
                  '${state.countdownRemaining}',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontMono,
                    fontSize: 84,
                    fontWeight: FontWeight.w900,
                    color: AppColors.pureWhite,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          Text(
            state.phaseLabel,
            style: const TextStyle(
              fontFamily: AppTypography.fontDisplay,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.pureWhite,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.phaseCoachingNote,
            style: const TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 13.5,
              color: AppColors.platinum,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),
          // Instant start button
          TextButton.icon(
            onPressed: () {
              notifier.startSession(
                exerciseName: state.exerciseName ?? 'Exercise',
                exerciseId: state.exerciseId ?? '',
                setIndex: state.setIndex ?? 0,
                targetReps: state.targetReps,
                weightKg: state.weightKg,
                preset: state.preset,
                skipCountdown: true,
              );
            },
            icon: const Icon(Icons.play_arrow, color: Color(0xFF00E5FF), size: 18),
            label: const Text(
              'SKIP PREP • START NOW',
              style: TextStyle(
                fontFamily: AppTypography.fontMono,
                fontSize: 12.0,
                fontWeight: FontWeight.w800,
                color: Color(0xFF00E5FF),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Active Wave Pacer Stage ───────────────────────────────────────────────
  Widget _buildActiveWaveStage(BuildContext context, TempoPacerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Monumental Rep Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'REP ${state.currentRep.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontFamily: AppTypography.fontMono,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  color: AppColors.pureWhite,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ ${state.targetReps.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontFamily: AppTypography.fontMono,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.platinum,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── The Biomechanical Wave Track (Seamless HUD Instrument) ────────
          TempoSineWaveWidget(
            state: state,
            height: 230,
          ),
        ],
      ),
    );
  }

  // ── Set Completed Celebration Stage ───────────────────────────────────────
  Widget _buildCompletedStage(TempoPacerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withValues(alpha: 0.20),
              border: Border.all(color: const Color(0xFF10B981), width: 3.0),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.40),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 52,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'SET COMPLETED!',
            style: TextStyle(
              fontFamily: AppTypography.fontDisplay,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.pureWhite,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${state.currentRep} reps finished on exact tempo.',
            style: const TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 14,
              color: AppColors.platinum,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Starting rest timer automatically...',
            style: TextStyle(
              fontFamily: AppTypography.fontMono,
              fontSize: 12.5,
              color: Color(0xFF00E5FF),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Action & Safety Bar ────────────────────────────────────────────
  Widget _buildBottomBar(
    BuildContext context,
    TempoPacerState state,
    TempoPacerNotifier notifier,
  ) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF161A23).withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: AppColors.steel, width: 1.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hands-Free Auto Advance Notification
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_bottom,
                size: 14,
                color: Color(0xFF00E5FF),
              ),
              const SizedBox(width: 6),
              Text(
                'Auto-completes at ${state.targetReps} reps • Launches rest timer',
                style: const TextStyle(
                  fontFamily: AppTypography.fontMono,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.platinum,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action row
          Row(
            children: [
              // Audio Toggle Icon
              IconButton(
                onPressed: notifier.toggleSound,
                icon: Icon(
                  state.soundEnabled ? Icons.volume_up : Icons.volume_off,
                  color: state.soundEnabled
                      ? AppColors.pureWhite
                      : AppColors.platinum.withValues(alpha: 0.50),
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.charcoal,
                  minimumSize: const Size(46, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.steel),
                  ),
                ),
                tooltip: 'Toggle audio',
              ),
              const SizedBox(width: 8),

              // Haptic Toggle Icon
              IconButton(
                onPressed: notifier.toggleHaptics,
                icon: Icon(
                  Icons.vibration,
                  color: state.hapticsEnabled
                      ? AppColors.pureWhite
                      : AppColors.platinum.withValues(alpha: 0.50),
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.charcoal,
                  minimumSize: const Size(46, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.steel),
                  ),
                ),
                tooltip: 'Toggle haptics',
              ),
              const SizedBox(width: 8),

              // Pause / Resume Button
              Expanded(
                flex: 4,
                child: FilledButton.icon(
                  onPressed: notifier.togglePause,
                  icon: Icon(
                    state.isPaused ? Icons.play_arrow : Icons.pause,
                    size: 18,
                    color: AppColors.onyx,
                  ),
                  label: Text(
                    state.isPaused ? 'RESUME' : 'PAUSE',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontMono,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onyx,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.pureWhite,
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Early Finish & Rest Button
              Expanded(
                flex: 5,
                child: OutlinedButton.icon(
                  onPressed: notifier.finishEarlyAndRest,
                  icon: const Icon(Icons.check, size: 16, color: AppColors.pureWhite),
                  label: Text(
                    'LOG ${state.currentRep} & REST',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontMono,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.pureWhite,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.steel, width: 1.2),
                    backgroundColor: AppColors.charcoal.withValues(alpha: 0.50),
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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

  // ── Preset Picker Modal ───────────────────────────────────────────────────
  void _showPresetPicker(
    BuildContext context,
    TempoPacerState state,
    TempoPacerNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161A23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SELECT REPETITION TEMPO',
                      style: TextStyle(
                        fontFamily: AppTypography.fontDisplay,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pureWhite,
                        letterSpacing: 0.8,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: AppColors.platinum, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...TempoPreset.values.map((preset) {
                  final isSelected = state.preset == preset;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        notifier.setPreset(preset);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.12)
                              : AppColors.charcoal,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00E5FF)
                                : AppColors.steel,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    preset.name,
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontBody,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? AppColors.pureWhite
                                          : AppColors.platinum,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    preset.description,
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontMono,
                                      fontSize: 11.5,
                                      color: isSelected
                                          ? const Color(0xFF00E5FF)
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF00E5FF),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── The Dynamic Tactical Perimeter HUD Pulsing Lines ─────────────────────────
/// Renders animated glowing perimeter rails, corner brackets, and edge ambient bloom
/// that continuously pulse in rhythm with the lifting tempo, giving 100% peripheral
/// visibility across the entire phone display.
class _TacticalPerimeterPulse extends StatefulWidget {
  final TempoPacerState state;

  const _TacticalPerimeterPulse({required this.state});

  @override
  State<_TacticalPerimeterPulse> createState() => _TacticalPerimeterPulseState();
}

class _TacticalPerimeterPulseState extends State<_TacticalPerimeterPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Continuous smooth breathing pulse at ~1.0 Hz
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _TacticalPerimeterPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.phase != widget.state.phase) {
      switch (widget.state.phase) {
        case TempoPhase.eccentric:
          _pulseController.duration = const Duration(milliseconds: 1000);
          _pulseController.repeat(reverse: true);
          break;
        case TempoPhase.bottomHold:
          // Rapid tension micro-pulse during isometric stretch
          _pulseController.duration = const Duration(milliseconds: 300);
          _pulseController.repeat(reverse: true);
          break;
        case TempoPhase.concentric:
          // High-energy fast flash during concentric drive
          _pulseController.duration = const Duration(milliseconds: 350);
          _pulseController.repeat(reverse: true);
          break;
        default:
          _pulseController.duration = const Duration(milliseconds: 1000);
          _pulseController.repeat(reverse: true);
          break;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return CustomPaint(
          painter: _PerimeterPulsePainter(
            phase: widget.state.phase,
            phaseProgress: widget.state.phaseProgress,
            pulseValue: _pulseController.value,
            currentRep: widget.state.currentRep,
            targetReps: widget.state.targetReps,
          ),
        );
      },
    );
  }
}

class _PerimeterPulsePainter extends CustomPainter {
  final TempoPhase phase;
  final double phaseProgress;
  final double pulseValue; // 0.0 -> 1.0 (breathing)
  final int currentRep;
  final int targetReps;

  _PerimeterPulsePainter({
    required this.phase,
    required this.phaseProgress,
    required this.pulseValue,
    required this.currentRep,
    required this.targetReps,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Rep progress: 0.0 at rep 1 to 1.0 at final target rep
    final repProgress = targetReps > 1
        ? ((currentRep - 1) / (targetReps - 1)).clamp(0.0, 1.0)
        : 0.0;

    // Progressive transition from Electric Cyan (rep 1) to Pure White (final rep)
    final cyanToWhite = Color.lerp(
      const Color(0xFF00E5FF),
      AppColors.pureWhite,
      repProgress,
    )!;

    // Peripheral radiance expands with rep fatigue
    final repScale = 1.0 + (repProgress * 0.45);

    // Determine active phase color & pulse dynamics
    final Color baseColor;
    final double baseOpacity;
    final double maxBorderWidth;

    switch (phase) {
      case TempoPhase.countdown:
        baseColor = const Color(0xFF00E5FF);
        baseOpacity = 0.15 + (pulseValue * 0.15);
        maxBorderWidth = 3.0 + (pulseValue * 2.0);
        break;

      case TempoPhase.eccentric:
        baseColor = cyanToWhite;
        final depthMultiplier = 0.20 + (phaseProgress * 0.35);
        baseOpacity = (depthMultiplier + (pulseValue * 0.20)) * (1.0 + repProgress * 0.25);
        maxBorderWidth = (3.5 + (phaseProgress * 3.5) + (pulseValue * 2.0)) * repScale;
        break;

      case TempoPhase.bottomHold:
        baseColor = Color.lerp(const Color(0xFFFFB300), AppColors.pureWhite, repProgress * 0.35)!;
        baseOpacity = 0.40 + (pulseValue * 0.35);
        maxBorderWidth = (5.0 + (pulseValue * 3.0)) * repScale;
        break;

      case TempoPhase.concentric:
        baseColor = AppColors.pureWhite;
        baseOpacity = 0.50 + ((1.0 - phaseProgress) * 0.40);
        maxBorderWidth = (6.0 + ((1.0 - phaseProgress) * 4.0)) * repScale;
        break;

      case TempoPhase.topHold:
        baseColor = cyanToWhite;
        baseOpacity = 0.15 + (pulseValue * 0.15);
        maxBorderWidth = 3.0 * repScale;
        break;

      case TempoPhase.completed:
        baseColor = const Color(0xFF10B981);
        baseOpacity = 0.35 + (pulseValue * 0.30);
        maxBorderWidth = 5.0;
        break;
    }

    // ── Single smooth rounded perimeter ─────────────────────────────────
    const margin = 3.0;
    const radius = 28.0; // smooth curved corners
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(margin, margin, w - margin * 2, h - margin * 2),
      const Radius.circular(radius),
    );

    // Outer bloom glow — expands dynamically with reps
    final bloomPaint = Paint()
      ..color = baseColor.withValues(alpha: (baseOpacity * 0.35).clamp(0.0, 1.0))
      ..strokeWidth = maxBorderWidth * 3.5
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18.0 * repScale);
    canvas.drawRRect(rrect, bloomPaint);

    // Mid glow pass
    final glowPaint = Paint()
      ..color = baseColor.withValues(alpha: (baseOpacity * 0.65).clamp(0.0, 1.0))
      ..strokeWidth = maxBorderWidth * 2.0
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.0 * repScale);
    canvas.drawRRect(rrect, glowPaint);

    // Core laser rail — crisp
    final railPaint = Paint()
      ..color = baseColor.withValues(alpha: baseOpacity.clamp(0.0, 1.0))
      ..strokeWidth = maxBorderWidth
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, railPaint);
  }

  @override
  bool shouldRepaint(covariant _PerimeterPulsePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.phaseProgress != phaseProgress ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.currentRep != currentRep ||
        oldDelegate.targetReps != targetReps;
  }
}

/// Internal launcher widget that starts the tempo provider on mount.
class _TempoPacerModalLauncher extends ConsumerStatefulWidget {
  final String exerciseName;
  final String exerciseId;
  final int setIndex;
  final int targetReps;
  final double? weightKg;
  final TempoPreset preset;

  const _TempoPacerModalLauncher({
    required this.exerciseName,
    required this.exerciseId,
    required this.setIndex,
    required this.targetReps,
    this.weightKg,
    this.preset = TempoPreset.controlled,
  });

  @override
  ConsumerState<_TempoPacerModalLauncher> createState() =>
      _TempoPacerModalLauncherState();
}

class _TempoPacerModalLauncherState
    extends ConsumerState<_TempoPacerModalLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tempoPacerProvider.notifier).startSession(
            exerciseName: widget.exerciseName,
            exerciseId: widget.exerciseId,
            setIndex: widget.setIndex,
            targetReps: widget.targetReps,
            weightKg: widget.weightKg,
            preset: widget.preset,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const TempoPacerOverlay();
  }
}
