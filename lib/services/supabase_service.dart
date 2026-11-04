import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';

/// Provider exposing the SupabaseService singleton.
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// Direct Supabase client interactions and lifecycle management.
class SupabaseService {
  SupabaseService();

  static bool _initialized = false;

  /// Initializes the Supabase client with AEON configuration.
  /// Fails gracefully if offline or storage unavailable.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
        debug: false,
      );
      _initialized = true;
      debugPrint(
        '[SupabaseService] Client initialized; cloud saves are verified separately.',
      );
    } catch (e, stack) {
      debugPrint('[SupabaseService] Initialization failed: $e\n$stack');
    }
  }

  /// Whether Supabase client has been successfully initialized.
  bool get isInitialized => _initialized;

  /// The active Supabase client instance.
  SupabaseClient get client => Supabase.instance.client;

  /// Currently authenticated user, or null if unauthenticated.
  User? get currentUser => _initialized ? client.auth.currentUser : null;

  /// Current user ID, or null if unauthenticated.
  String? get currentUserId => currentUser?.id;

  /// Stream of Supabase auth state transitions.
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
