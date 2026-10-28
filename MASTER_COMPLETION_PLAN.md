# LEON Master Completion Plan

**Last reconciled:** October 28, 2026  
**Purpose:** Single source of truth for completed work, remaining work, execution order, and definition of done.

> Only unchecked items in this file are active work. Older roadmaps, handoffs, briefs, and verification reports are retained as evidence or historical context; they are not separate backlogs.

## 1. Current truth

The project is not fully finished.

- Chunks 1–5 of the UI polish and performance roadmap are complete.
- The Home/Workout implementation and active-session plan are substantially implemented; their responsive closeout is covered by Chunk 5.
- The AEON launcher/acrylic-logo brief is implemented. Physical-device icon/material validation remains part of platform closeout.
- Android workout notifications and iOS Live Activity/Dynamic Island code exist. README's “upcoming” description is stale; physical platform verification is still required.
- Cloud authentication/sync, real wearable health sync, recovery aggregation, rest-timer audio assets, nutrition/macros, barcode scanning, story-image export, and watch companions remain unfinished.

## 2. Chunk status

| Chunk | Scope | Status | Primary evidence |
|---|---|---|---|
| 1 | Navigation architecture and bottom clearance | **DONE** | `56ee426`, `test/app_shell_slide_test.dart` |
| 2 | Riverpod rebuild scope, search, paint performance | **DONE** | `ef58cfa`, dashboard/search tests |
| 3 | Typography, contrast, two-accent system, normal gym wording | **DONE** | `920233a`, `chunk_3_verification.md` |
| 4 | History empty states, screen density, Account and active-plan hierarchy | **DONE** | `efba67b`, `c627934`, `44fec5b`, `chunk_4_verification.md` |
| 5 | Responsive/device polish and performance baseline | **DONE** | `chunk_5_verification.md`, `test/core/chunk5_responsive_test.dart` |
| 6 | Product truth, real data feeds, platform-service closeout | **OPEN** | Placeholder/service audit |
| 7 | Cloud identity and secure account linking | **OPEN** | Former TODO Epic 1.1 |
| 8 | Offline-first bidirectional cloud sync | **OPEN** | Former TODO Epic 1.2 |
| 9 | Rest audio and notification/live-activity hardening | **OPEN** | Former TODO Epic 2 + existing platform code |
| 10 | Nutrition, macros, and barcode food logging | **OPEN** | Former TODO Epic 3 |
| 11 | Social workout story exporter | **OPEN** | Former TODO Epic 5 |
| 12 | Wear OS and watchOS companions | **DEFERRED / OPEN** | Former TODO Epic 4 |

## 3. Completed chunks

### Chunk 1 — Navigation architecture and clearance

- [x] Persistent `IndexedStack` tab architecture.
- [x] No adjacent-page peeking during primary navigation.
- [x] Per-tab scroll state preservation.
- [x] Offscreen ticker muting.
- [x] Shared safe-area and floating-navigation bottom clearance.
- [x] Rapid taps, swipes, route synchronization, and Account bottom reachability verified.

### Chunk 2 — Rendering and state-update scope

- [x] Dashboard metric cards use fine-grained Riverpod selection.
- [x] Exercise search is debounced and catalog work is moved out of build.
- [x] Radar/tempo painters have equality checks and repaint boundaries.
- [x] Granular rebuild and search/provider tests are present.

### Chunk 3 — Visual foundation

- [x] Outfit and JetBrains Mono are the active typography families.
- [x] Minimum 11pt typography and 4.5:1 contrast gates are tested.
- [x] Cyan/amber accent discipline is enforced.
- [x] User-facing roleplay terminology gate is tested.
- [x] All main tabs and workout tools were rendered with bundled fonts.

### Chunk 4 — Density and empty states

- [x] History has accurate, actionable empty states.
- [x] Exercise Library rows are compact and accessible.
- [x] Account sections and metrics are simplified.
- [x] Active plan is expandable and highlights the next workout.
- [x] 36 focused checks and Android emulator review completed.

### Chunk 5 — Responsive and performance closeout

- [x] Compact, large-text, keyboard-open, landscape, and tablet layouts are covered by tracked tests.
- [x] Main tabs use a centered 720dp maximum width on wide displays.
- [x] Shared glass rendering, navigation transitions, and rebuild scope were optimized.
- [x] Physical RMX3840 profile evidence includes separate UI and raster timing below the 120Hz processing budget at p95.
- [x] Analysis, debug/profile builds, physical install, and the exhaustive 197-test suite pass.

