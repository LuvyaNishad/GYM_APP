import 'package:flutter/material.dart';
import 'app_colors.dart';

/// LEON typography system.
/// Headers → Outfit (tactical / bold).
/// Numbers  → JetBrains Mono (HUD-style).
abstract final class AppTypography {
  // ── Outfit (headings) ─────────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.0,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.8,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
    color: AppColors.textMuted,
  );

  // ── JetBrains Mono (HUD numbers) ─────────────────────────────────────────
  static const TextStyle monoLarge = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.primary,
  );

  static const TextStyle monoMedium = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
    color: AppColors.primary,
  );

  static const TextStyle monoSmall = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.8,
    color: AppColors.textSecondary,
  );
}
