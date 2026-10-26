import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/shared/widgets/app_shell.dart';
import 'package:leon/shared/widgets/glass_nav_pill.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppShell Navigation & Layout Tests', () {
    testWidgets('AppShell renders IndexedStack and GlassNavPill with solid background',
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

      // IndexedStack is present with 5 children
      final indexedStackFinder = find.byType(IndexedStack);
      expect(indexedStackFinder, findsOneWidget);

      final indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, 0);
      expect(indexedStack.children.length, 5);

      // GlassNavPill is present
      expect(find.byType(GlassNavPill), findsOneWidget);
    });

    testWidgets('Tapping on a nav pill tab switches IndexedStack to target tab',
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

      // Initial tab is 0
      var indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 0);

      // Tap on 'Exercises' tab in the nav pill
      final exercisesTab = find.text('Exercises');
      expect(exercisesTab, findsOneWidget);

      await tester.tap(exercisesTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify IndexedStack switched to index 2 (Exercises)
      indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 2);
    });

    testWidgets('Tapping Workouts and Account tabs updates active index cleanly',
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

      // Tap Workouts
      await tester.tap(find.text('Workouts'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      var indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 1);

      // Tap Account
      await tester.tap(find.text('Account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 4);
    });

    testWidgets('Horizontal swipe gestures navigate forward and backward between tabs',
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

      var indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 0);

      // Fling left (right-to-left) to advance from Home (0) to Workouts (1)
      await tester.fling(find.byType(IndexedStack), const Offset(-400, 0), 1000.0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 1);

      // Fling left again to advance from Workouts (1) to Exercises (2)
      await tester.fling(find.byType(IndexedStack), const Offset(-400, 0), 1000.0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 2);

      // Fling right (left-to-right) to go back from Exercises (2) to Workouts (1)
      await tester.fling(find.byType(IndexedStack), const Offset(400, 0), 1000.0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 1);
    });

    testWidgets('AppShell.bottomPadding computes total clearance with safe area',
        (tester) async {
      double? computedPadding;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(bottom: 34.0),
            ),
            child: Builder(
              builder: (context) {
                computedPadding = AppShell.bottomPadding(context, extra: 24.0);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // reservedBottomSpace (102.0) + bottomInset (34.0) + extra (24.0) = 160.0
      expect(computedPadding, equals(160.0));
    });
  });
}
