# DESIGN.md — LEON Operational Fitness OS
## Complete Design System Reference

> This file is the single source of truth for all visual decisions in LEON.
> Every developer, AI assistant, and designer working on this project must follow these specs.
> Do not deviate from these values without updating this file.

---

## 1. Design Philosophy

LEON is an **Operational Fitness OS** — not a wellness app, not a casual tracker.

The aesthetic identity is **Cyber-Slate Tactical**:
- Dark, high-contrast, information-dense
- Inspired by: RE4 Remake tactical HUD × Apple Liquid Glass × Nothing Phone minimalism
- Every screen must feel like a piece of expensive professional equipment
- Data density over decoration — every pixel earns its place
- Premium but never flashy — refined, not loud

### What LEON is NOT:
- Not a Material Design app
- Not a pastel wellness app
- Not a skeuomorphic app
- Not a cartoon fitness app
- Not generic — every screen must feel unmistakably LEON

---

## 2. Color System

**Defined in:** `lib/core/theme/app_colors.dart`

### Background Layers
```dart
AppColors.background    = Color(0xFF0A0C10)  // OLED Black — main scaffold
AppColors.surface       = Color(0xFF11141C)  // Raised surface
AppColors.surfaceVariant = Color(0xFF1A1F2E) // Card backgrounds, input fills
```

### Glass Overlay
```dart
AppColors.glassWhite    = Color(0x14FFFFFF)  // 8% white — glass card fill
AppColors.glassBorder   = Color(0x33FFFFFF)  // 20% white — glass card border
```

### Accent Colors
```dart
AppColors.primary       = Color(0xFF00E5FF)  // Neon Cyan — primary accent
AppColors.primaryDim    = Color(0xFF008EAF)  // Dim Cyan — inactive states
AppColors.secondary     = Color(0xFFFF6B35)  // Tactical Orange
AppColors.danger        = Color(0xFFE53935)  // Alert Red
AppColors.success       = Color(0xFF00C853)  // ECG Green
AppColors.warning       = Color(0xFFFFC107)  // Amber
AppColors.purple        = Color(0xFF7B61FF)  // Pull axis / analytics
```

### Text Colors
```dart
AppColors.textPrimary   = Color(0xFFEAECF0)  // Primary text
AppColors.textSecondary = Color(0xFF8892A4)  // Secondary text
AppColors.textMuted     = Color(0xFF4A5568)  // Muted / disabled text
```

### Chart Colors
```dart
AppColors.chartPush     = Color(0xFF00E5FF)  // Push — Cyan
AppColors.chartPull     = Color(0xFF7B61FF)  // Pull — Purple
AppColors.chartLegs     = Color(0xFFFF6B35)  // Legs — Orange
AppColors.chartCore     = Color(0xFFFFD600)  // Core — Yellow
AppColors.chartGrid     = Color(0xFF1E2537)  // Grid lines
```

### Color Usage Rules (NON-NEGOTIABLE)
| Color | ONLY used for |
|---|---|
| `#00E5FF` Cyan | Primary CTAs, active states, data values, Push muscle group |
| `#FF6B35` Orange | Secondary accent, Legs muscle group, warm-up badges |
| `#7B61FF` Purple | Pull muscle group, analytics secondary data |
| `#00C853` Green | Success states, Recovery Ready, completed sets |
| `#E53935` Red | Danger, destructive actions, Recovery Rest Recommended |
| `#FFC107` Amber | Warnings, junk volume alerts, Moderate recovery |
| `#FFD600` Yellow | Core muscle group only |

**Never use these colors decoratively. Each color has exactly one semantic meaning.**

### Special Case: Active Workout Screen
The active workout session uses `Colors.black` (`#000000`) — true OLED black.
All other screens use `AppColors.background` (`#0A0C10`).

---

## 3. Typography

**Defined in:** `lib/core/theme/app_typography.dart`

### Font Families
- **Headers, labels, body, buttons:** `Outfit`
- **Numbers, metrics, data, timers:** `JetBrains Mono`

**Rule:** If it's a number, a metric, a weight, a rep count, a timer value, or any data value — it uses JetBrains Mono. Everything else uses Outfit.

