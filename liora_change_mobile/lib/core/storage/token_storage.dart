import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the Sanctum bearer token in platform secure storage.
///
/// `docs/mvp/teams/MOBILE-TEAM-GUIDE.md` §8: the token is the only credential
/// stored on device — passwords are never persisted.
class TokenStorage {
  const TokenStorage(this._storage);

  static const String authTokenKey = 'auth_token';

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: authTokenKey);

  Future<void> write(String token) =>
      _storage.write(key: authTokenKey, value: token);

  Future<void> clear() => _storage.delete(key: authTokenKey);
}

final Provider<TokenStorage> tokenStorageProvider = Provider<TokenStorage>(
  (Ref ref) => const TokenStorage(FlutterSecureStorage()),
);
