import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/constants/app_constants.dart';
import '../../../services/hive_service.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth_service.dart';
import '../../workout_session/providers/active_session_provider.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.userId,
    this.email,
    this.error,
    this.message,
    this.isLoading = false,
    this.isAnonymous = false,
    this.emailCooldown = 0,
  });
  final AuthStatus status;
  final String? userId, email, error, message;
  final bool isLoading, isAnonymous;
  final int emailCooldown;
  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? email,
    String? error,
    String? message,
    bool? isLoading,
    bool? isAnonymous,
    int? emailCooldown,
  }) => AuthState(
    status: status ?? this.status,
    userId: userId ?? this.userId,
    email: email ?? this.email,
    error: error,
    message: message,
    isLoading: isLoading ?? this.isLoading,
    isAnonymous: isAnonymous ?? this.isAnonymous,
    emailCooldown: emailCooldown ?? this.emailCooldown,
  );
}

class AuthNotifier extends Notifier<AuthState> {
  bool _busy = false;
  Timer? _emailTimer;
  AuthService get _auth => ref.read(authServiceProvider);
  AuthState _current() => AuthState(
    status: _auth.isAuthenticated
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated,
    userId: _auth.currentUserId,
    email: _auth.currentUserEmail,
    isAnonymous: _auth.isAnonymous,
  );
  @override
  AuthState build() {
    final service = ref.watch(authServiceProvider);
    final subscription = service.changes.listen(
      (_) {
        if (ref.mounted) {
          state = _current().copyWith(
            isLoading: _busy,
            emailCooldown: state.emailCooldown,
          );
        }
      },
      onError: (Object _) {
        if (ref.mounted) {
          state = state.copyWith(
            isLoading: false,
            error:
                'Sign-in did not finish. Retry, or use the existing-account option if Google is already linked.',
          );
        }
      },
    );
    ref.onDispose(() => unawaited(subscription.cancel()));
    ref.onDispose(() => _emailTimer?.cancel());
    return _current();
  }

  Future<void> _settleDraft() async {
    final session = ref.read(activeSessionProvider);
    if (session.isActive) {
      throw StateError(
        'Finish your active workout before changing accounts. Your draft remains on this device.',
      );
    }
    await ref.read(activeSessionProvider.notifier).flushPendingChanges();
  }

  Future<void> _run(
    Future<void> Function() action, {
    bool settleDraft = true,
  }) async {
    if (_busy) return;
    _busy = true;
    state = state.copyWith(isLoading: true);
    try {
      if (settleDraft) await _settleDraft();
      await action();
      if (ref.mounted) {
        state = state.copyWith(isLoading: false, message: state.message);
      }
    } catch (error) {
      if (ref.mounted) {
        state = state.copyWith(isLoading: false, error: _format(error));
      }
      rethrow;
    } finally {
      _busy = false;
    }
  }

  Future<void> _sendEmail(
    Future<void> Function() send,
    String message,
  ) => _run(() async {
    if (state.emailCooldown > 0) {
      throw StateError(
        'Please wait ${state.emailCooldown} seconds before requesting another email.',
      );
    }
    await send();
    if (!ref.mounted) return;
    state = state.copyWith(
      message: message,
      emailCooldown: 60,
      isLoading: true,
    );
    _emailTimer?.cancel();
    _emailTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!ref.mounted) {
        timer.cancel();
        return;
      }
      final remaining = (state.emailCooldown - 1).clamp(0, 60);
      state = state.copyWith(
        emailCooldown: remaining,
        message: state.message,
        error: state.error,
      );
      if (remaining == 0) timer.cancel();
    });
  }, settleDraft: false);

  Future<void> requestPasswordReset(String email) => _sendEmail(
    () => _auth.requestPasswordReset(email),
    'If this email can receive a password reset, a link is on its way. Open the newest email on this device. Check your spam folder too.',
  );

  Future<void> resendConfirmation(String email) => _sendEmail(
    () => _auth.resendConfirmation(email),
    'If this account needs confirmation, a new email is on its way. Open the newest email on this device, or sign in if you already confirmed it.',
  );

  Future<void> signIn(String email, String password) => _run(() async {
    final response = await _auth.signInWithEmail(email, password);
    if (response.session == null) {
      throw StateError('Sign in did not create a session.');
    }
    if (ref.mounted) state = _current();
  });
  Future<void> signUp(
    String email,
    String password,
    String name,
  ) => _run(() async {
    final response = await _auth.signUpWithEmail(
      email: email,
      password: password,
      displayName: name,
    );
    if (!ref.mounted) return;
    state = response.session == null
        ? const AuthState(
            status: AuthStatus.unauthenticated,
            message:
                'Check your email to confirm your account, then sign in. No cloud save has happened yet.',
          )
        : _current();
  });
  Future<void> signInWithGoogle({
    bool useExistingAccount = false,
  }) => _run(() async {
    final launched = await _auth.signInWithGoogle(
      useExistingAccount: useExistingAccount,
    );
    if (!launched) throw StateError('Could not open Google sign-in.');
    if (ref.mounted) {
      state = state.copyWith(
        message:
            'Finish signing in in your browser. You can retry if you cancelled.',
      );
    }
  });

  /// Guest navigation works immediately offline. Provisioning happens separately.
  Future<void> signInAsGuest() => _run(() async {
    await ref
        .read(hiveServiceProvider)
        .putSettingChecked(AppConstants.settingAccountChoicePending, false);
    ref.invalidate(accountChoicePendingProvider);
  });
  Future<void> signOut() => _run(() async => _auth.signOut());

  String _format(Object error) {
    if (error is StateError) return error.message;
    if (error is sb.AuthException) {
      if (error.statusCode == '429' ||
          error.code == 'over_email_send_rate_limit' ||
          error.code == 'over_request_rate_limit') {
        return 'Too many requests. Wait a minute before trying again.';
      }
    }
    final text = error.toString();
    if (text.contains('Invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (text.contains('Email not confirmed')) {
      return 'Confirm your email before signing in.';
    }
    if (text.contains('identity_already_exists')) {
      return 'Google is already linked to another account. Choose Sign in to an existing account.';
    }
    return 'Could not complete this request. Check your connection and try again.';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
