import 'package:flutter/material.dart';

/// LEON — Noguchi Black & White Minimalist Color System.
///
/// Palette inspired by Noguchi Design & Japanese/Swiss monochrome luxury:
/// - `#0F131B`: Deep dark slate / onyx background
/// - `#27262A`: Charcoal card containers
/// - `#383B42`: Mid-tone steel slate borders & elevated interactive elements
/// - `#B8BCC3`: Light platinum silver secondary text (WCAG AAA 9.1:1 on #0F131B)
/// - `#FFFFFF`: Pure white primary text & high-contrast CTA accents
abstract final class AppColors {
  // ── Noguchi Design Core Swatches ──────────────────────────────────────────
  static const Color onyx = Color(0xFF0F131B);
  static const Color charcoal = Color(0xFF27262A);
  static const Color steel = Color(0xFF383B42);
  static const Color platinum = Color(0xFFB8BCC3);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);

  // ── Dashboard Refined Design Tokens ────────────────────────────────────────
  static const Color dashboardBg = Color(0xFF10131B);
  static const Color cardBackground = Color(0xFF25262C);
  static const Color surfaceSecondary = Color(0xFF2D2F36);
  static const Color subtleBorder = Color(0xFF373942);
  static const Color primaryButton = Color(0xFFF4F4F5);
  static const Color primaryButtonText = Color(0xFF161A23);
  static const Color activeCyan = Color(0xFF00E5FF);
  static const Color emeraldGreen = Color(0xFF00E676);
  static const Color textMutedSlate = Color(0xFF8E929B);

  // ── Atmospheric Ambient Glow Tokens ────────────────────────────────────────
  /// Core frosty blueish-grayish-white aura tint (subtle glass backlighting)
  static const Color ambientGlowCore = Color(0xFFB8D0E8);
  /// Mid spread misty slate-blue ambient tint
  static const Color ambientGlowMid = Color(0xFF648CAE);
  /// Deep outer slate dispersion tint
  static const Color ambientGlowOuter = Color(0xFF1E293B);

  // ── Background Layers ─────────────────────────────────────────────────────
  static const Color background = onyx; // Deep dark slate (#0F131B)
  static const Color surface = charcoal; // Raised surface (#27262A)
  static const Color surfaceVariant = steel; // Border / elevated surface (#383B42)
  static const Color card = charcoal; // Card background (#27262A)

  // ── Glass Overlay ─────────────────────────────────────────────────────────
  static const Color glassWhite = Color(0x0AFFFFFF);
  static const Color glassWhiteStrong = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33383B42); // Refined steel border

  // ── Monochrome Accent Hierarchy ───────────────────────────────────────────
  /// High-contrast primary call-to-action (crisp pure white with dark label).
  static const Color primary = pureWhite;
  /// High-luminance platinum silver for supporting accents.
  static const Color primaryDim = platinum;
  /// Deep dark canvas color to render text/glyphs upon primary white buttons.
  static const Color onPrimary = onyx;

  static const Color secondary = platinum;
  static const Color purple = platinum;
  static const Color danger = Color(0xFFEF4444); // Subdued functional alert red
  static const Color success = pureWhite; // Completed state
  static const Color warning = platinum; // Restrained status warning
  static const Color amber = pureWhite; // Active calendar / today indicator

  // ── Text Hierarchy (Apple HIG WCAG AA & AAA compliant) ─────────────────────
  static const Color textPrimary = pureWhite; // 17.8:1 contrast on onyx
  static const Color textSecondary = platinum; // 9.1:1 contrast on onyx, 6.5:1 on charcoal
  static const Color textMuted = Color(0xFF8E929B); // 5.2:1 contrast on onyx (exceeds 4.5:1 floor)

  // ── Chart Palette (Monochrome Architectural Grayscale) ────────────────────
  static const Color chartPush = pureWhite;
  static const Color chartPull = platinum;
  static const Color chartLegs = Color(0xFF8E929B);
  static const Color chartCore = steel;
  static const Color chartGrid = Color(0xFF27262A);
}
