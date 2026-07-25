import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liora_change_mobile/core/api/api_client.dart';
import 'package:liora_change_mobile/core/api/api_exception.dart';
import 'package:liora_change_mobile/core/storage/token_storage.dart';
import 'package:liora_change_mobile/features/auth/application/auth_controller.dart';
import 'package:liora_change_mobile/models/user.dart';

import '../../support/fake_api.dart';

Map<String, dynamic> _meBody() => <String, dynamic>{
  'data': <String, dynamic>{
    'id': 1,
    'name': 'Selam',
    'email': 'selam@example.com',
    'timezone': 'Africa/Addis_Ababa',
    'xp_total': 40,
    'level': 1,
    'current_streak': 2,
    'longest_streak': 5,
  },
};

ProviderContainer _container(FakeApi api, {String? storedToken}) {
  FlutterSecureStorage.setMockInitialValues(<String, String>{
    TokenStorage.authTokenKey: ?storedToken,
  });

  final ProviderContainer container = ProviderContainer(
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
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a signed-out cold start settles on null without calling the API',
    () async {
      final FakeApi api = FakeApi();
      final ProviderContainer container = _container(api);

      expect(await container.read(authControllerProvider.future), isNull);
      expect(api.requests, isEmpty);
      expect(
        container.read(authControllerProvider.notifier).sessionChecked,
        isTrue,
      );
    },
  );

  test('login stores the token and exposes the user', () async {
    final FakeApi api = FakeApi()
      ..stub('POST', '/auth/login', FakeResponse(200, authSessionBody()));
    final ProviderContainer container = _container(api);
    await container.read(authControllerProvider.future);

    await container
        .read(authControllerProvider.notifier)
        .login(email: 'selam@example.com', password: 'password123');

    expect(container.read(currentUserProvider)?.email, 'selam@example.com');
    expect(await container.read(tokenStorageProvider).read(), 'test-token');
  });

  test('a failed login surfaces an ApiException and stores nothing', () async {
    final FakeApi api = FakeApi()
      ..stub(
        'POST',
        '/auth/login',
        FakeResponse(422, errorBody('The given data was invalid.')),
      );
    final ProviderContainer container = _container(api);
    await container.read(authControllerProvider.future);

    await container
        .read(authControllerProvider.notifier)
        .login(email: 'selam@example.com', password: 'wrong');

    final AsyncValue<User?> state = container.read(authControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<ApiException>());
    expect(container.read(currentUserProvider), isNull);
    expect(await container.read(tokenStorageProvider).read(), isNull);
  });

  test('logout revokes the token and clears it locally', () async {
    final FakeApi api = FakeApi()
      ..stub('GET', '/me', FakeResponse(200, _meBody()))
      ..stub(
        'POST',
        '/auth/logout',
        FakeResponse(200, <String, dynamic>{'message': 'Logged out'}),
      );
    final ProviderContainer container = _container(
      api,
      storedToken: 'live-token',
    );

    expect(await container.read(authControllerProvider.future), isNotNull);

    await container.read(authControllerProvider.notifier).logout();

    expect(container.read(currentUserProvider), isNull);
    expect(await container.read(tokenStorageProvider).read(), isNull);
    expect(api.callsTo('POST', '/auth/logout'), 1);
  });

  test('logout still ends the session when the server call fails', () async {
    final FakeApi api = FakeApi()
      ..stub('GET', '/me', FakeResponse(200, _meBody()))
      ..stub('POST', '/auth/logout', FakeResponse(500, errorBody('Boom')));
    final ProviderContainer container = _container(
      api,
      storedToken: 'live-token',
    );
    await container.read(authControllerProvider.future);

    await container.read(authControllerProvider.notifier).logout();

    expect(container.read(currentUserProvider), isNull);
    expect(await container.read(tokenStorageProvider).read(), isNull);
  });

  test('a 401 on any request signs the user out', () async {
    final FakeApi api = FakeApi()
      ..stub('GET', '/me', FakeResponse(200, _meBody()));
    final ProviderContainer container = _container(
      api,
      storedToken: 'live-token',
    );

    expect(await container.read(authControllerProvider.future), isNotNull);

    // A later call finds the token revoked server-side.
    api.stub(
      'GET',
      '/challenges',
      FakeResponse(401, errorBody('Unauthenticated.', code: 'UNAUTHORIZED')),
    );
    await expectLater(
      container.read(apiClientProvider).get<dynamic>('/challenges'),
      throwsA(isA<DioException>()),
    );

    expect(container.read(currentUserProvider), isNull);
    expect(await container.read(tokenStorageProvider).read(), isNull);
  });
}
