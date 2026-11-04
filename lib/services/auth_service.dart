import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';
import 'hive_service.dart';

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
  static const callbackUrl = 'app.leon.fitness://login-callback/';
  bool get isAnonymous => _supabaseService.currentUser?.isAnonymous ?? false;
  Stream<AuthState> get changes => _supabaseService.isInitialized
      ? _supabaseService.authStateChanges
      : const Stream.empty();

  Future<void> prepareSignIn() async {
    if (currentUserId == null || isAnonymous) {
      await HiveService.stageGuestSource(HiveService.activeWorkspaceId);
    }
  }

  Future<bool> signInWithGoogle({bool useExistingAccount = false}) async {
    await prepareSignIn();
    if (isAnonymous && !useExistingAccount) {
      return _client.auth.linkIdentity(
        OAuthProvider.google,
        redirectTo: callbackUrl,
      );
    }
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: callbackUrl,
    );
  }

  /// Sign in with email and password.
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    await prepareSignIn();
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
    await prepareSignIn();
    return await _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: callbackUrl,
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
    await HiveService.clearGuestSource();
    if (_supabaseService.isInitialized) {
      await _client.auth.signOut(scope: SignOutScope.local);
    }
  }

  /// Returns the current authenticated user id, or null.
  String? get currentUserId => _supabaseService.currentUserId;

  /// Returns the current authenticated user email, or null.
  String? get currentUserEmail => _supabaseService.currentUser?.email;

  /// Whether a user session is active.
  bool get isAuthenticated => _supabaseService.currentUserId != null;
}
