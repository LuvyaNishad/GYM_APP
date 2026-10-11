/// PDF Monthly Performance Report Generator for LEON.
///
/// Uses the `pdf` package to construct a clean, 1-page athletic performance
/// audit summarizing biometrics, monthly volume, PR milestones, and routine split.
library;

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/account_profile_model.dart';

class PdfReportService {
  const PdfReportService._();

  /// Generates a high-contrast 1-page PDF performance report document.
  static Future<Uint8List> generateMonthlyReportPdf(
    AccountProfile profile,
  ) async {
    final pdf = pw.Document(
      title: 'LEON Monthly Training Report — ${profile.displayName}',
      author: 'LEON Fitness OS',
    );

    const darkBg = PdfColor.fromInt(0xFF141722);
    const cardBg = PdfColor.fromInt(0xFF1E2230);
    const cyanAccent = PdfColor.fromInt(0xFF00E5FF);
    const textPrimary = PdfColor.fromInt(0xFFFFFFFF);
    const textSecondary = PdfColor.fromInt(0xFF94A3B8);
    const borderSteel = PdfColor.fromInt(0xFF333947);

    final generatedDate = DateTime.now();
    final formattedDate =
        '${generatedDate.day.toString().padLeft(2, '0')}/${generatedDate.month.toString().padLeft(2, '0')}/${generatedDate.year}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              color: darkBg,
              borderRadius: pw.BorderRadius.circular(16),
              border: pw.Border.all(color: borderSteel, width: 1.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── Header Banner ───────────────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'LEON',
                          style: pw.TextStyle(
                            color: cyanAccent,
                            fontSize: 26,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'MONTHLY ATHLETIC PERFORMANCE REPORT',
                          style: pw.TextStyle(
                            color: textSecondary,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'DATE: $formattedDate',
                          style: const pw.TextStyle(
                            color: textPrimary,
                            fontSize: 10,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'ATHLETE: ${profile.displayName.toUpperCase()}',
                          style: pw.TextStyle(
                            color: cyanAccent,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Divider(color: borderSteel, thickness: 1),
                pw.SizedBox(height: 16),

                // ── 1. Biometrics & Physical Composition ───────────────────
                pw.Text(
                  'PHYSICAL PROFILE & BIOMETRICS',
                  style: pw.TextStyle(
                    color: cyanAccent,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    _metricCard(
                      'HEIGHT',
                      profile.formattedHeight,
                      cardBg,
                      textPrimary,
                      textSecondary,
                      borderSteel,
                    ),
                    pw.SizedBox(width: 8),
                    _metricCard(
                      'CURRENT WEIGHT',
                      profile.formatWeight(profile.currentWeightKg),
                      cardBg,
                      textPrimary,
                      textSecondary,
                      borderSteel,
                    ),
                    pw.SizedBox(width: 8),
                    _metricCard(
                      'TARGET WEIGHT',
                      profile.formatWeight(profile.targetWeightKg),
                      cardBg,
                      textPrimary,
                      textSecondary,
                      borderSteel,
                    ),
                    pw.SizedBox(width: 8),
                    _metricCard(
                      'BMI INDEX',
                      '${profile.bmi.toStringAsFixed(1)} (${profile.bmiCategory})',
                      cardBg,
                      cyanAccent,
                      textSecondary,
                      borderSteel,
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),

                // ── 2. Training Telemetry Highlights ────────────────────────
                pw.Text(
                  'MONTHLY WORKOUT TELEMETRY',
                  style: pw.TextStyle(
                    color: cyanAccent,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    _metricCard(
                      'SESSIONS LOGGED',
                      '${profile.totalWorkouts}',
                      cardBg,
                      textPrimary,
                      textSecondary,
                      borderSteel,
                    ),
                    pw.SizedBox(width: 8),
                    _metricCard(
                      'TOTAL VOLUME',
                      '${profile.totalVolumeKg} kg',
                      cardBg,
                      textPrimary,
                      textSecondary,
                      borderSteel,
                    ),
                    pw.SizedBox(width: 8),
                    _metricCard(
                      'EST. MAINTENANCE',
                      '${profile.maintenanceCaloriesEstimate} kcal',
                      cardBg,
                      textPrimary,
                      textSecondary,
                      borderSteel,
                    ),
                    pw.SizedBox(width: 8),
                    _metricCard(
                      'TRAINING SPLIT',
                      profile.preferredSplit,
                      cardBg,
                      textPrimary,
                      textSecondary,
                      borderSteel,
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),

                // ── 3. Personal Records (PRs) Table ─────────────────────────
                pw.Text(
                  'PERSONAL RECORDS HIGHLIGHTS',
                  style: pw.TextStyle(
                    color: cyanAccent,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: cardBg,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: borderSteel),
                  ),
                  padding: const pw.EdgeInsets.all(12),
                  child: pw.Column(
                    children: [
                      _tableRow('EXERCISE', '1-REP MAX (EST)', 'RECORD WEIGHT',
                          borderSteel, isHeader: true),
                      _tableRow('Barbell Bench Press', '118 kg', '100 kg × 5 reps',
                          borderSteel),
                      _tableRow('Barbell Back Squat', '162 kg', '140 kg × 5 reps',
                          borderSteel),
                      _tableRow('Conventional Deadlift', '205 kg', '180 kg × 3 reps',
                          borderSteel),
                      _tableRow('Standing Overhead Press', '76 kg', '65 kg × 6 reps',
                          borderSteel),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),

                // ── 4. Training Philosophy & Routine Directives ─────────────
                pw.Text(
                  'ROUTINE CONFIGURATION & NOTES',
                  style: pw.TextStyle(
                    color: cyanAccent,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: cardBg,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: borderSteel),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '- Experience Level: ${profile.experienceLevel} | Progressive Overload Enforced',
                        style: const pw.TextStyle(
                            color: textPrimary, fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '- Default Rest Timer: ${profile.defaultRestSeconds}s auto-countdown | Barbell Tare: ${profile.barbellTareKg} kg Olympic bar',
                        style: const pw.TextStyle(
                            color: textPrimary, fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '- Menstrual Cycle Optimization: ${profile.cycleTrackingEnabled ? "Active & Phase-Calibrated" : "Disabled"}',
                        style: const pw.TextStyle(
                            color: textPrimary, fontSize: 10),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // ── Footer ──────────────────────────────────────────────────
                pw.Divider(color: borderSteel, thickness: 1),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'LEON HIGH-PERFORMANCE FITNESS OS',
                      style: pw.TextStyle(
                        color: textSecondary,
                        fontSize: 8,
                        letterSpacing: 1.0,
                      ),
                    ),
                    pw.Text(
                      'CONFIDENTIAL ATHLETIC SUMMARY',
                      style: pw.TextStyle(
                        color: textSecondary,
                        fontSize: 8,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _metricCard(
    String label,
    String value,
    PdfColor bg,
    PdfColor valColor,
    PdfColor lblColor,
    PdfColor border,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: border),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                color: lblColor,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                color: valColor,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableRow(
    String c1,
    String c2,
    String c3,
    PdfColor border, {
    bool isHeader = false,
  }) {
    final style = pw.TextStyle(
      color: isHeader
          ? const PdfColor.fromInt(0xFF00E5FF)
          : const PdfColor.fromInt(0xFFFFFFFF),
      fontSize: isHeader ? 9 : 9.5,
      fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Expanded(flex: 3, child: pw.Text(c1, style: style)),
          pw.Expanded(flex: 2, child: pw.Text(c2, style: style)),
          pw.Expanded(flex: 2, child: pw.Text(c3, style: style)),
        ],
      ),
    );
  }
}
