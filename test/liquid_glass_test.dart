import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/shared/widgets/glass_nav_pill.dart';
import 'package:leon/shared/widgets/liquid_glass.dart';

void main() {
  group('Liquid Glass Navigation & Components', () {
    testWidgets('LiquidGlassContainer and LiquidGlassButton render correctly',
        (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Center(
              child: LiquidGlassButton(
                onPressed: () => tapped = true,
                child: const Text('ENGAGE'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('ENGAGE'), findsOneWidget);
      expect(find.byType(LiquidGlassContainer), findsOneWidget);

      await tester.tap(find.text('ENGAGE'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('GlassNavPill renders all 5 tabs and responds to selection',
        (WidgetTester tester) async {
      int? selectedTab;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: GlassNavPill(
                activeIndex: 0,
                onTabSelected: (index) {
                  selectedTab = index;
                },
              ),
            ),
          ),
        ),
      );

      // Verify all 5 tab labels are rendered (Title Case per Apple HIG tab-bars.md)
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Workouts'), findsOneWidget);
      expect(find.text('Exercises'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);

      // Verify tapping History selects tab index 3
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(selectedTab, 3);
    });

    test('navPillIndexFor correctly maps route locations', () {
      expect(navPillIndexFor('/'), 0);
      expect(navPillIndexFor('/workout-builder'), 1);
      expect(navPillIndexFor('/exercise-library'), 2);
      expect(navPillIndexFor('/analytics'), 3);
      expect(navPillIndexFor('/profile'), 4);
      expect(navPillIndexFor('/unknown-route'), -1);
    });
  });
}
