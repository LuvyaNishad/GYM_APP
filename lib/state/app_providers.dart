/// LEON — global Riverpod providers.
///
/// Feature-specific providers live inside each feature's own `providers/`
/// directory. This file is for truly cross-cutting state (auth user, theme, etc.)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/split_model.dart';
import '../models/user_model.dart';

// ── Auth State ────────────────────────────────────────────────────────────────

/// The UID of the currently authenticated user, or null if logged out.
/// Feature providers should `watch` this to react to auth changes.
final currentUserIdProvider = StateProvider<String?>((ref) => null);

/// Whether the app has completed its bootstrap (Hive init, DI, etc.)
final appBootstrappedProvider = StateProvider<bool>((ref) => false);

// ── Theme ─────────────────────────────────────────────────────────────────────

/// Whether the UI is in compact (phone) or expanded (tablet) layout.
final isCompactLayoutProvider = Provider<bool>((ref) => true);

// ── Navigation ────────────────────────────────────────────────────────────────

/// Currently selected bottom-navigation index.
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// ── Training Split ────────────────────────────────────────────────────────────

/// The user's currently active training split.
/// Drives "today's workout" on the dashboard and session-start routing.
/// Null = no split assigned yet (send user to split builder).
final activeSplitProvider = StateProvider<SplitModel?>((ref) => null);

// ── User Profile ──────────────────────────────────────────────────────────────

/// The current user's profile model.
/// Drives weight-unit toggle, profile screen display, and questionnaire data.
/// Null = not loaded yet.
final userProfileProvider = StateProvider<UserModel?>((ref) => null);
