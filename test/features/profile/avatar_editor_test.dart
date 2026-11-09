import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/core/providers/local_date_provider.dart';
import 'package:leon/features/profile/models/avatar_reference.dart';
import 'package:leon/features/profile/providers/avatar_editor_provider.dart';
import 'package:leon/features/profile/providers/profile_provider.dart';
import 'package:leon/features/profile/widgets/avatar_editor_sheet.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/services/avatar_service.dart';
import 'package:leon/state/app_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:leon/shared/widgets/app_shell.dart';
import 'package:leon/shared/widgets/glass_nav_pill.dart';
import '../../services/cloud_sync_engine_test.dart' show WorkspaceMemory;
import '../../services/avatar_service_test.dart' show photoBytes;
import 'account_layout_test.dart' show mountAccount;

class PhotoPicker implements AvatarPhotoPicker {
  Uint8List? bytes;
  Completer<Uint8List?>? gate;
  @override
  Future<Uint8List?> pick(AvatarSource source) async =>
      gate == null ? bytes : gate!.future;
}

Future<ProviderContainer> mountEditor(
  WidgetTester tester,
  WorkspaceMemory hive,
  PhotoPicker picker, {
  double width = 390,
  double scale = 1,
  GlobalKey? capture,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  for (final family in ['Outfit', 'JetBrainsMono']) {
    final loader = FontLoader(family)
      ..addFont(rootBundle.load('assets/fonts/$family-Regular.ttf'));
    await loader.load();
  }
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
  final container = ProviderContainer(
    overrides: [
      hiveServiceProvider.overrideWithValue(hive),
      localDateProvider.overrideWith((ref) => DateTime(2026, 11, 6)),
      avatarPhotoPickerProvider.overrideWithValue(picker),
    ],
  );
  addTearDown(container.dispose);
  await container
      .read(accountProfileProvider.notifier)
      .updateProfile(displayName: 'Alex');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: RepaintBoundary(
            key: capture,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: const AvatarEditorSheet(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
    'editor opens above the tab navigator and covers its navigation pill',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final root = GlobalKey<NavigatorState>();
      final branch = GlobalKey<NavigatorState>();
      final router = GoRouter(
        navigatorKey: root,
        initialLocation: '/profile',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) =>
                AppShell.navigation(navigationShell: shell),
            branches: [
              StatefulShellBranch(
                navigatorKey: branch,
                routes: [
                  GoRoute(
                    path: '/profile',
                    builder: (context, state) => Scaffold(
                      body: Center(
                        child: TextButton(
                          onPressed: () => showAvatarEditor(context),
                          child: const Text('Change picture'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hiveServiceProvider.overrideWithValue(WorkspaceMemory()),
            localDateProvider.overrideWith((ref) => DateTime(2026, 11, 6)),
          ],
          child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change picture'));
      await tester.pumpAndSettle();
      final editorContext = tester.element(find.byType(AvatarEditorSheet));
      expect(Navigator.of(editorContext), same(root.currentState));
      expect(Navigator.of(editorContext), isNot(same(branch.currentState)));
      expect(find.byType(GlassNavPill).hitTestable(), findsNothing);
      expect(find.byType(FilledButton).hitTestable(), findsOneWidget);
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(find.byType(GlassNavPill).hitTestable(), findsOneWidget);
    },
  );
  testWidgets(
    'profile avatar opens the editor and Save returns to the updated account',
    (tester) async {
      final container = await mountAccount(tester, storage: WorkspaceMemory());
      await tester.tap(find.byTooltip('Change profile picture'));
      await tester.pumpAndSettle();
      expect(find.text('PROFILE PICTURE'), findsOneWidget);
      await tester.tap(find.text('Sage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save picture'));
      await tester.pumpAndSettle();
      expect(find.text('PROFILE PICTURE'), findsNothing);
      expect(
        container.read(accountProfileProvider).avatarUrl,
        AvatarReference.preset('sage'),
      );
    },
  );
  testWidgets('concurrent profile edits retain an atomically saved avatar', (
    tester,
  ) async {
    final hive = WorkspaceMemory();
    final container = await mountEditor(tester, hive, PhotoPicker());
    final gate = Completer<void>();
    final save = container.read(userProfileProvider.notifier).persistSnapshot((
      _,
    ) async {
      await gate.future;
      await AvatarService(hive).save(AvatarReference.preset('olive'));
    });
    final edit = container
        .read(accountProfileProvider.notifier)
        .updateIdentity(displayName: 'Alex Morgan');
    gate.complete();
    await save;
    await edit;
    expect(container.read(accountProfileProvider).displayName, 'Alex Morgan');
    expect(
      container.read(accountProfileProvider).avatarUrl,
      AvatarReference.preset('olive'),
    );
    expect(
      hive.read('user', 'account_profile_data', (j) => j)!['avatar_url'],
      AvatarReference.preset('olive'),
    );
  });
  testWidgets(
    'portrait selection and crop cancellation do not save; save failure retries',
    (tester) async {
      final hive = WorkspaceMemory();
      final picker = PhotoPicker();
      final container = await mountEditor(tester, hive, picker);
      final before = hive.snapshot()['documents'];
      await tester.tap(find.text('Sage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();
      expect(
        container.read(avatarEditorProvider).reference,
        AvatarReference.preset('sage'),
      );
      expect(hive.snapshot()['documents'], before);
      hive.failSnapshot = true;
      await tester.tap(find.text('Save picture'));
      await tester.pumpAndSettle();
      expect(find.textContaining('could not be saved'), findsOneWidget);
      expect(hive.snapshot()['documents'], before);
      hive.failSnapshot = false;
      expect(
        await container.read(avatarEditorProvider.notifier).save(),
        isTrue,
      );
      expect(
        container.read(accountProfileProvider).avatarUrl,
        AvatarReference.preset('sage'),
      );
    },
  );

  testWidgets('photo preview, pending controls and removal use explicit Save', (
    tester,
  ) async {
    final hive = WorkspaceMemory();
    final picker = PhotoPicker()..gate = Completer<Uint8List?>();
    final container = await mountEditor(tester, hive, picker);
    await tester.tap(find.text('Camera'));
    await tester.pump();
    expect(container.read(avatarEditorProvider).busy, isTrue);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    picker.gate!.complete(photoBytes());
    await tester.pumpAndSettle();
    expect(container.read(avatarEditorProvider).bytes, photoBytes());
    expect(await container.read(avatarEditorProvider.notifier).save(), isTrue);
    final editor = container.read(avatarEditorProvider.notifier);
    editor.select(null);
    expect(container.read(accountProfileProvider).avatarUrl, isNotNull);
    expect(await editor.save(), isTrue);
    expect(container.read(accountProfileProvider).avatarUrl, isNull);
  });

  for (final size in [(390.0, 1.0), (320.0, 2.0)]) {
    testWidgets('editor renders without overflow at ${size.$1}/${size.$2}', (
      tester,
    ) async {
      final capture = GlobalKey();
      await mountEditor(
        tester,
        WorkspaceMemory(),
        PhotoPicker(),
        width: size.$1,
        scale: size.$2,
        capture: capture,
      );
      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final save = tester.getRect(find.byType(FilledButton));
      expect(save.bottom, lessThanOrEqualTo(844));
      expect(save.height, greaterThanOrEqualTo(44));
      await tester.runAsync(() async {
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ImageByteFormat.png);
        final file = File(
          'build/avatar_editor_${size.$1.toInt()}_${size.$2.toInt()}.png',
        );
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
