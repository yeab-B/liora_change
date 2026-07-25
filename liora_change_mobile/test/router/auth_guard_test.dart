import 'package:flutter_test/flutter_test.dart';
import 'package:liora_change_mobile/models/user.dart';
import 'package:liora_change_mobile/router/app_router.dart';

const User _user = User(id: 1, name: 'Selam', email: 'selam@example.com');

void main() {
  group('while the session is still being restored', () {
    test('anything other than the splash is held back', () {
      expect(
        authGuard(
          sessionChecked: false,
          user: null,
          location: AppRoute.home.path,
        ),
        splashPath,
      );
    });

    test('the splash itself stays', () {
      expect(
        authGuard(sessionChecked: false, user: null, location: splashPath),
        isNull,
      );
    });
  });

  group('signed out', () {
    test('protected routes go to login', () {
      for (final AppRoute route in AppRoute.values.where(
        (AppRoute route) => !route.isPublic,
      )) {
        expect(
          authGuard(sessionChecked: true, user: null, location: route.path),
          AppRoute.login.path,
          reason: '${route.path} should be guarded',
        );
      }
    });

    test('the auth screens stay reachable', () {
      expect(
        authGuard(
          sessionChecked: true,
          user: null,
          location: AppRoute.login.path,
        ),
        isNull,
      );
      expect(
        authGuard(
          sessionChecked: true,
          user: null,
          location: AppRoute.register.path,
        ),
        isNull,
      );
    });
  });

  group('signed in', () {
    test('the auth screens and splash send the user home', () {
      for (final String location in <String>[
        AppRoute.login.path,
        AppRoute.register.path,
        splashPath,
      ]) {
        expect(
          authGuard(sessionChecked: true, user: _user, location: location),
          AppRoute.home.path,
        );
      }
    });

    test('app routes are left alone', () {
      expect(
        authGuard(
          sessionChecked: true,
          user: _user,
          location: AppRoute.challenges.path,
        ),
        isNull,
      );
    });
  });
}
