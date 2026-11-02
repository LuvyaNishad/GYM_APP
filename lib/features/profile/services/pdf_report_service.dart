import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/measurement_units.dart';
import 'training_report_data.dart';

class PdfReportService {
  static Future<Uint8List> generateMonthlyReportPdf(
    TrainingReportData data, {
    MeasurementUnits units = const MeasurementUnits(),
    String? displayName,
  }) async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Outfit-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Outfit-Bold.ttf'),
    );
    final fallback = [
      pw.Font.ttf(
        await rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf'),
      ),
      pw.Font.ttf(
        await rootBundle.load('assets/fonts/ChakraPetch-Regular.ttf'),
      ),
    ];
    final pdf = pw.Document();
    pw.Widget heading(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
      ),
    );
    String date(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    pw.Widget table(List<String> headers, List<List<String>> rows) =>
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: rows,
          cellStyle: const pw.TextStyle(fontSize: 11),
          headerStyle: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xff161a23),
          ),
          cellPadding: const pw.EdgeInsets.all(8),
          cellAlignment: pw.Alignment.centerLeft,
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        );
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        maxPages: 1000,
        theme: pw.ThemeData.withFont(
          base: regular,
          bold: bold,
          fontFallback: fallback,
        ).copyWith(defaultTextStyle: const pw.TextStyle(fontSize: 11)),
        header: (_) => pw.Text(
          '${AppConstants.appName} / MONTHLY TRAINING REPORT',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        footer: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Saved workout data • ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
        ),
        build: (_) => [
          pw.SizedBox(height: 16),
          if (displayName != null && displayName.isNotEmpty)
            pw.Text(displayName),
          pw.Text(
            data.summary(units),
            style: const pw.TextStyle(fontSize: 12, lineSpacing: 4),
          ),
          heading('Completed sessions'),
          if (data.sessions.isEmpty)
            pw.Text('No workouts logged in this month.')
          else
            table(
              ['Date', 'Workout', 'Minutes', 'Volume'],
              [
                for (final w in data.sessions)
                  [
                    date(w.date),
                    w.name,
                    (w.durationSeconds / 60).toStringAsFixed(1),
                    units.weight(w.totalVolumeKg),
                  ],
              ],
            ),
          heading('Personal records'),
          pw.Text(
            'Compared with earlier logged sessions. First sessions establish a baseline; warm-ups are excluded.',
          ),
          pw.SizedBox(height: 8),
          if (data.prs.isEmpty)
            pw.Text('No new PR sets logged in this month.')
          else
            table(
              ['Date', 'Exercise', 'Recorded set'],
              [
                for (final (d, name, s) in data.prs)
                  [
                    date(d),
                    name,
                    '${units.weight(s.weightKg)} x ${s.reps}'
                        '${s.weightKgRight != null || s.repsRight != null ? '\nRight: ${units.weight(s.weightKgRight ?? s.weightKg)} x ${s.repsRight ?? s.reps}' : ''}',
                  ],
              ],
            ),
          heading('Body measurements'),
          if (data.measurements.isEmpty)
            pw.Text('No measurements logged in this month.')
          else
            table(
              [
                'Date',
                'Weight',
                'Body fat',
                'Waist',
                'Chest',
                'Arms',
                'Thighs',
              ],
              [
                for (final m in data.measurements)
                  [
                    date(m.date),
                    units.weight(m.weightKg),
                    m.bodyFatPercent == null
                        ? '-'
                        : '${m.bodyFatPercent!.toStringAsFixed(1)}%',
                    units.length(m.waistCm),
                    units.length(m.chestCm),
                    units.length(m.armsCm),
                    units.length(m.thighsCm),
                  ],
              ],
            ),
        ],
      ),
    );
    return pdf.save();
  }
}
