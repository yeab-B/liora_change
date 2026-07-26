import 'package:flutter_test/flutter_test.dart';
import 'package:liora_change_mobile/core/api/mock/mock_backend.dart';

/// Drives [MockBackend] directly so the contract's §5 business rules are
/// verified without a widget tree.
class _Client {
  _Client(this.backend);

  final MockBackend backend;
  String? token;

  MockResponse call(
    String method,
    String path, {
    Map<String, dynamic> body = const <String, dynamic>{},
    Map<String, dynamic> query = const <String, dynamic>{},
  }) {
    return backend.handle(
      method: method,
      path: path,
      body: body,
      query: query,
      token: token,
    );
  }

  Map<String, dynamic> data(MockResponse response) =>
      response.body['data'] as Map<String, dynamic>;

  List<dynamic> list(MockResponse response) =>
      response.body['data'] as List<dynamic>;

  void loginAsDemo() {
    final MockResponse response = call(
      'POST',
      '/auth/login',
      body: <String, dynamic>{
        'email': MockBackend.demoEmail,
        'password': MockBackend.demoPassword,
      },
    );
    expect(response.statusCode, 200);
    token = data(response)['token'] as String;
  }
}

String _dateString(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _daysAgo(int days) =>
    _dateString(DateTime.now().subtract(Duration(days: days)));

void main() {
  late _Client client;

  // Most of these assert absolute XP and counts, so they start from an empty
  // account rather than the seeded demo history.
  setUp(() => client = _Client(MockBackend(seedHistory: false)));

  group('auth', () {
    test('the seeded demo account can log in', () {
      client.loginAsDemo();
      expect(client.token, isNotNull);

      final MockResponse me = client.call('GET', '/me');
      expect(me.statusCode, 200);
      expect(client.data(me)['email'], MockBackend.demoEmail);
    });

    test('protected routes reject a missing token with 401', () {
      final MockResponse response = client.call('GET', '/dashboard');
      expect(response.statusCode, 401);
      expect(response.body['message'], 'Unauthenticated.');
    });

    test('registering a duplicate email returns a 422 field error', () {
      final MockResponse response = client.call(
        'POST',
        '/auth/register',
        body: <String, dynamic>{
          'name': 'Copy',
          'email': MockBackend.demoEmail,
          'password': 'password123',
          'password_confirmation': 'password123',
        },
      );

      expect(response.statusCode, 422);
      final Map<String, dynamic> errors =
          response.body['errors'] as Map<String, dynamic>;
      expect(errors['email'], contains('The email has already been taken.'));
    });

    test('wrong credentials are rejected', () {
      final MockResponse response = client.call(
        'POST',
        '/auth/login',
        body: <String, dynamic>{
          'email': MockBackend.demoEmail,
          'password': 'wrong-password',
        },
      );
      expect(response.statusCode, 422);
    });
  });

  group('the demo loop', () {
    late int challengeId;

    setUp(() {
      client.loginAsDemo();
      final MockResponse created = client.call(
        'POST',
        '/challenges',
        body: <String, dynamic>{'title': 'Morning Walk', 'duration_days': 7},
      );
      expect(created.statusCode, 201);
      challengeId = client.data(created)['id'] as int;
    });

    test('a new challenge starts as a draft and activates', () {
      final MockResponse activated = client.call(
        'POST',
        '/challenges/$challengeId/activate',
      );

      expect(activated.statusCode, 200);
      expect(client.data(activated)['status'], 'active');
      expect(client.data(activated)['start_date'], _daysAgo(0));
      expect(client.data(activated)['end_date'], isNotNull);
    });

    test('a check-in cannot be logged before activation', () {
      final MockResponse response = client.call(
        'POST',
        '/challenges/$challengeId/check-ins',
        body: <String, dynamic>{'status': 'completed'},
      );
      expect(response.statusCode, 422);
      expect(response.body['code'], 'INVALID_STATUS');
    });

    test('completing, skipping, and recovering follows the contract rules', () {
      client.call('POST', '/challenges/$challengeId/activate');

      // Day one: completed → +10 XP, streak 1.
      final MockResponse first = client.call(
        'POST',
        '/challenges/$challengeId/check-ins',
        body: <String, dynamic>{
          'status': 'completed',
          'check_in_date': _daysAgo(2),
        },
      );
      expect(first.statusCode, 201);
      Map<String, dynamic> summary =
          client.data(first)['summary'] as Map<String, dynamic>;
      expect(summary['xp_earned'], 10);
      expect(summary['xp_total'], 10);
      expect(summary['current_streak'], 1);
      expect(summary['recovery_available'], isFalse);

      // Day two: skipped → no XP, streak resets, recovery offered.
      final MockResponse skipped = client.call(
        'POST',
        '/challenges/$challengeId/check-ins',
        body: <String, dynamic>{
          'status': 'skipped',
          'check_in_date': _daysAgo(1),
        },
      );
      summary = client.data(skipped)['summary'] as Map<String, dynamic>;
      expect(summary['xp_earned'], 0);
      expect(summary['xp_total'], 10);
      expect(summary['current_streak'], 0);
      expect(summary['recovery_available'], isTrue);

      final Map<String, dynamic> recovery = client.data(
        client.call('GET', '/recovery/current'),
      );
      expect(recovery['active'], isTrue);
      expect(recovery['challenge_id'], challengeId);
      expect(recovery['reason'], 'skipped');
      expect(recovery['suggested_action'], isNotNull);

      // Day three: the comeback.
      final MockResponse recovered = client.call(
        'POST',
        '/challenges/$challengeId/check-ins',
        body: <String, dynamic>{'status': 'completed'},
      );
      summary = client.data(recovered)['summary'] as Map<String, dynamic>;
      expect(summary['current_streak'], 1);
      expect(summary['xp_total'], 20);
      // 2 of 7 days completed.
      expect(summary['challenge_progress_percent'], 28.57);

      expect(
        client.data(client.call('GET', '/recovery/current'))['active'],
        isFalse,
      );

      final List<dynamic> badges = client.list(
        client.call('GET', '/badges/unlocked'),
      );
      final List<String> codes = badges
          .map((dynamic b) => (b as Map<String, dynamic>)['code'] as String)
          .toList();
      expect(codes, containsAll(<String>['first_checkin', 'comeback']));
    });

    test('two check-ins on the same day are rejected', () {
      client.call('POST', '/challenges/$challengeId/activate');
      client.call(
        'POST',
        '/challenges/$challengeId/check-ins',
        body: <String, dynamic>{'status': 'completed'},
      );

      final MockResponse duplicate = client.call(
        'POST',
        '/challenges/$challengeId/check-ins',
        body: <String, dynamic>{'status': 'completed'},
      );
      expect(duplicate.statusCode, 422);
      expect(duplicate.body['code'], 'ALREADY_CHECKED_IN');
    });

    test('the dashboard reflects the day so far', () {
      client.call('POST', '/challenges/$challengeId/activate');

      Map<String, dynamic> dashboard = client.data(
        client.call('GET', '/dashboard'),
      );
      Map<String, dynamic> today = dashboard['today'] as Map<String, dynamic>;
      expect(today['active_challenges_count'], 1);
      expect(today['completed_checkins_count'], 0);
      expect(today['pending_checkins_count'], 1);

      client.call(
        'POST',
        '/challenges/$challengeId/check-ins',
        body: <String, dynamic>{'status': 'completed'},
      );

      dashboard = client.data(client.call('GET', '/dashboard'));
      today = dashboard['today'] as Map<String, dynamic>;
      expect(today['completed_checkins_count'], 1);
      expect(today['pending_checkins_count'], 0);
      expect((dashboard['user'] as Map<String, dynamic>)['xp_total'], 10);
      expect(
        (dashboard['recovery'] as Map<String, dynamic>)['active'],
        isFalse,
      );
    });

    test('level follows floor(xp / 100) + 1', () {
      client.call('POST', '/challenges/$challengeId/activate');

      for (int day = 0; day < 7; day++) {
        client.call(
          'POST',
          '/challenges/$challengeId/check-ins',
          body: <String, dynamic>{
            'status': 'completed',
            'check_in_date': _daysAgo(day),
          },
        );
      }

      final Map<String, dynamic> me = client.data(client.call('GET', '/me'));
      expect(me['xp_total'], 70);
      expect(me['level'], 1);

      final Map<String, dynamic> progress = client.data(
        client.call('GET', '/progress'),
      );
      expect(progress['completed_checkins'], 7);
      expect(progress['success_rate'], 100);
    });
  });

  group('ai', () {
    setUp(() {
      client.loginAsDemo();
      final int id =
          client.data(
                client.call(
                  'POST',
                  '/challenges',
                  body: <String, dynamic>{'title': 'Morning Walk'},
                ),
              )['id']
              as int;
      client.call('POST', '/challenges/$id/activate');
    });

    test('motivation names the challenge and falls back to a template', () {
      final Map<String, dynamic> motivation = client.data(
        client.call('POST', '/ai/motivation', body: <String, dynamic>{}),
      );

      expect(motivation['message'], contains('Morning Walk'));
      expect(motivation['challenge_title'], 'Morning Walk');
      expect(motivation['source'], 'template');
      expect(motivation['tone'], 'encouraging');
    });

    test('chat grounds a recovery question in the seeded knowledge', () {
      final Map<String, dynamic> reply = client.data(
        client.call(
          'POST',
          '/ai/chat',
          body: <String, dynamic>{'message': 'What if I miss a day?'},
        ),
      );

      final List<dynamic> sources = reply['sources'] as List<dynamic>;
      expect(sources, isNotEmpty);
      expect(
        sources.map((dynamic s) => (s as Map<String, dynamic>)['title']),
        contains('Recovery basics'),
      );
      expect(reply['session_id'], isNotNull);
    });

    test('a follow-up stays in the same session', () {
      final int sessionId =
          client.data(
                client.call(
                  'POST',
                  '/ai/chat',
                  body: <String, dynamic>{'message': 'How do check-ins work?'},
                ),
              )['session_id']
              as int;

      client.call(
        'POST',
        '/ai/chat',
        body: <String, dynamic>{
          'message': 'And what about streaks?',
          'session_id': sessionId,
        },
      );

      final List<dynamic> messages = client.list(
        client.call('GET', '/ai/chat/sessions/$sessionId/messages'),
      );
      expect(messages.length, 4);
      expect(client.list(client.call('GET', '/ai/chat/sessions')).length, 1);
    });

    test('an over-long message is rejected', () {
      final MockResponse response = client.call(
        'POST',
        '/ai/chat',
        body: <String, dynamic>{'message': 'a' * 1001},
      );
      expect(response.statusCode, 422);
    });
  });

  group('the seeded demo history', () {
    setUp(() {
      client = _Client(MockBackend());
      client.loginAsDemo();
    });

    test('opens on an active challenge with recovery waiting', () {
      final Map<String, dynamic> dashboard = client.data(
        client.call('GET', '/dashboard'),
      );

      expect((dashboard['active_challenges'] as List<dynamic>).length, 1);
      expect((dashboard['user'] as Map<String, dynamic>)['xp_total'], 10);
      expect((dashboard['user'] as Map<String, dynamic>)['current_streak'], 0);

      final Map<String, dynamic> challenge =
          (dashboard['active_challenges'] as List<dynamic>).first
              as Map<String, dynamic>;
      expect(challenge['current_streak'], 0);
      expect(challenge['completed_checkins'], 1);
      expect(challenge['progress_percent'], 14.29);

      final Map<String, dynamic> recovery =
          dashboard['recovery'] as Map<String, dynamic>;
      expect(recovery['active'], isTrue);
      expect(recovery['reason'], 'skipped');
      expect(recovery['challenge_title'], 'Morning Walk');
      expect(
        (recovery['suggested_action'] as Map<String, dynamic>)['challenge_id'],
        recovery['challenge_id'],
      );
    });

    test('a gap day without a skip restarts the streak at one', () {
      final int id =
          client.data(
                client.call(
                  'POST',
                  '/challenges',
                  body: <String, dynamic>{'title': 'Focus Hour'},
                ),
              )['id']
              as int;
      client.call('POST', '/challenges/$id/activate');

      client.call(
        'POST',
        '/challenges/$id/check-ins',
        body: <String, dynamic>{
          'status': 'completed',
          'check_in_date': _daysAgo(2),
        },
      );
      // Yesterday left blank — silent miss, not a skip row.
      final MockResponse today = client.call(
        'POST',
        '/challenges/$id/check-ins',
        body: <String, dynamic>{'status': 'completed'},
      );

      final Map<String, dynamic> summary =
          client.data(today)['summary'] as Map<String, dynamic>;
      expect(summary['current_streak'], 1);

      final Map<String, dynamic> challenge = client.data(
        client.call('GET', '/challenges/$id'),
      );
      expect(challenge['current_streak'], 1);
    });

    test('two challenges on the same day do not double the streak', () {
      final int walkId =
          (client.data(client.call('GET', '/dashboard'))['active_challenges']
                  as List<dynamic>)
              .first['id']
          as int;
      final int focusId =
          client.data(
                client.call(
                  'POST',
                  '/challenges',
                  body: <String, dynamic>{'title': 'Focus Hour'},
                ),
              )['id']
              as int;
      client.call('POST', '/challenges/$focusId/activate');

      client.call(
        'POST',
        '/challenges/$walkId/check-ins',
        body: <String, dynamic>{'status': 'completed'},
      );
      client.call(
        'POST',
        '/challenges/$focusId/check-ins',
        body: <String, dynamic>{'status': 'completed'},
      );

      final Map<String, dynamic> dashboard = client.data(
        client.call('GET', '/dashboard'),
      );
      // Best challenge streak is 1 (comeback after seed skip), not 2.
      expect((dashboard['user'] as Map<String, dynamic>)['current_streak'], 1);
      expect(
        (dashboard['today'] as Map<String, dynamic>)['pending_checkins_count'],
        0,
      );
    });

    test('today is still open, so the comeback lands the same session', () {
      final int challengeId =
          client.data(client.call('GET', '/recovery/current'))['challenge_id']
              as int;

      final MockResponse comeback = client.call(
        'POST',
        '/challenges/$challengeId/check-ins',
        body: <String, dynamic>{'status': 'completed'},
      );

      expect(comeback.statusCode, 201);
      final Map<String, dynamic> summary =
          client.data(comeback)['summary'] as Map<String, dynamic>;
      expect(summary['xp_earned'], 10);
      expect(summary['xp_total'], 20);
      expect(summary['current_streak'], 1);
      expect(summary['recovery_available'], isFalse);

      expect(
        client.data(client.call('GET', '/recovery/current'))['active'],
        isFalse,
      );
    });
  });
}
