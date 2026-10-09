import 'package:flutter/material.dart';
import 'app_colors.dart';

/// LEON typography system.
///
/// Implements a disciplined 2-font tactical pairing:
/// 1. [fontDisplay] ('Nano') — Architectural, high-precision science & tech
///    typeface with a mono look for headers, titles, CTAs, and operational labels.
/// 2. [fontBody] ('SpaceGrotesk') — Clean cyber-grotesque with technical DNA
///    for body, subtitles, tags, and interface copy.
/// 3. [fontMono] ('JetBrainsMono') — Monospace numerals for precision telemetry readouts.
abstract final class AppTypography {
  // ── Two-Font Core Tokens ────────────────────────────────────────────────────
  /// Primary tactical display and headings font ('Nano' science & tech family)
  static const String fontDisplay = 'Nano';

  /// Supporting interface, body, and caption font ('PlusJakartaSans')
  static const String fontBody = 'PlusJakartaSans';

  /// High-density telemetry data and numeral font ('JetBrainsMono')
  static const String fontMono = 'JetBrainsMono';

  /// Apple HIG minimum type floor for mobile readability.
  static const double minTypeFloor = 11.0;

  // ── Display & Headings (Nano) ───────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontDisplay,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontDisplay,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontDisplay,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontDisplay,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontDisplay,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontDisplay,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: AppColors.textPrimary,
  );

  // ── Body & Interface (Space Grotesk) ─────────────────────────────────────────
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontBody,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontBody,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontBody,
    fontSize: minTypeFloor,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  // ── HUD Telemetry & Numbers (JetBrains Mono) ───────────────────────────────
  static const TextStyle monoLarge = TextStyle(
    fontFamily: fontMono,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.primary,
  );

  static const TextStyle monoMedium = TextStyle(
    fontFamily: fontMono,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
    color: AppColors.primary,
  );

  static const TextStyle monoSmall = TextStyle(
    fontFamily: fontMono,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  // Aliases for Stitch / Liquid Glass tokens
  static const TextStyle dataLarge = monoLarge;
  static const TextStyle dataMedium = monoMedium;
  static const TextStyle dataSmall = monoSmall;
}
