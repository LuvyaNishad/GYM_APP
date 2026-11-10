import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'hive_service.dart';

enum AuthLinkPhase { idle, verifying, recovery, complete, invalid }

class AuthLinkState {
  const AuthLinkState({
    this.phase = AuthLinkPhase.idle,
    this.userId,
    this.email,
    this.error,
    this.busy = false,
    this.passwordSaved = false,
  });

  final AuthLinkPhase phase;
  final String? userId, email, error;
  final bool busy, passwordSaved;
  bool get visible => phase != AuthLinkPhase.idle;
}

/// Lives outside owner workspaces so a recovery callback survives their rebuild.
/// Only the recovery owner's ID is persisted; credentials stay in Supabase.
class AuthLinkService {
  AuthLinkService({
    String? Function()? readRecoveryOwner,
    Future<void> Function(String?)? writeRecoveryOwner,
  }) : _readOwner =
           readRecoveryOwner ?? (() => HiveService.pendingRecoveryOwner),
       _writeOwner = writeRecoveryOwner ?? HiveService.setPendingRecoveryOwner;

  final String? Function() _readOwner;
  final Future<void> Function(String?) _writeOwner;
  final _changes = StreamController<AuthLinkState>.broadcast(sync: true);
  Stream<AuthLinkState> get changes => _changes.stream;
  AuthLinkState _state = const AuthLinkState();
  AuthLinkState get state => _state;
  SupabaseClient? _client;
  StreamSubscription<AuthState>? _subscription;
  Future<void> _writes = Future.value();
  int _revision = 0;
  String? _recoveryOwner;
  Timer? _linkTimeout;

  void _emit(AuthLinkState value) {
    if (value.phase != AuthLinkPhase.verifying) _linkTimeout?.cancel();
    _state = value;
    _changes.add(value);
  }

  void bind(SupabaseClient client) {
    if (_client != null) return;
    _client = client;
    _subscription = client.auth.onAuthStateChange.listen(
      handleAuthState,
      onError: (Object _) {
        if (_state.phase == AuthLinkPhase.verifying) {
          _revision++;
          _emit(const AuthLinkState(phase: AuthLinkPhase.invalid));
        }
      },
    );
  }

  /// Used by the SDK's callback predicate before it consumes a cold-start link.
  bool inspectCallback(Uri uri) {
    if (_state.busy) return false;
    if (uri.scheme != 'app.leon.fitness' || uri.host != 'login-callback') {
      return false;
    }
    try {
      final keys = {
        ...uri.queryParameters.keys,
        ...Uri.splitQueryString(uri.fragment).keys,
      };
      if (!keys.any(
        const {
          'code',
          'access_token',
          'error',
          'error_code',
          'error_description',
        }.contains,
      )) {
        return false;
      }
    } on FormatException {
      return false;
    }
    _revision++;
    _emit(const AuthLinkState(phase: AuthLinkPhase.verifying));
    _linkTimeout?.cancel();
    _linkTimeout = Timer(const Duration(seconds: 30), () {
      if (_state.phase == AuthLinkPhase.verifying) {
        _revision++;
        _emit(const AuthLinkState(phase: AuthLinkPhase.invalid));
      }
    });
    return true;
  }

  Future<void> _persist(String? owner) {
    final next = _writes
        .catchError((Object _) {})
        .then((_) => _writeOwner(owner));
    _writes = next;
    // Event callbacks cannot await disk; completion below does await this queue.
    unawaited(next.catchError((Object _) {}));
    return next;
  }

  void handleAuthState(AuthState event) {
    final user = event.session?.user;
    if (event.event == AuthChangeEvent.passwordRecovery &&
        user != null &&
        !user.isAnonymous) {
      _revision++;
      _recoveryOwner = user.id;
      _emit(
        AuthLinkState(
          phase: AuthLinkPhase.recovery,
          userId: user.id,
          email: user.email,
        ),
      );
      _persist(user.id);
    } else if (event.event == AuthChangeEvent.signedOut ||
        (user != null && _state.userId != null && user.id != _state.userId) ||
        event.event == AuthChangeEvent.signedIn) {
      _revision++;
      _recoveryOwner = null;
      _emit(const AuthLinkState());
      _persist(null);
    }
    // Token refresh and userUpdated must not dismiss an unfinished reset.
  }

  Future<void> restore() async {
    if (_state.visible) return;
    final owner = _readOwner();
    if (owner == null) return;
    final user = _client?.auth.currentUser;
    if (user?.id == owner && user?.isAnonymous == false) {
      _recoveryOwner = owner;
      _emit(
        AuthLinkState(
          phase: AuthLinkPhase.recovery,
          userId: owner,
          email: user!.email,
        ),
      );
    } else {
      await _persist(null);
    }
  }

  Future<void> updatePassword(String password) async {
    final before = _state;
    if (before.busy) return;
    final client = _client;
    if (before.phase != AuthLinkPhase.recovery ||
        before.userId == null ||
        client?.auth.currentUser?.id != before.userId ||
        client!.auth.currentUser!.isAnonymous) {
      throw StateError(
        'Open a new password reset link before changing your password.',
      );
    }
    if (password.length < 6) throw StateError('Use at least 6 characters.');
    final revision = _revision;
    var saved = before.passwordSaved;
    _emit(
      AuthLinkState(
        phase: before.phase,
        userId: before.userId,
        email: before.email,
        busy: true,
        passwordSaved: saved,
      ),
    );
    try {
      if (!saved) {
        final result = await client.auth.updateUser(
          UserAttributes(password: password),
        );
        if (revision != _revision ||
            client.auth.currentUser?.id != before.userId) {
          return;
        }
        if (result.user?.id != before.userId) {
          throw StateError('Account changed.');
        }
        saved = true;
      }
      await _persist(null);
      if (revision != _revision) return;
      _recoveryOwner = null;
      _emit(
        AuthLinkState(
          phase: AuthLinkPhase.complete,
          userId: before.userId,
          email: before.email,
          passwordSaved: true,
        ),
      );
    } catch (error) {
      if (revision != _revision) return;
      _emit(
        AuthLinkState(
          phase: before.phase,
          userId: before.userId,
          email: before.email,
          passwordSaved: saved,
          error: saved
              ? 'Your password was updated. Tap Finish to close recovery.'
              : error is AuthException && error.code == 'same_password'
              ? 'Choose a password different from your current password.'
              : error is AuthException && error.code == 'weak_password'
              ? 'Choose a stronger password and try again.'
              : 'Could not update your password. Check your connection, or request a new reset link.',
        ),
      );
    }
  }

  Future<void> leave() async {
    if (_state.busy) return;
    if (_recoveryOwner != null &&
        _client?.auth.currentUser?.id == _recoveryOwner) {
      // Leaving an unfinished reset never leaves a recovery login active.
      await _client?.auth.signOut(scope: SignOutScope.local);
    }
    await _persist(null);
    _recoveryOwner = null;
    _revision++;
    _emit(const AuthLinkState());
  }

  Future<void> dispose() async {
    _linkTimeout?.cancel();
    await _subscription?.cancel();
    await _writes.catchError((Object _) {});
    await _changes.close();
  }
}