### Historical Home/Workout implementation

The older Home/Workout progress and handoff notes are superseded. Confirmed implemented items include:

- [x] Multiple same-day sessions survive and are shown in History.
- [x] Durable active-session persistence, checked writes, retry behavior, and lifecycle flushing.
- [x] Explicit missing-effort semantics through `effortLogged`.
- [x] Bilateral/unilateral history hydration and volume handling.
- [x] Replacement preserves completed and partial unilateral work.
- [x] Shared warmup plan and single-warmup flow.
- [x] Plate preference precedence and attainable-load handling.
- [x] Tempo generation guards and left/right rep confirmation.
- [x] A/B rotation, recovery days, split switching, future preview, and multiple same-day session tests.
- [x] Home habits, water, sleep, goals, routine editor, workout recap, and active workout tools.

The former Home/Workout layout failures were closed in Chunk 5.

## 4. Active execution plan

### Chunk 5 — Release-quality responsive and performance closeout `[COMPLETE]`

Completed October 28, 2026. See `chunk_5_verification.md` for measurements and evidence.

#### 5A. Compact and large-text remediation

- [x] Fix the Dashboard 37px right overflow at 360×800 and 1.5× text.
- [x] Fix `ExerciseSequenceCard` 189px right overflow with 1.5× text and keyboard open.
- [x] Fix `FloatingRestTimerBar` 14px right overflow in the same configuration.
- [x] Prevent five bottom-navigation labels from crowding at 1.5× text while preserving labels and 44dp targets.
- [x] Verify Home, History, Exercises, Workouts, Account, sheets, forms, and workout logging at 1.3× and 1.5× text.
- [x] Verify keyboard-open layouts on a compact phone for weight/reps, routine editing, plate calculator, and health logging.

#### 5B. Wide and landscape remediation

- [x] Add a centered readable max-width strategy for tablet/wide Dashboard and main tabs.
- [x] Verify tablet/wide Account, History, Exercise Library, routine editor, sheets, and dialogs.
- [x] Recheck active workout in landscape with expanded exercise, keyboard, rest dock, plate calculator, and finish recap.
- [x] Verify gesture navigation and Android navigation safe areas through physical and automated inset checks.

#### 5C. Performance closeout

Current emulator baseline:

- Cold profile launch: 2756ms; Choreographer reported 39 skipped startup frames.
- Warm task resume: 47ms.
- Post-navigation memory: 168,419KB PSS / 273,048KB RSS.
- Exercise scroll frame interval: p50 16.780ms, p95 17.803ms, max 19.796ms on a 60Hz emulator.
- Frame-ready latency: p50 9.779ms, p95 24.817ms, max 27.318ms.

Completed:

- [x] Capture Flutter UI-thread and raster-thread p50/p95/max in profile mode.
- [x] Repeat the scenario on a physical mid-range Android device.
- [x] Bring UI and raster p95 within the 120Hz device processing budget.
- [x] Recheck startup after navigation/rendering changes; cold launch is 1453ms with 50 Android startup skipped frames.
- [x] Record memory, refresh rate, cold/hot results, and the final device capture.
- [x] Re-run reduced motion; reduced transparency was unavailable on the tested Android devices.

#### 5D. Toolchain and release gate

- [x] Evaluate Gradle 9.1+, Android Gradle Plugin 9.0.1+, and Kotlin 2.3.20+; defer the major migration to a dedicated maintenance change.
- [x] Complete an exhaustive serial run of all 40 test files and 197 tests; two Windows runner launches required one retry each.
- [x] Run `flutter analyze --no-pub`, debug build, profile build, and final install after remediation.
- [x] Update `RUNNING.md` with the current clean analysis command.
- [x] Update README test counts, feature descriptions, and roadmap source.

#### Chunk 5 definition of done

- [x] No overflow/clipping at compact, wide, landscape, keyboard-open, 1.3×, or 1.5× configurations.
- [x] Primary controls remain visible, reachable, and at least 44×44dp.
- [x] Physical-device profile evidence includes separate UI/raster numbers.
- [x] Exhaustive suite, analysis, debug/profile builds, emulator baseline, and physical-device smoke test pass.