### Type Scale

```dart
// Outfit — Headers
AppTypography.displayLarge  = Outfit, 34px, weight 800, letterSpacing 2.0
AppTypography.displayMedium = Outfit, 26px, weight 700, letterSpacing 1.8
AppTypography.headlineLarge = Outfit, 22px, weight 700, letterSpacing 1.5
AppTypography.headlineMedium = Outfit, 18px, weight 600, letterSpacing 1.5
AppTypography.titleLarge    = Outfit, 16px, weight 600, letterSpacing 1.2
AppTypography.bodyMedium    = Outfit, 14px, weight 400, letterSpacing 0.2
AppTypography.labelSmall    = Outfit, 11px, weight 500, letterSpacing 1.0, ALL CAPS

// JetBrains Mono — Data
AppTypography.monoLarge     = JetBrains Mono, 32px, weight 700, letterSpacing 1.5
AppTypography.monoMedium    = JetBrains Mono, 20px, weight 500, letterSpacing 1.0
AppTypography.monoSmall     = JetBrains Mono, 13px, weight 400, letterSpacing 0.8
```

### Font Files
```
assets/fonts/Outfit-Regular.ttf     (weight: 400)
assets/fonts/Outfit-Medium.ttf      (weight: 500)
assets/fonts/Outfit-Bold.ttf        (weight: 700)
assets/fonts/JetBrainsMono-Regular.ttf (weight: 400)
assets/fonts/JetBrainsMono-Medium.ttf  (weight: 500)
assets/fonts/JetBrainsMono-Bold.ttf    (weight: 700)
```

---

## 4. Glassmorphism System

**Defined in:** `lib/shared/widgets/glass_card.dart`

This is the core visual identity of LEON. Every card, every modal, every container uses this effect.

### Standard Glass Card
```dart
GlassCard(
  sigmaBlur: 10.0,                          // BackdropFilter sigmaX and sigmaY
  backgroundColor: AppColors.glassWhite,     // #FFFFFF14 — 8% white
  borderColor: AppColors.glassBorder,        // #FFFFFF33 — 20% white
  borderRadius: 16,                          // dp
  border: true,                              // always true
  padding: EdgeInsets.all(16),              // default padding
)
```

### Glass Card States
```
Default:   blur 10px, fill #FFFFFF14, border #FFFFFF33
Selected:  border → #00E5FF 1.5px, inner glow rgba(0,229,255,0.08)
Error:     border → #E53935 1.5px, inner glow rgba(229,57,53,0.08)
```

### Glow Effects
When a glass card needs a glow (PR banner, selected state):
```dart
BoxShadow(
  color: AppColors.primary.withOpacity(0.20),
  blurRadius: 16,
  spreadRadius: 0,
  offset: Offset(0, 4),
)
```

### Glassmorphism Rules
- **NEVER** use opaque cards. Every surface must be glass.
- **NEVER** reduce blur below 8px — 10px is the standard.
- **NEVER** increase opacity above 12% for the fill — it breaks the glass effect.
- Cards must NEVER touch screen edges — minimum 16dp horizontal margin.
- Maximum card border radius: 24dp (only for bottom sheets and modals). Standard: 16dp.

---

## 5. Component Specifications

### 5.1 LeonButton
**Defined in:** `lib/shared/widgets/leon_button.dart`

```
Height:           52dp
Border radius:    12dp
Background:       #00E5FF (default) | #E53935 (destructive)
Text:             Outfit, 13px, weight 600, ALL CAPS, letterSpacing 1.8, color #0A0C10
Icon size:        18dp
Glow:             BoxShadow color rgba(0,229,255,0.25), blur 14, spread 1, offset (0,4)

States:
  Default:    background #00E5FF, glow active
  Loading:    background #00E5FF, 18dp white CircularProgressIndicator, disabled
  Disabled:   background #008EAF, no glow, opacity 0.60
  Destructive: background #E53935, glow rgba(229,57,53,0.25)
  Pressed:    scale 0.97, brightness +5%
```

