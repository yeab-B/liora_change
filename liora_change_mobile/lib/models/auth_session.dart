import 'user.dart';

/// `AuthSession` from `docs/mvp/teams/SHARED-DATA-CONTRACT.md` §3.2 — the
/// `data` payload of register and login.
class AuthSession {
  const AuthSession({required this.user, required this.token});

  final User user;

  /// Sanctum plain-text token. The contract calls this `token`, never
  /// `access_token`.
  final String token;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }
}
