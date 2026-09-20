# DESIGN.md — LEON Operational Fitness OS
## Liquid Glass Tactical — Complete Design System Reference

> **This file is the single source of truth for every visual decision in LEON.**
> Every developer, AI assistant, and designer working on this project follows these specs.
> Do not deviate from these values without updating this file in the same commit.
>
> **Provenance.** LEON previously carried four competing design systems: this file's original
> Cyber-Slate spec (cyan on `#0A0C10`), `context.md` (purple `#7B61FF` on `#0B0F14`),
> `brandGuidelines.md` (blue `#3B82F6`, "R.P.D. Navy"), and
> `reference images/liquid_glass_tactical/DESIGN.md`. The 14 reference mockups were all built in
> **Liquid Glass Tactical**, so that is the system — keeping this file's cyan `#00E5FF` rather than
> the reference's Material tint. The three superseded documents are preserved verbatim under
> `docs/archive/` for the record; do not build from them.

---

## 1. Design Philosophy

LEON is an **Operational Fitness OS** — not a wellness app, not a casual tracker.

The aesthetic is a **glass heads-up display projected onto a deep void**. Hierarchy comes from
refraction and emitted light, never from drop shadows. The emotional target is total control, peak
focus, and expensive professional equipment.

- Dark, high-contrast, information-dense
- Inspired by: RE4 Remake tactical HUD × Apple Liquid Glass × Nothing Phone minimalism
- Data density over decoration — every pixel earns its place
- Premium but never flashy — refined, not loud
- Elements of focus **emit** light (localized radial cyan glow). Nothing casts a shadow.

### What LEON is NOT
- Not a Material Design app
- Not a pastel wellness app
- Not a skeuomorphic app
- Not a cartoon fitness app
- Not generic — every screen must feel unmistakably LEON

---

## 2. Color System

**Defined in:** `lib/core/theme/app_colors.dart` — this section and that file must match exactly.

### Background Layers
```dart
AppColors.background     = Color(0xFF0A0C10)  // OLED black — main scaffold
AppColors.surface        = Color(0xFF11141C)  // Raised surface
AppColors.surfaceVariant = Color(0xFF1A1F2E)  // Input fills
```

### Glass Overlay
```dart
AppColors.glassWhite       = Color(0x0AFFFFFF)  // #FFFFFF0A ~4 % — standard card fill
AppColors.glassWhiteStrong = Color(0x1AFFFFFF)  // #FFFFFF1A ~10 % — nav pill, modals
AppColors.glassBorder      = Color(0x33FFFFFF)  // #FFFFFF33 ~20 % — 1px border
```

The fill is deliberately faint. Depth comes from the 24px blur and the border, not from opacity —
raising the fill is the single fastest way to make LEON look cheap.

### Accent Colors
```dart
AppColors.primary    = Color(0xFF00E5FF)  // Neon cyan — primary accent
AppColors.primaryDim = Color(0xFF008EAF)  // Dim cyan — inactive states
AppColors.secondary  = Color(0xFFFF6B35)  // Tactical orange
AppColors.purple     = Color(0xFF7B61FF)  // Pull axis / analytics secondary
AppColors.danger     = Color(0xFFE53935)  // Alert red
AppColors.success    = Color(0xFF00C853)  // ECG green
AppColors.warning    = Color(0xFFFFC107)  // Amber
```

### Text Colors
```dart
AppColors.textPrimary   = Color(0xFFEAECF0)
AppColors.textSecondary = Color(0xFF8892A4)
AppColors.textMuted     = Color(0xFF4A5568)
```

### Chart Palette
```dart
AppColors.chartPush = Color(0xFF00E5FF)  // Push  — cyan
AppColors.chartPull = Color(0xFF7B61FF)  // Pull  — purple
AppColors.chartLegs = Color(0xFFFF6B35)  // Legs  — orange
AppColors.chartCore = Color(0xFFFFD600)  // Core  — yellow
AppColors.chartGrid = Color(0xFF1E2537)  // Grid lines
```

### Color Usage Rules (NON-NEGOTIABLE)
| Color | ONLY used for |
|---|---|
| `#00E5FF` Cyan | Primary CTAs, active states, data values, Push muscle group |
| `#FF6B35` Orange | Secondary accent, Legs muscle group, warm-up badges |
| `#7B61FF` Purple | Pull muscle group, analytics secondary data |
| `#00C853` Green | Success states, Recovery Ready, completed sets |
| `#E53935` Red | Danger, destructive actions, Recovery Rest Recommended, weak radar axis |
| `#FFC107` Amber | Warnings, junk-volume alerts, Moderate recovery |
| `#FFD600` Yellow | Core muscle group only |

**Never use these colors decoratively. Each has exactly one semantic meaning.**

### Special Case: Active Workout Screen
The active session uses `Colors.black` (`#000000`) — true OLED black. Every other screen uses
`AppColors.background` (`#0A0C10`).

### Ambient Glow
Screens may carry one very faint atmospheric orb: cyan at 4–6 % opacity, blurred 60–100dp,
positioned off-centre. It should never read as a colour — only as depth. From the mockups:
`bg-[#00E5FF]/5 blur-[100px]`.

---

## 3. Typography

**Defined in:** `lib/core/theme/app_typography.dart`

Dual-font strategy: **Outfit** for everything human, **JetBrains Mono** for everything machine.

**Rule:** if it is a number, metric, weight, rep count, timer, or any data value — JetBrains Mono.
Everything else — Outfit. Never mix fonts inside a single text element.

**Hierarchy rule:** large display headings use *tighter* letter spacing; small tactical labels use
*increased* letter spacing so they stay legible on a dark screen.

