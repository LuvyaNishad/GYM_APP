/// LEON Auth Service (placeholder)
///
/// Bridges Riverpod state with Supabase auth operations.
/// Handles sign-in, sign-up, sign-out, and session persistence.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that exposes the AuthService singleton.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Placeholder auth service.
class AuthService {
  AuthService();

  /// Sign in with email and password.
  Future<void> signInWithEmail(String email, String password) async {
    // TODO(backend): await supabase.client.auth.signInWithPassword(...)
    throw UnimplementedError('signInWithEmail not yet implemented.');
  }

  /// Register a new account.
  Future<void> signUpWithEmail(String email, String password) async {
    // TODO(backend): await supabase.client.auth.signUp(...)
    throw UnimplementedError('signUpWithEmail not yet implemented.');
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    // TODO(backend): await supabase.client.auth.signOut()
    throw UnimplementedError('signOut not yet implemented.');
  }

  /// Returns the current authenticated user id, or null.
  String? get currentUserId =>
      null; // TODO(backend): supabase.client.auth.currentUser?.id
}
