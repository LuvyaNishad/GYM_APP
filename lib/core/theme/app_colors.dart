import 'package:flutter/material.dart';

/// Dark slate surfaces, neutral metrics, cyan actions, and amber warnings/dates.
/// Foregrounds are opaque so captions remain readable over raised/glass cards.
abstract final class AppColors {
  static const Color onyx = Color(0xFF0F131B);
  static const Color charcoal = Color(0xFF27262A);
  static const Color steel = Color(0xFF383B42);
  static const Color platinum = Color(0xFFB8BCC3);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);

  static const Color dashboardBg = Color(0xFF10131B);
  static const Color cardBackground = Color(0xFF25262C);
  static const Color surfaceSecondary = Color(0xFF2D2F36);
  static const Color subtleBorder = Color(0xFF373942);
  static const Color primaryButton = primary;
  static const Color primaryButtonText = onPrimary;
  static const Color activeCyan = primary;
  static const Color emeraldGreen = success;
  static const Color textMutedSlate = textMuted;

  static const Color background = onyx;
  static const Color surface = charcoal;
  static const Color surfaceVariant = steel;
  static const Color card = charcoal;

  static const Color glassWhite = Color(0x0AFFFFFF);
  static const Color glassWhiteStrong = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33383B42);

  static const Color primary = Color(0xFF00E5FF);
  static const Color primaryDim = platinum;
  static const Color onPrimary = onyx;
  static const Color secondary = platinum;
  static const Color purple = platinum;
  // Functional error state, bright enough for text on raised surfaces.
  static const Color danger = Color(0xFFFFB3B3);
  static const Color success = pureWhite;
  static const Color warning = Color(0xFFFFB300);
  static const Color amber = warning;

  static const Color textPrimary = pureWhite;
  static const Color textSecondary = Color(0xFFCBD5E1);
  // Brighter than Slate-400: also clears 4.5:1 on steel + a 10% white overlay.
  static const Color textMuted = Color(0xFFB8C0CE);

  static const Color chartPush = pureWhite;
  static const Color chartPull = platinum;
  static const Color chartLegs = Color(0xFF94A3B8);
  static const Color chartCore = textMuted;
  static const Color chartGrid = charcoal;
}
