import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/widgets/app_startup.dart';
import 'package:leon/features/history/providers/history_provider.dart';
import 'package:leon/features/history/widgets/sessions_tab_view.dart';
import 'package:leon/features/history/widgets/workout_history_card.dart';
import 'package:leon/models/workout_model.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/shared/widgets/deferred_tab.dart';
import 'package:leon/shared/widgets/tab_reveal.dart';

import '../helpers/memory_hive_service.dart';

class _History extends HistoryWorkoutsNotifier {
  _History(this.workouts);
  final List<WorkoutModel> workouts;
  @override
  List<WorkoutModel> build() => workouts;
}

void main() {
  testWidgets(
    'storage gates destination and readiness interrupts launch motion',
    (tester) async {
      final storage = Completer<void>();
      var builds = 0, ready = false, taps = 0;
      await tester.pumpWidget(
        AppStartup(
          initialize: () => storage.future,
          onReady: () => ready = true,
          failureBuilder: (_) => const Text('failure'),
          child: Builder(
            builder: (_) {
              builds++;
              return MaterialApp(
                home: Scaffold(
                  body: TextButton(
                    onPressed: () => taps++,
                    child: const Text('Home'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      expect(builds, 0);
      expect(find.byType(LaunchLogo), findsOneWidget);
      storage.complete();
      await tester.pump();
      expect(ready, isTrue);
      expect(builds, 1);
      await tester.tap(find.text('Home'));
      expect(taps, 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
      await tester.pump();
      expect(find.byType(LaunchLogo), findsNothing);
    },
  );

  testWidgets('storage failure never builds data-dependent screens', (
    tester,
  ) async {
    final storage = Completer<void>();
    var ready = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AppStartup(
          initialize: () => storage.future,
          onReady: () => ready = true,
          failureBuilder: (_) => const Text('Storage unavailable'),
          child: const Text('Home'),
        ),
      ),
    );
    storage.completeError(StateError('Cannot open storage'));
    await tester.pump();
    expect(ready, isFalse);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Storage unavailable'), findsOneWidget);
    expect(find.byType(LaunchLogo), findsNothing);
  });

  testWidgets('reduced motion removes launch overlay as soon as ready', (
    tester,
  ) async {
    final storage = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: AppStartup(
            initialize: () => storage.future,
            onReady: () {},
            failureBuilder: (_) => const Text('failure'),
            child: const Text('Home'),
          ),
        ),
      ),
    );
    storage.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byType(LaunchLogo), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets(
    'offscreen tab waits to warm, but selection mounts it immediately',
    (tester) async {
      var builds = 0;
      Widget tab(bool active) => MaterialApp(
        home: TickerMode(
          enabled: active,
          child: DeferredTab(
            index: 4,
            child: Builder(
              builder: (_) {
                builds++;
                return const Text('Account');
              },
            ),
          ),
        ),
      );
      await tester.pumpWidget(tab(false));
      await tester.pump(const Duration(milliseconds: 100));
      expect(builds, 0);
      await tester.pumpWidget(tab(true));
      expect(find.text('Account'), findsOneWidget);
      await tester.pumpWidget(tab(false));
      expect(find.text('Account'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('tab transitions retain child state and respect reduced motion', (
    tester,
  ) async {
    final fieldKey = GlobalKey();
    Widget shell(int index, {bool reduced = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Material(
          child: TabReveal(
            index: index,
            child: IndexedStack(
              index: index,
              children: [
                TextField(key: fieldKey),
                const Text('Other section'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(shell(0));
    await tester.enterText(find.byType(TextField), 'Retained input');
    await tester.pumpWidget(shell(1));
    await tester.pumpWidget(shell(0, reduced: true));
    expect(find.text('Retained input'), findsOneWidget);
    expect(
      tester
          .widget<SlideTransition>(
            find.descendant(
              of: find.byType(TabReveal),
              matching: find.byType(SlideTransition),
            ),
          )
          .position
          .value,
      Offset.zero,
    );
  });

  testWidgets(
    'history lazily builds rows and retains expanded rows offscreen',
    (tester) async {
      final workouts = List.generate(
        200,
        (index) => WorkoutModel(
          id: 'history_$index',
          userId: 'guest',
          name: 'Push Day $index',
          date: DateTime(2026, 10, 31).subtract(Duration(days: index)),
          durationSeconds: 1200,
          exercises: const [],
        ),
      );
      final container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(MemoryHiveService()),
          historyWorkoutsProvider.overrideWith(() => _History(workouts)),
        ],
      );
      addTearDown(container.dispose);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                controller: scroll,
                slivers: const [SessionsTabView(sliver: true)],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(WorkoutHistoryCard).evaluate().length, lessThan(20));
      await tester.tap(find.byKey(const ValueKey('history_0')));
      await tester.pump();
      expect(find.text('REPEAT WORKOUT'), findsOneWidget);
      scroll.jumpTo(5000);
      await tester.pump();
      scroll.jumpTo(0);
      await tester.pump();
      expect(find.text('REPEAT WORKOUT'), findsOneWidget);
      expect(find.byType(WorkoutHistoryCard).evaluate().length, lessThan(20));
    },
  );
}
