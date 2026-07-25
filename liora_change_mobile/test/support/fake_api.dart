import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` lives outside the main entry point in Riverpod 3.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liora_change_mobile/core/api/api_client.dart';
import 'package:liora_change_mobile/core/storage/token_storage.dart';
import 'package:liora_change_mobile/main.dart';

/// A canned HTTP response for one route.
class FakeResponse {
  const FakeResponse(this.statusCode, this.body, {this.delay});

  final int statusCode;
  final Object body;

  /// Holds the response open so tests can observe in-flight UI.
  final Duration? delay;
}

/// Stubs Dio at the transport layer, so tests exercise the real interceptor,
/// repository, and controller rather than a hand-written fake.
class FakeApi implements HttpClientAdapter {
  final Map<String, FakeResponse> _routes = <String, FakeResponse>{};

  /// Requests received, in order — useful for asserting no double submit.
  final List<RequestOptions> requests = <RequestOptions>[];

  void stub(String method, String path, FakeResponse response) {
    _routes['$method $path'] = response;
  }

  int callsTo(String method, String path) => requests
      .where((RequestOptions r) => r.method == method && r.path == path)
      .length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    final FakeResponse response =
        _routes['${options.method} ${options.path}'] ??
        FakeResponse(501, <String, dynamic>{
          'message': 'No stub for ${options.method} ${options.path}',
        });

    if (response.delay != null) await Future<void>.delayed(response.delay!);

    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Success envelope from `docs/mvp/05-api-contract.md` §0.2.
Map<String, dynamic> authSessionBody({
  int id = 1,
  String name = 'Selam',
  String email = 'selam@example.com',
  String token = 'test-token',
}) {
  return <String, dynamic>{
    'data': <String, dynamic>{
      'user': <String, dynamic>{
        'id': id,
        'name': name,
        'email': email,
        'timezone': 'Africa/Addis_Ababa',
      },
      'token': token,
    },
  };
}

/// Error envelope from `docs/mvp/05-api-contract.md` §0.3.
Map<String, dynamic> errorBody(
  String message, {
  String? code,
  Map<String, List<String>>? errors,
}) {
  return <String, dynamic>{
    'message': message,
    'code': ?code,
    'errors': ?errors,
  };
}

/// Boots the real app against [api], with no token in secure storage unless
/// [storedToken] is given. Stub [api] before calling.
Future<void> pumpApp(
  WidgetTester tester,
  FakeApi api, {
  String? storedToken,
}) async {
  FlutterSecureStorage.setMockInitialValues(<String, String>{
    TokenStorage.authTokenKey: ?storedToken,
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        apiClientProvider.overrideWith((Ref ref) {
          final Dio dio = createApiClient(
            tokenStorage: ref.watch(tokenStorageProvider),
            onUnauthorized: () =>
                ref.read(authExpiredProvider.notifier).markExpired(),
            baseUrl: 'http://localhost/api/v1',
          );
          dio.httpClientAdapter = api;
          return dio;
        }),
      ],
      child: const LioraChangeApp(),
    ),
  );
}
