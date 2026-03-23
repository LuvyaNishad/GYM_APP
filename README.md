<div align="center">
```
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
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Local Storage | Hive (local-first) |
| Cloud Sync | Supabase |
| Charts | fl_chart |
| Navigation | go_router |
| Models | Freezed + JsonSerializable |
| Animations | Lottie |

---

## Design System

**Vibe:** Cyber-Slate · Tactical · Glassmorphism · Operational

| Token | Value |
|---|---|
| Background | `#0A0C10` OLED black |
| Primary accent | `#00E5FF` cyan-neon |
| Success | `#00C853` ECG green |
| Danger | `#E53935` alert red |
| Header font | Outfit |
| Numbers font | JetBrains Mono |

Cards use `BackdropFilter` with `sigmaX/Y: 10` glassmorphism throughout.

---

## Project Structure
```
lib/
├── core/           # Theme, router, constants, utils, notifications
├── features/       # One folder per screen/feature
│   ├── questionnaire/
│   ├── authentication/
│   ├── dashboard/
│   ├── workout_session/
│   ├── workout_builder/
│   ├── split_builder/
│   ├── exercise_library/
│   ├── analytics/
│   ├── recovery/
│   ├── profile/
│   └── health_tracking/
├── models/         # Freezed data models
├── services/       # Supabase, Hive, auth, analytics, PR detection
├── shared/         # Reusable widgets
└── state/          # Global Riverpod providers
```

---

## Getting Started

### Prerequisites
- Flutter SDK `^3.5.0`
- Dart SDK `^3.5.0`
- A Supabase project

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
dart run build_runner build --delete-conflicting-outputs

# 5. Run the app
flutter run
```

### Environment Variables
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

---

## Roadmap

- [x] Project skeleton + architecture
- [x] Design system (colors, typography, glassmorphism)
- [x] Data models (Freezed + codegen)
- [x] Exercise library (100+ exercises)
- [ ] Onboarding questionnaire flow
- [ ] Authentication (Supabase)
- [ ] Active workout session (set logger, RPE, rest timer, PR detection)
- [ ] Split builder
- [ ] Dashboard with real radar chart data
- [ ] Analytics + GitHub-style heatmap
- [ ] Recovery scoring
- [ ] Supabase cloud sync
- [ ] Push notifications

---

## Status

> Early development — skeleton complete, feature implementation in progress.

---

<div align="center">
Built with precision. Trained with intent.
</div>