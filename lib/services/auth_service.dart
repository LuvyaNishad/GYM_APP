import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Provider that exposes the AuthService singleton.
final authServiceProvider = Provider<AuthService>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return AuthService(supabaseService);
});

/// Bridges Riverpod state with Supabase auth operations.
class AuthService {
  const AuthService(this._supabaseService);

  final SupabaseService _supabaseService;

  SupabaseClient get _client => _supabaseService.client;

  /// Sign in with email and password.
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Register a new account.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: displayName != null && displayName.isNotEmpty
          ? {'full_name': displayName.trim()}
          : null,
    );
  }

  /// Sign in anonymously for guest users so they obtain a unique UUID.
  Future<AuthResponse> signInAnonymously() async {
    return await _client.auth.signInAnonymously();
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    if (_supabaseService.isInitialized) {
      await _client.auth.signOut();
    }
  }

  /// Returns the current authenticated user id, or null.
  String? get currentUserId => _supabaseService.currentUserId;

  /// Returns the current authenticated user email, or null.
  String? get currentUserEmail => _supabaseService.currentUser?.email;

  /// Whether a user session is active.
  bool get isAuthenticated => _supabaseService.currentUserId != null;
}