### 5.2 Glass Input Field
```
Fill:           #1A1F2E
Border:         1px solid #FFFFFF33
Border radius:  12dp
Text:           Outfit 14px, #EAECF0
Placeholder:    Outfit 14px, #4A5568
Label above:    Label Small style (ALL CAPS, #8892A4)

States:
  Default:   fill #1A1F2E, border #FFFFFF33
  Focused:   border #00E5FF 1.5px, subtle left cyan accent line 3dp
  Error:     border #E53935, error text below in #E53935 11px
  Filled:    border #FFFFFF33, text #EAECF0
  Disabled:  opacity 0.45
```

### 5.3 Filter Pills / Chips
```
Active pill:
  background: #00E5FF
  text:       #0A0C10, Outfit 12px, weight 500
  border:     none
  radius:     20dp
  padding:    12dp horizontal, 6dp vertical

Inactive pill:
  background: #FFFFFF14
  text:       #8892A4, same font
  border:     1px solid #FFFFFF33
  radius:     20dp
```

### 5.4 Muscle Group Badges
```
Push:  background rgba(0,229,255,0.15),  border rgba(0,229,255,0.40),  text #00E5FF
Pull:  background rgba(123,97,255,0.15), border rgba(123,97,255,0.40), text #7B61FF
Legs:  background rgba(255,107,53,0.15), border rgba(255,107,53,0.40), text #FF6B35
Core:  background rgba(255,214,0,0.15),  border rgba(255,214,0,0.40),  text #FFD600

Warm-up:
  background: rgba(255,166,0,0.15)
  border:     rgba(255,166,0,0.40)
  text:       #FFA600
  label:      "WARM-UP" — JetBrains Mono 9px, letterSpacing 1

PR badge:
  background: rgba(0,229,255,0.10)
  border:     1px solid #00E5FF
  text:       #00E5FF — "RPE X" or "NEW PR"
```

### 5.5 Exercise Accent Bar
```
Width:    4dp
Height:   48dp (matches exercise card content height)
Radius:   2dp

Colors by muscle group:
  Push:  #00E5FF
  Pull:  #7B61FF (or #69FF47 — green variant also acceptable)
  Legs:  #FF6B35
  Core:  #FFD600
  Other: #4A5568
```

### 5.6 RPE Slider
```
Track height:     4dp
Track color:      #1E2537
Filled gradient:  linear — #7B61FF (left/low) → #00E5FF (center) → #E53935 (right/high)
Thumb:            14dp circle, fill #00E5FF, glow rgba(0,229,255,0.40) blur 8dp
Labels:           "1" and "10" in JetBrains Mono 11px at ends
Current value:    shown above thumb — JetBrains Mono 14px bold, #00E5FF
```

### 5.7 Segmented Control
```
Container:    glass card, border-radius 10dp
Active tab:   background #00E5FF, text #0A0C10, Outfit 12px weight 600
Inactive tab: transparent, text #8892A4, Outfit 12px
Height:       36dp
Transition:   animated fill slide
```

### 5.8 Toggle Switch (Neumorphic)
```
Off state:
  track:  #1A1F2E, inset shadow
  thumb:  #4A5568

On state:
  track:  #00E5FF (default) | #FF6B35 (warm-up) | #E53935 (danger)
  thumb:  #FFFFFF

Transition: 200ms ease-in-out
```

### 5.9 Drag Handle
```
Width:      36dp
Height:     4dp
Radius:     2dp
Color:      #4A5568
Position:   top center of bottom sheets, 12dp from top
```

### 5.10 Bottom Sheet
```
Background:   glass card style (#FFFFFF14 + blur 10px)
Top radius:   24dp
Border:       1px solid #FFFFFF33 (top and sides only)
Drag handle:  always present
Min height:   30% of screen
Max height:   90% of screen
Backdrop:     rgba(0,0,0,0.6) scrim behind sheet
```

---

## 6. Navigation