### Type Scale
```dart
// Outfit
AppTypography.displayLarge   = 34px / w800 / ls 2.0
AppTypography.displayMedium  = 26px / w700 / ls 1.8
AppTypography.headlineLarge  = 22px / w700 / ls 1.5
AppTypography.headlineMedium = 18px / w600 / ls 1.5
AppTypography.titleLarge     = 16px / w600 / ls 1.2
AppTypography.bodyMedium     = 14px / w400 / ls 0.2   (colour: textSecondary)
AppTypography.labelSmall     = 11px / w500 / ls 1.0   ALL CAPS (colour: textMuted)

// JetBrains Mono
AppTypography.monoLarge  = 32px / w700 / ls 1.5   (colour: primary)
AppTypography.monoMedium = 20px / w500 / ls 1.0   (colour: primary)
AppTypography.monoSmall  = 13px / w400 / ls 0.8   (colour: textSecondary)
```

### Data Metric Pairing
A large metric is white (`textPrimary`); its unit and label are muted (`textSecondary` /
`textMuted`). `78` is bright, `%` is not — the value carries the focus.

### Font Families
Registered in `pubspec.yaml` as `Outfit` and `JetBrainsMono`; the full variable-weight families
live in `assets/fonts/`.

---

## 4. Glass System

**Defined in:** `lib/shared/widgets/glass_card.dart`

This is the core visual identity. Every card, modal, and container uses it.

### Standard Glass Card (the defaults)
```dart
GlassCard(
  sigmaBlur: 24.0,                        // BackdropFilter sigmaX and sigmaY
  backgroundColor: AppColors.glassWhite,   // #FFFFFF0A
  borderColor: AppColors.glassBorder,      // #FFFFFF33
  borderWidth: 1.0,
  borderRadius: 24,                        // dp — minimum for a large container
  padding: EdgeInsets.all(24),
  border: true,                            // always true
)
```

Structure is `ClipRRect` → `BackdropFilter` → `Container`. **No inner shadows** — refraction does
the depth work, and a shadow only muddies it.

### Glass Card States
```
Default:   blur 24, fill #FFFFFF0A, border #FFFFFF33 1px
Selected:  border → #00E5FF 1.5px, fill → rgba(0,229,255,0.06)
Error:     border → #E53935 1.5px, fill → rgba(229,57,53,0.06)
```

### Elevation Layers
```
Level 0  Background      #0A0C10, no blur
Level 1  Surface         #11141C, no blur
Level 2  Cards           blur 24, fill #FFFFFF0A
Level 3  Floating nav    blur 24, fill #FFFFFF1A
Level 4  Modals / sheets blur 40+, fill #FFFFFF1A  (extreme proximity to the user)
```

### Glow Effects
Glow is the only legitimate use of `BoxShadow`, and it is always **centred — zero offset**.
```dart
BoxShadow(
  color: AppColors.primary.withValues(alpha: 0.20),
  blurRadius: 20,   // 32 for the nav pill's active-tab glow
)
```
Permitted glows: LeonButton, PR banner (`alpha 0.30`, blur 20), recovery ring
(`success` at `alpha 0.40`, blur 12), active nav icon (blur 32).

### Rules
- **NEVER** use opaque cards. Every surface is glass.
- **NEVER** drop blur below 16px — 24px is the standard.
- **NEVER** raise the card fill above 10 % white — it kills the glass.
- Cards **never** touch screen edges — 24dp horizontal margin.
- **NEVER** use an offset `BoxShadow`. Light is emitted, not cast.

---

## 5. Shape Language

**Hyper-rounded corners**, with one deliberate exception for precision.

```
Large containers / cards:   24dp minimum (rounded-3xl)
Interactive elements:       pill (fully rounded) or 16dp minimum
Internal data viz:          4dp — sharper, to read as precise
Bottom sheets:              24dp top corners
```

Soft containers, sharp data. That contrast is the point.

---

## 6. Spacing System

4dp base grid. Every spacing value is a multiple of 4dp.

```
4dp    xs   micro spacing, icon padding
8dp    sm   tight spacing between related elements
12dp   sm+  compact internal padding, stack-gap-sm
16dp   md   input padding
20dp   md+  between sections within a card (stack-gap-md)
24dp   lg   glass padding, screen margin, container-margin
32dp   xl   between major glass cards (stack-gap-lg)
40dp   2xl  deep vertical rhythm between screen sections
48dp   3xl  top section padding
```

### Screen Margins
```
Horizontal:        24dp (all screens — bezel breathing room)
Content start:     16dp below the app bar
Fixed bottom CTA:  16dp above the safe area
Scrollable bottom: pad by AppShell.reservedBottomSpace so content clears the nav pill
```

---

## 7. Component Specifications

### 7.1 LeonButton
**Defined in:** `lib/shared/widgets/leon_button.dart`

Primary buttons are **opaque** — only cards are glass.

```
Height:        52dp
Radius:        pill (height / 2)
Background:    #00E5FF  |  #E53935 when isDestructive
Text:          Outfit 13px, w600, ALL CAPS, ls 1.8, colour #0A0C10
Icon:          18dp, same colour as text
Glow:          BoxShadow rgba(0,229,255,0.20), blur 20, NO offset
               (destructive: rgba(229,57,53,0.20))

States:
  Default:     solid accent, glow on
  Loading:     disabled, 18dp CircularProgressIndicator in #0A0C10, glow off
  Disabled:    accent at 30 % alpha, glow off
  Pressed:     scale 0.97, 150ms easeInOut
```

### 7.2 Glass Input Field
```
Fill:           #1A1F2E
Border:         1px solid #FFFFFF33
Radius:         16dp
Text:           Outfit 14px, #EAECF0
Placeholder:    Outfit 14px, #4A5568
Label above:    labelSmall, ALL CAPS, #8892A4
Prefix icon:    outlined, 18dp, #4A5568

States:
  Focused:   border #00E5FF 1.5px, 3dp cyan left accent line
  Error:     border #E53935, message below in #E53935 11px
  Disabled:  opacity 0.45
```

