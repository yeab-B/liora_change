import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liora_change_mobile/core/api/api_client.dart';
import 'package:liora_change_mobile/core/api/api_exception.dart';
import 'package:liora_change_mobile/core/api/mock/mock_api_adapter.dart';
import 'package:liora_change_mobile/core/api/mock/mock_backend.dart';
import 'package:liora_change_mobile/core/storage/token_storage.dart';
import 'package:liora_change_mobile/features/auth/data/auth_repository.dart';
import 'package:liora_change_mobile/models/auth_session.dart';
import 'package:liora_change_mobile/models/user.dart';

/// Exercises the real Dio stack — interceptor, repository, and envelope
/// parsing — against the mock adapter, which is what a mock-mode build runs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenStorage tokenStorage;
  late AuthRepository repository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    tokenStorage = const TokenStorage(FlutterSecureStorage());

    final Dio dio = createApiClient(
      tokenStorage: tokenStorage,
      onUnauthorized: () {},
      baseUrl: 'http://mock/api/v1',
    );
    dio.httpClientAdapter = MockApiAdapter(latency: Duration.zero);
    repository = AuthRepository(dio);
  });

  test('the demo account logs in and /me resolves with the token', () async {
    final AuthSession session = await repository.login(
      email: MockBackend.demoEmail,
      password: MockBackend.demoPassword,
    );

    expect(session.user.name, 'Alex Demo');
    expect(session.token, isNotEmpty);

    await tokenStorage.write(session.token);
    final User me = await repository.me();

    expect(me.email, MockBackend.demoEmail);
    expect(me.level, 1);
  });

  test('a bad password surfaces as a validation ApiException', () async {
    await expectLater(
      repository.login(email: MockBackend.demoEmail, password: 'nope'),
      throwsA(
        isA<ApiException>()
            .having((ApiException e) => e.isValidation, 'isValidation', isTrue)
            .having(
              (ApiException e) => e.errorFor('email'),
              'email error',
              isNotNull,
            ),
      ),
    );
  });

  test('an unauthenticated call fails with 401', () async {
    await expectLater(
      repository.me(),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.isUnauthorized,
          'isUnauthorized',
          isTrue,
        ),
      ),
    );
  });

  test('registering through the stack returns a usable session', () async {
    final AuthSession session = await repository.register(
      name: 'Selam',
      email: 'selam@example.com',
      password: 'password123',
      passwordConfirmation: 'password123',
      timezone: 'Africa/Addis_Ababa',
    );

    expect(session.user.email, 'selam@example.com');
    expect(session.user.timezone, 'Africa/Addis_Ababa');
    expect(session.user.xpTotal, 0);
  });
}
