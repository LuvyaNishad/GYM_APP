# LEON — GOOGLE STITCH MASTER PROMPT
## Complete 27-Screen UI Generation Request

---

## CRITICAL INSTRUCTIONS — READ FIRST

You are generating a complete, production-quality mobile UI for **LEON**, an elite fitness operating system. This is NOT a generic fitness app. Every design decision must feel like premium military-grade software.

**Device:** Android portrait phone only. Use 390×844dp canvas (standard Android phone viewport).

**Do NOT use:**
- Flat Material Design
- Generic fitness app templates
- Saturated rainbow gradients
- Skeuomorphic elements
- Cartoon icons
- Any screen that looks like it belongs in a different app

**Every single screen MUST use:**
- Glassmorphism cards (backdrop-blur: 10px, background: #FFFFFF14, border: 1px solid #FFFFFF33, border-radius: 16px)
- OLED black scaffold (#0A0C10) — except active workout which is true black (#000000)
- Neon cyan (#00E5FF) as the primary accent
- Outfit font for all headers and labels
- JetBrains Mono for ALL numbers, metrics, weights, reps, timers, and data values
- Consistent 8dp spacing grid throughout

---

## GLOBAL DESIGN SYSTEM

### Color Tokens
```
Background Primary:    #0A0C10  (OLED Black — main scaffold)
Background Active:     #000000  (True Black — active workout only)
Surface:               #11141C  (raised surface)
Surface Variant:       #1A1F2E  (card backgrounds, input fills)
Glass Fill:            #FFFFFF14 (8% white — all glass cards)
Glass Border:          #FFFFFF33 (20% white — all glass card borders)

Primary:               #00E5FF  (Neon Cyan)
Primary Dim:           #008EAF  (Dim Cyan — inactive states)
Secondary:             #FF6B35  (Tactical Orange)
Success:               #00C853  (ECG Green)
Warning:               #FFC107  (Amber)
Danger:                #E53935  (Alert Red)
Purple:                #7B61FF  (Pull muscle group / analytics)

Text Primary:          #EAECF0
Text Secondary:        #8892A4
Text Muted:            #4A5568

Chart Push:            #00E5FF
Chart Pull:            #7B61FF
Chart Legs:            #FF6B35
Chart Core:            #FFD600
Chart Grid:            #1E2537
```

### Typography
```
Display Large:  Outfit, 34px, weight 800, letter-spacing 2.0
Display Medium: Outfit, 26px, weight 700, letter-spacing 1.8
Headline Large: Outfit, 22px, weight 700, letter-spacing 1.5
Headline Med:   Outfit, 18px, weight 600, letter-spacing 1.5
Title Large:    Outfit, 16px, weight 600, letter-spacing 1.2
Body Medium:    Outfit, 14px, weight 400, letter-spacing 0.2
Label Small:    Outfit, 11px, weight 500, letter-spacing 1.0, ALL CAPS
Mono Large:     JetBrains Mono, 32px, weight 700, letter-spacing 1.5
Mono Medium:    JetBrains Mono, 20px, weight 500, letter-spacing 1.0
Mono Small:     JetBrains Mono, 13px, weight 400, letter-spacing 0.8
```

### Glass Card Spec (apply to EVERY card, modal, container)
```
background:       rgba(255,255,255,0.08)  →  #FFFFFF14
backdrop-filter:  blur(10px)
border:           1px solid rgba(255,255,255,0.20)  →  #FFFFFF33
border-radius:    16px
padding:          16dp
```

### LeonButton Spec (primary CTA used on every screen)
```
height:           52dp
border-radius:    12dp
background:       #00E5FF
text-color:       #0A0C10
font:             Outfit, 13px, weight 600, ALL CAPS, letter-spacing 1.8
box-shadow:       0 4px 14px rgba(0,229,255,0.25), spread 1px
states:
  default:        background #00E5FF, shadow cyan 25%
  loading:        background #00E5FF, shows 18dp white CircularProgressIndicator, disabled
  disabled:       background #008EAF (dim), no shadow, opacity 0.6
  destructive:    background #E53935, shadow red 25%
```

### Pill / Chip Components
```
Filter pill (active):   background #00E5FF, text #0A0C10, border-radius 20dp, px 12dp py 6dp
Filter pill (inactive): background #FFFFFF14, text #8892A4, border 1px #FFFFFF33, same radius
Muscle badge (Push):    accent #00E5FF
Muscle badge (Pull):    accent #7B61FF
Muscle badge (Legs):    accent #FF6B35
Muscle badge (Core):    accent #FFD600
Warm-up badge:          background rgba(255,166,0,0.15), border rgba(255,166,0,0.4), text orange
PR badge:               background rgba(0,229,255,0.15), border #00E5FF, text #00E5FF
```

### Navigation (Bottom Nav Bar — appears on main app screens)
```
5 tabs, always visible
background:     #11141C
height:         64dp
border-top:     1px solid #FFFFFF33
tabs:           Dashboard | Workout | History | Analytics | Profile
icons:          outlined style
selected:       icon + label in #00E5FF
unselected:     icon + label in #4A5568
active tab:     small 4dp cyan dot indicator below icon
no elevation shadow — flat against the surface
```

### RPE Slider Spec
```
track-height:     4dp
track-color:      #1E2537
filled-color:     linear gradient #7B61FF → #00E5FF → #E53935 (left to right)
thumb:            14dp circle, #00E5FF, glow shadow rgba(0,229,255,0.4) blur 8dp
labels:           1 and 10 in JetBrains Mono 11px at ends
current value:    shown above thumb in JetBrains Mono 14px bold, #00E5FF
```

### Component States (apply everywhere)
```
Interactive elements:
  default:   as specified
  pressed:   scale 0.97, brightness +5%
  disabled:  opacity 0.45, no interaction
  loading:   spinner replaces icon/label, no interaction
  
Glass cards:
  default:    blur 10px, fill #FFFFFF14
  selected:   border changes to #00E5FF, inner glow rgba(0,229,255,0.08)
  error:      border changes to #E53935, inner glow rgba(229,57,53,0.08)

Input fields:
  default:    fill #1A1F2E, border #FFFFFF33
  focused:    border #00E5FF 1.5px, subtle cyan glow
  error:      border #E53935, error text below in #E53935
  filled:     border #FFFFFF33, text #EAECF0
  disabled:   opacity 0.45
```

---

## SCREEN SPECIFICATIONS

---

### SCREEN 01 — SPLASH
**File ref:** `01_splash`
**Background:** #0A0C10, full bleed

**Layout (centered, vertically middle):**
- Word "L E O N" — Outfit, 34px, weight 800, #00E5FF, letter-spacing 4.0
- Below it: "OPERATIONAL FITNESS OS" — Outfit, 11px, weight 500, #8892A4, letter-spacing 2.0, ALL CAPS
- 48dp gap
- Glowing cyan circular loading indicator (not a spinner — a pulsing ring). Ring color #00E5FF, glow shadow rgba(0,229,255,0.4) blur 12dp, ring diameter 40dp, stroke 2dp

**Background detail:** Very subtle radial gradient from center — rgba(0,229,255,0.04) at center fading to transparent at edges. Not visible as an obvious color, just a barely-there atmospheric glow.

**No other elements.**

---

### SCREEN 02 — ONBOARDING: WELCOME
**File ref:** `02_onboarding_welcome`
**Background:** #0A0C10

**Layout:**
- Top 40dp: progress bar — thin 2dp line, #1E2537 background, #00E5FF fill at 0% (first step)
- Center illustration area: abstract tactical grid or radar-like SVG illustration, ~200dp tall, dark with cyan accent lines, NOT a photo or generic illustration
- Headline: "WELCOME TO LEON" — Outfit 28px, weight 700, #EAECF0, letter-spacing 1.5
- Subheading: "Your operational fitness OS.\nBuilt for performance." — Outfit 16px, #8892A4
- 40dp gap
- LeonButton full width: "COMMENCE OPERATION"
- Below button: small text "Already have an account? Sign in" — Outfit 12px, #00E5FF, tappable

---

### SCREEN 03 — ONBOARDING: NAME
**File ref:** `03_onboarding_name`

- Progress bar: 7% fill
- Top label: "01 / 12" in JetBrains Mono 12px, #4A5568
- Headline: "IDENTIFY AGENT" — Outfit 26px, weight 700, #EAECF0
- Subhead: "What do we call you?" — Outfit 15px, #8892A4
- Glass input field:
  - fill: #1A1F2E, border: 1px #FFFFFF33, border-radius 12dp
  - placeholder: "Your name" in #4A5568
  - focused state: border #00E5FF, cyan left accent line 3dp
  - label above field: "DISPLAY NAME" in Label Small
- LeonButton: "CONTINUE" — positioned 32dp above bottom safe area

---

### SCREEN 04 — ONBOARDING: AGE
**File ref:** `04_onboarding_age`

- Progress bar: 14% fill
- Label: "02 / 12"
- Headline: "DATE OF BIRTH"
- Subhead: "How old are you?"
- **Large vertical scroll-wheel picker (iOS drum-roll style):**
  - Shows 5 rows, center row is selected
  - Selected item: JetBrains Mono 42px, weight 700, #00E5FF, full brightness
  - Adjacent items (±1): JetBrains Mono 32px, #8892A4, 70% opacity
  - Outer items (±2): JetBrains Mono 24px, #4A5568, 40% opacity
  - Two horizontal hairlines (#FFFFFF33, 1dp) framing the selected center row
  - Range: 16–80
- LeonButton: "CONFIRM AGE"

---

### SCREEN 05 — ONBOARDING: HEIGHT
**File ref:** `05_onboarding_height`

- Progress bar: 21%
- Label: "03 / 12"
- Headline: "PHYSICAL STATS — HEIGHT"
- **Unit toggle pill at top right:** "CM | FT" — segmented control, glass card, selected side gets cyan fill
- **Same scroll-wheel picker style** — shows height values
  - CM mode: 140–220 cm
  - FT mode: 4'0" – 7'0"
- Live preview: large text below picker showing selected value — JetBrains Mono 18px, #00E5FF
- LeonButton: "CONFIRM HEIGHT"

---

### SCREEN 06 — ONBOARDING: WEIGHT
**File ref:** `06_onboarding_weight`

- Progress bar: 28%
- Label: "04 / 12"
- Headline: "PHYSICAL STATS — WEIGHT"
- **Unit toggle:** "KG | LBS"
- **Same scroll-wheel** — KG: 40–200, LBS: 88–440
- Live preview value below picker
- LeonButton: "CONFIRM WEIGHT"

---

### SCREEN 07 — ONBOARDING: GOAL WEIGHT
**File ref:** `07_onboarding_goal_weight`

- Progress bar: 35%
- Label: "05 / 12"
- Headline: "TARGET WEIGHT"
- Subhead: "Where are you headed?"
- Same scroll-wheel + unit toggle
- Small note below picker: "Optional — tap skip to proceed" in Outfit 12px, #4A5568
- Two buttons: "SKIP" (text button, #8892A4) and LeonButton "SET TARGET"

---

### SCREEN 08 — ONBOARDING: EXPERIENCE LEVEL
**File ref:** `08_onboarding_experience`

- Progress bar: 42%
- Label: "06 / 12"
- Headline: "EXPERIENCE LEVEL"
- Subhead: "Select your current training level"
- **4 large selectable glass cards** (stacked vertically, ~80dp each):

  Card 1 — BEGINNER
  - Icon: simple barbell outline
  - Title: "BEGINNER" — Outfit 15px, weight 600
  - Subtitle: "Less than 1 year. Building foundations." — Outfit 13px, #8892A4
  - Right badge: "3–4 days/week" — JetBrains Mono 11px

  Card 2 — INTERMEDIATE
  - Icon: barbell with plates
  - "INTERMEDIATE" / "1–3 years. Consistent progress."
  - Badge: "4–5 days/week"

  Card 3 — ADVANCED
  - Icon: heavy barbell
  - "ADVANCED" / "3+ years. Optimising performance."
  - Badge: "5–6 days/week"

  Card 4 — ELITE
  - Icon: trophy / medal outline
  - "ELITE" / "Competitive. Periodised programming."
  - Badge: "6 days/week"

- **Selected card state:** border becomes 1.5px #00E5FF, inner background rgba(0,229,255,0.06), cyan checkmark in top right corner
- No CTA button — tapping a card advances automatically

---

### SCREEN 09 — ONBOARDING: PRIMARY GOAL
**File ref:** `09_onboarding_goal`

- Progress bar: 49%
- Label: "07 / 12"
- Headline: "PRIMARY OBJECTIVE"
- **6 glass cards in 2×3 grid** (each ~100dp tall):
  - BUILD MUSCLE — icon: muscle/bicep outline
  - LOSE FAT — icon: flame outline
  - INCREASE STRENGTH — icon: barbell outline
  - ATHLETIC PERFORMANCE — icon: lightning bolt
  - BODY RECOMPOSITION — icon: arrows cycling
  - GENERAL FITNESS — icon: activity chart

- Selected state: same as experience cards (#00E5FF border + inner glow)
- Auto-advance on selection

---

### SCREEN 10 — ONBOARDING: TRAINING FREQUENCY
**File ref:** `10_onboarding_frequency`

- Progress bar: 56%
- Label: "08 / 12"
- Headline: "TRAINING FREQUENCY"
- Subhead: "Days per week you will train"
- **Large number scroll-wheel, range 1–7**
  - Center: massive JetBrains Mono 64px, #00E5FF
- Below picker: dynamic text label changes with selection:
  - 1-2: "Recovery-focused programme recommended"
  - 3: "Full body split recommended"
  - 4: "Upper / Lower split recommended"
  - 5-6: "PPL or Bro Split recommended"
  - 7: "Ensure adequate recovery days"
  - All in Outfit 13px, #8892A4
- LeonButton: "CONFIRM"

---

### SCREEN 11 — ONBOARDING: PREFERRED SPLIT
**File ref:** `11_onboarding_split`

- Progress bar: 63%
- Label: "09 / 12"
- Headline: "PREFERRED PROTOCOL"
- Subhead: "Choose your training split"
- **Horizontal scrolling carousel** of glass cards (each ~120dp wide × 140dp tall):

  Card style:
  - Split name: Outfit 14px, weight 600, #EAECF0
  - Days: JetBrains Mono 11px, #00E5FF (e.g., "6 DAYS")
  - Pattern diagram: small grid of colored circles showing the day pattern
  - Description: Outfit 11px, #8892A4

  Splits shown:
  1. PPL — "6 DAYS" — Push/Pull/Legs/Push/Pull/Legs
  2. Upper/Lower — "4 DAYS"
  3. Full Body — "3 DAYS"
  4. Bro Split — "5 DAYS"
  5. Arnold Split — "6 DAYS"
  6. Surprise Me — "?" — cyan card with question mark

- Selected card: #00E5FF border, scale 1.04
- LeonButton: "SELECT PROTOCOL"

---

### SCREEN 12 — ONBOARDING: EQUIPMENT
**File ref:** `12_onboarding_equipment`

- Progress bar: 70%
- Label: "10 / 12"
- Headline: "EQUIPMENT PROFILE"
- Subhead: "What does your gym have? Select all that apply."
- **Multi-select chip grid (3 per row):**
  - Barbell | Dumbbells | Cable Machine
  - Smith Machine | Leg Press | Pull-up Bar
  - Resistance Bands | Kettlebells | EZ Bar
  - Bodyweight only | Plate-loaded | Cardio machines

  Chip style:
  - Unselected: glass fill #FFFFFF14, border #FFFFFF33, text #8892A4
  - Selected: background #00E5FF, text #0A0C10, no border

- LeonButton: "CONFIRM EQUIPMENT"
- Small note: "You can update this anytime in Settings"

---

### SCREEN 13 — ONBOARDING: INJURIES
**File ref:** `13_onboarding_injuries`

- Progress bar: 77%
- Label: "11 / 12"
- Headline: "LIMITATIONS & INJURIES"
- Subhead: "We'll adapt your programme to keep you safe"
- **Large selectable cards (same style as experience):**
  - LOWER BACK — "Avoid heavy deadlifts and good mornings"
  - SHOULDER — "Avoid overhead pressing movements"
  - KNEE — "Avoid heavy squatting and lunging"
  - ELBOW / WRIST — "Avoid high-grip-demand exercises"
  - NONE — "No current limitations" — this card has green (#00C853) accent when selected
- Multi-select allowed (except NONE deselects others)
- LeonButton: "CONFIRM"

---

### SCREEN 14 — ONBOARDING: GENERATING PROGRAM
**File ref:** `14_onboarding_generating`

- Progress bar: 91%
- Background: #0A0C10
- **Center animated element:** A radar/spider chart that draws itself — axes extending out one by one, then the polygon filling in with cyan. NOT a loading spinner. This is the signature LEON animation.
- Below animation: scanning text that changes every ~800ms:
  - "ANALYSING PROFILE..."
  - "CALIBRATING SPLIT..."
  - "MAPPING MUSCLE GROUPS..."
  - "OPTIMISING RECOVERY..."
  - "DEPLOYING PROGRAMME..."
  - All in JetBrains Mono 14px, #00E5FF
- Progress bar below text: #1E2537 track, #00E5FF fill, animating 0→100%
- No button — auto-advances when complete

---

### SCREEN 15 — ONBOARDING: PROGRAMME READY
**File ref:** `15_onboarding_program_ready`

- Progress bar: 100% (full cyan)
- **Top glass card — recommended split summary:**
  - Header: "RECOMMENDED PROTOCOL" — Label Small, #8892A4
  - Split name: "PUSH PULL LEGS" — Headline Large, #EAECF0
  - Training days: row of 7 day chips (MON TUE WED THU FRI SAT SUN), active days in cyan glass, rest days in #1E2537
  - Estimated duration: "60–75 MIN / SESSION" — JetBrains Mono 14px, #00E5FF
  - Recovery score prediction: "RECOVERY: OPTIMISED" — ECG green chip

- **Middle glass card — weekly structure:**
  - 6 rows (one per training day), each showing:
    - Day name (JetBrains Mono 12px, #8892A4)
    - Session type (Outfit 14px, #EAECF0) e.g. "Push Day A"
    - Muscle group colored dots

- **Bottom:**
  - LeonButton: "DEPLOY PROGRAMME"
  - Below: "Customise first" — text button, #00E5FF

---

### SCREEN 16 — AUTHENTICATION: LOGIN
**File ref:** `16_auth_login`

- Background: #0A0C10 with a soft blurred cyan orb (rgba(0,229,255,0.06), 300dp diameter, positioned top-right, blurred 60dp) for atmospheric glass reflection
- **Top:** "LEON" wordmark — Outfit 34px, #00E5FF, letter-spacing 4.0
- Below: "OPERATIONAL FITNESS OS" — Label Small, #8892A4

- **Large glass card (center):**
  - Glass spec as defined globally
  - Field 1: Email
    - Label: "EMAIL" — Label Small, #8892A4
    - Input: fill #1A1F2E, border #FFFFFF33, border-radius 12dp, icon: mail outline left side
    - Focused: border #00E5FF
  - 16dp gap
  - Field 2: Password
    - Label: "PASSWORD"
    - Input: same style, icon: lock outline left, eye toggle right
    - Focused state same
  - 24dp gap
  - LeonButton full width: "SIGN IN"
  - 16dp gap
  - Divider: thin line with "OR" centered, all #4A5568
  - 16dp gap
  - Ghost button (glass, no fill, border #FFFFFF33): "CONTINUE AS GUEST" — Outfit 13px, #8892A4

- Bottom: "No account? Create one →" — Outfit 13px, #00E5FF, centered

- **Component states shown:**
  - Email field: show filled state (with example email)
  - Password field: show filled + obscured dots
  - Error state inset: small example below email "Invalid email address" in #E53935, 11px

---

### SCREEN 17 — AUTHENTICATION: SIGNUP
**File ref:** `17_auth_signup`

- Same background as login
- Back button top left (chevron, #EAECF0)
- Headline: "CREATE ACCOUNT" — Headline Large
- Subhead: "Join the programme." — #8892A4

- **Glass card:**
  - Display Name field
  - Email field
  - Password field
  - Confirm Password field
  - 24dp gap
  - LeonButton: "CREATE ACCOUNT"
  - Below: "By continuing you agree to our Terms & Privacy" — Outfit 11px, #4A5568, centered

---

### SCREEN 18 — DASHBOARD
**File ref:** `18_dashboard`

- Bottom nav visible
- **SliverAppBar (collapsed state shown):**
  - "LEON" — Display Medium, #00E5FF, letter-spacing 4
  - Right: profile avatar circle (32dp, glass card with user initials)
  - No elevation, #0A0C10 background

- **Scrollable content (top to bottom):**

  **Card 1 — RECOVERY STATUS** (full width glass card):
  - Left: pulsing circle (40dp, border 2dp #00C853, inner glow green). Inside: heart icon #00C853
  - Center column:
    - "RECOVERY STATUS" — Label Small, #4A5568
    - "READY TO TRAIN" — Title Large, #00C853
  - Right: chevron > in #4A5568
  - Pulse animation: ring scale 1.0→1.15→1.0, opacity 1.0→0.6→1.0, 900ms loop

  **Card 2 — MUSCLE BALANCE RADAR** (full width glass card, ~260dp tall):
  - Header row: "MUSCLE BALANCE" Label Small left, "THIS WEEK" pill right
  - Radar chart: 3 axes — PUSH (cyan), PULL (purple), LEGS (orange)
  - Grid lines: #1E2537
  - Filled polygon: rgba(0,229,255,0.15) fill, #00E5FF stroke
  - Axis labels at tips: PUSH / PULL / LEGS in Label Small, respective colors
  - Pending data message: "fl_chart — pending" in JetBrains Mono 10px, center glass pill

  **Card 3 — WEEK STATS ROW** (3 mini glass cards in a row):
  - Card A: "VOLUME" label + "0 KG" in Mono Medium
  - Card B: "STREAK" label + "0 DAYS" in Mono Medium
  - Card C: "SESSIONS" label + "0" in Mono Medium
  - All labels in Label Small, #4A5568

  **Card 4 — UPCOMING WORKOUT** (full width glass card):
  - Top left: "TODAY'S SESSION" — Label Small, #4A5568
  - Session name: "PUSH DAY A" — Headline Medium, #EAECF0
  - Exercises preview: 3 exercise names in Outfit 13px, #8892A4, with • between
  - Bottom row: "5 EXERCISES" (JetBrains Mono 11px) + "START" LeonButton (compact, 40dp height, right-aligned)

  **Card 5 — MY PROGRAMME** (full width glass card):
  - "MY PROGRAMME" — Label Small
  - Active split name: "PPL — 6 DAY" — Title Large
  - Today's marker: "TODAY: PUSH DAY A" — JetBrains Mono 13px, #00E5FF
  - Tap entire card → navigates to Split Builder

  **Quick Actions Row** (3 equal glass cards):
  - HISTORY — Icons.history — label
  - ANALYTICS — Icons.bar_chart
  - RECOVERY — Icons.favorite_border

- Bottom nav active tab: Dashboard

---

### SCREEN 19 — EXERCISE LIBRARY
**File ref:** `19_exercise_library`

- Bottom nav active: Workout tab
- **AppBar:**
  - Title: "EXERCISE LIBRARY" — Headline Medium
  - No back button (accessed from bottom nav)

- **Search bar (glass):**
  - Full width, below AppBar
  - fill #1A1F2E, border #FFFFFF33, border-radius 12dp
  - Prefix: search icon #4A5568
  - Placeholder: "Search exercises..." — #4A5568

- **Filter pills (horizontal scroll):**
  - ALL | PUSH | PULL | LEGS | CORE | BARBELL | DUMBBELL | CABLE | BODYWEIGHT
  - Active pill: #00E5FF fill, #0A0C10 text
  - Inactive: glass #FFFFFF14, #8892A4 text

- **Exercise list (ListView):**
  Each item is a glass card with:
  - Left: 4dp × 48dp color accent bar (Push=cyan, Pull=purple, Legs=orange, Core=yellow)
  - 16dp gap
  - Column:
    - Exercise name: Outfit 15px, weight 600, #EAECF0
    - Row below: "LEGS · BARBELL" — JetBrains Mono 11px, #4A5568, letter-spacing 0.8
  - Right column:
    - Star icon (favorite toggle) — outlined=#4A5568, filled=#00E5FF
    - If exercise has RPE: cyan glass badge "RPE 7"
  - WARM-UP badge if applicable: orange border pill

  Show these exercises in the list:
  1. Barbell Back Squat (LEGS · BARBELL)
  2. Barbell Bench Press (PUSH · BARBELL)
  3. Conventional Deadlift (PULL · BARBELL)
  4. Overhead Press (PUSH · BARBELL)
  5. Pull-Up (PULL · BODYWEIGHT) — WARM-UP badge variant also shown
  6. Romanian Deadlift (LEGS · BARBELL)
  7. Barbell Row (PULL · BARBELL)
  8. Incline Dumbbell Press (PUSH · DUMBBELL)

---

### SCREEN 20 — EXERCISE DETAIL
**File ref:** `20_exercise_detail`

- **Hero area (top ~200dp):**
  - Dark glass card spanning full width
  - Placeholder anatomy diagram (silhouette with highlighted muscles)
  - Primary muscle highlighted in #00E5FF
  - Secondary muscles in #FF6B35 at 60% opacity
  - Exercise name overlaid bottom-left: "BARBELL BACK SQUAT" — Headline Large
  - Tag pills bottom-right: "COMPOUND" | "BARBELL" | "LEGS" — glass pills

- **Stats row** (3 glass cards):
  - "SETS" + "3" Mono Medium
  - "REPS" + "8-12" Mono Medium
  - "RPE" + "7" Mono Medium

- **1RM Progress chart** (glass card, ~140dp):
  - Label: "STRENGTH PROGRESS" — Label Small
  - Line chart: x=dates, y=estimated 1RM
  - Line color: #00E5FF
  - PR star markers: cyan star icons on peak points
  - Empty state: "Log your first set to see progress"

- **Instructions** (glass card):
  - "HOW TO PERFORM" — Label Small
  - Numbered steps in Outfit 14px, #EAECF0

- **Alternative exercises** (horizontal scroll of small glass cards):
  - "ALTERNATIVES" label
  - Each card: exercise name + muscle badge

- **Bottom** (fixed):
  - LeonButton: "ADD TO WORKOUT"

---

### SCREEN 21 — WORKOUT BUILDER
**File ref:** `21_workout_builder`

- **AppBar:**
  - Back button left
  - Title: "CONFIGURE LOADOUT" — Headline Medium
  - Right: "PREVIEW" text button, #00E5FF

- **Workout name input** (glass card at top):
  - Input field, placeholder "Workout Name", Outfit font, large
  - Focused: #00E5FF border

- **Junk volume warning banner** (shown as example):
  - Full width amber glass card
  - Left icon: warning triangle, #FFC107
  - "JUNK VOLUME DETECTED — Push volume exceeds recommended threshold"
  - Outfit 13px, #FFC107
  - Right: × dismiss button

- **Exercise list** (reorderable):
  Each exercise row is a glass card:
  - Left: drag handle (3 horizontal lines, #4A5568)
  - Accent bar (muscle group color, 4dp)
  - Exercise name: Outfit 15px
  - Below: set/rep pickers inline
    - "SETS" label + −/number/+ controls (JetBrains Mono)
    - "REPS" label + −/number/+ controls
    - "REST" label + duration (90S in Mono)
    - Warm-up toggle: small pill toggle, off=glass, on=orange
  - Right: × remove button, #4A5568

  Show 3 exercises pre-loaded:
  1. Barbell Back Squat — LEGS — 4 sets × 8 reps — 120S rest
  2. Romanian Deadlift — LEGS — 3 sets × 12 reps — 90S rest
  3. Leg Press — LEGS — 3 sets × 15 reps — 90S rest

- **Bottom (fixed):**
  - "ADD EXERCISE" ghost button (glass, full width, dashed border #FFFFFF33)
  - 12dp gap
  - LeonButton: "START WORKOUT"

---

### SCREEN 22 — ACTIVE WORKOUT SESSION
**File ref:** `22_workout_session`
**BACKGROUND: TRUE OLED BLACK #000000 — NOT #0A0C10**

This is the most important screen. It must feel like professional sports software.

- **Top bar:**
  - Left: elapsed time "00:15:42" — JetBrains Mono 20px, #8892A4
  - Center: workout name "PUSH DAY A" — Outfit 14px, #8892A4, letter-spacing 1.2
  - Right: "END" — glass pill button, border #E53935, text #E53935

- **Progress bar** (full width, 4dp):
  - Background: #1E2537
  - Fill: #00E5FF
  - Shows 3 of 5 exercises complete (60% fill)
  - Below: "3 / 5 EXERCISES" — JetBrains Mono 11px, #4A5568, centered

- **Exercise header:**
  - "BARBELL BENCH PRESS" — Outfit 26px, weight 700, #EAECF0, centered
  - "SET 3 / 5" — JetBrains Mono 14px, #4A5568, centered

- **Previous set reference:**
  - Glass pill: "PREV: 80KG × 10 REPS RPE 7" — JetBrains Mono 12px, #4A5568, centered

- **Weight input row:**
  ```
  [−5]   [−2.5]   [ 82.5 KG ]   [+2.5]   [+5]
  ```
  - Minus/plus buttons: glass cards 52dp × 52dp, border #FFFFFF33, text #EAECF0, JetBrains Mono 18px
  - Center value: JetBrains Mono 36px, weight 700, #EAECF0
  - "KG" unit: JetBrains Mono 14px, #4A5568
  - Long-press +2.5: shows increment picker sheet

- **Reps input row (same layout):**
  ```
  [−1]   [−]   [ 10 REPS ]   [+]   [+1]
  ```
  - Center: JetBrains Mono 36px, #EAECF0

- **RPE Slider:**
  - Label row: "RPE" left, "7" right (current value, #00E5FF, JetBrains Mono)
  - Track: 4dp, gradient as specified
  - Thumb: 14dp cyan circle with glow

- **Notes field (collapsible):**
  - Glass input, placeholder "Add set notes..." — Outfit 13px, #4A5568
  - Collapsed by default, expand icon

- **Bottom (fixed):**
  - Plate calculator icon button (left, glass)
  - LeonButton (center, full width minus plate button): "LOG SET"
  - Add exercise icon (right, glass)

- **Rest timer overlay** (shown in active state, slides up from bottom):
  - Semi-transparent glass sheet
  - Large countdown: "01:32" — JetBrains Mono 64px, weight 700, #00E5FF
  - "REST TIMER" — Label Small, #4A5568
  - Circular progress ring: 120dp diameter, #1E2537 track, #00E5FF fill, animating
  - "SKIP" text button below: #8892A4
  - Auto-dismisses when reaches 00:00

---

### SCREEN 23 — SET LOGGER & PLATE CALCULATOR
**File ref:** `23_set_logger_plate_calc`

Show this as two states side by side or stacked — both are bottom sheets:

**State A — Set Logger bottom sheet:**
- Sheet slides up from bottom, glass card, rounded top corners 24dp
- Drag handle: 4dp × 36dp pill, #4A5568, centered at top
- Title: "LOG SET 3" — Outfit 16px, weight 600, #EAECF0
- PR indicator: if beating best, show "🔥 NEW PR INCOMING" banner in cyan glass at top of sheet
- Weight: same −/+ input as session screen but slightly smaller
- Reps: same
- RPE slider: same spec
- Warm-up toggle: "Mark as warm-up" label + neumorphic toggle (off=#1A1F2E, on=#FF6B35)
- LeonButton full width: "SAVE SET"

**State B — Plate Calculator bottom sheet:**
- Same sheet style
- Title: "PLATE CALCULATOR" — Outfit 16px, weight 600
- Input: "TOTAL WEIGHT" glass input, shows "82.5 KG"
- Bar weight selector: pill selector — "15KG | 20KG | 25KG", selected = cyan
- **Visual barbell diagram:**
  - Horizontal bar: #8892A4 rectangle, 240dp wide, 8dp tall, centered
  - Plates drawn as colored rectangles on each side (from inside out):
    - 25kg: Red (#E53935) — 12dp wide × 44dp tall
    - 20kg: Blue (#2196F3) — 11dp × 40dp
    - 15kg: Yellow (#FFC107) — 10dp × 36dp
    - 10kg: Green (#4CAF50) — 9dp × 32dp
    - 5kg: White (#EAECF0) — 8dp × 26dp
    - 2.5kg: Red small — 6dp × 20dp
  - Collar ends: #4A5568, 6dp × 48dp
- Text breakdown below:
  - "PER SIDE: 2×20KG + 1×2.5KG = 42.5KG" — JetBrains Mono 13px, #00E5FF
- LeonButton: "APPLY TO SESSION"

---

### SCREEN 24 — PR BANNER + WORKOUT COMPLETE
**File ref:** `24_workout_complete`

**PR Banner (top overlay, slides down from top):**
- Full width glass card, cyan glow border
- "🏆 NEW PERSONAL RECORD" — Outfit 16px, weight 700, #00E5FF
- Exercise name + "You lifted 87.5KG × 8 REPS" — JetBrains Mono 14px, #EAECF0
- Previous best: "PREVIOUS BEST: 85KG × 8" — JetBrains Mono 12px, #4A5568
- Auto-dismisses after 3 seconds

**Workout Complete screen (below PR banner):**
- Background: #0A0C10
- **Header:** "OPERATION COMPLETE" — Display Medium, #EAECF0
- Subtitle: "Push Day A — Thu 23 Mar" — Outfit 14px, #8892A4

- **Stats row (3 glass cards):**
  - "VOLUME" + "4,125 KG" Mono Medium, #00E5FF
  - "DURATION" + "52:14" Mono Medium
  - "SETS" + "18" Mono Medium

- **PRs broken card (glass, cyan border):**
  - "2 PRs BROKEN" — Title Large, #00E5FF
  - List: "Barbell Bench Press — 82.5KG × 10" and "Incline DB Press — 32.5KG × 12"
  - Each with trophy icon

- **Muscle distribution mini-radar** (glass card, 160dp):
  - Same radar chart, showing this session's muscle hit distribution
  - Push=80%, Pull=0%, Legs=20% (example push day data)

- **Session notes field** (glass card):
  - "SESSION NOTES" — Label Small
  - Glass textarea, placeholder "How was the session?"
  - Character count: "0 / 500"

- **Two buttons (bottom):**
  - Ghost button: "SHARE" — glass, border #FFFFFF33
  - LeonButton: "DONE"

---

### SCREEN 25 — RECOVERY
**File ref:** `25_recovery`

- Bottom nav active: none (accessed from Dashboard quick action)
- AppBar: "RECOVERY" — Headline Medium, back button

- **Hero card — Recovery Score:**
  - Large glass card, full width
  - Center: massive circular dial
    - Outer ring: 160dp diameter, 12dp stroke
    - Track: #1E2537
    - Fill: gradient arc — #E53935 (0%) through #FFC107 (50%) to #00C853 (100%)
    - Current value: "78" — JetBrains Mono 52px, weight 700, #00C853
    - Below value: "RECOVERY SCORE" — Label Small, #4A5568
    - Below: "READY TO TRAIN" — Outfit 16px, weight 600, #00C853
  - Below dial in same card:
    - 5 input sliders (one per recovery factor):

    **Days since last workout:**
    - Label: "REST DAYS" — Label Small left, "1" right (JetBrains Mono)
    - Pill selector: 0d | 1d | 2d | 3d+ — active = cyan

    **Sleep hours:**
    - Label: "SLEEP" left, "7.5 HRS" right
    - Slider: 4–12h, cyan thumb, track gradient

    **Soreness rating:**
    - Label: "SORENESS" left, "3/10" right
    - Slider: 1–10
    - Below slider: body region selector chips: PUSH | PULL | LEGS | CORE

    **Session RPE:**
    - Label: "LAST SESSION RPE" left, "7" right
    - Pill selector: 1-2 | 3-4 | 5-6 | 7-8 | 9-10

    **Muscle group fatigue:**
    - Label: "TRAINED TODAY'S MUSCLES RECENTLY?" left
    - Toggle: NO (green) / YES (red)

- **Insight card** (glass, amber border):
  - "RECOVERY INSIGHT" — Label Small
  - Body: "Pull volume is low this week. Consider targeting back and biceps tomorrow." — Outfit 14px, #EAECF0

- Bottom: LeonButton "SAVE CHECK-IN"

---

### SCREEN 26 — ANALYTICS
**File ref:** `26_analytics`

- Bottom nav active: Analytics (tab 4)
- AppBar: "ANALYTICS" — Headline Medium

- **Segmented control at top:**
  - "OVERVIEW | STRENGTH | VOLUME | CALENDAR"
  - Glass pill, active = #00E5FF fill

**Showing OVERVIEW tab:**

- **GitHub-style heatmap** (glass card, full width):
  - "52-WEEK TRAINING LOG" — Label Small
  - Grid: 52 columns (weeks) × 7 rows (days)
  - Cell: 10dp × 10dp, 2dp gap, border-radius 2dp
  - Colors:
    - No training: #1E2537
    - Low volume: rgba(0,229,255,0.25)
    - Medium: rgba(0,229,255,0.55)
    - High volume: #00E5FF
  - Month labels below: "JAN FEB MAR..." in JetBrains Mono 9px, #4A5568
  - Below grid: "CURRENT STREAK: 5 DAYS · LONGEST: 21 DAYS" — JetBrains Mono 12px, #00E5FF

- **Radar — this week** (glass card, ~200dp):
  - "MUSCLE BALANCE — THIS WEEK" — Label Small
  - Toggle below: "THIS WORKOUT | THIS WEEK | ALL TIME"
  - Inner toggle: "VOLUME | SETS"
  - Radar chart (same spec as dashboard but larger)
  - If any axis < 40% of max: that axis label turns #E53935, text insight below

- **PR summary** (glass card):
  - "RECENT PRs" — Label Small
  - List of 3 most recent PRs: exercise name + weight + date, each with trophy icon

- **Volume trend** (glass card, bar chart ~120dp):
  - "WEEKLY VOLUME" — Label Small
  - 8-bar bar chart, bars in #00E5FF with 20% opacity fill + solid top line
  - X-axis: week labels in JetBrains Mono 9px

---

### SCREEN 27 — PROFILE & SETTINGS
**File ref:** `27_profile`

- Bottom nav active: Profile (tab 5)
- AppBar: "PROFILE" — Headline Medium

- **Profile header glass card:**
  - Circle avatar: 72dp, glass background, user initials in Outfit 26px
  - Name: "OPERATOR" — Headline Medium, #EAECF0
  - Below: "INTERMEDIATE · PPL SPLIT" — Outfit 13px, #8892A4

- **Stats row** (3 glass cards):
  - "WORKOUTS" + "0" Mono Medium
  - "VOLUME" + "0 KG" Mono Medium
  - "STREAK" + "0" Mono Medium

- **Settings sections** (glass cards grouped):

  **Training:**
  - My Active Split → chevron right
  - Exercise Library → chevron right
  - Workout History → chevron right

  **Body:**
  - Current Weight → "82.5 KG" right, tappable
  - Target Weight → "78 KG" right, tappable
  - Weight Unit → "KG | LBS" toggle (neumorphic, active side cyan)

  **Preferences:**
  - Default Rest Timer → "90 SECONDS" right
  - Training Reminder → time + toggle (cyan when on)
  - Recovery Check-In → time + toggle

  **Notifications:**
  - Rest Timer Vibration → toggle
  - Weekly Summary → toggle + day selector
  - Recovery Alerts → toggle

  **Account:**
  - Edit Profile → chevron
  - Export Data → chevron
  - Privacy Policy → chevron
  - Log Out → text in #E53935, no chevron

- Each settings row:
  - Label: Outfit 14px, #EAECF0
  - Right: value in JetBrains Mono 13px, #8892A4, or toggle, or chevron

---

## CROSS-SCREEN REQUIREMENTS

1. **Every screen must look like it belongs to the same operating system.** No screen should feel like it was designed separately.

2. **No screen should be empty.** Every screen must have sufficient data shown to demonstrate the UI at its most useful.

3. **Populate with realistic data everywhere:**
   - User: "OPERATOR" — 82.5 KG — Intermediate — PPL split
   - Sample exercises use real names (Barbell Back Squat, Bench Press, etc.)
   - Dates shown: realistic (March 2026)
   - All metrics have real numbers filled in

4. **Glass cards must never touch screen edges.** Minimum 16dp horizontal margin on all cards.

5. **Bottom safe area:** All fixed bottom CTAs must sit 16dp above bottom edge (account for Android navigation bar).

6. **Consistency check before finalising:**
   - Cyan (#00E5FF) only used for: primary accent, active states, data values, CTAs
   - Orange (#FF6B35) only used for: secondary accent, legs muscle group, warm-up
   - Purple (#7B61FF) only used for: pull muscle group, analytics secondary
   - Green (#00C853) only used for: success states, recovery ready
   - Red (#E53935) only used for: danger, destructive, recovery rest recommended
   - Never use these colors decoratively

7. **Typography enforcement:**
   - ALL numbers, ALL metrics, ALL weights, ALL timer values, ALL rep counts → JetBrains Mono
   - ALL labels, ALL body text, ALL button text, ALL titles → Outfit
   - Never mix fonts within a single text element

8. **Icon style:** Outlined icons only. No filled/solid icons except when in active/selected state.

9. **Spacing grid:** Every spacing value must be a multiple of 4dp. Preferred: 8, 12, 16, 20, 24, 32, 48.

10. **The active workout session (Screen 22) must feel noticeably different** from all other screens — true black background, larger numbers, maximum contrast, zero decorative elements.

---

## OUTPUT REQUIREMENTS

- Generate all 27 screens as a complete design system
- Maintain pixel-perfect consistency across every screen
- Show component states (default, active, error, loading, disabled) where relevant
- Use the exact color values and typography specs defined above
- Every screen must be annotated with the file reference name (01_splash, 02_onboarding_welcome, etc.)
- The result must feel like a production-ready premium Android fitness application

**The final output must be indistinguishable from a real product designed by a senior UI team.**
