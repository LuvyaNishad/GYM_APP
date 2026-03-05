# LEON – AI Project Context

## Project Overview

LEON is a **high-performance fitness tracking application** built with Flutter.
The app is designed to behave like an **Operational Fitness OS**, not just a workout logger.

LEON focuses on:

• fast workout logging
• data-driven training insights
• minimal friction during workouts
• clear visualization of training balance
• performance-oriented UI

The experience should feel **fast, precise, tactical, and professional**, similar to software used by athletes or training coaches.

The app must prioritize **speed, clarity, and reliability** over decorative UI.

---

# Core Design Philosophy

LEON follows a **Cyber-Slate Tactical UI philosophy**.

Key principles:

• Dark interface optimized for OLED screens
• High contrast data display
• Minimal clutter
• Information density without confusion
• Focus on training metrics
• Fast interaction loops

Inspirations:

• Tactical interfaces in modern games
• Resident Evil 4 Remake HUD design
• Professional athlete tracking software
• Military control dashboards

---

# Product Goals

LEON helps users:

1. Log workouts quickly
2. Track training balance (Push / Pull / Legs)
3. Monitor recovery readiness
4. Avoid redundant or junk training volume
5. Maintain long-term consistency

The app should encourage **smart training decisions**, not just record workouts.

---

# Target Users

• Intermediate lifters
• Strength athletes
• Gym enthusiasts
• Personal trainers
• Users who want deeper training insight than typical fitness apps

---

# Tech Stack

Primary Framework:

Flutter

Programming Language:

Dart

State Management:

Riverpod

Local Database:

Hive or Isar (local-first architecture)

Charts:

fl_chart

Platforms:

Primary: Android
Secondary: iOS
Optional: Desktop / Web

---

# Architecture Overview

The project uses a **feature-based architecture**.

Each feature should be isolated and modular.

Directory structure:

lib/
core/
theme/
constants/
utils/
services/

features/
dashboard/
workout_builder/
active_session/
analytics/
recovery/

models/
widgets/

---

# Core Screens

## 1 Dashboard (Command Center)

This is the main screen of the application.

It should function like a **training control panel**.

Displayed information:

• Radar chart (Push / Pull / Legs balance)
• Recovery readiness indicator
• Quick action buttons
• Current workout streak
• Last workout summary

The dashboard should immediately communicate the user's **training state**.

---

## 2 Workout Builder

Users assemble workouts before starting them.

Features:

• drag-and-drop exercises
• reorderable exercise list
• rest timer configuration
• set definitions
• weight and rep presets

The UX should feel similar to **preparing a training loadout**.

---

## 3 Active Workout Mode

When a workout starts the app enters **Focus Mode**.

Design goals:

• minimal distractions
• OLED black background
• large readable numbers
• fast set logging

Features:

• auto rest timer
• quick rep entry
• plate calculator
• RPE slider

---

## 4 Recovery Status

Recovery indicates readiness to train.

States:

Ready (Green)
Moderate (Yellow)
Rest (Red)

Factors used:

• time since last workout
• muscle group fatigue
• workout intensity

---

# Data Models (Conceptual)

Exercise

Fields:

id
name
muscleGroup
equipment
difficulty

Workout

Fields:

id
name
date
exercises

Set

Fields:

weight
reps
RPE
restTime

Session

Fields:

workoutId
startTime
endTime
completedSets

---

# Chart System

Radar charts visualize muscle group balance.

Axes:

Push
Pull
Legs

This helps detect:

• training imbalance
• neglected muscle groups
• overtraining risk

---

# UI Design System

Primary Background

#0B0F14

Secondary Surface

#121821

Card Surface

#1A2330

Accent Color

#7B61FF

Success

#4CAF50

Warning

#FFC107

Error

#F44336

---

# Typography

Headers

Outfit

Metrics and numbers

JetBrains Mono

Body text

Inter

---

# UI Component Style

Cards use glassmorphism style.

Example concept:

• blurred background
• translucent surfaces
• soft rounded corners

Flutter example concept:

BackdropFilter with blur effect.

Spacing grid:

8px layout system

---

# Coding Standards

State management must use Riverpod.

Avoid using setState for complex state.

Prefer:

StateNotifier
Provider
Consumer widgets

Widget rules:

• widgets should be small and reusable
• avoid deeply nested widget trees
• extract components into reusable widgets

---

# Performance Guidelines

The application must remain responsive.

Avoid:

• unnecessary widget rebuilds
• heavy synchronous computation
• blocking the UI thread

Prefer:

• const widgets
• lazy lists
• Riverpod selective listening

---

# AI Development Rules

When generating code:

1. follow the existing architecture
2. maintain UI consistency
3. use Riverpod for state
4. prefer reusable widgets
5. avoid unnecessary dependencies
6. keep logic separate from UI

---

# Feature Roadmap

Future features planned:

• AI workout recommendations
• fatigue detection
• progressive overload tracking
• cloud backup and sync
• social workout sharing
• Apple Health integration
• Google Fit integration

---

# Development Workflow

Standard workflow:

1 design feature
2 implement UI
3 connect state management
4 persist data
5 test on emulator or device

---

# Repository Usage Instructions

When an AI system reads this repository it should:

1 read this context.md file first
2 read gemini.md for system instructions
3 follow the architecture defined here
4 maintain UI and coding standards

---

# Project Name

LEON

Meaning:

A strong, tactical fitness system designed to support serious training.

---

# Summary

LEON is a **data-focused, high-performance fitness tracking system** built with Flutter.

It is designed to:

• be fast
• be minimal
• provide actionable insights
• help users train intelligently
