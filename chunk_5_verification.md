# Chunk 5 Verification — Responsive and Performance Closeout

**Completed:** October 28, 2026  
**Status:** Complete

## Implemented

- Main navigation now uses preloaded `StatefulShellRoute.indexedStack` branches and preserves tab state.
- Shared glass surfaces use grouped backdrop filtering and repaint isolation while retaining the required 10px blur.
- Navigation animation was reduced to 180ms and Impeller/Vulkan is explicitly enabled on Android.
- Dashboard, History calendar, active exercise actions, and rest-timer controls adapt to compact screens and 1.5× text.
- Bottom-navigation labels remain bounded and all five navigation targets remain at least 44×44dp.
- Main-tab content and navigation are centered with a 720dp maximum width on tablet-class displays.
- Exercise Library and Account scrolling avoid unnecessary blur/repaint work.

## Responsive verification

Tracked coverage in `test/core/chunk5_responsive_test.dart` verifies:

- 360×800 at 1.5× text across all five main tabs.
- 44dp minimum navigation targets.
- 800×1280 centered content and navigation at the 720dp cap.
- Active workout at 360×800 with a 280dp keyboard inset and 1.5× text.
- Plate calculator in the same compact keyboard configuration.
- Active workout at 800×360 landscape.

`test/core/home_workout_layout_test.dart` additionally covers Dashboard, health sheets, routine editing, workout tools, scrolling, and keyboard-open layouts at 1.5× text. No responsive overflow remains in the tracked scenarios.

## Physical-device profile

- Device: Realme 12 Pro+ / RMX3840 (`e78fd823`)
- Display: 1080×2412, active 120Hz mode
- Build: Flutter profile APK
- Renderer: Impeller / Vulkan
- Cold profile launch: 1453ms after installation caches were warm
- Hot task resume: 123ms
- Settled memory: 118,257KB PSS / 267,484KB RSS
- Startup: 50 skipped Android Choreographer frames during engine/app initialization

Flutter VM timeline during repeated tab changes and Exercise/Account scrolling:

| Thread/work | p50 | p95 | max |
|---|---:|---:|---:|
| UI frame (`Animator::BeginFrame`) | 1.285ms | 5.345ms | 21.829ms |
| Raster work (`CompositorContext::ScopedFrame::Raster`) | 0.279ms | 0.336ms | 7.719ms |
| Build | 0.451ms | 2.537ms | 18.532ms |
| Paint | 0.073ms | 0.754ms | 1.138ms |

The UI and raster p95 values are within the 8.33ms processing budget of the phone's 120Hz mode. `GPURasterizer::Draw` p95 was 10.254ms because it includes surface submission/vsync pacing; measured raster work itself remained below budget. The result also comfortably meets the requested 60fps floor.

## Release gate

- `flutter analyze --no-pub`: clean, 0 issues.
- Debug APK: built successfully.
- Profile APK: built successfully and installed on RMX3840.
- Physical-device smoke test and screenshot: passed; `tool/latest_screen.png` retained locally.
- Exhaustive serial suite: 40/40 test files and 197 tests passed.
- Windows `flutter_tester` intermittently closed before loading two files; the exhaustive harness retried those runner launches once and both files passed. No test assertion failed.
- Gradle 8.14, AGP 8.11.1, and Kotlin 2.2.20 remain compatible. Flutter warns that future releases will require Gradle 9.1, AGP 9.0.1, and Kotlin 2.3.20; that major Android toolchain migration is deferred to a dedicated maintenance change to avoid combining build-system risk with this UI/performance release.
- Reduced-motion navigation passed. Android on the available devices did not expose a reduced-transparency switch, so that platform-specific setting could not be exercised.

## Result

Chunk 5 is complete: compact, large-text, keyboard, landscape, wide-layout, performance, build, analysis, automated-test, and physical-device gates are closed.
