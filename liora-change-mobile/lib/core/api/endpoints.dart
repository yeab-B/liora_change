class ApiEndpoints {
  ApiEndpoints._();

  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';
  static const authMe = '/auth/me';
  static const dashboard = '/dashboard';
  static const challenges = '/challenges';

  static String challenge(int id) => '/challenges/$id';
  static String activateChallenge(int id) => '/challenges/$id/activate';
  static String checkIns(int id) => '/challenges/$id/check-ins';
}

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);
