import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/measurement_units.dart';
import '../../../services/export_file_service.dart';
import '../../../services/hive_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/account_profile_model.dart';
import '../services/pdf_report_service.dart';
import '../services/training_report_data.dart';

void showReportPreviewSheet(BuildContext context, [AccountProfile? profile]) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => const _ReportSheet(),
    );

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet();
  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<TrainingReportData> data;
  bool busy = false;
  String? message;
  Uint8List? pdf;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    pdf = null;
    data = TrainingReportData.load(ref.read(hiveServiceProvider), month);
  }

  void change(int delta) => setState(() {
    month = DateTime(month.year, month.month + delta);
    message = null;
    load();
  });
  Future<void> export(TrainingReportData report, bool share) async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      pdf ??= await PdfReportService.generateMonthlyReportPdf(
        report,
        units: ref.read(measurementUnitsProvider),
      );
      final files = ref.read(exportFileServiceProvider);
      final name =
          'AEON-report-${month.year}-${month.month.toString().padLeft(2, '0')}.pdf';
      final result = share
          ? (await files.share(name, 'application/pdf', pdf!)
                ? 'Share sheet opened.'
                : 'Sharing cancelled.')
          : (await files.save(name, 'application/pdf', pdf!) == null
                ? 'Save cancelled.'
                : 'PDF saved to your selected destination.');
      if (mounted) setState(() => message = result);
    } catch (e) {
      if (mounted) setState(() => message = 'Could not export the report: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'MONTHLY REPORT',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: busy ? null : () => change(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      MaterialLocalizations.of(context).formatMonthYear(month),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed:
                        busy ||
                            !month.isBefore(
                              DateTime(
                                DateTime.now().year,
                                DateTime.now().month,
                              ),
                            )
                        ? null
                        : () => change(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              FutureBuilder<TrainingReportData>(
                future: data,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Could not read saved data: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final report = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlassCard(
                        blur: true,
                        child: Text(
                          report.summary(ref.watch(measurementUnitsProvider)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'PDF includes this month’s sessions, new PR sets and measurements. Profile name, email, workout notes and measurement notes are omitted.',
                      ),
                      FilledButton(
                        onPressed: busy ? null : () => export(report, false),
                        child: const Text('Save PDF'),
                      ),
                      OutlinedButton(
                        onPressed: busy ? null : () => export(report, true),
                        child: const Text('Share PDF'),
                      ),
                    ],
                  );
                },
              ),
              if (busy) const Center(child: CircularProgressIndicator()),
              if (message != null) Text(message!),
            ],
          ),
        ),
      ),
    ),
  );
}
