/// Footsteps Bento Card for the LEON Dashboard.
///
/// Displays:
/// - Daily step telemetry with formatted count and distance traveled
/// - Goal percentage milestone indicator
/// - 12-hour activity bar chart with rounded pill bars
/// - Dynamic peak indicator with floating high-contrast tooltip badge
/// - Tactical neon lime glassmorphism aesthetics
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/liquid_glass.dart';
import '../models/daily_telemetry_model.dart';

/// Footsteps bento tracker card with interactive hourly activity bars.
class StepsBentoCard extends StatefulWidget {
  const StepsBentoCard({
    super.key,
    required this.telemetry,
    this.onTap,
  });

  /// Daily telemetry source data.
  final DailyTelemetry telemetry;

  /// Optional card tap handler.
  final VoidCallback? onTap;

  @override
  State<StepsBentoCard> createState() => _StepsBentoCardState();
}

class _StepsBentoCardState extends State<StepsBentoCard> {
  static const Color _limeAccent = Color(0xFFCCFF00);
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    // Default selection to the peak hourly step index
    _hoveredIndex = _calculatePeakIndex();
  }

  int _calculatePeakIndex() {
    final list = widget.telemetry.hourlySteps;
    if (list.isEmpty) return 0;
    int peakIndex = 0;
    int maxVal = list[0];
    for (int i = 1; i < list.length; i++) {
      if (list[i] > maxVal) {
        maxVal = list[i];
        peakIndex = i;
      }
    }
    return peakIndex;
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.telemetry;
    final peakIndex = _calculatePeakIndex();
    final activeIndex = _hoveredIndex ?? peakIndex;
    final maxStepsInHour = t.hourlySteps.isNotEmpty
        ? t.hourlySteps.reduce((a, b) => a > b ? a : b)
        : 1;

    final progressPct = (t.stepsProgress * 100).toInt();

    return LiquidGlassContainer(
      borderRadius: 22,
      blurSigma: 24,
      glowColor: _limeAccent.withValues(alpha: 0.14),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      borderWidth: 1.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row: Footsteps Icon + Title + Distance Badge ───────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _limeAccent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _limeAccent.withValues(alpha: 0.4),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _limeAccent.withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.directions_walk_rounded,
                        color: _limeAccent,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'FOOTSTEPS',
                    style: AppTypography.labelSmall.copyWith(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // Distance pill badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me_outlined,
                      size: 11,
                      color: _limeAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${t.distanceKm.toStringAsFixed(2)} km',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Stat Numbers Row: 8,420 Steps ──────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatNumber(t.steps),
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Steps',
                style: AppTypography.titleLarge.copyWith(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Target completion badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _limeAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$progressPct% OF GOAL',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _limeAccent,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Hourly Activity Bar Chart with Floating Peak Badge ────────────
          SizedBox(
            height: 110,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barCount = t.hourlySteps.length;
                const double chartBarAreaHeight = 72;
                final double barWidth =
                    ((constraints.maxWidth - ((barCount - 1) * 8)) / barCount)
                        .clamp(8.0, 22.0);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Bar chart elements
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 22,
                      height: chartBarAreaHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (int i = 0; i < barCount; i++)
                            _buildBar(
                              index: i,
                              value: t.hourlySteps[i],
                              maxValue: maxStepsInHour,
                              width: barWidth,
                              maxHeight: chartBarAreaHeight,
                              isActive: i == activeIndex,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _hoveredIndex = i);
                              },
                            ),
                        ],
                      ),
                    ),

                    // Floating Tooltip Badge above active bar
                    if (activeIndex >= 0 && activeIndex < barCount)
                      _buildFloatingTooltip(
                        activeIndex: activeIndex,
                        barCount: barCount,
                        totalWidth: constraints.maxWidth,
                        barWidth: barWidth,
                        barHeight: ((t.hourlySteps[activeIndex] / maxStepsInHour) *
                                (chartBarAreaHeight - 16)) +
                            12,
                        stepValue: t.hourlySteps[activeIndex],
                      ),

                    // Timeline X-Axis Labels (08:00 - 20:00)
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _TimeLabel('08:00'),
                          _TimeLabel('11:00'),
                          _TimeLabel('14:00'),
                          _TimeLabel('17:00'),
                          _TimeLabel('20:00'),
                        ],
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

  Widget _buildBar({
    required int index,
    required int value,
    required int maxValue,
    required double width,
    required double maxHeight,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final double normalizedHeight =
        ((value / maxValue) * (maxHeight - 16)) + 10;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: width,
        height: normalizedHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isActive
                ? [
                    _limeAccent,
                    _limeAccent.withValues(alpha: 0.85),
                  ]
                : [
                    _limeAccent.withValues(alpha: 0.35),
                    _limeAccent.withValues(alpha: 0.12),
                  ],
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _limeAccent.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  Widget _buildFloatingTooltip({
    required int activeIndex,
    required int barCount,
    required double totalWidth,
    required double barWidth,
    required double barHeight,
    required int stepValue,
  }) {
    // Calculate horizontal center coordinate of the active bar
    final double spacing = (totalWidth - (barCount * barWidth)) / (barCount - 1);
    final double barCenterX =
        (activeIndex * (barWidth + spacing)) + (barWidth / 2);

    const double tooltipWidth = 48.0;
    final double tooltipLeft = (barCenterX - (tooltipWidth / 2))
        .clamp(0.0, totalWidth - tooltipWidth);

    return Positioned(
      left: tooltipLeft,
      bottom: 22 + barHeight + 5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1014),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _limeAccent,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _limeAccent.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              _formatNumber(stepValue),
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: _limeAccent,
                letterSpacing: 0.4,
              ),
            ),
          ),
          // Downward pointer caret
          CustomPaint(
            size: const Size(6, 4),
            painter: _CaretPainter(color: _limeAccent),
          ),
        ],
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: 9.5,
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Downward pointing caret triangle for the tooltip.
class _CaretPainter extends CustomPainter {
  const _CaretPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CaretPainter oldDelegate) =>
      oldDelegate.color != color;
}
