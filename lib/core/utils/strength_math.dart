import 'dart:math' as math;

/// Scientific strength and 1RM calculation utilities for LEON.
///
/// Implements standard evidence-based equations from exercise physiology:
/// - Epley Equation: 1RM = weight * (1 + reps / 30)
/// - Brzycki Equation: 1RM = weight * (36 / (37 - reps))
/// - Lombardi Equation: 1RM = weight * reps^0.10
final class StrengthMath {
  StrengthMath._();

  /// Calculates estimated One-Rep Maximum (1RM) using the standard Epley formula.
  ///
  /// For 1 rep, returns the exact weight lifted.
  static double calculateEpley1RM(double weightKg, int reps) {
    if (weightKg <= 0 || reps <= 0) return 0.0;
    if (reps == 1) return weightKg;
    return weightKg * (1.0 + (reps / 30.0));
  }

  /// Calculates estimated 1RM using the Brzycki formula.
  static double calculateBrzycki1RM(double weightKg, int reps) {
    if (weightKg <= 0 || reps <= 0) return 0.0;
    if (reps == 1) return weightKg;
    if (reps >= 37) return weightKg * 2.0; // Prevent division by zero
    return weightKg * (36.0 / (37.0 - reps));
  }

  /// Calculates estimated 1RM using the Lombardi formula.
  static double calculateLombardi1RM(double weightKg, int reps) {
    if (weightKg <= 0 || reps <= 0) return 0.0;
    if (reps == 1) return weightKg;
    return weightKg * math.pow(reps, 0.10);
  }

  /// Calculates estimated target weight for a given percentage of 1RM.
  static double weightForPercentage(double oneRepMax, double percentage) {
    return oneRepMax * (percentage / 100.0);
  }

  /// Returns typical training percentages and repetition expectations based on 1RM.
  static List<Map<String, dynamic>> repMaxTable(double oneRepMax) {
    const percentages = [
      {'percent': 100, 'reps': 1, 'description': 'Max Single'},
      {'percent': 95, 'reps': 2, 'description': 'Heavy Double'},
      {'percent': 90, 'reps': 4, 'description': 'Strength Focus'},
      {'percent': 85, 'reps': 6, 'description': 'Power / Strength'},
      {'percent': 80, 'reps': 8, 'description': 'Hypertrophy Top'},
      {'percent': 75, 'reps': 10, 'description': 'Hypertrophy Mid'},
      {'percent': 70, 'reps': 12, 'description': 'Endurance / Volume'},
    ];

    return percentages.map((p) {
      final pct = (p['percent'] as int).toDouble();
      final weight = weightForPercentage(oneRepMax, pct);
      return {
        'percent': p['percent'],
        'reps': p['reps'],
        'weightKg': (weight * 2).round() / 2, // Rounded to nearest 0.5 kg
        'description': p['description'],
      };
    }).toList();
  }
}
