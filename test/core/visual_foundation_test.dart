import 'dart:io';
import 'package:leon/services/hive_service.dart';
import '../helpers/memory_hive_service.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/exercise_library/providers/exercise_library_provider.dart';
import 'package:leon/features/exercise_library/repositories/exercise_repository.dart';
import 'package:leon/shared/widgets/app_shell.dart';
import 'package:leon/features/workout_session/providers/active_session_provider.dart';
import 'package:leon/features/workout_session/screens/workout_session_screen.dart';
import 'package:leon/features/workout_session/widgets/plate_calculator_modal.dart';

Future<void> capture(WidgetTester tester, Key key, String name) async {
  const captureScreenshots = bool.fromEnvironment('CHUNK3_SCREENSHOTS');
  if (!captureScreenshots) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/chunk3/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  testWidgets('Main tabs and workout tools lay out with the bundled fonts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = ExerciseRepository();
    await tester.runAsync(() async {
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      for (final family in ['Outfit', 'JetBrainsMono']) {
        final loader = FontLoader(family);
        for (final weight in ['Regular', 'Medium', 'Bold']) {
          loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
        }
        await loader.load();
      }
      await repository.loadCatalog();
    });

    const captureKey = ValueKey('visual-foundation');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [exerciseRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const RepaintBoundary(
            key: captureKey,
            child: AppShell(location: '/dashboard'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    for (final tab in ['Home', 'Workouts', 'Exercises', 'History', 'Account']) {
      if (tab != 'Home') {
        await tester.tap(find.text(tab).last);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      }
      expect(
        tester.takeException(),
        isNull,
        reason: '$tab layout with real fonts',
      );

      // Optional review artifacts; no golden updates are needed for this check.
      await capture(tester, captureKey, tab.toLowerCase());
    }

    final session = ProviderContainer(
      overrides: [hiveServiceProvider.overrideWithValue(MemoryHiveService())],
    );
    session.read(activeSessionProvider.notifier).startSession();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: session,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const RepaintBoundary(
            key: captureKey,
            child: WorkoutSessionScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.takeException(),
      isNull,
      reason: 'Session layout with real fonts',
    );
    await capture(tester, captureKey, 'session');
    await session.read(activeSessionProvider.notifier).discardSession();
    session.dispose();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const RepaintBoundary(
            key: captureKey,
            child: Scaffold(
              body: PlateCalculatorModal(initialTotalWeightKg: 100),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.takeException(),
      isNull,
      reason: 'Plate calculator layout with real fonts',
    );
    await capture(tester, captureKey, 'plates');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