### 7.3 Filter Pills / Chips
```
Active:    fill #00E5FF, text #0A0C10 Outfit 12px w500, no border, radius pill
Inactive:  fill #FFFFFF0A, text #8892A4, border 1px #FFFFFF33, radius pill
Padding:   12dp horizontal, 6dp vertical
```

### 7.4 Muscle Group Badges
```
Push:  fill rgba(0,229,255,0.15),  border rgba(0,229,255,0.40),  text #00E5FF
Pull:  fill rgba(123,97,255,0.15), border rgba(123,97,255,0.40), text #7B61FF
Legs:  fill rgba(255,107,53,0.15), border rgba(255,107,53,0.40), text #FF6B35
Core:  fill rgba(255,214,0,0.15),  border rgba(255,214,0,0.40),  text #FFD600

Warm-up:  fill rgba(255,166,0,0.15), border rgba(255,166,0,0.40), text #FFA600
          label "WARM-UP" — JetBrains Mono 9px, ls 1.0
PR badge: fill rgba(0,229,255,0.10), border 1px #00E5FF, text #00E5FF
```

### 7.5 Exercise Accent Bar
```
4dp wide × 48dp tall, radius 2dp
Push #00E5FF · Pull #7B61FF · Legs #FF6B35 · Core #FFD600 · Other #4A5568
```

### 7.6 RPE Slider
```
Track:     4dp tall, #1E2537
Fill:      linear gradient #7B61FF (low) → #00E5FF (mid) → #E53935 (high)
Thumb:     14dp circle, #00E5FF, glow rgba(0,229,255,0.40) blur 8
End labels: "1" / "10" — JetBrains Mono 11px
Value:     above thumb — JetBrains Mono 14px bold, #00E5FF
```

### 7.7 Segmented Control
```
Container:     glass, radius pill, height 36dp
Active tab:    fill #00E5FF, text #0A0C10 Outfit 12px w600
Inactive tab:  transparent, text #8892A4 Outfit 12px
Transition:    animated fill slide, 300ms easeOutCubic
```

### 7.8 Toggle Switch
```
Off:  track #1A1F2E, thumb #4A5568
On:   track #00E5FF (or #FF6B35 warm-up, #E53935 danger), thumb #FFFFFF
Transition: 200ms easeInOut
```

### 7.9 Drag Handle
```
36dp × 4dp, radius 2dp, #4A5568, top-centre of a sheet, 12dp from top
```

### 7.10 Bottom Sheet
```
Background:  glass — blur 40, fill #FFFFFF1A
Top radius:  24dp
Border:      1px #FFFFFF33 (top and sides)
Drag handle: always present
Height:      min 30 %, max 90 % of screen
Backdrop:    rgba(0,0,0,0.6) scrim
```

### 7.11 Action Circle
```
48dp glass circle, centred outlined icon — quick actions only
```

---

## 8. Navigation

### 8.1 Floating Glass Nav Pill
**Defined in:** `lib/shared/widgets/glass_nav_pill.dart`, hosted by
`lib/shared/widgets/app_shell.dart`

A centred, bottom-fixed tray on its own layer — never part of the content stack.

```
Height:          64dp
Radius:          fully pill (height / 2)
Background:      #FFFFFF1A, blur 24, 1px #FFFFFF33 border
Margin:          24dp horizontal, 16dp above the safe area
Icons:           22dp, OUTLINED ONLY
Active icon:     #00E5FF, scale 1.1, with a 32px radial cyan glow centred BEHIND it
Inactive icon:   #8892A4
Glow motion:     slides between tabs — 300ms easeOutCubic (AnimatedAlign)
No labels.       Icon + glow carry the state; each icon has a semantic label for screen readers.

Tabs (index order, matching kNavPillTabs):
  0  Dashboard  dashboard_outlined  /
  1  Builder    work_outline        /workout-builder
  2  Exercises  fitness_center      /exercise-library
  3  Analytics  show_chart          /analytics
  4  Profile    person_outline      /profile
```

The pill floats **over** scrolling content — that overlap is what gives the glass something to
refract. Scrollable tab content pads its bottom by `AppShell.reservedBottomSpace`.

### 8.2 Shell Boundary
`ShellRoute` wraps exactly the five tab routes above. Everything else renders **without** the pill:

```
Outside the shell:  /login  /signup  /onboarding  /workout-session
                    /recovery  /health-tracking   (detail screens pushed from a tab)
```

The session screen is full-bleed OLED with zero chrome; auth and onboarding have no nav.

`AppRouter.build(initialLocation:)` is guest-first: a fresh install starts at `/onboarding`,
and `/` once `AppConstants.settingOnboardingComplete` is set. The router is read once at
construction — see `routerProvider` in `lib/core/router/app_router.dart`.

### 8.3 AppBar
```
Background:    AppColors.background (transparent over scroll)
Title:         headlineMedium, left-aligned
Icon colour:   textPrimary
Elevation:     0
```

### 8.4 Route Transitions
```
Forward:  slide left + fade, 300ms
Back:     slide right + fade, 200ms
Modal:    slide up from bottom, 350ms elasticOut
```

---

## 9. Animation & Motion

### Timing (`AppConstants`)
```
animFast    150ms  micro-interactions (button press, toggle, icon scale)
animNormal  300ms  screen transitions, nav glow slide, card expand
animSlow    500ms  onboarding transitions, radar draw-on
Crawl       900ms  pulsing loops (recovery widget)
```

### Curves
```
Standard  Curves.easeInOut
Enter     Curves.easeOut / easeOutCubic
Exit      Curves.easeIn
Spring    Curves.elasticOut  (bottom sheets)
```

### Core Animations

**Recovery status — pulse.** A *continuous* loop: `AnimationController` with
`repeat(reverse: true)`, 900ms. Ring scale 1.0 → 1.15, opacity 0.6 → 1.0. A one-shot
`TweenAnimationBuilder` is wrong here — it animates once and stops.