### Bottom Navigation Bar
```
Height:         64dp
Background:     #11141C
Top border:     1px solid #FFFFFF33
Icon size:      24dp (outlined style)
Label:          Outfit 11px, weight 500

Tabs (in order):
  0: Dashboard   — dashboard_outlined
  1: Workout     — fitness_center_outlined
  2: History     — history
  3: Analytics   — bar_chart
  4: Profile     — person_outline

Selected state:
  Icon + label: #00E5FF
  Indicator:    4dp × 4dp cyan dot below icon

Unselected state:
  Icon + label: #4A5568

Elevation: none — flat surface
```

### AppBar
```
Background:       AppColors.background (transparent on scroll)
Title:            AppTypography.headlineMedium
Icon color:       AppColors.textPrimary
Elevation:        0
Center title:     false (left-aligned)
```

### Route Transitions
```
Forward:  slide left + fade (300ms)
Back:     slide right + fade (200ms)
Modal:    slide up from bottom (350ms, elastic curve)
```

---

## 7. Spacing System

LEON uses an 8dp base grid. All spacing values must be multiples of 4dp.

```
4dp   — xs  (micro spacing, icon padding)
8dp   — sm  (tight spacing between related elements)
12dp  — sm+ (card internal padding compact)
16dp  — md  (standard card padding, screen horizontal margin)
20dp  — md+ (between sections within a card)
24dp  — lg  (between cards)
32dp  — xl  (between major sections)
48dp  — 2xl (top section padding)
64dp  — 3xl (full section gaps)
```

### Screen Margins
```
Horizontal padding:   16dp (all screens)
Vertical padding:     16dp (content start)
Bottom safe area:     16dp minimum above bottom edge
```

---

## 8. Elevation & Depth

LEON uses visual depth through blur and opacity, not hard shadows.

```
Level 0 (background):     #0A0C10, no blur
Level 1 (surface):        #11141C, no blur
Level 2 (cards):          glass effect — blur 10px, #FFFFFF14
Level 3 (overlays):       glass effect — blur 16px, #FFFFFF1A (slightly more opaque)
Level 4 (modals/sheets):  glass effect — blur 20px, #FFFFFF1F
```

Hard shadows are ONLY used for:
- LeonButton glow (rgba(0,229,255,0.25), blur 14)
- PR banner glow (rgba(0,229,255,0.30), blur 20)
- Active recovery status ring glow (rgba(0,200,83,0.40), blur 12)

---

## 9. Animation & Motion

### Timing Functions
```
Fast:     150ms — micro-interactions (button press, toggle)
Normal:   300ms — screen transitions, card expand
Slow:     500ms — onboarding transitions, complex animations
Crawl:    900ms — pulsing animations (recovery widget)
```

### Curves
```
Standard:    Curves.easeInOut
Enter:       Curves.easeOut
Exit:        Curves.easeIn
Spring:      Curves.elasticOut (FAB, bottom sheets)
```

### Core Animations

**Recovery Status Widget — Pulse:**
```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0.6, end: 1.0),
  duration: const Duration(milliseconds: 900),
  curve: Curves.easeInOut,
  // Ring opacity: 0.6 → 1.0 → 0.6, loops
  // Ring scale: 1.0 → 1.15 → 1.0, loops
)
```

**PR Banner — Slide down from top:**
```
Enter:  slide from y=-60 → y=0, fade 0→1, duration 300ms easeOut
Exit:   slide from y=0 → y=-60, fade 1→0, duration 200ms easeIn, auto after 3000ms
```

**Rest Timer Overlay — Slide up:**
```
Enter:  slide from y=+300 → y=0, duration 350ms elasticOut
Exit:   slide from y=0 → y=+300, duration 250ms easeIn
```

**Radar Chart — Draw animation:**
```
Axes:    draw one by one, 200ms per axis, staggered
Polygon: scale 0 → 1 from center, 400ms easeOut after all axes drawn
Fill:    fade opacity 0 → 1, 200ms after polygon
```

**Onboarding — Page transitions:**
```
Exit:   slide left x=0 → x=-30, fade 1→0, 250ms
Enter:  slide right x=+30 → x=0, fade 0→1, 300ms
```

**Button press:**
```
Scale: 1.0 → 0.97 on press down, 0.97 → 1.0 on release
Duration: 150ms easeInOut
```

