import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/active_session_state.dart';

/// Modal bottom sheet allowing users to fine-tune effort via RIR and RPE simultaneously.
class EffortPickerModal extends StatefulWidget {
  const EffortPickerModal({
    super.key,
    required this.initialRir,
    required this.initialRpe,
    required this.onSaved,
  });

  final double initialRir;
  final double initialRpe;
  final void Function(double rir, double rpe) onSaved;

  @override
  State<EffortPickerModal> createState() => _EffortPickerModalState();
}

class _EffortPickerModalState extends State<EffortPickerModal> {
  late double _currentRir;
  late double _currentRpe;

  @override
  void initState() {
    super.initState();
    _currentRir = widget.initialRir;
    _currentRpe = widget.initialRpe;
  }

  void _updateFromRir(double rir) {
    setState(() {
      _currentRir = rir.clamp(0.0, 5.0);
      _currentRpe = rpeFromRir(_currentRir);
    });
  }

  void _nudgeRir(double delta) {
    _updateFromRir((_currentRir + delta).clamp(0.0, 5.0));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF141722),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EFFORT SELECTOR',
                style: AppTypography.headlineSmall.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Display readout: RIR and RPE together
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${_currentRir.toStringAsFixed(1)} RIR',
                      style: AppTypography.monoMedium.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _currentRir <= 0.5 ? AppColors.warning : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reps In Reserve',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 11.0,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                Column(
                  children: [
                    Text(
                      'RPE ${_currentRpe.toStringAsFixed(1)}',
                      style: AppTypography.monoMedium.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Perceived Exertion',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 11.0,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Preset Chips Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip(
                rir: 0.0,
                label: '0 RIR · RPE 10 (Failure)',
                isWarning: true,
              ),
              _buildPresetChip(
                rir: 1.0,
                label: '1 RIR · RPE 9 (Very Hard)',
              ),
              _buildPresetChip(
                rir: 2.0,
                label: '2 RIR · RPE 8 (Sweet Spot)',
              ),
              _buildPresetChip(
                rir: 3.0,
                label: '3 RIR · RPE 7 (Moderate)',
              ),
              _buildPresetChip(
                rir: 4.0,
                label: '4+ RIR · RPE ≤6 (Warm-up)',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stepper Fine-tuning (0.5 increments)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepperButton(
                icon: Icons.remove,
                onPressed: () => _nudgeRir(-0.5),
                tooltip: 'Increase effort (-0.5 RIR)',
              ),
              const SizedBox(width: 20),
              Text(
                'Adjust ±0.5',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 20),
              _buildStepperButton(
                icon: Icons.add,
                onPressed: () => _nudgeRir(0.5),
                tooltip: 'Decrease effort (+0.5 RIR)',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Confirm button
          FilledButton(
            onPressed: () {
              widget.onSaved(_currentRir, _currentRpe);
              Navigator.of(context).maybePop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'CONFIRM',
              style: AppTypography.labelSmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip({
    required double rir,
    required String label,
    bool isWarning = false,
  }) {
    final isSelected = (_currentRir - rir).abs() < 0.25;
    final color = isWarning ? AppColors.warning : AppColors.primary;

    return InkWell(
      onTap: () => _updateFromRir(rir),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.monoSmall.copyWith(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? (isWarning ? AppColors.warning : Colors.white) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}
