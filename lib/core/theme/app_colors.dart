import 'package:flutter/material.dart';

/// LEON — Cyber-Slate color system
/// All colours are handpicked to match the "Tactical / Operational" brand.
abstract final class AppColors {
  // ── Background Layers ─────────────────────────────────────────────────────
  static const Color background = Color(0xFF0A0C10); // OLED black
  static const Color surface = Color(0xFF11141C); // raised surface
  static const Color surfaceVariant = Color(0xFF1A1F2E); // card bg

  // ── Glass Overlay ─────────────────────────────────────────────────────────
  /// Standard glass fill for cards (Liquid Glass spec: `#FFFFFF0A`, ~4 %).
  /// Deliberately faint — depth comes from the 24px blur and the border, not
  /// from opacity.
  static const Color glassWhite = Color(0x0AFFFFFF);

  /// Elevated glass for the nav pill and modals (`#FFFFFF1A`, ~10 %).
  static const Color glassWhiteStrong = Color(0x1AFFFFFF);

  static const Color glassBorder = Color(0x33FFFFFF); // ~20 % white border

  // ── Accent ────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF00E5FF); // cyan-neon
  static const Color primaryDim = Color(0xFF008EAF); // dim cyan for inactive
  static const Color secondary = Color(0xFFFF6B35); // tactical orange
  static const Color purple = Color(0xFF7B61FF); // secondary data series
  static const Color danger = Color(0xFFE53935); // alert red
  static const Color success = Color(0xFF00C853); // ECG green
  static const Color warning = Color(0xFFFFC107); // amber
  static const Color amber = Color(0xFFFFB300); // Amber status accent

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFEAECF0);
  /// High-contrast secondary text meeting Apple HIG 4.5:1 minimum on dark surfaces.
  static const Color textSecondary = Color(0xFF94A3B8); // Slate-400 (~5.4:1 contrast)
  static const Color textMuted = Color(0xFF64748B); // Slate-500

  // ── Chart Palette ─────────────────────────────────────────────────────────
  static const Color chartPush = Color(0xFF00E5FF);
  static const Color chartPull = Color(0xFF7B61FF);
  static const Color chartLegs = Color(0xFFFF6B35);
  static const Color chartCore = Color(0xFFFFD600); // 4th radar axis
  static const Color chartGrid = Color(0xFF1E2537);
}
