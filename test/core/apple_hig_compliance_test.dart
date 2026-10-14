import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_colors.dart';

void main() {
  group('Apple HIG & Operational System Compliance Gates', () {
    test('1. Typography Floor: All UI widgets enforce minimum 11.0 pt font size', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          // Exclude print-only PDF generation service which produces A4 paper layouts
          .where((f) => !f.path.contains('pdf_report_service.dart'));

      final violations = <String>[];
      final under11Regex = RegExp(r'fontSize:\s*([0-9]|10)(\.\d+)?\b');

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.contains('fontSize:') && under11Regex.hasMatch(line)) {
            // Ensure not a false positive like 11, 12, 100, etc.
            final match = under11Regex.firstMatch(line);
            if (match != null) {
              final val = double.tryParse(match.group(1) ?? '');
              if (val != null && val < 11.0) {
                violations.add('${file.path}:${i + 1} -> $line');
              }
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Apple HIG requires a strict typography floor of 11.0 pt. Violations found:\n${violations.join('\n')}',
      );
    });

    test('2. Language Discipline: Zero pseudo-military or sci-fi roleplay keywords in UI strings', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final forbiddenRegex = RegExp(
        r"""['"][^'"]*\b(cadence|telemetry|protocol|operative|mission|briefing|commence|agent identifier)\b[^'"]*['"]""",
        caseSensitive: false,
      );

      final violations = <String>[];

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          // Skip internal comments or code-level API mentions that are not UI strings
          if (line.trim().startsWith('//') || line.trim().startsWith('*')) continue;
          if (forbiddenRegex.hasMatch(line)) {
            violations.add('${file.path}:${i + 1} -> $line');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'AGENTS.md mandates standard gym terminology. Forbidden keywords found:\n${violations.join('\n')}',
      );
    });

    test('3. Color Discipline: Pure White Primary, High-Contrast Platinum Secondary Text', () {
      // Primary accent is pure white for maximum legibility and CTA hierarchy
      expect(AppColors.primary, AppColors.pureWhite);
      // Secondary text is platinum silver (WCAG AAA 9.1:1 contrast on onyx)
      expect(AppColors.textSecondary, AppColors.platinum);
      // Muted text meets the minimum 4.5:1 contrast floor
      expect(AppColors.textMuted.toARGB32(), 0xFF8E929B);
    });
  });
}