### Lottie Animation Files
```
assets/lottie/pr_celebration.json     — plays on PR detected (2.5s, no loop)
assets/lottie/onboarding_intro.json   — plays on welcome screen (3s, no loop)
assets/lottie/program_ready.json      — plays on program ready screen (2s, plays once)
```

---

## 10. Charts & Data Visualisation

### 10.1 Radar / Spider Chart
**Library:** `fl_chart` — `RadarChart`

```dart
// 3-axis PPL view
axes: [Push, Pull, Legs]
colors: [#00E5FF, #7B61FF, #FF6B35]

// 6-axis detailed view
axes: [Chest, Back, Shoulders, Arms, Legs, Core]

// Shared properties
gridColor:        #1E2537
gridLines:        4 rings
fillColor:        rgba(0,229,255,0.12)
strokeColor:      #00E5FF
strokeWidth:      2dp
labelStyle:       JetBrains Mono 11px, color = axis color
tickCount:        4

// Imbalance detection
threshold:        < 40% of max axis value
weak axis:        label color → #E53935
text insight:     shown below chart, Outfit 13px, #E53935
```

### 10.2 GitHub-Style Heatmap
```
Grid:       52 columns × 7 rows
Cell size:  10dp × 10dp
Gap:        2dp
Radius:     2dp

Color scale (by volume intensity):
  None:     #1E2537
  Low:      rgba(0,229,255,0.20)
  Medium:   rgba(0,229,255,0.50)
  High:     #00E5FF (full opacity)

Labels:     month names below — JetBrains Mono 9px, #4A5568
Tooltip:    on tap — glass card — date + workout name + volume
```

### 10.3 Progress Line Chart (1RM)
```
Line color:       #00E5FF, strokeWidth 2dp
Area fill:        rgba(0,229,255,0.08)
PR markers:       ★ star icon, #00E5FF, 16dp
Axes:             JetBrains Mono 10px, #4A5568
Grid lines:       #1E2537, 0.5dp
Background:       transparent (shows glass card behind)
```

### 10.4 Volume Bar Chart
```
Bar color:        #00E5FF at 20% opacity fill, solid #00E5FF 2dp top line
Bar radius:       4dp top corners
Background:       transparent
X-axis labels:    JetBrains Mono 9px, #4A5568
Y-axis:           hidden (values shown in tooltips only)
```

### 10.5 Plate Calculator Diagram
```
Bar:              240dp wide × 8dp tall, #8892A4
Collar:           6dp wide × 48dp tall, #4A5568

Plate colors (left to right = heaviest to lightest):
  25kg:   #E53935 (Red)
  20kg:   #2196F3 (Blue)
  15kg:   #FFC107 (Yellow)
  10kg:   #4CAF50 (Green)
  5kg:    #EAECF0 (White/chrome)
  2.5kg:  #E53935 (Small red)
  1.25kg: #9E9E9E (Chrome)

Plate height (proportional to weight):
  25kg:   44dp
  20kg:   40dp
  15kg:   36dp
  10kg:   32dp
  5kg:    26dp
  2.5kg:  20dp
  1.25kg: 16dp
```

---

## 11. Screen Inventory

