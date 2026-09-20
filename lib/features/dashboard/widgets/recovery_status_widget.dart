import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

/// Recovery status ECG-style widget.
///
/// Displays a coloured status indicator (Green = Ready, Red = Rest) with a
/// continuously pulsing ring — a one-shot [TweenAnimationBuilder] only pulses
/// once, so this drives a looping [AnimationController] instead.
class RecoveryStatusWidget extends StatefulWidget {
  const RecoveryStatusWidget({super.key, this.isReady = true});

  final bool isReady;

  @override
  State<RecoveryStatusWidget> createState() => _RecoveryStatusWidgetState();
}

class _RecoveryStatusWidgetState extends State<RecoveryStatusWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _pulse = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

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
        widget.isReady ? 'READY TO TRAIN' : 'REST RECOMMENDED';
    final IconData statusIcon =
        widget.isReady ? Icons.favorite : Icons.favorite_border;

    return GlassCard(
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final t = 0.6 + _pulse.value * 0.4; // 0.6 → 1.0
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: statusColor.withValues(alpha: t),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.4 * _pulse.value),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RECOVERY STATUS', style: AppTypography.labelSmall),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: AppTypography.titleLarge.copyWith(color: statusColor),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
