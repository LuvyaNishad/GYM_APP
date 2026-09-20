<div align="center">

```text
██╗     ███████╗ ██████╗ ███╗   ██╗
██║     ██╔════╝██╔═══██╗████╗  ██║
██║     █████╗  ██║   ██║██╔██╗ ██║
██║     ██╔══╝  ██║   ██║██║╚██╗██║
███████╗███████╗╚██████╔╝██║ ╚████║
╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝
```

### Operational Fitness OS

*Fast. Tactical. Precise.*

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-0553B1?style=for-the-badge&logo=flutter&logoColor=white)

</div>

---

## What is LEON?

LEON is a high-performance fitness tracking app built for serious lifters. It's not just a workout logger — it's an **Operational Fitness OS** designed to help you train smarter, track everything, and never waste a set.

Inspired by tactical interfaces and the RE4 Remake HUD, LEON prioritises speed, clarity, and data density over decorative UI.

---

## Features

### Onboarding & Profile
- Full questionnaire on first launch — collects goals, experience level, available equipment, training days, injuries
- Auto-generates a recommended training split based on your answers
- kg / lbs toggle, body weight tracking, target weight

### Split Builder
- Built-in templates: PPL, Upper/Lower, Full Body, Bro Split, Arnold Split, Custom blank
- Full control — rename days, reorder, clone days, swap exercises
- Multiple splits saved, one active at a time
- Equipment profile — mark exercises unavailable, LEON suggests alternatives and remembers your preferred substitutions

### Active Workout Session
- OLED black distraction-free interface
- Live PR detection — flashes when you beat your best
- Smart rest timer — auto-adjusts duration based on RPE logged
- Weight input via type or +2.5 / +5 kg tap buttons
- RPE slider per set
- Visual plate calculator (bar diagram)
- Add exercises mid-workout
- Auto-saves every set — resumes if app is killed
- Previous set shown as reference ghost text

### Muscle Balance Spider Graph
- 3-axis PPL overview + 6-axis detailed breakdown (Chest / Back / Shoulders / Arms / Legs / Core)
- Toggle between volume (kg) and sets
- Three time windows — this workout / this week / all time
- Highlights weak axes in red + text insight + suggests which day to add more

### Analytics
- GitHub-style gym heatmap (full year, green squares — trains consistency)
- PR history per exercise
- Reps progression charts
- Workout frequency calendar

### Recovery
- Recovery score from: days since last session, muscle group fatigue, sleep hours, soreness rating, last session RPE
- Manual input only (no wearable required)

### History
- List view with drill-down to full session details
- Filter by muscle group or exercise

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart 3.10) |
| State Management | Riverpod 3 (`Notifier` / `AsyncNotifier`) |
| Local Storage | `hive_ce` (local-first, models stored as JSON) |
| Cloud Sync | Supabase *(deferred)* |
| Charts | Hand-written `CustomPainter` for the radar; fl_chart for line/bar |
| Navigation | go_router (`ShellRoute` + floating glass nav pill) |
| Models | Freezed + JsonSerializable |
| Animations | Flutter implicit + explicit controllers |

---

## Design System

**Vibe:** Liquid Glass Tactical · Operational · High-contrast

| Token | Value |
|---|---|
| Background | `#0A0C10` OLED black |
| Primary accent | `#00E5FF` cyan-neon |
| Glass fill | `#FFFFFF0A` (`#FFFFFF1A` elevated) |
| Glass border | `#FFFFFF33`, 1px |
| Success | `#00C853` ECG green |
| Danger | `#E53935` alert red |
| Header font | Outfit |
| Numbers font | JetBrains Mono |

Cards use `BackdropFilter` at `sigmaX/Y: 24`, 24dp radius, 24dp padding, and a centred cyan glow
instead of drop shadows. Full spec — including per-screen layout and copy — lives in
[DESIGN.md](DESIGN.md), which is the single source of truth for every visual decision.

---

## Project Structure
```
lib/
├── core/           # Theme, router, constants, utils, notifications
├── features/       # One folder per screen/feature
│   ├── onboarding/
│   ├── authentication/
│   ├── dashboard/
│   ├── workout_session/
│   ├── workout_builder/
│   ├── split_builder/
│   ├── exercise_library/
│   ├── analytics/
│   ├── recovery/
│   ├── profile/
│   ├── health_tracking/
│   └── cycle/          # reserved — cycle tracking
├── models/         # Freezed data models
├── services/       # Hive storage, workouts, splits, PR detection
├── shared/         # Reusable widgets (glass card, nav pill, app shell)
└── state/          # Global Riverpod providers

docs/archive/       # Superseded design docs, kept for the record
reference images/   # Mockups for screens 01–15
```

---

## Getting Started

### Prerequisites
- Flutter SDK `>=3.38`
- Dart SDK `^3.8.0`
- **Windows only:** Developer Mode enabled (Flutter plugins need symlink support) —
  `start ms-settings:developers`
- A Supabase project *(optional — cloud sync is deferred; the app is local-first)*

### Setup
```bash
# 1. Clone the repo
git clone https://github.com/LuvyaNishad/GYM_APP.git
cd leon

# 2. Copy env file and fill in your Supabase credentials
cp .env.example .env

# 3. Install dependencies
flutter pub get

# 4. Run code generation
dart run build_runner build --force-jit

# 5. Run the app
flutter run
```

> `--force-jit` is required: the AOT snapshot step fails on `objective_c`'s native build hook.
> Use `dart analyze`, not `flutter analyze` — the latter crashes with "analysis server exited
> with code 64" on this toolchain.

**New here?** [RUNNING.md](RUNNING.md) walks through the full Antigravity + Android Studio +
Flutter setup, including the required Windows Developer Mode step.

### Environment Variables
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

---

## Roadmap

**Foundation milestone**
- [x] Project skeleton + architecture
- [x] Design system (Liquid Glass Tactical — colors, typography, glass, buttons)
- [x] Data models (Freezed + codegen)
- [x] Local persistence (Hive CE, JSON-encoded models — survives restart)
- [x] Navigation shell (`ShellRoute` + floating glass nav pill)
- [x] Guest-first routing (fresh install lands on onboarding)
- [ ] Real radar chart (`CustomPainter`, self-drawing, weak-axis detection)
- [ ] Pluggable recovery scoring (cycle-ready factor list)

**Next**
- [ ] Onboarding questionnaire flow (4-page stub today; 14 screens specified)
- [ ] Exercise library seed — 100+ exercises (6 hardcoded today; search + filters built)
- [ ] Active workout session (set logger, RPE, rest timer, plate calculator, PR detection)
- [ ] Split builder + rules-based program generator
- [ ] Analytics + GitHub-style heatmap
- [ ] Authentication + Supabase cloud sync
- [ ] Push notifications
- [ ] Cycle tracking

---

## Status

> Foundation milestone largely complete — persistence, navigation shell, and the Liquid Glass
> design system are in place. Feature implementation in progress. Nothing above is "feature
> complete"; check the roadmap checkboxes for the real state.

---

<div align="center">
Built with precision. Trained with intent.
</div>