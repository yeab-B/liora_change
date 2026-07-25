import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../models/auth_session.dart';
import '../../../models/user.dart';
import '../data/auth_repository.dart';

/// Owns the signed-in user for the whole app.
///
/// `null` data means signed out. [sessionChecked] separates the cold-start
/// session restore — which the splash screen waits on — from a later sign-in
/// attempt, since both look like `AsyncLoading`.
class AuthController extends AsyncNotifier<User?> {
  bool _sessionChecked = false;

  /// True once the stored token has been verified (or discarded) at least once.
  bool get sessionChecked => _sessionChecked;

  @override
  Future<User?> build() async {
    // A 401 from any request clears the token in the interceptor; mirror that
    // here so the router immediately sends the user back to /login.
    ref.listen<bool>(authExpiredProvider, (bool? previous, bool next) {
      if (next && state.value != null) {
        state = const AsyncValue<User?>.data(null);
        ref.read(authExpiredProvider.notifier).reset();
      }
    });

    final User? user = await _restoreSession();
    _sessionChecked = true;
    return user;
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  TokenStorage get _tokenStorage => ref.read(tokenStorageProvider);

  /// Resumes a previous session: a stored token is only trusted once `/me`
  /// confirms it, otherwise it is discarded.
  Future<User?> _restoreSession() async {
    final String? token = await _tokenStorage.read();
    if (token == null || token.isEmpty) return null;

    try {
      return await _repository.me();
    } on Object {
      await _tokenStorage.clear();
      return null;
    }
  }

  Future<void> login({required String email, required String password}) async {
    await _authenticate(
      () => _repository.login(email: email, password: password),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? timezone,
  }) async {
    await _authenticate(
      () => _repository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        timezone: timezone,
      ),
    );
  }

  Future<void> logout() async {
    state = const AsyncValue<User?>.loading();
    try {
      await _repository.logout();
    } on Object {
      // Revoking server-side is best effort: the local session ends either way.
    }
    await _tokenStorage.clear();
    ref.read(authExpiredProvider.notifier).reset();
    state = const AsyncValue<User?>.data(null);
  }

  Future<void> _authenticate(Future<AuthSession> Function() call) async {
    state = const AsyncValue<User?>.loading();
    state = await AsyncValue.guard<User?>(() async {
      final AuthSession session = await call();
      // Persist before publishing the user so the next request is authorised.
      await _tokenStorage.write(session.token);
      ref.read(authExpiredProvider.notifier).reset();
      return session.user;
    });
  }
}

final AsyncNotifierProvider<AuthController, User?> authControllerProvider =
    AsyncNotifierProvider<AuthController, User?>(AuthController.new);

/// True only during the initial session restore, while the splash is showing.
final Provider<bool> authBootstrappingProvider = Provider<bool>((Ref ref) {
  ref.watch(authControllerProvider);
  return !ref.read(authControllerProvider.notifier).sessionChecked;
});

/// Convenience for widgets that only care who is signed in.
final Provider<User?> currentUserProvider = Provider<User?>((Ref ref) {
  return ref.watch(authControllerProvider).value;
});
