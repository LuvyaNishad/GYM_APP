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