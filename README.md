<div align="center">

```text
██╗     ███████╗ ██████╗ ███╗   ██╗
██║     ██╔════╝██╔═══██╗████╗  ██║
██║     █████╗  ██║   ██║██╔██╗ ██║
██║     ██╔══╝  ██║   ██║██║╚██╗██║
███████╗███████╗╚██████╔╝██║ ╚████║
╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝
```

### Premium Minimalist Fitness OS

*Fast. Data-Dense. Distraction-Free.*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![State](https://img.shields.io/badge/State-Riverpod_3-0553B1?style=flat-square&logo=flutter&logoColor=white)](https://riverpod.dev)
[![Storage](https://img.shields.io/badge/Storage-Hive_CE_(Local--First)-F8981D?style=flat-square)](https://pub.dev/packages/hive_ce)
[![Tests](https://img.shields.io/badge/Tests-54_Passing-00C853?style=flat-square)](./test)
[![Design](https://img.shields.io/badge/Design-Noguchi_Monochrome-FFFFFF?style=flat-square&labelColor=0F131B)](./lib/core/theme)

</div>

---

## Overview

**LEON** is a high-performance fitness operating system engineered for lifters who prioritize precision, speed, and clean data over decorative gimmicks. Built from the ground up in Flutter and Dart, LEON marries **Noguchi-inspired Japanese/Swiss monochrome luxury** with **Apple Human Interface Guidelines (HIG)** discipline.

Operating under a **local-first** architecture, every session, set, rep, and routine is stored directly on-device using Hive CE — delivering instant 120Hz responsiveness, zero network lag, and full offline autonomy in any gym environment.

---

## Key Modules & Features

### 1. Dashboard (The Command Center)
- **Retractable Calendar Header:** Interactive weekly/monthly selector with smooth expansion physics.
- **Recovery Readiness Status:** Dynamic ECG-style status card calculating physiological readiness.
- **Activity Metrics Bento Grid:** High-contrast widgets tracking steps, burned calories, hydration, and sleep.
- **Today's Workout Spotlight:** Highlights the active rotation day with exercise previews, target RPE, and a 1-tap **`START WORKOUT`** launcher.

### 2. Workouts & Routine Hub
- **Pre-Loaded Scientific Training Splits:**
  - **Push Pull Legs (PPL):** 6-Day Hypertrophy focus (114 weekly sets)
  - **Upper / Lower (U/L):** 4-Day Strength & Mass focus (81 weekly sets)
  - **Arnold Split:** 6-Day Antagonist volume focus (118 weekly sets)
  - **5-Day Bro Split:** 5-Day Bodypart specialization (95 weekly sets)
- **Interactive 6-Axis Muscle Radar Chart:** Custom-painted polygon canvas comparing planned routine volume vs actual 14-day logged volume across Chest, Back, Shoulders, Quads, Hamstrings, and Arms.
- **Volume Deficit Diagnostics:** Intelligent labels flagging **Optimal Volume** vs **Needs Attention** muscle groups with a 1-tap **`AUTO-BALANCE DEFICIT`** action.
- **Switch Training Split Modal:** Tactile bottom sheet with live volume delta impact calculation (e.g., `Shift: -2 days/wk (-33 sets/wk volume)`).
- **Freestyle Workout Launcher:** Direct entry for unstructured training sessions.

### 3. Active Workout Session (OLED Distraction-Free HUD)
- **Focused Execution Interface:** Pure OLED dark canvas eliminating distractions.
- **Stopwatch & Floating Rest Timer:** Live timer bar featuring tactile $\pm10\text{s}$ adjustment chips and auto-start on set completion.
- **Interactive Set Logger:** Records weight, target reps, RIR (Reps in Reserve), and RPE with ghost reference text showing past performance.
- **Visual Plate Calculator:** Modal barbell diagram calculating exact Olympic plate breakdowns per sleeve for any target weight.
- **Effort Picker Modal:** Dual-mode RIR / RPE selector translating perceived exertion into target training stress.
- **Exercise Sequence Management:** Expandable exercise accordions with live reordering and on-the-fly substitutions.
- **Workout Summary:** End-of-session modal computing total volume tonnage, set counts, and workout duration.

### 4. Exercise Library
- **150+ Gym Exercises:** Standard compound and isolation movements cataloged with muscle targets, mechanics, and required equipment.
- **Instant Filtering & Debounced Search:** Real-time filter bar with quick-tap muscle chips (Chest, Back, Shoulders, Legs, Arms) and equipment selectors.
- **Exercise Detail Drawer:** Tactile bottom-up modal sheet detailing execution form, target anatomy, and viable alternatives.
- **Custom Exercise Builder:** Create and save personalized exercises with tailored muscle assignments.

### 5. History & Performance Hub (The Timeline Hub)
- **Collapsible Monthly & Weekly Calendar Header:** Pinned tactical header with a custom notch grab handle (`—`). Expands to a full 6-row monthly calendar with quick jump pickers (Days, Months, Decade Years); collapses to a compact 1-week strip via single tap or vertical drag.
- **Unified Color-Coded Day Highlighting:**
  - 🟢 **Solid Emerald Green (`#00E676`):** Completed workout sessions
  - ⚪ **Solid Pure White (`#FFFFFF`):** Current day (Today)
  - 🔴 **Soft Red (`#FF5252`):** Missed scheduled sessions
  - ⚫ **Slate Onyx (`#262D3D`):** Designated recovery/rest days
  - 🟢 **Dimmed Green:** Completed workouts in adjacent months
  - 🔵 **Electric Cyan Ring:** Active date filter selection
- **Interactive Date Filtering:** 1-tap filtering from any calendar day to show workouts completed on that date, complete with an active filter badge and 1-tap clear action.
- **Lifetime Tonnage Progress Tracker:** High-visibility progress bar tracking total lifetime kilograms lifted against milestone targets (e.g. `32.7K KG LIFTED`, target `36.0K KG`).
- **Tri-Segment Performance Switcher:**
  - **`[ SESSIONS ]`**: Chronological workout logs with muscle group tags, session duration, set counts, tonnage, PR trophy badges (`2 PRS`), and expandable set-by-set accordions.
  - **`[ OVERLOAD ]`**: Progressive overload analytics featuring 1RM strength progression curves for key compound lifts (Bench Press, Squat, Deadlift, Overhead Press, Barbell Row) and volume load histories.
  - **`[ RADAR ]`**: 6-axis Muscle Balance Radar Canvas mapping planned vs actual volume distribution with volume deficit diagnostics.

### 6. Floating Tubelight Glass Navigation Pill
- **Liquid Glassmorphism:** Custom stadium capsule featuring 40% translucent gunmetal tint, 18px hardware-accelerated Gaussian blur, and a subtle white hairline rim (`Colors.white.withValues(alpha: 0.16)`).
- **Optical Depth Shadow:** Downward-offset elevation shadow that separates the glass capsule from scrolling cards without darkening the frosted face.
- **Sliding Tubelight Emitter:** Top emitter element casting a smooth, linear ambient downlight curtain across the active tab column.

---

## Design System & Principles

LEON enforces a strict, minimalist aesthetic governed by three core rules:

```
┌────────────────────────────────────────────────────────────────────────┐
│  Noguchi Minimalist Palette                                            │
│  ├─ Onyx Background     │ #0F131B (Deepest canvas)                     │
│  ├─ Charcoal Surface    │ #27262A (Bento cards & containers)           │
│  ├─ Steel Slate         │ #383B42 (Borders & elevated dividers)        │
│  ├─ Platinum Silver     │ #B8BCC3 (Secondary metrics & muted labels)   │
│  └─ Pure White          │ #FFFFFF (Primary headings, text & CTA buttons)
└────────────────────────────────────────────────────────────────────────┘
```

1. **Apple HIG Typography Floor (Min 11.0 pt):** Every piece of text, tag, badge, timestamp, metric caption, and button label strictly observes an 11.0 pt floor.
2. **WCAG Contrast Threshold (Min 4.5:1 AA / AAA):** Secondary text uses light platinum silver (`#B8BCC3`), delivering 9.1:1 contrast on onyx and 6.5:1 on charcoal.
3. **Standard Gym Terminology:** Strictly zero pseudo-military or sci-fi roleplay terminology. Only clean, professional, and standard gym vocabulary across all screens.

---

## Tech Stack

| Layer | Technology | Details |
| :--- | :--- | :--- |
| **Framework** | **Flutter 3.x / Dart 3.x** | Multi-platform declarative UI engine |
| **State Management** | **Riverpod 3** | Pure immutable state using `Notifier` / `AsyncNotifier` |
| **Local Storage** | **`hive_ce`** | High-performance local-first storage; models stored as JSON |
| **Routing** | **`go_router`** | Declarative navigation with `ShellRoute` keeping the nav pill persistent |
| **Data Models** | **Freezed & JSON Serializable** | Immutable models with type-safe copy, equality, and JSON serialization |
| **Custom Graphics** | **Flutter `CustomPainter`** | Hand-crafted 6-axis Radar Balance Canvas & Barbell Plate Diagram |
| **Testing** | **Flutter Test** | 54 unit and widget tests covering providers, painters, and screens |

---

## Project Structure

```text
lib/
├── core/
│   ├── constants/          # Application constants and route identifiers
│   ├── router/             # GoRouter configuration & AppRouter build
│   └── theme/              # AppColors (Noguchi palette), AppTheme, AppTypography
├── features/
│   ├── analytics/          # Performance tracking, 1RM trends, volume load
│   ├── authentication/     # Login, signup, and session recovery
│   ├── dashboard/          # Command Center, calendar header, health metrics
│   ├── exercise_library/   # 150+ exercise database, search, detail modal sheet
│   ├── health_tracking/    # Metric logging and health integrations
│   ├── history/            # Collapsible notched calendar, overload curves, radar, session logs
│   ├── onboarding/         # Initial setup and questionnaire
│   ├── profile/            # User settings, units (kg/lbs), barbell configurations
│   ├── recovery/           # Physiological readiness and soreness scoring
│   ├── workout_builder/    # Training Splits hub, Muscle Radar chart, switch modal
│   └── workout_session/    # OLED active workout HUD, timer, plate calc, set logger
├── models/                 # Freezed models (Exercise, Workout, Split, SessionLog)
├── services/               # HiveService, WorkoutService, SplitService, PRDetection
├── shared/
│   └── widgets/            # NotchedHeaderPainter, GlassCard, GlassNavPill, AppShell
└── state/                  # Global Riverpod providers and application state
```

---

## Getting Started

### Prerequisites
- **Flutter SDK:** `>=3.38.0`
- **Dart SDK:** `^3.8.0`
- **Platform:** Android SDK (API 34+) / iOS (iOS 16+) / Desktop
- **Windows Developer Mode:** Recommended for symlink support (`start ms-settings:developers`)

### Quickstart Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/LuvyaNishad/GYM_APP.git
   cd leon
   ```

2. **Install project dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate Freezed & JSON code:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Verify static analysis:**
   ```bash
   flutter analyze
   ```

5. **Run the test suite:**
   ```bash
   flutter test
   ```

6. **Launch the application:**
   ```bash
   flutter run
   ```

---

## Testing & Quality Assurance

LEON maintains high test reliability across state transitions, UI rendering, and custom graphic pipelines:

```bash
# Run all unit and widget tests
flutter test -j 1
```

- **54 passing tests** across:
  - `active_session_provider_test.dart` (Effort math, RIR/RPE conversions, timer controls)
  - `plate_calculator_test.dart` (Barbell sleeve plate distribution logic & modal rendering)
  - `exercise_set_table_test.dart` (Set logging, ghost text references, completion toggles)
  - `workout_builder_test.dart` (Training splits state, muscle radar painter, deficit auto-balancer)
  - `exercise_library_widgets_test.dart` (Exercise catalog filtering, debounce search, detail sheets)
  - `liquid_glass_test.dart` (Nav pill routing, container rendering, and tab selection)

---

## Roadmap

- [x] **Core Architecture & Shell:** Persistent floating Liquid Glass navigation shell with `ShellRoute`
- [x] **Dashboard:** Command Center with retractable calendar, recovery status, and activity tracking
- [x] **Active Workout Mode:** OLED black HUD with stopwatch, $\pm10\text{s}$ rest timer, plate calculator, and RPE/RIR picker
- [x] **Exercise Library:** 150+ categorized gym exercises with instant search, filters, and custom creator
- [x] **Training Splits Hub:** PPL, Upper/Lower, Arnold, and Bro split presets with 6-axis Muscle Radar Balance
- [x] **Liquid Glass Nav Pill:** Ethereal frosted glass capsule with true ambient linear downlight emitter
- [x] **History & Performance Hub (Tab 3):** Collapsible notched calendar (1-week and full month), progressive overload 1RM analytics, 6-axis muscle balance radar, lifetime tonnage bar, and interactive session logs
- [ ] **AI Photo Calorie Tracking:** Zero-cost multimodal food intake logging via Gemini Flash Vision with editable macro review sheet
- [ ] **Health & Wearable Sync:** Bi-directional sync with Apple HealthKit and Google Health Connect

---

<div align="center">

**LEON** — Built with precision. Trained with intent.

</div>