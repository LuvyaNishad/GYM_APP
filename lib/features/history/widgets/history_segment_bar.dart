/// Clean, modern segmented control for the LEON History & Performance Center.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class HistorySegmentBar extends StatelessWidget {
  const HistorySegmentBar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _labels = ['SESSIONS', 'OVERLOAD', 'RADAR'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.steel.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < _labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (selectedIndex != i) {
                    HapticFeedback.selectionClick();
                    onChanged(i);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: selectedIndex == i
                        ? AppColors.pureWhite
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: selectedIndex == i
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      _labels[i],
                      style: AppTypography.labelSmall.copyWith(
                        fontFamily: AppTypography.fontDisplay,
                        fontSize: 11.5,
                        fontWeight: selectedIndex == i
                            ? FontWeight.w800
                            : FontWeight.w600,
                        letterSpacing: 1.0,
                        color: selectedIndex == i
                            ? AppColors.onyx
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
