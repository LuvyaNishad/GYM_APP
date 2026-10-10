import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Available Olympic standard plate denominations in kilograms.
const List<double> kOlympicPlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];

/// Calculates plate counts per barbell side given a total target weight.
Map<double, int> calculatePlatesPerSide({
  required double totalWeightKg,
  double barWeightKg = 20.0,
  List<double> availablePlates = kOlympicPlates,
}) {
  if (totalWeightKg <= barWeightKg) return {};

  // Round to nearest 0.01 to avoid precision floating issues
  var remainingPerSide =
      double.parse(((totalWeightKg - barWeightKg) / 2.0).toStringAsFixed(2));
  final breakdown = <double, int>{};

  for (final plate in availablePlates) {
    if (remainingPerSide >= plate) {
      final count = (remainingPerSide / plate).floor();
      if (count > 0) {
        breakdown[plate] = count;
        remainingPerSide =
            double.parse((remainingPerSide - (count * plate)).toStringAsFixed(2));
      }
    }
  }

  return breakdown;
}

Color getPlateColor(double plateKg) {
  if (plateKg >= 25.0) return const Color(0xFFEF4444); // Red
  if (plateKg >= 20.0) return const Color(0xFF3B82F6); // Blue
  if (plateKg >= 15.0) return const Color(0xFFEAB308); // Yellow
  if (plateKg >= 10.0) return const Color(0xFF22C55E); // Green
  if (plateKg >= 5.0) return const Color(0xFFF8FAFC); // White
  if (plateKg >= 2.5) return const Color(0xFF64748B); // Slate
  return const Color(0xFFCBD5E1); // Silver
}

/// Interactive Barbell Plate Calculator modal.
class PlateCalculatorModal extends StatefulWidget {
  const PlateCalculatorModal({
    super.key,
    required this.initialTotalWeightKg,
    this.initialBarWeightKg = 20.0,
  });

  final double initialTotalWeightKg;
  final double initialBarWeightKg;

  @override
  State<PlateCalculatorModal> createState() => _PlateCalculatorModalState();
}

class _PlateCalculatorModalState extends State<PlateCalculatorModal> {
  late double _totalWeightKg;
  late double _barWeightKg;

  @override
  void initState() {
    super.initState();
    _totalWeightKg = widget.initialTotalWeightKg;
    _barWeightKg = widget.initialBarWeightKg;
  }

  void _adjustWeight(double delta) {
    setState(() {
      _totalWeightKg = (_totalWeightKg + delta).clamp(_barWeightKg, 500.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final platesPerSide = calculatePlatesPerSide(
      totalWeightKg: _totalWeightKg,
      barWeightKg: _barWeightKg,
    );

    final perSideWeight = (_totalWeightKg - _barWeightKg).clamp(0.0, 999.0) / 2.0;

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
                'PLATE CALCULATOR',
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

          // Target Weight Display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${_totalWeightKg.toStringAsFixed(1)} KG',
                  style: AppTypography.monoLarge.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${perSideWeight.toStringAsFixed(1)} KG PER SIDE (+ ${_barWeightKg.toInt()} KG BAR)',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.5,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Barbell Visual sleeve with color-coded plates
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Bar shaft
                Container(
                  width: 32,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF64748B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Collar
                Container(
                  width: 8,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF94A3B8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                // Plates on sleeve
                if (platesPerSide.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      'Empty Bar',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  )
                else
                  ...platesPerSide.entries.expand((entry) {
                    final plate = entry.key;
                    final count = entry.value;
                    final height = 30.0 + (plate * 1.5).clamp(8.0, 48.0);
                    final color = getPlateColor(plate);

                    return List.generate(count, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Container(
                          width: 14,
                          height: height,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            plate >= 10 ? '${plate.toInt()}' : '${plate.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      );
                    });
                  }),
                // Sleeve tip
                Container(
                  width: 24,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Plate Text Breakdown
          if (platesPerSide.isNotEmpty) ...[
            Text(
              'PLATES NEEDED PER SIDE:',
              style: AppTypography.monoSmall.copyWith(
                fontSize: 11.0,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in platesPerSide.entries)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: getPlateColor(entry.key).withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: getPlateColor(entry.key),
                      ),
                    ),
                    child: Text(
                      '${entry.value}× ${entry.key >= 10 ? entry.key.toInt() : entry.key} kg',
                      style: AppTypography.monoSmall.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Quick Weight Steppers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAdjustChip(label: '-5 kg', onTap: () => _adjustWeight(-5.0)),
              _buildAdjustChip(label: '-2.5 kg', onTap: () => _adjustWeight(-2.5)),
              _buildAdjustChip(label: '+2.5 kg', onTap: () => _adjustWeight(2.5)),
              _buildAdjustChip(label: '+5 kg', onTap: () => _adjustWeight(5.0)),
            ],
          ),
          const SizedBox(height: 16),

          // Close button
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'DONE',
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

  Widget _buildAdjustChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minWidth: 70, minHeight: 40),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.monoSmall.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
