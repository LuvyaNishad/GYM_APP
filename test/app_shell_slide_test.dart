import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/shared/widgets/app_shell.dart';
import 'package:leon/shared/widgets/glass_nav_pill.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppShell Horizontal Sliding / Swiping Tests', () {
    testWidgets('AppShell renders PageView and GlassNavPill with solid background',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppShell(location: '/dashboard'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // PageView is present with BouncingScrollPhysics
      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);

      final pageView = tester.widget<PageView>(pageViewFinder);
      expect(pageView.physics, isA<BouncingScrollPhysics>());

      // GlassNavPill is present
      expect(find.byType(GlassNavPill), findsOneWidget);
    });

    testWidgets('Swiping right-to-left moves from Dashboard to Workouts',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppShell(location: '/dashboard'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Initial page is 0
      final pageViewBefore = tester.widget<PageView>(find.byType(PageView));
      expect(pageViewBefore.controller?.page?.round(), 0);

      // Swipe horizontally from right to left (drag by -500 pixels)
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify PageView advanced to page 1
      final pageViewAfter = tester.widget<PageView>(find.byType(PageView));
      expect(pageViewAfter.controller?.page?.round(), 1);
    });

    testWidgets('Swiping left-to-right moves back to previous section',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppShell(location: '/workout-builder'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Initial page is 1 (Workouts)
      final pageViewBefore = tester.widget<PageView>(find.byType(PageView));
      expect(pageViewBefore.controller?.page?.round(), 1);

      // Swipe left-to-right (drag from left to right by +500 pixels)
      await tester.drag(find.byType(PageView), const Offset(500, 0));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify PageView returned to page 0 (Dashboard)
      final pageViewAfter = tester.widget<PageView>(find.byType(PageView));
      expect(pageViewAfter.controller?.page?.round(), 0);
    });

    testWidgets('Tapping on a nav pill tab animates PageView to target tab',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppShell(location: '/'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Tap on 'Exercises' tab in the nav pill
      final exercisesTab = find.text('Exercises');
      expect(exercisesTab, findsOneWidget);

      await tester.tap(exercisesTab);
      // Pump multiple animation ticks to advance the PageController animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Verify page controller navigated to index 2 (Exercises)
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller?.page?.round(), 2);
    });
  });
}
