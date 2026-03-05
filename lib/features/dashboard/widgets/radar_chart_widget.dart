import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Placeholder radar chart widget.
///
/// Replace with a real `fl_chart` RadarChart when the analytics data layer
/// is wired. Currently renders a styled placeholder so the UI compiles.
class RadarChartWidget extends StatelessWidget {
  const RadarChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative rings
          _ring(200, AppColors.chartGrid.withOpacity(0.6)),
          _ring(140, AppColors.chartGrid.withOpacity(0.8)),
          _ring(80, AppColors.chartGrid),

          // Placeholder labels
          ..._labels(),

          // "Coming soon" badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
            ),
            child: Text(
              'fl_chart · pending data',
              style: AppTypography.monoSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 0.8),
    ),
  );

  List<Widget> _labels() {
    const labels = [
      (label: 'PUSH', top: 0.0, left: null, bottom: null, right: null),
      (label: 'PULL', top: null, left: null, bottom: 0.0, right: null),
      (label: 'LEGS', top: null, left: 0.0, bottom: null, right: null),
    ];
    return labels
        .map(
          (l) => Positioned(
            top: l.top,
            bottom: l.bottom,
            left: l.left,
            child: Text(l.label, style: AppTypography.labelSmall),
          ),
        )
        .toList();
  }
}