**Radar chart — draw-on (~500ms total, staggered):**
```
1. Grid rings   fade + scale from centre
2. Axes         draw outward one by one, staggered
3. Data polygon scale 0 → 1 from centre, easeOut
4. Gradient fill fades in last
```

**Pulse ring (splash / generating):** 2s infinite — `scale(0.8) opacity 0.5` →
`scale(1.5) opacity 0`.

**PR banner:** slide y −60 → 0 + fade in, 300ms easeOut; auto-dismiss after 3000ms with the
reverse at 200ms easeIn.

**Rest timer overlay:** slide y +300 → 0, 350ms elasticOut; exit 250ms easeIn.

**Onboarding pages:** exit slide x 0 → −30 + fade out 250ms; enter slide x +30 → 0 + fade in 300ms.

**Button press:** scale 1.0 → 0.97 → 1.0, 150ms easeInOut.

### Lottie (planned, not yet in the repo)
`pr_celebration.json`, `onboarding_intro.json`, `program_ready.json`. The `assets/lottie/`
declaration was removed from `pubspec.yaml` until the files actually land — re-add it in the same
commit as the first file.

---

## 10. Charts & Data Visualisation

Progress fills always run **cyan → transparent** in the same hue, reading as a power level.

### 10.1 Radar / Spider Chart
**Hand-written `CustomPainter`** — `lib/shared/widgets/radar_chart.dart`, surfaced on the dashboard
by `features/dashboard/widgets/radar_chart_widget.dart`. `fl_chart`'s radar is not flexible enough
for the staggered draw-on animation or per-axis colouring; `fl_chart` is retained for the line and
bar charts below.

```
Data in:      RadarSnapshot (lib/models/progress_model.dart)
3-axis mode:  PUSH #00E5FF · PULL #7B61FF · LEGS #FF6B35
6-axis mode:  Chest · Back · Shoulders · Arms · Legs · Core  (same painter, axis count is a param)

Grid:         4 rings, #1E2537
Fill:         cyan → transparent gradient, from rgba(0,229,255,0.15)
Stroke:       #00E5FF, 2dp
Axis labels:  JetBrains Mono 11px, coloured per axis

Imbalance:    an axis below 40 % of the max axis is "weak"
              → its label turns #E53935, with an insight line below the chart
                (Outfit 13px, #E53935)
```

### 10.2 GitHub-Style Heatmap
```
52 columns × 7 rows · cell 10dp · gap 2dp · radius 2dp
None #1E2537 · Low rgba(0,229,255,0.25) · Medium rgba(0,229,255,0.55) · High #00E5FF
Month labels: JetBrains Mono 9px, #4A5568
Tooltip on tap: glass card — date, workout name, volume
```

### 10.3 Progress Line Chart (1RM)
```
Line #00E5FF 2dp · area fill rgba(0,229,255,0.08) · PR markers ★ #00E5FF 16dp
Axes JetBrains Mono 10px #4A5568 · grid #1E2537 0.5dp · transparent background
```

### 10.4 Volume Bar Chart
```
Bars: #00E5FF at 20 % fill with a solid #00E5FF 2dp top line, 4dp top radius
X labels JetBrains Mono 9px #4A5568 · Y axis hidden (tooltips only)
```

### 10.5 Plate Calculator Diagram
```
Bar:    240dp × 8dp, #8892A4      Collar: 6dp × 48dp, #4A5568
Plates (inside out), colour / width / height:
  25kg   #E53935  12dp × 44dp
  20kg   #2196F3  11dp × 40dp
  15kg   #FFC107  10dp × 36dp
  10kg   #4CAF50   9dp × 32dp
  5kg    #EAECF0   8dp × 26dp
  2.5kg  #E53935   6dp × 20dp
  1.25kg #9E9E9E   5dp × 16dp
Breakdown below: "PER SIDE: 2×20KG + 1×2.5KG = 42.5KG" — JetBrains Mono 13px, #00E5FF
```

---

## 11. Screen Inventory

Routes are the real constants in `lib/core/constants/app_constants.dart`. **Onboarding lives in
`features/onboarding/`** — the old `features/questionnaire/` folder and `/questionnaire` route were
never wired up and have been removed.

| # | Screen | Route | File | Status |
|---|---|---|---|---|
| 01 | Splash | — | `features/authentication/screens/splash_screen.dart` | planned |
| 02–15 | Onboarding flow | `/onboarding` | `features/onboarding/screens/onboarding_screen.dart` | 4-page stub |
| 16 | Login | `/login` | `features/authentication/screens/login_screen.dart` | built |
| 17 | Signup | `/signup` | `features/authentication/screens/signup_screen.dart` | built |
| 18 | Dashboard | `/` | `features/dashboard/screens/dashboard_screen.dart` | built (shell tab 0) |
| 19 | Exercise Library | `/exercise-library` | `features/exercise_library/screens/exercise_library_screen.dart` | built (shell tab 2) |
| 20 | Exercise Detail | `/exercise-library/:id` | `features/exercise_library/screens/exercise_detail_screen.dart` | planned |
| 21 | Workout Builder | `/workout-builder` | `features/workout_builder/screens/workout_builder_screen.dart` | stub (shell tab 1) |
| 22 | Active Session | `/workout-session` | `features/workout_session/screens/workout_session_screen.dart` | stub, full-screen |
| 23 | Set Logger / Plate Calculator | modal | `features/workout_session/widgets/`, `shared/widgets/plate_calculator_sheet.dart` | planned |
| 24 | PR Banner + Complete | overlay | `shared/widgets/pr_banner_widget.dart` | planned |
| 25 | Recovery | `/recovery` | `features/recovery/screens/recovery_screen.dart` | stub |
| 26 | Analytics | `/analytics` | `features/analytics/screens/analytics_screen.dart` | stub (shell tab 3) |
| 27 | Profile & Settings | `/profile` | `features/profile/screens/profile_screen.dart` | stub (shell tab 4) |
| — | Split Builder | `/split-builder` | `features/split_builder/` | planned |
| — | History | `/history` | `features/workout_session/screens/workout_history_screen.dart` | planned |
| — | Health Tracking | `/health-tracking` | `features/health_tracking/screens/health_tracking_screen.dart` | stub |
| — | Cycle Tracking | — | `features/cycle/` | reserved |

