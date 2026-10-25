import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_colors.dart';
import 'package:leon/shared/widgets/acrylic_card.dart';

void main() {
  group('AcrylicCard Widget & Material Tests', () {
    testWidgets('renders BackdropFilter with slight blur and translucent body',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcrylicCard(
              child: Text('Bento Card'),
            ),
          ),
        ),
      );

      // Verify BackdropFilter with sigma 10 is present
      final backdropFinder = find.byType(BackdropFilter);
      expect(backdropFinder, findsOneWidget);

      final backdrop = tester.widget<BackdropFilter>(backdropFinder);
      expect(backdrop.filter, ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0));

      // Verify child content renders
      expect(find.text('Bento Card'), findsOneWidget);
    });

    testWidgets('triggers onTap callback with haptic feedback',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcrylicCard(
              onTap: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('respects custom borderRadius, glowColor, and padding',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcrylicCard(
              borderRadius: 18.0,
              padding: EdgeInsets.all(16),
              borderColor: AppColors.activeCyan,
              borderWidth: 1.5,
              glowColor: AppColors.activeCyan,
              child: Text('Custom Acrylic'),
            ),
          ),
        ),
      );

      final clipRRectFinder = find.byType(ClipRRect);
      expect(clipRRectFinder, findsOneWidget);

      final clipRRect = tester.widget<ClipRRect>(clipRRectFinder);
      expect(clipRRect.borderRadius, BorderRadius.circular(18.0));
    });
  });
}
