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

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      expandedInsets: EdgeInsets.zero,
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: 0, label: _SegmentLabel('SESSIONS')),
        ButtonSegment(value: 1, label: _SegmentLabel('OVERLOAD')),
        ButtonSegment(value: 2, label: _SegmentLabel('RADAR')),
      ],
      selected: {selectedIndex},
      onSelectionChanged: (selection) {
        HapticFeedback.selectionClick();
        onChanged(selection.single);
      },
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(44, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 4),
        ),
        side: const WidgetStatePropertyAll(BorderSide.none),
        textStyle: const WidgetStatePropertyAll(AppTypography.labelSmall),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.16)
              : AppColors.charcoal,
        ),
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
    );
  }
}
