/// Footsteps Bento Card for the LEON Dashboard.
///
/// Clean, minimal, non-sloppy design without outer glow bleeds:
/// - Daily step telemetry with formatted count and distance traveled
/// - Goal percentage milestone indicator
/// - Compact 12-hour activity bar chart with rounded pill bars
/// - Crisp peak indicator with floating high-contrast tooltip badge
/// - Tactical clean dark aesthetic
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/daily_telemetry_model.dart';

/// Footsteps bento tracker card with clean hourly activity bars.
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
  static const Color _cyanAccent = AppColors.primary;
  static const Color _cardBg = Color(0xFF161A23);
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
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

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header Row: Footsteps Icon + Title + Distance Badge ───────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _cyanAccent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: _cyanAccent.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.directions_walk_rounded,
                        color: _cyanAccent,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'FOOTSTEPS',
                    style: AppTypography.labelSmall.copyWith(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // Distance pill badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
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
                      color: _cyanAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${t.distanceKm.toStringAsFixed(2)} km',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Stat Numbers Row: 8,420 Steps ──────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatNumber(t.steps),
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3, // SKILL2.md §15: Negative optical tracking
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Steps',
                style: AppTypography.titleLarge.copyWith(
                  fontFamily: AppTypography.fontBody,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Target completion badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _cyanAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$progressPct% OF GOAL',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: _cyanAccent,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Compact Hourly Activity Bar Chart with Clean Tooltip ───────────
          SizedBox(
            height: 68,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barCount = t.hourlySteps.length;
                const double chartBarAreaHeight = 44;
                final double barWidth =
                    ((constraints.maxWidth - ((barCount - 1) * 7)) / barCount)
                        .clamp(6.0, 18.0);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Bar chart elements
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 18,
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

                    // Clean Tooltip Badge above active bar (NO blurry glow)
                    if (activeIndex >= 0 && activeIndex < barCount)
                      _buildCleanTooltip(
                        activeIndex: activeIndex,
                        barCount: barCount,
                        totalWidth: constraints.maxWidth,
                        barWidth: barWidth,
                        barHeight: ((t.hourlySteps[activeIndex] / maxStepsInHour) *
                                (chartBarAreaHeight - 12)) +
                            8,
                        stepValue: t.hourlySteps[activeIndex],
                      ),

                    // Timeline X-Axis Labels (08:00 - 20:00) with Apple HIG floor & contrast
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
        ((value / maxValue) * (maxHeight - 12)) + 7;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent, // Expands hit testing to full column height
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        alignment: Alignment.bottomCenter,
        height: maxHeight,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: width,
          height: normalizedHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? _cyanAccent : _cyanAccent.withValues(alpha: 0.25),
          ),
        ),
      ),
    );
  }

  Widget _buildCleanTooltip({
    required int activeIndex,
    required int barCount,
    required double totalWidth,
    required double barWidth,
    required double barHeight,
    required int stepValue,
  }) {
    final double spacing = (totalWidth - (barCount * barWidth)) / (barCount - 1);
    final double barCenterX =
        (activeIndex * (barWidth + spacing)) + (barWidth / 2);

    const double tooltipWidth = 52.0;
    final double tooltipLeft = (barCenterX - (tooltipWidth / 2))
        .clamp(0.0, totalWidth - tooltipWidth);

    return Positioned(
      left: tooltipLeft,
      bottom: 18 + barHeight + 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1218),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _cyanAccent,
                width: 1.0,
              ),
            ),
            child: Text(
              _formatNumber(stepValue),
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11.0,
                fontWeight: FontWeight.w700,
                color: _cyanAccent,
                letterSpacing: 0.3,
              ),
            ),
          ),
          // Downward pointer caret
          CustomPaint(
            size: const Size(6, 3.5),
            painter: _CaretPainter(color: _cyanAccent),
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
        fontSize: 11.0,
        color: AppColors.textSecondary,
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
