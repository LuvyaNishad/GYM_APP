import 'package:flutter/material.dart';

/// Miscellaneous helper utilities used across the LEON codebase.
abstract final class AppHelpers {
  AppHelpers._();

  /// Format seconds into `MM:SS` for timers.
  static String formatSeconds(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Convert a weight in kg to lbs.
  static double kgToLbs(double kg) => kg * 2.20462;

  /// Convert lbs to kg.
  static double lbsToKg(double lbs) => lbs / 2.20462;

  /// Returns a muscle group emoji for display.
  static String muscleGroupEmoji(String group) {
    return switch (group.toLowerCase()) {
      'push' => '🔴',
      'pull' => '🟣',
      'legs' => '🟠',
      'core' => '🟡',
      _ => '⚪',
    };
  }

  /// Clamps a double RPE value to the 1–10 range.
  static double clampRpe(double rpe) => rpe.clamp(1.0, 10.0);

  /// Shows a LEON-styled snackbar.
  static void showSnack(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
