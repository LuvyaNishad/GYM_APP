import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_colors.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/core/theme/app_typography.dart';
import 'package:leon/shared/widgets/leon_button.dart';
import 'package:leon/features/workout_session/widgets/plate_calculator_modal.dart';

double contrast(Color foreground, Color background) {
  final rendered = Color.alphaBlend(foreground, background);
  final a = rendered.computeLuminance();
  final b = background.computeLuminance();
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

void main() {
  group('Apple HIG and visual foundation', () {
    test(
      '1. Typography Floor: All UI widgets enforce minimum 11.0 pt font size',
      () {
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
          reason:
              'Apple HIG requires a strict typography floor of 11.0 pt. Violations found:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '2. Language Discipline: Zero pseudo-military or sci-fi roleplay keywords in UI strings',
      () {
        final libDir = Directory('lib');
        final dartFiles = libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        final forbiddenRegex = RegExp(
          r"""['"][^'"]*\b(cadence|telemetry|protocol|operative|operational|operation|mission|briefing|commence|tactical|callsign|deploy|agent)\b[^'"]*['"]""",
          caseSensitive: false,
        );

        final violations = <String>[];

        for (final file in dartFiles) {
          final lines = file.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            // Skip internal comments or code-level API mentions that are not UI strings
            if (line.trim().startsWith('//') || line.trim().startsWith('*')) {
              continue;
            }
            if (forbiddenRegex.hasMatch(line)) {
              violations.add('${file.path}:${i + 1} -> $line');
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'AGENTS.md mandates standard gym terminology. Forbidden keywords found:\n${violations.join('\n')}',
        );
      },
    );

    test('3. Actions use cyan, warnings and calendar selection use amber', () {
      expect(AppColors.primary.toARGB32(), 0xFF00E5FF);
      expect(AppColors.primaryButton, AppColors.primary);
      expect(AppColors.warning.toARGB32(), 0xFFFFB300);
      expect(AppColors.amber, AppColors.warning);
      expect(
        contrast(AppColors.onPrimary, AppColors.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.onPrimary, AppColors.amber),
        greaterThanOrEqualTo(4.5),
      );
    });

    test(
      '4. Text contrast clears 4.5:1 on surfaces and composited overlays',
      () {
        final backgrounds = <String, Color>{
          'canvas': AppColors.background,
          'dashboard': AppColors.dashboardBg,
          'OLED workout': Colors.black,
          'card': AppColors.cardBackground,
          'surface': AppColors.surface,
          'secondary surface': AppColors.surfaceSecondary,
          'raised surface': AppColors.surfaceVariant,
          'raised highlight': Color.alphaBlend(
            Colors.white.withValues(alpha: 0.10),
            AppColors.surfaceVariant,
          ),
          'glass highlight': Color.alphaBlend(
            Colors.white.withValues(alpha: 0.16),
            AppColors.surface,
          ),
          'active tint': Color.alphaBlend(
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.surface,
          ),
          'warning tint': Color.alphaBlend(
            AppColors.warning.withValues(alpha: 0.16),
            AppColors.surface,
          ),
        };
        final foregrounds = <String, Color>{
          'primary': AppColors.textPrimary,
          'secondary': AppColors.textSecondary,
          'muted': AppColors.textMuted,
          'action': AppColors.primary,
          'warning': AppColors.warning,
          'error': AppColors.danger,
        };
        for (final background in backgrounds.entries) {
          for (final foreground in foregrounds.entries) {
            expect(
              contrast(foreground.value, background.value),
              greaterThanOrEqualTo(4.5),
              reason: '${foreground.key} text on ${background.key}',
            );
          }
        }
      },
    );

    test('5. Complete Material type scale uses Outfit and readable sizes', () {
      final theme = AppTheme.dark.textTheme;
      final styles = [
        theme.displayLarge,
        theme.displayMedium,
        theme.displaySmall,
        theme.headlineLarge,
        theme.headlineMedium,
        theme.headlineSmall,
        theme.titleLarge,
        theme.titleMedium,
        theme.titleSmall,
        theme.bodyLarge,
        theme.bodyMedium,
        theme.bodySmall,
        theme.labelLarge,
        theme.labelMedium,
        theme.labelSmall,
      ];
      for (final style in styles) {
        expect(style!.fontFamily, 'Outfit');
        expect(style.fontSize, greaterThanOrEqualTo(11));
      }
      for (final style in [
        AppTypography.monoLarge,
        AppTypography.monoMedium,
        AppTypography.monoSmall,
      ]) {
        expect(style.fontFamily, 'JetBrainsMono');
        expect(style.fontSize, greaterThanOrEqualTo(11));
      }
    });

    test('Plate labels clear 4.5:1 on every equipment color', () {
      for (final plate in kOlympicPlates) {
        expect(
          contrast(getPlateLabelColor(plate), getPlateColor(plate)),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test(
      '6. Widget fonts resolve to bundled families, without fallback names',
      () {
        final fontPattern = RegExp(r"""fontFamily:\s*['"]([^'"]+)['"]""");
        for (final file
            in Directory('lib')
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))) {
          for (final match in fontPattern.allMatches(file.readAsStringSync())) {
            expect(
              ['Outfit', 'JetBrainsMono'],
              contains(match.group(1)),
              reason: file.path,
            );
          }
        }
        final manifest = File('pubspec.yaml').readAsStringSync();
        for (final family in ['Outfit', 'JetBrainsMono']) {
          expect(manifest, contains('family: $family'));
          for (final weight in ['Regular', 'Medium', 'Bold']) {
            final asset = 'assets/fonts/$family-$weight.ttf';
            expect(manifest, contains(asset));
            expect(File(asset).lengthSync(), greaterThan(0));
          }
        }
      },
    );

    testWidgets(
      '7. Disabled workout actions stay readable and do not activate',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(
              body: LeonButton(label: 'Start Workout', onPressed: null),
            ),
          ),
        );
        final label = tester.widget<Text>(find.text('START WORKOUT'));
        expect(label.style!.fontFamily, 'Outfit');
        expect(
          contrast(label.style!.color!, AppColors.surfaceVariant),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNull,
        );
      },
    );
  });
}
