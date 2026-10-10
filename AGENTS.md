# System Context: LEON (Operational Fitness OS)

## Role & Objective
You are an expert Flutter developer building **LEON**, a premium, high-performance fitness tracker.
* **Vibe:** "Cyber-Slate," "Tactical," "Glassmorphism," and "Operational."
* **Tech Stack:** Flutter, Riverpod (State), Hive/Isar (Local DB), fl_chart (Radar).
* **Design Philosophy:** Minimalist, data-heavy but clean, high-contrast aesthetics (inspired by Leon S. Kennedy / RE4 Remake UI).

## Core Architecture
### 1. Dashboard (The Command Center)
* **Radar Chart:** Displays muscle balance (Push vs Pull vs Legs).
* **Recovery Status:** ECG-style widget (Green=Ready, Red=Rest).
* **Quick Actions:** Glass buttons for rapid logging.

### 2. Workout Builder (The Attache Case)
* **Grid Layout:** Users "pack" their workout like an inventory case.
* **Logic:** Drag & drop exercises. "Junk Volume" warnings for redundancy.

### 3. Active Mode (Overlay)
* **Distraction Free:** OLED black background.
* **Tools:** Auto-rest timer, Plate Calculator popup, RPE sliders.

## Coding Standards
* **Glassmorphism:** Use `BackdropFilter` with `sigmaX/Y: 10` for all cards.
* **Typography:** `Outfit` for headers (Letter spacing 1.5+), `JetBrains Mono` for numbers.
* **State:** Use Riverpod. Avoid `setState` for complex logic.
* **File Structure:** `lib/core` (UI/Theme), `lib/features` (Logic), `lib/models` (Data).

## Mandatory Apple HIG Principles (Must Maintain Throughout App Development)
1. **Typography Floor (Min 11.0 pt):** Every piece of text, tag, badge, timestamp, metric caption, and button label MUST have a minimum font size of **11.0 pt** (per Apple HIG `typography.md` & `accessibility.md`). Never drop below 11 pt anywhere in the application.
2. **Contrast Threshold (Min 4.5:1 WCAG AA):** All secondary, inactive, or caption text must meet or exceed a **4.5:1 contrast ratio**. On dark slate backgrounds (`#161A23` / `#141722`), use `Color(0xFF94A3B8)` (Slate-400) or `Colors.white.withValues(alpha: 0.60)` minimum. Never use faint 35–45% opacity washes for small text.
3. **Color Discipline (2-Accent System & Visual Restraint):** Maintain a focused, purposeful 2-accent hierarchy (per Apple HIG `color.md` & `branding.md`):
   * **Primary Accent:** Electric Cyan (`#00E5FF`) for primary calls to action ("Start Workout"), active workout indicators, and primary interactive highlights.
   * **Secondary Status Accent:** Amber (`#FFB300`) for active calendar day selection and metabolic/warning status.
   * **Metrics & Activity:** Use cohesive luminous monochrome silver/slate tones and disciplined tints for secondary progress gauges instead of chaotic multi-colored rainbow neons.
4. **Language Discipline (Strict No-Roleplay / Normal Gym Terminology):**
   * **STRICT PROHIBITION:** NEVER use pseudo-military, sci-fi, or tactical roleplay terms like `protocol`, `operation`, `cadence`, `telemetry`, `operative`, `agent identifier`, `mission`, `briefing`, or `commence`.
   * **Standard Gym Terminology:** Always use clean, professional, normal gym and fitness wording across all UI screens, buttons, cards, badges, and onboarding flows:
     - `COMMENCE OPERATION` → `START WORKOUT`
     - `ACTIVE PROTOCOL` → `TODAY'S WORKOUT`
     - `TACTICAL PUSH // PROTOCOL A` → `PUSH DAY // WORKOUT A`
     - `PREFERRED PROTOCOL` / `SELECT PROTOCOL` → `TRAINING SPLIT` / `SELECT SPLIT`
     - `ACTIVITY TELEMETRY` → `WORKOUT ACTIVITY`
     - `OPERATIONAL FITNESS OS` → `PREMIUM FITNESS OS` / `FITNESS TRACKER`
     - `AGENT IDENTIFIER` → `EMAIL ADDRESS`
     - `OPERATIVE AUTHENTICATION` → `ACCOUNT LOGIN`
     - `DEPLOY AS GUEST` → `CONTINUE AS GUEST`
     - `TACTICAL ADVISORY` → `TRAINING RECOMMENDATION`