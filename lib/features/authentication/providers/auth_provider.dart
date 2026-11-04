import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/auth_service.dart';

/// Auth status for the authentication feature.
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.userId,
    this.email,
    this.error,
    this.isLoading = false,
  });

  final AuthStatus status;
  final String? userId;
  final String? email;
  final String? error;
  final bool isLoading;

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? email,
    String? error,
    bool? isLoading,
  }) =>
      AuthState(
        status: status ?? this.status,
        userId: userId ?? this.userId,
        email: email ?? this.email,
        error: error,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// Authentication notifier bridging UI with Supabase AuthService.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    ref.keepAlive();
    final authService = ref.watch(authServiceProvider);
    if (authService.isAuthenticated) {
      return AuthState(
        status: AuthStatus.authenticated,
        userId: authService.currentUserId,
        email: authService.currentUserEmail,
      );
    }
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  AuthService get _authService => ref.read(authServiceProvider);

  /// Sign in with email and password.
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.signInWithEmail(email, password);
      if (response.user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          userId: response.user!.id,
          email: response.user!.email,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Sign in failed. Please check your credentials.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _formatAuthError(e),
      );
      rethrow;
    }
  }

  /// Register a new account.
  Future<void> signUp(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: name,
      );
      if (response.user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          userId: response.user!.id,
          email: response.user!.email,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Account creation failed.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _formatAuthError(e),
      );
      rethrow;
    }
  }

  /// Sign in anonymously for guest sessions.
  Future<void> signInAsGuest() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.signInAnonymously();
      state = AuthState(
        status: AuthStatus.authenticated,
        userId: response.user?.id,
        email: 'Guest',
        isLoading: false,
      );
    } catch (e) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
    }
  }

  /// Sign out current user.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.signOut();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  String _formatAuthError(Object error) {
    final str = error.toString();
    if (str.contains('Invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (str.contains('User already registered')) {
      return 'An account with this email already exists.';
    }
    if (str.contains('Password should be at least 6 characters')) {
      return 'Password must be at least 6 characters.';
    }
    if (str.contains('SocketException') || str.contains('Failed host lookup')) {
      return 'No internet connection. Please check your network.';
    }
    return 'Authentication error: $str';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