### Chunk 6 — Product truth, data integrity, and platform-service closeout `[P0]`

#### 6A. Canonical product identity

- [ ] Decide whether the public product name is **LEON** or **AEON**.
- [ ] Apply the decision consistently to Android/iOS labels, onboarding, dashboard, launcher assets, exports, PDF metadata, sharing text, README, and design guidance.
- [ ] Keep migrations/data keys compatible; do not perform a partial rename.

#### 6B. Honest data and service states

- [ ] Replace Recovery's demo factors with workout-history and actual health-input aggregation, or clearly label unavailable inputs.
- [ ] Replace `NoOpHealthSyncService` with a real integration or keep wearable sync hidden/explicitly unavailable.
- [ ] Ensure `SyncStatusIndicator` does not claim remote synchronization before a real sync engine exists.
- [ ] Review/remove unused placeholder providers and scaffolds (`analytics`, legacy session/builder providers, `set_logger_widget.dart`) or document why they remain.
- [ ] Remove stale “one workout per day” claims and other comments/docs contradicted by current multiple-session behavior.

#### 6C. Existing platform features

- [ ] Validate Android persistent workout/rest notifications and interactive actions on a physical device.
- [ ] Validate iOS Live Activity/Dynamic Island on a supported physical iPhone.
- [ ] Eliminate notification initialization errors from tests through injectable platform setup/fakes.
- [ ] Validate adaptive/monochrome AEON launcher icons on multiple real launcher masks.
- [ ] Confirm the acrylic shader/material fallback on a physical Impeller device and document whether it performs live texture sampling.

#### Chunk 6 definition of done

- [ ] Public naming and feature claims are consistent.
- [ ] No production screen presents demo/placeholder data as real data.
- [ ] Existing notification/live-activity/icon features have physical-device evidence.
- [ ] README and operational documentation match shipped behavior.

### Chunk 7 — Cloud identity and account linking `[P0]`

- [ ] Select Firebase or Supabase as the authoritative backend.
- [ ] Implement Apple ID and Google sign-in.
- [ ] Preserve immediate guest/local-only use.
- [ ] Store credentials/tokens using secure platform storage.
- [ ] Add Account linking, unlinking, sign-out, and account-deletion flows.
- [ ] Define guest-to-cloud data ownership and migration behavior.
- [ ] Add auth error, cancellation, offline, and token-refresh tests.

#### Chunk 7 definition of done

- [ ] Guest mode works without network access.
- [ ] Account linking preserves all local data.
- [ ] Sign-in/out and token refresh work on Android and iOS.

### Chunk 8 — Bidirectional offline-first cloud sync `[P0]`

- [ ] Define versioned remote schemas for workouts, routines, measurements, habits, and profile data.
- [ ] Add a durable offline change queue with timestamps/tombstones.
- [ ] Implement upload, download, retry, backoff, and conflict resolution.
- [ ] Make sync idempotent and safe across multiple devices.
- [ ] Surface accurate Synced / Pending / Error states.
- [ ] Add migration, deletion, conflict, offline, partial-failure, and reinstall recovery tests.
- [ ] Provide export/backup before destructive account actions.

#### Chunk 8 definition of done

- [ ] Two devices converge without duplicates or silent data loss.
- [ ] Offline training remains fully functional.
- [ ] Sync status always reflects real backend state.

### Chunk 9 — Rest audio and notification hardening `[P1]`

- [ ] Add licensed/original countdown, completion, metronome, and round-bell assets.
- [ ] Add Sound + Vibrate / Vibrate Only / Silent preference.
- [ ] Configure headphone/background-audio ducking correctly on Android and iOS.
- [ ] Keep haptic-only and silent accessibility paths.
- [ ] Test background, locked-screen, Bluetooth/headphone, Do Not Disturb, and interrupted-audio behavior.
- [ ] Reuse and harden the existing persistent notification and Live Activity implementations.

### Chunk 10 — Nutrition and food logging `[P1]`

#### 10A. Macro foundation

- [ ] Add date-keyed protein, carbohydrate, fat, calorie, serving, and meal-entry models.
- [ ] Define evidence-based but editable targets; avoid presenting estimates as medical facts.
- [ ] Add daily macro entry/history and Dashboard summary.
- [ ] Preserve local-first storage, undo, editing, and export.