### Populate everything with realistic data
No screen ships empty. Reference persona: **OPERATOR** — 82.5 KG, Intermediate, PPL split.
Real exercise names (Barbell Back Squat, Bench Press, Romanian Deadlift, …), real numbers, real
dates. An empty screen can't be judged.

---

## 12. Per-Screen Briefs

Layout and copy for all 27 screens. The full long-form generation prompts are archived at
`docs/archive/LEON_STITCH_MASTER_PROMPT.md`; this section is the working reference.

### 01 — Splash
Centred: `L E O N` — Outfit 34px w800 `#00E5FF` ls 4.0. Below: `OPERATIONAL FITNESS OS` —
Outfit 11px w500 `#8892A4` ls 2.0. 48dp gap, then a *pulsing ring* (not a spinner): 40dp diameter,
2dp stroke `#00E5FF`, glow rgba(0,229,255,0.40) blur 12. Background carries the faint central
cyan orb. Nothing else.

### 02 — Onboarding: Welcome
2dp progress bar at 0 % (`#1E2537` track, `#00E5FF` fill). ~200dp abstract tactical-grid / radar
illustration — never a photo. Headline `WELCOME TO LEON` (Outfit 28px w700 ls 1.5). Subhead
"Your operational fitness OS.\nBuilt for performance." 40dp gap. LeonButton full-width
`COMMENCE OPERATION`. Below: "Already have an account? Sign in" — Outfit 12px `#00E5FF`, tappable.

### 03 — Onboarding: Name
Progress 7 %. Step label `01 / 12` — JetBrains Mono 12px `#4A5568`. Headline `IDENTIFY AGENT`.
Subhead "What do we call you?". Glass input labelled `DISPLAY NAME`, placeholder "Your name".
LeonButton `CONTINUE`, 32dp above the safe area.

### 04 — Onboarding: Age
Progress 14 %, `02 / 12`. Headline `DATE OF BIRTH`, subhead "How old are you?". Vertical
drum-roll picker, 5 visible rows, range 16–80:
```
selected   JetBrains Mono 42px w700 #00E5FF
±1         JetBrains Mono 32px #8892A4 @70 %
±2         JetBrains Mono 24px #4A5568 @40 %
frame      two 1dp #FFFFFF33 hairlines around the centre row
```
LeonButton `CONFIRM AGE`.

