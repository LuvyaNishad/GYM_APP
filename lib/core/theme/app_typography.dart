import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Shared type scale: Outfit for reading, JetBrains Mono for numeric data.
/// Keep normal system text scaling and at least 11 logical pixels in overrides.
abstract final class AppTypography {
  static const String fontDisplay = 'Outfit';
  static const String fontBody = 'Outfit';
  static const String fontMono = 'JetBrainsMono';
  static const double minTypeFloor = 11.0;

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontDisplay,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    height: 1.2,
    color: AppColors.textPrimary,
  );
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontDisplay,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    height: 1.25,
    color: AppColors.textPrimary,
  );
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontDisplay,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    height: 1.3,
    color: AppColors.textPrimary,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontDisplay,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    height: 1.3,
    color: AppColors.textPrimary,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontDisplay,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    height: 1.3,
    color: AppColors.textPrimary,
  );
  static const TextStyle titleLarge = headlineSmall;

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontBody,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontBody,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontBody,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontBody,
    fontSize: minTypeFloor,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
    color: AppColors.textSecondary,
  );
  static const TextStyle button = TextStyle(
    fontFamily: fontBody,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // Metrics stay neutral; active timers can explicitly request the cyan accent.
  static const TextStyle monoLarge = TextStyle(
    fontFamily: fontMono,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
  );
  static const TextStyle monoMedium = TextStyle(
    fontFamily: fontMono,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.25,
    color: AppColors.textPrimary,
  );
  static const TextStyle monoSmall = TextStyle(
    fontFamily: fontMono,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  static const TextStyle screenTitle = displayMedium;
  static const TextStyle sectionTitle = headlineSmall;
  static const TextStyle supportingBody = bodySmall;
  static const TextStyle metric = monoLarge;
  static const TextStyle dataLabel = monoSmall;
  static const TextStyle dataLarge = monoLarge;
  static const TextStyle dataMedium = monoMedium;
  static const TextStyle dataSmall = monoSmall;
}
