import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Tactical drum wheel picker with cylindrical snap scrolling, focus line guides,
/// and luminous cyan active readout.
class DrumWheelPicker extends StatefulWidget {
  const DrumWheelPicker({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    required this.onChanged,
    this.unit = '',
    this.itemHeight = 60.0,
    this.diameterRatio = 1.6,
  });

  final int minValue;
  final int maxValue;
  final int initialValue;
  final ValueChanged<int> onChanged;
  final String unit;
  final double itemHeight;
  final double diameterRatio;

  @override
  State<DrumWheelPicker> createState() => _DrumWheelPickerState();
}

class _DrumWheelPickerState extends State<DrumWheelPicker> {
  late final FixedExtentScrollController _controller;
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue.clamp(widget.minValue, widget.maxValue);
    final initialIndex = _selectedValue - widget.minValue;
    _controller = FixedExtentScrollController(initialItem: initialIndex);
  }

  @override
  void didUpdateWidget(covariant DrumWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      final target = widget.initialValue.clamp(widget.minValue, widget.maxValue);
      if (target != _selectedValue) {
        _selectedValue = target;
        final targetIndex = target - widget.minValue;
        _controller.jumpToItem(targetIndex);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.maxValue - widget.minValue + 1;

    return Center(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              spreadRadius: -5,
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 20,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Focus Indicator Guideline with side dots
            Positioned(
              top: (280 - widget.itemHeight) / 2,
              left: 20,
              right: 20,
              height: widget.itemHeight,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  color: AppColors.primary.withValues(alpha: 0.04),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scroll Wheel
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.25, 0.75, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: ListWheelScrollView.useDelegate(
                controller: _controller,
                itemExtent: widget.itemHeight,
                perspective: 0.003,
                diameterRatio: widget.diameterRatio,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  final val = widget.minValue + index;
                  setState(() => _selectedValue = val);
                  widget.onChanged(val);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: count,
                  builder: (context, index) {
                    final val = widget.minValue + index;
                    final isSelected = val == _selectedValue;

                    return Center(
                      child: Text(
                        '$val',
                        style: isSelected
                            ? AppTypography.dataLarge.copyWith(
                                fontSize: 36,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  const Shadow(
                                    color: AppColors.primary,
                                    blurRadius: 16,
                                  ),
                                ],
                              )
                            : AppTypography.dataLarge.copyWith(
                                fontSize: 26,
                                color: Colors.white.withValues(alpha: 0.3),
                                fontWeight: FontWeight.w400,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Optional Unit Tag at the bottom of the chamber
            if (widget.unit.isNotEmpty)
              Positioned(
                bottom: 28,
                child: Text(
                  widget.unit.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.7),
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