#### 10B. Barcode scanner

- [ ] Integrate camera permission and barcode scanning.
- [ ] Integrate OpenFoodFacts with caching, timeout, offline, and missing-product states.
- [ ] Add portion/serving confirmation before saving.
- [ ] Test malformed data, unit conversion, duplicate scan, and privacy behavior.

### Chunk 11 — Social workout story exporter `[P2]`

- [ ] Build a 1080×1920 workout recap renderer from real completed-session data.
- [ ] Include only supported metrics and records.
- [ ] Export PNG bytes and open the native share sheet.
- [ ] Support long exercise lists, large text, and privacy controls.
- [ ] Keep the existing plain-text share action as a lightweight alternative.

### Chunk 12 — Watch companions and wearable integration `[P2]`

#### 12A. Wear OS

- [ ] Define phone/watch sync protocol and offline ownership.
- [ ] Implement current exercise, set logging, weight/reps adjustments, and rest alerts.
- [ ] Test reconnect, duplicate events, and phone/watch conflict behavior.

#### 12B. watchOS

- [ ] Add a WatchKit/SwiftUI companion with `WatchConnectivity`.
- [ ] Implement Digital Crown adjustments and Taptic rest alerts.
- [ ] Keep watchOS companion work separate from the existing iOS Live Activity extension.

#### 12C. Health data

- [ ] Decide supported Health Connect / HealthKit metrics and permission language.
- [ ] Replace the no-op health service only after permissions, provenance, and fallback behavior are defined.
- [ ] Never infer injury, exact recovery, or medical readiness from incomplete data.

## 5. Documentation reconciliation

| Existing file | New role |
|---|---|
| `MASTER_COMPLETION_PLAN.md` | **Only active backlog and completion tracker** |
| `FLUIDITY_AND_POLISH_ROADMAP.md` | Historical implementation guidance and detailed acceptance reference |
| `chunk_3_verification.md` | Chunk 3 evidence |
| `chunk_4_verification.md` | Chunk 4 evidence |
| `chunk_5_verification.md` | Chunk 5 audit evidence and measured failures |
| `TODO.md` | Superseded; all genuine items are now Chunks 7–12 here |
| `docs/home_workout_implementation.md` | Superseded progress log; resolved work summarized above |
| `docs/home_workout_handoff.md` | Superseded handoff; genuine layout issues moved to Chunk 5 |
| `docs/plans/2026-10-10-active-workout-session.md` | Historical implementation plan, not an active checklist |
| `AEON_Acrylic_Logo_Antigravity_Instructions.md` | Historical logo brief; implementation exists, physical validation moved to Chunk 6 |
| `RUNNING.md` | Operational setup guide; update during Chunk 5D |
| `DESIGN.md` / `AGENTS.md` | Product/design constraints, not backlogs |
| Exercise-library markdown files | Content/reference sources, not project status |

## 6. Global definition of done for every future chunk

Each chunk is complete only when all applicable items are satisfied:

- [ ] Implementation and migrations are complete without unrelated refactors.
- [ ] User-facing wording follows normal fitness terminology.
- [ ] Minimum 11pt text, 4.5:1 contrast, 44dp targets, semantics, large text, keyboard, and safe areas are checked.
- [ ] Unit/widget/integration tests cover success, empty, error, persistence, lifecycle, and rollback paths.
- [ ] `flutter analyze --no-pub` passes.
- [ ] Relevant focused tests pass, followed by one stable full-suite run.
- [ ] Debug and profile builds succeed.
- [ ] Emulator smoke test passes; platform-specific chunks also require physical-device evidence.
- [ ] Performance is measured rather than inferred from screenshots.
- [ ] README, setup instructions, and this master plan are updated.
- [ ] Work lands in reviewable logical commits and is pushed to GitHub.

## 7. Immediate next sequence

1. Authorize the UI changes required for Chunk 5A and 5B.
2. Fix the known compact/large-text/session/nav/tablet issues.
3. Complete physical-device and DevTools profiling for Chunk 5C.
4. Close toolchain, full-suite, and documentation truth work in Chunk 5D.
5. Resolve naming and demo/placeholder service truth in Chunk 6.
6. Build cloud identity and sync in Chunks 7–8.
7. Continue with audio, nutrition, sharing, and watches in priority order.
