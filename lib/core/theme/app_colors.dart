import 'package:flutter/material.dart';

/// LEON — Cyber-Slate color system
/// All colours are handpicked to match the "Tactical / Operational" brand.
abstract final class AppColors {
  // ── Background Layers ─────────────────────────────────────────────────────
  static const Color background = Color(0xFF0A0C10); // OLED black
  static const Color surface = Color(0xFF11141C); // raised surface
  static const Color surfaceVariant = Color(0xFF1A1F2E); // card bg

  // ── Glass Overlay ─────────────────────────────────────────────────────────
  /// Use as [BoxDecoration] color for glassmorphism cards (low opacity).
  static const Color glassWhite = Color(0x14FFFFFF); // ~8 % white
  static const Color glassBorder = Color(0x33FFFFFF); // ~20 % white border

  // ── Accent ────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF00E5FF); // cyan-neon
  static const Color primaryDim = Color(0xFF008EAF); // dim cyan for inactive
  static const Color secondary = Color(0xFFFF6B35); // tactical orange
  static const Color danger = Color(0xFFE53935); // alert red
  static const Color success = Color(0xFF00C853); // ECG green
  static const Color warning = Color(0xFFFFC107); // amber

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFEAECF0);
  static const Color textSecondary = Color(0xFF8892A4);
  static const Color textMuted = Color(0xFF4A5568);

  // ── Chart Palette ─────────────────────────────────────────────────────────
  static const Color chartPush = Color(0xFF00E5FF);
  static const Color chartPull = Color(0xFF7B61FF);
  static const Color chartLegs = Color(0xFFFF6B35);
  static const Color chartGrid = Color(0xFF1E2537);
}