### 05 — Onboarding: Height
Progress 21 %, `03 / 12`. Headline `PHYSICAL STATS — HEIGHT`. Segmented unit toggle top-right
`CM | FT`. Same drum-roll (CM 140–220, FT 4'0"–7'0"). Live preview below — JetBrains Mono 18px
`#00E5FF`. LeonButton `CONFIRM HEIGHT`.

### 06 — Onboarding: Weight
Progress 28 %, `04 / 12`. Headline `PHYSICAL STATS — WEIGHT`. Toggle `KG | LBS`. Drum-roll
KG 40–200 / LBS 88–440. Live preview. LeonButton `CONFIRM WEIGHT`.

### 07 — Onboarding: Goal Weight
Progress 35 %, `05 / 12`. Headline `TARGET WEIGHT`, subhead "Where are you headed?". Drum-roll +
unit toggle. Note "Optional — tap skip to proceed" (Outfit 12px `#4A5568`). Two actions: `SKIP`
text button `#8892A4`, LeonButton `SET TARGET`.

### 08 — Onboarding: Experience Level
Progress 42 %, `06 / 12`. Headline `EXPERIENCE LEVEL`, subhead "Select your current training
level". Four stacked ~80dp selectable glass cards — outlined icon, title (Outfit 15px w600),
subtitle (Outfit 13px `#8892A4`), right badge (JetBrains Mono 11px):

| Card | Subtitle | Badge |
|---|---|---|
| `BEGINNER` | Less than 1 year. Building foundations. | 3–4 days/week |
| `INTERMEDIATE` | 1–3 years. Consistent progress. | 4–5 days/week |
| `ADVANCED` | 3+ years. Optimising performance. | 5–6 days/week |
| `ELITE` | Competitive. Periodised programming. | 6 days/week |

Selected: border 1.5px `#00E5FF`, fill rgba(0,229,255,0.06), cyan checkmark top-right. No CTA —
selection auto-advances.

### 09 — Onboarding: Primary Goal
Progress 49 %, `07 / 12`. Headline `PRIMARY OBJECTIVE`. 2×3 grid of ~100dp glass cards:
`BUILD MUSCLE` (bicep), `LOSE FAT` (flame), `INCREASE STRENGTH` (barbell),
`ATHLETIC PERFORMANCE` (bolt), `BODY RECOMPOSITION` (cycling arrows), `GENERAL FITNESS`
(activity chart). Selection style as screen 08; auto-advance.

### 10 — Onboarding: Training Frequency
Progress 56 %, `08 / 12`. Headline `TRAINING FREQUENCY`, subhead "Days per week you will train".
Drum-roll 1–7, centre value JetBrains Mono 64px `#00E5FF`. Dynamic caption (Outfit 13px
`#8892A4`):
```
1–2  Recovery-focused programme recommended
3    Full body split recommended
4    Upper / Lower split recommended
5–6  PPL or Bro Split recommended
7    Ensure adequate recovery days
```
LeonButton `CONFIRM`.

### 11 — Onboarding: Preferred Split
Progress 63 %, `09 / 12`. Headline `PREFERRED PROTOCOL`, subhead "Choose your training split".
Horizontal carousel of ~120×140dp glass cards: split name (Outfit 14px w600), day count
(JetBrains Mono 11px `#00E5FF`), a pattern diagram of coloured day dots, description (Outfit 11px
`#8892A4`). Cards: PPL 6 DAYS · Upper/Lower 4 DAYS · Full Body 3 DAYS · Bro Split 5 DAYS ·
Arnold Split 6 DAYS · Surprise Me `?` (cyan card). Selected: `#00E5FF` border, scale 1.04.
LeonButton `SELECT PROTOCOL`.

### 12 — Onboarding: Equipment
Progress 70 %, `10 / 12`. Headline `EQUIPMENT PROFILE`, subhead "What does your gym have? Select
all that apply." Multi-select chip grid, 3 per row: Barbell · Dumbbells · Cable Machine · Smith
Machine · Leg Press · Pull-up Bar · Resistance Bands · Kettlebells · EZ Bar · Bodyweight only ·
Plate-loaded · Cardio machines. Chip styling per § 7.3. LeonButton `CONFIRM EQUIPMENT`; note
"You can update this anytime in Settings".

### 13 — Onboarding: Injuries
Progress 77 %, `11 / 12`. Headline `LIMITATIONS & INJURIES`, subhead "We'll adapt your programme
to keep you safe". Cards (style as screen 08), multi-select:
```
LOWER BACK      Avoid heavy deadlifts and good mornings
SHOULDER        Avoid overhead pressing movements
KNEE            Avoid heavy squatting and lunging
ELBOW / WRIST   Avoid high-grip-demand exercises
NONE            No current limitations      ← green #00C853 accent; deselects the others
```
LeonButton `CONFIRM`.

### 14 — Onboarding: Generating Programme
Progress 91 %. Centre: **the radar chart drawing itself** — axes extend one by one, then the
polygon fills cyan. This is LEON's signature animation; never a loading spinner. Scanning text
cycles every ~800ms in JetBrains Mono 14px `#00E5FF`:
`ANALYSING PROFILE...` → `CALIBRATING SPLIT...` → `MAPPING MUSCLE GROUPS...` →
`OPTIMISING RECOVERY...` → `DEPLOYING PROGRAMME...`. Progress bar animates 0→100 %. No button;
auto-advances.

### 15 — Onboarding: Programme Ready
Progress 100 %. **Top card:** `RECOMMENDED PROTOCOL` (labelSmall) → split name `PUSH PULL LEGS`
(headlineLarge) → row of 7 day chips (active days cyan glass, rest days `#1E2537`) →
`60–75 MIN / SESSION` (JetBrains Mono 14px `#00E5FF`) → `RECOVERY: OPTIMISED` green chip.
**Middle card — weekly structure:** one row per training day — day name (JetBrains Mono 12px
`#8892A4`), session type (Outfit 14px, e.g. "Push Day A"), muscle-group colour dots.
**Bottom:** LeonButton `DEPLOY PROGRAMME`; below it "Customise first" text button `#00E5FF`.

### 16 — Login
Background carries a 300dp cyan orb (rgba(0,229,255,0.06), blur 60) top-right. Wordmark `LEON`
(Outfit 34px `#00E5FF` ls 4.0) over `OPERATIONAL FITNESS OS` (labelSmall). Centre glass card:
`EMAIL` field (mail icon) → 16dp → `PASSWORD` field (lock icon, eye toggle) → 24dp → LeonButton
`SIGN IN` → 16dp → divider with centred `OR` in `#4A5568` → 16dp → ghost button
`CONTINUE AS GUEST` (glass, border `#FFFFFF33`, Outfit 13px `#8892A4`). Bottom, centred:
"No account? Create one →" — Outfit 13px `#00E5FF`. Error inset example under email:
"Invalid email address" — `#E53935` 11px.

### 17 — Signup
Same background. Chevron back top-left. Headline `CREATE ACCOUNT` (headlineLarge), subhead
"Join the programme." Glass card: Display Name, Email, Password, Confirm Password → 24dp →
LeonButton `CREATE ACCOUNT` → "By continuing you agree to our Terms & Privacy" (Outfit 11px
`#4A5568`, centred).

### 18 — Dashboard
Nav pill visible, tab 0 active. SliverAppBar: `LEON` (displayMedium `#00E5FF` ls 4) with a 32dp
glass avatar circle right. Scrolling stack:

1. **Recovery status** — 40dp pulsing ring (2dp `#00C853` border, green inner glow, heart icon),
   `RECOVERY STATUS` (labelSmall `#4A5568`) over `READY TO TRAIN` (titleLarge `#00C853`),
   chevron right. Ring loops 900ms.
2. **Muscle balance radar** (~260dp) — `MUSCLE BALANCE` left, `THIS WEEK` pill right; 3-axis radar
   per § 10.1 with axis labels in their own colours.
3. **Week stats row** — three mini cards: `VOLUME` / `STREAK` / `SESSIONS`, values in monoMedium.
4. **Today's session** — `TODAY'S SESSION` (labelSmall) → `PUSH DAY A` (headlineMedium) → three
   exercise names in Outfit 13px `#8892A4` separated by `•` → bottom row `5 EXERCISES`
   (JetBrains Mono 11px) and a compact 40dp LeonButton `START`.
5. **My programme** — `MY PROGRAMME` → active split `PPL — 6 DAY` (titleLarge) →
   `TODAY: PUSH DAY A` (JetBrains Mono 13px `#00E5FF`). Whole card taps through to Split Builder.
6. **Quick actions** — three equal glass cards: HISTORY, ANALYTICS, RECOVERY.

### 19 — Exercise Library
Nav tab 2. AppBar `EXERCISE LIBRARY`, no back button. Glass search field, placeholder "Search
exercises...", prefix search icon. Horizontally scrolling filter pills:
`ALL | PUSH | PULL | LEGS | CORE | BARBELL | DUMBBELL | CABLE | BODYWEIGHT`. List rows are glass
cards: 4dp muscle-colour accent bar → 16dp → name (Outfit 15px w600) with
`LEGS · BARBELL` beneath (JetBrains Mono 11px `#4A5568` ls 0.8) → right: favourite star
(outlined `#4A5568` / filled `#00E5FF`) and an optional `RPE 7` cyan badge; warm-up variants get
the orange pill. Reference rows: Barbell Back Squat, Barbell Bench Press, Conventional Deadlift,
Overhead Press, Pull-Up, Romanian Deadlift, Barbell Row, Incline Dumbbell Press.

### 20 — Exercise Detail
~200dp hero glass card: anatomy silhouette, primary muscle `#00E5FF`, secondary `#FF6B35` @60 %,
name overlaid bottom-left (headlineLarge), tag pills bottom-right
(`COMPOUND | BARBELL | LEGS`). Stats row: `SETS 3` / `REPS 8-12` / `RPE 7` in monoMedium.
`STRENGTH PROGRESS` 1RM line chart (~140dp) with cyan PR stars; empty state "Log your first set to
see progress". `HOW TO PERFORM` numbered steps (Outfit 14px). `ALTERNATIVES` horizontal scroll of
small cards. Fixed bottom LeonButton `ADD TO WORKOUT`.

### 21 — Workout Builder
AppBar: back, title `CONFIGURE LOADOUT`, right `PREVIEW` text button `#00E5FF`. Glass workout-name
input at top. Junk-volume banner when triggered: amber glass card, warning triangle `#FFC107`,
"JUNK VOLUME DETECTED — Push volume exceeds recommended threshold" (Outfit 13px `#FFC107`),
dismiss ×. Reorderable exercise rows: drag handle `#4A5568` → 4dp accent bar → name → inline
`SETS` / `REPS` / `REST` −/value/+ controls in JetBrains Mono → warm-up pill toggle (on = orange)
→ remove ×. Reference load: Barbell Back Squat 4×8 120S · Romanian Deadlift 3×12 90S · Leg Press
3×15 90S. Fixed bottom: dashed-border ghost `ADD EXERCISE`, 12dp gap, LeonButton `START WORKOUT`.

### 22 — Active Workout Session
**Background: true `#000000`.** The most important screen — it must feel unlike any other:
larger numbers, maximum contrast, zero decoration.

Top bar: elapsed `00:15:42` (JetBrains Mono 20px `#8892A4`) · workout name `PUSH DAY A` (Outfit
14px ls 1.2) · `END` glass pill with `#E53935` border and text. 4dp progress bar (`#1E2537` track,
`#00E5FF` fill) with `3 / 5 EXERCISES` beneath (JetBrains Mono 11px, centred). Exercise header
`BARBELL BENCH PRESS` (Outfit 26px w700, centred) over `SET 3 / 5`. Previous-set glass pill:
`PREV: 80KG × 10 REPS RPE 7`.

```
Weight   [−5]  [−2.5]  [ 82.5 KG ]  [+2.5]  [+5]
Reps     [−1]  [ − ]   [ 10 REPS ]  [ + ]   [+1]
```
Stepper buttons are 52dp glass squares (border `#FFFFFF33`, JetBrains Mono 18px); centre values
are JetBrains Mono 36px w700 `#EAECF0` with a muted unit. Long-press ±2.5 opens an increment
sheet. RPE slider per § 7.6. Collapsible notes field, placeholder "Add set notes...".
Fixed bottom: plate-calculator glass icon button (left), LeonButton `LOG SET` (centre),
add-exercise glass icon (right).

**Rest timer overlay** slides up: countdown `01:32` (JetBrains Mono 64px w700 `#00E5FF`),
`REST TIMER` label, 120dp circular ring (`#1E2537` track, `#00E5FF` fill), `SKIP` text button.
Auto-dismisses at 00:00.

### 23 — Set Logger & Plate Calculator (bottom sheets)
**Set Logger:** drag handle, title `LOG SET 3` (Outfit 16px w600), optional
`🔥 NEW PR INCOMING` cyan glass banner, weight/reps steppers (slightly smaller than the session
screen), RPE slider, "Mark as warm-up" toggle (on = `#FF6B35`), LeonButton `SAVE SET`.
**Plate Calculator:** title `PLATE CALCULATOR`, `TOTAL WEIGHT` glass input showing `82.5 KG`,
bar-weight pill selector `15KG | 20KG | 25KG`, the barbell diagram of § 10.5, the per-side
breakdown line, LeonButton `APPLY TO SESSION`.

### 24 — PR Banner + Workout Complete
**PR banner** (top overlay, cyan glow border): `🏆 NEW PERSONAL RECORD` (Outfit 16px w700
`#00E5FF`), "You lifted 87.5KG × 8 REPS" (JetBrains Mono 14px `#EAECF0`),
`PREVIOUS BEST: 85KG × 8` (JetBrains Mono 12px `#4A5568`). Auto-dismiss 3s.
**Complete screen:** `OPERATION COMPLETE` (displayMedium) over "Push Day A — Thu 23 Mar". Stats
row `VOLUME 4,125 KG` / `DURATION 52:14` / `SETS 18`. PRs-broken card (cyan border):
`2 PRs BROKEN` (titleLarge `#00E5FF`) with trophy-marked rows. 160dp mini-radar of the session's
distribution. `SESSION NOTES` glass textarea with a `0 / 500` counter. Bottom: ghost `SHARE` and
LeonButton `DONE`.

### 25 — Recovery
AppBar `RECOVERY` with back; no nav pill. Hero card: 160dp dial, 12dp stroke, `#1E2537` track,
arc gradient `#E53935` → `#FFC107` → `#00C853`, value `78` (JetBrains Mono 52px w700 `#00C853`),
`RECOVERY SCORE` label, `READY TO TRAIN` beneath. Then the factor inputs — one per
`RecoveryFactor` in `features/recovery/models/recovery_factor.dart`:
```
REST DAYS          pill selector 0d | 1d | 2d | 3d+
SLEEP              slider 4–12h, value "7.5 HRS"
SORENESS           slider 1–10, plus region chips PUSH | PULL | LEGS | CORE
LAST SESSION RPE   pill selector 1-2 | 3-4 | 5-6 | 7-8 | 9-10
RECENTLY TRAINED?  toggle NO (green) / YES (red)
```
Insight card (amber border): `RECOVERY INSIGHT` → "Pull volume is low this week. Consider
targeting back and biceps tomorrow." Bottom LeonButton `SAVE CHECK-IN`.

The factor list is pluggable — a cycle-phase factor drops in as one more row here without
touching the scoring engine.

### 26 — Analytics
Nav tab 3. AppBar `ANALYTICS`. Segmented control `OVERVIEW | STRENGTH | VOLUME | CALENDAR`.
Overview tab: `52-WEEK TRAINING LOG` heatmap (§ 10.2) with
`CURRENT STREAK: 5 DAYS · LONGEST: 21 DAYS` beneath in JetBrains Mono 12px `#00E5FF`;
`MUSCLE BALANCE — THIS WEEK` radar (~200dp) with scope toggle
`THIS WORKOUT | THIS WEEK | ALL TIME` and metric toggle `VOLUME | SETS`, weak-axis logic per
§ 10.1; `RECENT PRs` list of three, trophy-marked; `WEEKLY VOLUME` 8-bar chart (§ 10.4).

### 27 — Profile & Settings
Nav tab 4. AppBar `PROFILE`. Header card: 72dp glass avatar with initials (Outfit 26px), name
`OPERATOR` (headlineMedium), `INTERMEDIATE · PPL SPLIT` (Outfit 13px `#8892A4`). Stats row
`WORKOUTS` / `VOLUME` / `STREAK` in monoMedium. Grouped settings cards — label Outfit 14px
`#EAECF0` left, value JetBrains Mono 13px `#8892A4` or toggle or chevron right:
```
TRAINING       My Active Split · Exercise Library · Workout History
BODY           Current Weight "82.5 KG" · Target Weight "78 KG" · Weight Unit KG | LBS toggle
PREFERENCES    Default Rest Timer "90 SECONDS" · Training Reminder · Recovery Check-In
NOTIFICATIONS  Rest Timer Vibration · Weekly Summary + day selector · Recovery Alerts
ACCOUNT        Edit Profile · Export Data · Privacy Policy · Log Out (#E53935, no chevron)
```

---

## 13. Do Not Rules

Absolute. Any change that violates these is rejected.

```
❌ DO NOT use flat opaque cards — always glass
❌ DO NOT use setState for anything beyond local widget animation — Riverpod only
❌ DO NOT hardcode colors — always use AppColors tokens
❌ DO NOT hardcode text styles — always use AppTypography tokens
❌ DO NOT render a number in anything but JetBrains Mono
❌ DO NOT reduce blur below 16px on glass cards (24 is standard, 40+ for modals)
❌ DO NOT raise the glass fill above 10 % white
❌ DO NOT use an offset BoxShadow — glows are centred, offset 0
❌ DO NOT use inner shadows on glass — refraction is the depth
❌ DO NOT use the primary cyan decoratively — it has semantic meaning
❌ DO NOT add spacing that isn't a multiple of 4dp
❌ DO NOT let cards touch screen edges (24dp margin)
❌ DO NOT use filled icons in an unselected state
❌ DO NOT add animations longer than 500ms (pulsing loops excepted)
❌ DO NOT show a loading spinner for local Hive reads — they are synchronous
❌ DO NOT call withOpacity — it is deprecated; use withValues(alpha: …)
❌ DO NOT edit *.freezed.dart or *.g.dart by hand
```

---

## 14. Asset Inventory

```
assets/
├── fonts/     Outfit (Thin→Black) and JetBrainsMono (Thin→ExtraBold, incl. italics)
│              Registered in pubspec.yaml as families 'Outfit' and 'JetBrainsMono'
├── images/    leon_app_icon.png, leon_logo.png
└── lottie/    NOT PRESENT — see § 9. Re-declare in pubspec.yaml when the files land.
```

Mockups for screens 01–15 live in `reference images/`, alongside the original
Liquid Glass Tactical token sheet at `reference images/liquid_glass_tactical/DESIGN.md`.

---

## 15. Accessibility

- Minimum tap target 44×44dp on every interactive element
- Colour is **never** the only state indicator — always pair with an icon, label, or position
  (the nav pill pairs its cyan glow with an icon scale for exactly this reason)
- Every interactive element carries a semantic label
- UI must not break at system font scale 1.3×
- Text on glass must meet WCAG AA (4.5:1)

---

## 16. Version History

| Version | Date | Changes |
|---|---|---|
| 1.0 | March 2026 | Initial design system — Cyber-Slate Tactical |
| 2.0 | September 2026 | Consolidated onto **Liquid Glass Tactical**: blur 10→24, radius 16→24, padding 16→24, glass fill 8 %→4 % with a new 10 % elevated tier, pill buttons with centred glow, floating glass nav pill replacing the Material bottom bar, `purple`/`chartCore` tokens added. Screen inventory corrected to the real routes and files; per-screen briefs folded in from the (now archived) Stitch master prompt. `context.md`, `brandGuidelines.md`, and `LEON_STITCH_MASTER_PROMPT.md` moved to `docs/archive/`. |

---

*This document is maintained alongside the codebase. When a design decision changes, update this
file in the same commit.*