| # | Screen | Route | File | Priority |
|---|---|---|---|---|
| 01 | Splash | — | `features/authentication/screens/splash_screen.dart` | Phase 2 |
| 02 | Onboarding Welcome | `/questionnaire` | `features/questionnaire/screens/questionnaire_screen.dart` | Phase 2 |
| 03–14 | Onboarding Steps | `/questionnaire` | `features/questionnaire/screens/questionnaire_screen.dart` | Phase 2 |
| 15 | Generating | `/questionnaire` | `features/questionnaire/screens/generating_screen.dart` | Phase 2 |
| 16 | Programme Ready | `/onboarding/program-ready` | `features/onboarding/screens/onboarding_screen.dart` | Phase 2 |
| 17 | Login | `/auth/login` | `features/authentication/screens/login_screen.dart` | Phase 2 |
| 18 | Signup | `/auth/signup` | `features/authentication/screens/signup_screen.dart` | Phase 2 |
| 19 | Dashboard | `/` | `features/dashboard/screens/dashboard_screen.dart` | Phase 3 |
| 20 | Exercise Library | `/exercise-library` | `features/exercise_library/screens/exercise_library_screen.dart` | Phase 3 |
| 21 | Exercise Detail | `/exercise-library/:id` | `features/exercise_library/screens/exercise_detail_screen.dart` | Phase 4 |
| 22 | Workout Builder | `/workout-builder` | `features/workout_builder/screens/workout_builder_screen.dart` | Phase 3 |
| 23 | Active Session | `/workout-session` | `features/workout_session/screens/workout_session_screen.dart` | Phase 2 |
| 24 | Set Logger Sheet | modal | `features/workout_session/widgets/set_logger_widget.dart` | Phase 2 |
| 25 | Plate Calculator | modal | `shared/widgets/plate_calculator_sheet.dart` | Phase 2 |
| 26 | PR Banner | overlay | `shared/widgets/pr_banner_widget.dart` | Phase 2 |
| 27 | Session Summary | `/session-summary` | `features/workout_session/screens/session_summary_screen.dart` | Phase 2 |
| 28 | Recovery | `/recovery` | `features/recovery/screens/recovery_screen.dart` | Phase 3 |
| 29 | Analytics | `/analytics` | `features/analytics/screens/analytics_screen.dart` | Phase 4 |
| 30 | History List | `/history` | `features/workout_session/screens/workout_history_screen.dart` | Phase 3 |
| 31 | History Detail | `/history/:id` | `features/workout_session/screens/workout_detail_screen.dart` | Phase 3 |
| 32 | Split Builder | `/split-builder` | `features/split_builder/screens/split_builder_screen.dart` | Phase 3 |
| 33 | Profile | `/profile` | `features/profile/screens/profile_screen.dart` | Phase 3 |
| 34 | Health Tracking | `/health` | `features/health_tracking/screens/health_tracking_screen.dart` | Phase 5 |

---

## 12. Do Not Rules

These are absolute. Non-negotiable. Any PR that violates these is rejected.

```
❌ DO NOT use flat opaque cards — always glass
❌ DO NOT use setState for complex state — Riverpod only
❌ DO NOT hardcode colors — always use AppColors tokens
❌ DO NOT hardcode text styles — always use AppTypography tokens
❌ DO NOT use a number without JetBrains Mono
❌ DO NOT reduce blur below 8px on glass cards
❌ DO NOT use the primary cyan decoratively — it has semantic meaning
❌ DO NOT add padding that isn't a multiple of 4dp
❌ DO NOT let cards touch screen edges (minimum 16dp margin)
❌ DO NOT use filled/solid icons in unselected state
❌ DO NOT add animations longer than 500ms (except pulsing loops)
❌ DO NOT show a loading spinner for local Hive reads (they're instant)
❌ DO NOT use withOpacity on text — use the defined color tokens
❌ DO NOT edit *.freezed.dart or *.g.dart files manually
```

---

## 13. Asset Inventory

```
assets/
├── fonts/
│   ├── Outfit-Regular.ttf
│   ├── Outfit-Medium.ttf
│   ├── Outfit-Bold.ttf
│   ├── JetBrainsMono-Regular.ttf
│   ├── JetBrainsMono-Medium.ttf
│   └── JetBrainsMono-Bold.ttf
├── images/
│   └── leon_app_icon.png
└── lottie/
    ├── pr_celebration.json
    ├── onboarding_intro.json
    └── program_ready.json
```

---

## 14. Accessibility

- Minimum tap target: 44×44dp (all buttons, icons, interactive elements)
- Color is NEVER the only state indicator — always pair with icon or text
- All interactive elements have semantic labels for screen readers
- Font scaling: UI must not break at system font scale 1.3×
- Contrast ratio: text on glass cards must meet WCAG AA (4.5:1 minimum)

---

## 15. Version History

| Version | Date | Changes |
|---|---|---|
| 1.0 | March 2026 | Initial design system — full Cyber-Slate Tactical spec |

---

*This document is maintained alongside the codebase. When a design decision changes, update this file in the same commit.*
