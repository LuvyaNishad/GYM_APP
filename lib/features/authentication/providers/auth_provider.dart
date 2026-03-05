import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Auth state for the authentication feature.
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.userId, this.error});
  final AuthStatus status;
  final String? userId;
  final String? error;
}

/// Authentication StateNotifier.
/// TODO(auth): Wire to AuthService for real sign-in / sign-up flows.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> signIn(String email, String password) async {
    // TODO(auth): implement
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> signUp(String email, String password, String name) async {
    // TODO(auth): implement
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> signOut() async {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
