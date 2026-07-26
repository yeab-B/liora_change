import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_storage.dart';
import 'mock/mock_api_adapter.dart';

/// Backend base URL. Override per environment with
/// `--dart-define=API_BASE_URL=http://<lan-ip>:8000/api/v1`.
///
/// The default targets the Android emulator's host loopback, per
/// `docs/mvp/teams/MOBILE-TEAM-GUIDE.md` §2.2.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);

/// Runs the app against the in-memory [MockBackend] instead of the network.
///
/// Enable with `--dart-define=USE_MOCK_API=true` while the Laravel API is
/// still being built. Off by default, so a normal build always talks to the
/// real server.
const bool useMockApi = true;

/// Set when the API rejects the stored token.
///
/// The router listens to this so an expired session sends the user back to
/// `/login`; the redirect itself is wired up in Issue #2.
class AuthExpiredNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markExpired() => state = true;

  void reset() => state = false;
}

final NotifierProvider<AuthExpiredNotifier, bool> authExpiredProvider =
    NotifierProvider<AuthExpiredNotifier, bool>(AuthExpiredNotifier.new);

/// Attaches the bearer token and reacts to `401 Unauthorized`.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenStorage, required this.onUnauthorized});

  final TokenStorage tokenStorage;
  final void Function() onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? token = await tokenStorage.read();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await tokenStorage.clear();
      onUnauthorized();
    }
    handler.next(err);
  }
}

Dio createApiClient({
  required TokenStorage tokenStorage,
  required void Function() onUnauthorized,
  String baseUrl = apiBaseUrl,
}) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(tokenStorage: tokenStorage, onUnauthorized: onUnauthorized),
  );

  if (useMockApi) {
    dio.httpClientAdapter = MockApiAdapter();
  }

  return dio;
}

final Provider<Dio> apiClientProvider = Provider<Dio>((Ref ref) {
  return createApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    onUnauthorized: () => ref.read(authExpiredProvider.notifier).markExpired(),
  );
});
