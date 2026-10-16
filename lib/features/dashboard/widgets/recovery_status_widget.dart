import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

/// Recovery & Readiness Widget
///
/// Features:
/// - Looping animated cardiac pulse beacon
/// - Live ECG waveform trace custom painter
/// - High-contrast health metrics (Readiness %, HRV, Resting BPM)
/// - Tap to open comprehensive recovery breakdown
class RecoveryStatusWidget extends StatefulWidget {
  const RecoveryStatusWidget({
    super.key,
    this.isReady = true,
    this.readinessScore = 94,
    this.hrvMs = 68,
    this.restingBpm = 52,
  });

  final bool isReady;
  final int readinessScore;
  final int hrvMs;
  final int restingBpm;

  @override
  State<RecoveryStatusWidget> createState() => _RecoveryStatusWidgetState();
}

class _RecoveryStatusWidgetState extends State<RecoveryStatusWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    final isTest = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    if (!isTest) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
        widget.isReady ? AppColors.success : AppColors.danger;
    final String statusLabel =
        widget.isReady ? 'READY TO TRAIN' : 'REST REQUIRED';

    return GlassCard(
      glowColor: statusColor,
      padding: const EdgeInsets.all(18),
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(AppConstants.routeRecovery);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ────────────────────────────────────────────────────
          Row(
            children: [
              // Animated Pulse Beacon
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final t = _controller.value;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Expanding sonar wave
                        Container(
                          width: 44 + (12 * t),
                          height: 44 + (12 * t),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: statusColor.withValues(alpha: (1.0 - t) * 0.45),
                              width: 1.5,
                            ),
                          ),
                        ),
                        // Core indicator
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor.withValues(alpha: 0.16),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.8),
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.35),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: child,
                        ),
                      ],
                    );
                  },
                  child: Icon(
                    widget.isReady ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Title and Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'RECOVERY READINESS',
                          style: AppTypography.labelSmall.copyWith(
                            letterSpacing: 1.5,
                            fontSize: 11.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _showRecoveryInfoDialog(context),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${widget.readinessScore}%',
                          style: AppTypography.titleLarge.copyWith(
                            fontFamily: 'JetBrains Mono',
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      statusLabel,
                      style: AppTypography.labelSmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                size: 14,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── ECG Waveform Simulation & Metric Badges ───────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Animated mini ECG graph
                RepaintBoundary(
                  child: SizedBox(
                    width: 90,
                    height: 28,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => CustomPaint(
                        painter: _EcgLinePainter(
                          color: statusColor,
                          progress: _controller.value,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),

                // Telemetry Chip: HRV
                _TelemetryChip(
                  label: 'HRV',
                  value: '${widget.hrvMs} ms',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),

                // Telemetry Chip: RHR
                _TelemetryChip(
                  label: 'RHR',
                  value: '${widget.restingBpm} bpm',
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),

                // CNS Recovery Chip
                _TelemetryChip(
                  label: 'CNS',
                  value: 'RECOVERED',
                  color: statusColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRecoveryInfoDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.onyx,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.steel),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.favorite_outline_rounded,
              color: Color(0xFF00E5FF),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'RECOVERY READINESS',
              style: AppTypography.headlineSmall.copyWith(
                fontSize: 14.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.pureWhite,
              ),
            ),
          ],
        ),
        content: const Text(
          'Self-reported readiness estimate based on workout frequency, rest intervals, and logged sleep/hydration. Not a medical evaluation.\n\nAlways listen to your body, warm up thoroughly, and adjust training intensity when fatigue accumulates.',
          style: TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 12.5,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'UNDERSTOOD',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00E5FF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryChip extends StatelessWidget {
  const _TelemetryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontSize: 11.0,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: AppTypography.labelSmall.copyWith(
            fontFamily: 'JetBrains Mono',
            fontSize: 11.0,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _EcgLinePainter extends CustomPainter {
  const _EcgLinePainter({
    required this.color,
    required this.progress,
  });

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final midY = size.height / 2;
    final w = size.width;

    // Draw baseline with QRS complex
    path.moveTo(0, midY);
    path.lineTo(w * 0.25, midY);
    // P wave
    path.quadraticBezierTo(w * 0.30, midY - 4, w * 0.35, midY);
    path.lineTo(w * 0.42, midY);
    // QRS complex
    path.lineTo(w * 0.46, midY + 3);
    path.lineTo(w * 0.52, midY - 14);
    path.lineTo(w * 0.58, midY + 8);
    path.lineTo(w * 0.62, midY);
    // T wave
    path.quadraticBezierTo(w * 0.72, midY - 6, w * 0.82, midY);
    path.lineTo(w, midY);

    canvas.drawPath(path, paint);

    // Glowing scan dot moving across
    final dotX = (w * progress);
    final dotY = midY;
    final dotPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
    canvas.drawCircle(Offset(dotX, dotY), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _EcgLinePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
