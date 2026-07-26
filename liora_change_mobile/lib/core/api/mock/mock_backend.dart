import 'dart:math';

/// In-memory stand-in for the Laravel API, used only when the app is built
/// with `--dart-define=USE_MOCK_API=true`.
///
/// Every response matches `docs/mvp/teams/SHARED-DATA-CONTRACT.md` exactly and
/// the business rules in its §5, so switching to the real backend is a config
/// change rather than a code change. State lives in memory and resets when the
/// app restarts; the seeded demo account keeps a stable token so a relaunch
/// still resumes its session.
class MockBackend {
  /// [seedHistory] gives the demo account a challenge that was completed two
  /// days ago and skipped yesterday, so the app opens on a live recovery
  /// banner and today's comeback check-in is still available. Tests that
  /// assert absolute XP or challenge counts pass false and start from zero.
  MockBackend({bool seedHistory = true}) {
    _seed(seedHistory: seedHistory);
  }

  static const String demoEmail = 'alex@example.com';
  static const String demoPassword = 'password';

  /// Business rules from the contract's §5.
  static const int xpPerCompletedCheckIn = 10;
  static const int xpPerLevel = 100;

  final List<_User> _users = <_User>[];
  final List<_Challenge> _challenges = <_Challenge>[];
  final List<_CheckIn> _checkIns = <_CheckIn>[];
  final List<_XpEntry> _xpLedger = <_XpEntry>[];
  final List<_Badge> _badges = <_Badge>[];
  final List<_ChatSession> _chatSessions = <_ChatSession>[];
  final List<_ChatMessage> _chatMessages = <_ChatMessage>[];

  int _nextUserId = 1;
  int _nextChallengeId = 1;
  int _nextCheckInId = 1;
  int _nextXpId = 1;
  int _nextBadgeId = 1;
  int _nextSessionId = 1;
  int _nextMessageId = 1;

  void _seed({required bool seedHistory}) {
    final _User alex = _User(
      id: _nextUserId++,
      name: 'Alex Demo',
      email: demoEmail,
      password: demoPassword,
      timezone: 'Africa/Addis_Ababa',
    );
    _users.add(alex);
    if (!seedHistory) return;

    final DateTime today = _today();
    final _Challenge walk = _Challenge(
      id: _nextChallengeId++,
      userId: alex.id,
      title: 'Morning Walk',
      description: 'Walk 10 minutes after waking up.',
      difficulty: 'easy',
      visibility: 'private',
      categoryId: 1,
      durationDays: 7,
      createdAt: today.subtract(const Duration(days: 2)),
    );
    walk.status = 'active';
    walk.startDate = today.subtract(const Duration(days: 2));
    walk.endDate = walk.startDate!.add(Duration(days: walk.durationDays - 1));
    _challenges.add(walk);

    // A good day, then a day that did not happen: exactly the state the
    // recovery flow exists for.
    _checkIns.add(
      _CheckIn(
        id: _nextCheckInId++,
        challengeId: walk.id,
        date: today.subtract(const Duration(days: 2)),
        status: 'completed',
        note: 'Cold but worth it.',
        xpEarned: xpPerCompletedCheckIn,
        streakAfter: 1,
        createdAt: today.subtract(const Duration(days: 2)),
      ),
    );
    _checkIns.add(
      _CheckIn(
        id: _nextCheckInId++,
        challengeId: walk.id,
        date: today.subtract(const Duration(days: 1)),
        status: 'skipped',
        xpEarned: 0,
        streakAfter: 0,
        createdAt: today.subtract(const Duration(days: 1)),
      ),
    );

    alex.xpTotal = xpPerCompletedCheckIn;
    alex.currentStreak = 0;
    alex.longestStreak = 1;

    _xpLedger.add(
      _XpEntry(
        id: _nextXpId++,
        userId: alex.id,
        amount: xpPerCompletedCheckIn,
        reason: 'check_in_completed',
        challengeId: walk.id,
        createdAt: today.subtract(const Duration(days: 2)),
      ),
    );
    _badges.add(
      _Badge(
        id: _nextBadgeId++,
        userId: alex.id,
        code: 'first_checkin',
        name: 'First step',
        description: 'Logged your first check-in.',
        unlockedAt: today.subtract(const Duration(days: 2)),
      ),
    );
  }

  // ---------------------------------------------------------------- dispatch

  MockResponse handle({
    required String method,
    required String path,
    required Map<String, dynamic> body,
    required Map<String, dynamic> query,
    String? token,
  }) {
    final List<String> segments = path
        .split('/')
        .where((String s) => s.isNotEmpty)
        .toList();

    // Public routes.
    if (_matches(method, segments, 'POST', <String>['auth', 'register'])) {
      return _register(body);
    }
    if (_matches(method, segments, 'POST', <String>['auth', 'login'])) {
      return _login(body);
    }

    final _User? user = _userForToken(token);
    if (user == null) {
      return MockResponse.error(
        401,
        'Unauthenticated.',
        code: 'UNAUTHENTICATED',
      );
    }

    if (_matches(method, segments, 'POST', <String>['auth', 'logout'])) {
      return MockResponse.ok(<String, dynamic>{'message': 'Logged out'});
    }
    if (_matches(method, segments, 'GET', <String>['me'])) {
      return MockResponse.ok(_userJson(user));
    }
    if (_matches(method, segments, 'PATCH', <String>['me'])) {
      return _updateMe(user, body);
    }
    if (_matches(method, segments, 'GET', <String>['dashboard'])) {
      return MockResponse.ok(_dashboardJson(user));
    }
    if (_matches(method, segments, 'GET', <String>['recovery', 'current'])) {
      return MockResponse.ok(_recoveryJson(user));
    }
    if (_matches(method, segments, 'GET', <String>['progress'])) {
      return MockResponse.ok(_progressJson(user));
    }
    if (_matches(method, segments, 'GET', <String>['challenge-categories'])) {
      return MockResponse.list(_categories);
    }
    if (_matches(method, segments, 'GET', <String>['challenge-templates'])) {
      final int? categoryId = int.tryParse('${query['category_id']}');
      return MockResponse.list(
        _templates
            .where(
              (Map<String, dynamic> t) =>
                  categoryId == null || t['category_id'] == categoryId,
            )
            .toList(),
      );
    }
    if (_matches(method, segments, 'GET', <String>['xp', 'history'])) {
      return MockResponse.list(
        _xpLedger
            .where((_XpEntry e) => e.userId == user.id)
            .map(_xpJson)
            .toList()
            .reversed
            .toList(),
      );
    }
    if (_matches(method, segments, 'GET', <String>['badges', 'unlocked'])) {
      return MockResponse.list(
        _badges
            .where((_Badge b) => b.userId == user.id)
            .map(_badgeJson)
            .toList(),
      );
    }
    if (_matches(method, segments, 'GET', <String>['challenges'])) {
      return _listChallenges(user, query);
    }
    if (_matches(method, segments, 'POST', <String>['challenges'])) {
      return _createChallenge(user, body);
    }
    if (_matches(method, segments, 'POST', <String>['ai', 'motivation'])) {
      return _motivation(user, body);
    }
    if (_matches(method, segments, 'POST', <String>['ai', 'chat'])) {
      return _chat(user, body);
    }
    if (_matches(method, segments, 'GET', <String>['ai', 'chat', 'sessions'])) {
      return MockResponse.list(
        _chatSessions
            .where((_ChatSession s) => s.userId == user.id)
            .map(_sessionJson)
            .toList(),
      );
    }

    // /challenges/{id}...
    if (segments.length >= 2 && segments[0] == 'challenges') {
      final int? id = int.tryParse(segments[1]);
      final _Challenge? challenge = id == null ? null : _challenge(user, id);
      if (challenge == null) {
        return MockResponse.error(
          404,
          'Challenge not found.',
          code: 'NOT_FOUND',
        );
      }

      if (segments.length == 2 && method == 'GET') {
        return MockResponse.ok(_challengeJson(challenge));
      }
      if (segments.length == 3 &&
          segments[2] == 'activate' &&
          method == 'POST') {
        return _activate(challenge);
      }
      if (segments.length == 3 && segments[2] == 'check-ins') {
        if (method == 'POST') return _createCheckIn(user, challenge, body);
        if (method == 'GET') {
          return MockResponse.list(
            _checkInsFor(challenge.id).map(_checkInJson).toList(),
          );
        }
      }
    }

    // /ai/chat/sessions/{id}/messages
    if (segments.length == 5 &&
        method == 'GET' &&
        segments[0] == 'ai' &&
        segments[1] == 'chat' &&
        segments[2] == 'sessions' &&
        segments[4] == 'messages') {
      final int? id = int.tryParse(segments[3]);
      return MockResponse.list(
        _chatMessages
            .where((_ChatMessage m) => m.sessionId == id)
            .map(_messageJson)
            .toList(),
      );
    }

    return MockResponse.error(
      404,
      'No mock route for $method /$path.',
      code: 'NOT_FOUND',
    );
  }

  bool _matches(
    String method,
    List<String> segments,
    String expectedMethod,
    List<String> expectedSegments,
  ) {
    if (method != expectedMethod) return false;
    if (segments.length != expectedSegments.length) return false;
    for (int i = 0; i < segments.length; i++) {
      if (segments[i] != expectedSegments[i]) return false;
    }
    return true;
  }

  // -------------------------------------------------------------------- auth

  /// Stable per-user so a relaunch can resume the seeded demo session.
  String _tokenFor(_User user) => '${user.id}|mock-token-${user.id}';

  _User? _userForToken(String? token) {
    if (token == null || token.isEmpty) return null;
    for (final _User user in _users) {
      if (_tokenFor(user) == token) return user;
    }
    return null;
  }

  MockResponse _register(Map<String, dynamic> body) {
    final Map<String, List<String>> errors = <String, List<String>>{};
    final String name = (body['name'] as String? ?? '').trim();
    final String email = (body['email'] as String? ?? '').trim().toLowerCase();
    final String password = body['password'] as String? ?? '';
    final String confirmation = body['password_confirmation'] as String? ?? '';

    if (name.isEmpty) errors['name'] = <String>['The name field is required.'];
    if (email.isEmpty) {
      errors['email'] = <String>['The email field is required.'];
    } else if (!email.contains('@')) {
      errors['email'] = <String>['The email must be a valid email address.'];
    } else if (_users.any((_User u) => u.email == email)) {
      errors['email'] = <String>['The email has already been taken.'];
    }
    if (password.length < 8) {
      errors['password'] = <String>[
        'The password must be at least 8 characters.',
      ];
    } else if (password != confirmation) {
      errors['password'] = <String>[
        'The password confirmation does not match.',
      ];
    }

    if (errors.isNotEmpty) return MockResponse.validation(errors);

    final _User user = _User(
      id: _nextUserId++,
      name: name,
      email: email,
      password: password,
      timezone: body['timezone'] as String?,
    );
    _users.add(user);

    return MockResponse(201, <String, dynamic>{
      'data': <String, dynamic>{
        'user': _userJson(user),
        'token': _tokenFor(user),
      },
    });
  }

  MockResponse _login(Map<String, dynamic> body) {
    final String email = (body['email'] as String? ?? '').trim().toLowerCase();
    final String password = body['password'] as String? ?? '';

    for (final _User user in _users) {
      if (user.email == email && user.password == password) {
        return MockResponse.ok(<String, dynamic>{
          'user': _userJson(user),
          'token': _tokenFor(user),
        });
      }
    }

    return MockResponse.validation(<String, List<String>>{
      'email': <String>['These credentials do not match our records.'],
    });
  }

  MockResponse _updateMe(_User user, Map<String, dynamic> body) {
    final Object? name = body['name'];
    if (name is String && name.trim().isNotEmpty) user.name = name.trim();
    final Object? timezone = body['timezone'];
    if (timezone is String) user.timezone = timezone;
    return MockResponse.ok(_userJson(user));
  }

  // -------------------------------------------------------------- challenges

  _Challenge? _challenge(_User user, int id) {
    for (final _Challenge challenge in _challenges) {
      if (challenge.id == id && challenge.userId == user.id) return challenge;
    }
    return null;
  }

  MockResponse _listChallenges(_User user, Map<String, dynamic> query) {
    final Object? status = query['status'];
    final List<Map<String, dynamic>> result = _challenges
        .where((_Challenge c) => c.userId == user.id)
        .where((_Challenge c) => status == null || c.status == status)
        .map(_challengeJson)
        .toList();
    return MockResponse.list(result);
  }

  MockResponse _createChallenge(_User user, Map<String, dynamic> body) {
    final String title = (body['title'] as String? ?? '').trim();
    if (title.isEmpty) {
      return MockResponse.validation(<String, List<String>>{
        'title': <String>['The title field is required.'],
      });
    }

    final DateTime now = DateTime.now();
    final _Challenge challenge = _Challenge(
      id: _nextChallengeId++,
      userId: user.id,
      title: title,
      description: body['description'] as String?,
      difficulty: body['difficulty'] as String? ?? 'beginner',
      visibility: body['visibility'] as String? ?? 'private',
      durationDays: body['duration_days'] as int? ?? 7,
      categoryId: body['category_id'] as int?,
      createdAt: now,
    );
    _challenges.add(challenge);

    return MockResponse(201, <String, dynamic>{
      'data': _challengeJson(challenge),
    });
  }

  MockResponse _activate(_Challenge challenge) {
    if (challenge.status != 'draft' && challenge.status != 'ready') {
      return MockResponse.error(
        422,
        'Only a draft or ready challenge can be activated.',
        code: 'INVALID_STATUS',
      );
    }

    final DateTime today = _today();
    challenge.status = 'active';
    challenge.startDate = today;
    challenge.endDate = today.add(Duration(days: challenge.durationDays - 1));
    challenge.updatedAt = DateTime.now();

    return MockResponse.ok(_challengeJson(challenge));
  }

  // ---------------------------------------------------------------- check-in

  List<_CheckIn> _checkInsFor(int challengeId) {
    final List<_CheckIn> list = _checkIns
        .where((_CheckIn c) => c.challengeId == challengeId)
        .toList();
    list.sort((_CheckIn a, _CheckIn b) => a.date.compareTo(b.date));
    return list;
  }

  MockResponse _createCheckIn(
    _User user,
    _Challenge challenge,
    Map<String, dynamic> body,
  ) {
    final String status = body['status'] as String? ?? '';
    if (status != 'completed' && status != 'skipped') {
      return MockResponse.validation(<String, List<String>>{
        'status': <String>['The status must be completed or skipped.'],
      });
    }
    if (challenge.status != 'active') {
      return MockResponse.error(
        422,
        'This challenge is not active yet.',
        code: 'INVALID_STATUS',
      );
    }

    final DateTime date = _parseDate(body['check_in_date']) ?? _today();
    final bool alreadyLogged = _checkInsFor(challenge.id)
        .any((_CheckIn c) => _sameDay(c.date, date));
    if (alreadyLogged) {
      return MockResponse.error(
        422,
        'You already checked in for this day.',
        code: 'ALREADY_CHECKED_IN',
      );
    }

    final bool completed = status == 'completed';
    final int xpEarned = completed ? xpPerCompletedCheckIn : 0;

    if (completed) {
      user.xpTotal += xpEarned;
    }

    // Streak is per challenge and calendar-based (contract §5): a completed
    // day counts only when it continues yesterday, otherwise the streak
    // restarts at 1. Skip breaks that challenge's streak; other challenges
    // are untouched.
    final _CheckIn checkIn = _CheckIn(
      id: _nextCheckInId++,
      challengeId: challenge.id,
      date: date,
      status: status,
      note: body['note'] as String?,
      mood: body['mood'] as int?,
      energy: body['energy'] as int?,
      xpEarned: xpEarned,
      streakAfter: 0,
      createdAt: DateTime.now(),
    );
    _checkIns.add(checkIn);
    challenge.updatedAt = DateTime.now();

    final List<_CheckIn> history = _checkInsFor(challenge.id);
    final int challengeStreak = completed
        ? _challengeStreakAt(history, date)
        : 0;
    checkIn.streakAfter = challengeStreak;
    _syncUserStreak(user);

    if (completed) {
      _xpLedger.add(
        _XpEntry(
          id: _nextXpId++,
          userId: user.id,
          amount: xpEarned,
          reason: 'check_in_completed',
          challengeId: challenge.id,
          createdAt: DateTime.now(),
        ),
      );
    }

    _awardBadges(user, challenge, checkIn);

    if (_completedCount(challenge) >= challenge.durationDays) {
      challenge.status = 'completed';
    }

    return MockResponse(201, <String, dynamic>{
      'data': <String, dynamic>{
        'check_in': _checkInJson(checkIn),
        'summary': <String, dynamic>{
          'current_streak': challengeStreak,
          'longest_streak': _challengeLongestStreak(_checkInsFor(challenge.id)),
          'xp_total': user.xpTotal,
          'xp_earned': xpEarned,
          'challenge_progress_percent': _progressPercent(challenge),
          'recovery_available': !completed,
        },
      },
    });
  }

  /// Home's flame uses `user.current_streak` — keep it as the best live
  /// challenge streak so multi-challenge days never double-count a calendar day.
  void _syncUserStreak(_User user) {
    int best = 0;
    for (final _Challenge challenge in _challenges) {
      if (challenge.userId != user.id) continue;
      if (challenge.status != 'active' && challenge.status != 'completed') {
        continue;
      }
      best = max(best, _challengeStreak(_checkInsFor(challenge.id)));
    }
    user.currentStreak = best;
    user.longestStreak = max(user.longestStreak, best);
  }

  void _awardBadges(_User user, _Challenge challenge, _CheckIn checkIn) {
    void unlock(String code, String name, String description) {
      final bool owned = _badges.any(
        (_Badge b) => b.userId == user.id && b.code == code,
      );
      if (owned) return;
      _badges.add(
        _Badge(
          id: _nextBadgeId++,
          userId: user.id,
          code: code,
          name: name,
          description: description,
          unlockedAt: DateTime.now(),
        ),
      );
    }

    if (checkIn.status != 'completed') return;

    unlock('first_checkin', 'First step', 'You logged your first check-in.');
    if (_challengeStreak(_checkInsFor(challenge.id)) >= 3) {
      unlock(
        'streak_3',
        'Three in a row',
        'You checked in three days running.',
      );
    }

    final List<_CheckIn> history = _checkInsFor(challenge.id);
    if (history.length >= 2 &&
        history[history.length - 2].status == 'skipped') {
      unlock('comeback', 'Comeback', 'You came back the day after a skip.');
    }
  }

  // -------------------------------------------------------------- dashboard

  Map<String, dynamic> _dashboardJson(_User user) {
    _syncUserStreak(user);

    final List<_Challenge> active = _challenges
        .where((_Challenge c) => c.userId == user.id && c.status == 'active')
        .toList()
      // Newest first so a just-created challenge lands at the top of Home.
      ..sort((_Challenge a, _Challenge b) => b.id.compareTo(a.id));

    final int completedToday = active
        .where(
          (_Challenge c) => _checkInsFor(c.id).any(
            (_CheckIn ci) =>
                _sameDay(ci.date, _today()) && ci.status == 'completed',
          ),
        )
        .length;

    // Pending = not yet logged today (skip or complete both clear the day).
    final int pendingToday = active
        .where(
          (_Challenge c) => !_checkInsFor(c.id).any(
            (_CheckIn ci) => _sameDay(ci.date, _today()),
          ),
        )
        .length;

    final Map<String, dynamic> recovery = _recoveryJson(user);

    return <String, dynamic>{
      'user': _userJson(user),
      'today': <String, dynamic>{
        'date': _dateString(_today()),
        'active_challenges_count': active.length,
        'completed_checkins_count': completedToday,
        'pending_checkins_count': pendingToday,
      },
      'active_challenges': active.map(_challengeJson).toList(),
      'recovery': recovery,
      'motivation_preview': active.isEmpty
          ? 'Pick one small thing you want to be true in a week.'
          : _motivationMessage(user, active.first),
    };
  }

  Map<String, dynamic> _recoveryJson(_User user) {
    for (final _Challenge challenge in _challenges) {
      if (challenge.userId != user.id || challenge.status != 'active') continue;

      final List<_CheckIn> history = _checkInsFor(challenge.id);
      if (history.isEmpty) continue;

      final _CheckIn last = history.last;
      final bool missedDay =
          last.status == 'skipped' || last.status == 'missed';
      final bool recoveredToday = history.any(
        (_CheckIn c) => _sameDay(c.date, _today()) && c.status == 'completed',
      );
      if (!missedDay || recoveredToday) continue;

      return <String, dynamic>{
        'active': true,
        'challenge_id': challenge.id,
        'challenge_title': challenge.title,
        'reason': last.status == 'skipped' ? 'skipped' : 'missed',
        'title': 'Yesterday does not cancel you',
        'message':
            'One skipped day is information, not failure. Do the smallest '
            'version of ${challenge.title} today — that counts.',
        'suggested_action': <String, dynamic>{
          'type': 'check_in',
          'challenge_id': challenge.id,
          'label': 'Check in now',
        },
      };
    }

    return <String, dynamic>{'active': false};
  }

  Map<String, dynamic> _progressJson(_User user) {
    final List<_Challenge> mine = _challenges
        .where((_Challenge c) => c.userId == user.id)
        .toList();
    final List<_CheckIn> all = mine
        .expand((_Challenge c) => _checkInsFor(c.id))
        .toList();

    final int completed = all
        .where((_CheckIn c) => c.status == 'completed')
        .length;
    final int skipped = all
        .where((_CheckIn c) => c.status != 'completed')
        .length;
    final int total = completed + skipped;

    return <String, dynamic>{
      'xp_total': user.xpTotal,
      'level': _level(user),
      'current_streak': user.currentStreak,
      'longest_streak': user.longestStreak,
      'success_rate': total == 0 ? 0 : _round2(completed / total * 100),
      'completed_checkins': completed,
      'skipped_checkins': skipped,
      'active_challenges': mine
          .where((_Challenge c) => c.status == 'active')
          .length,
      'completed_challenges': mine
          .where((_Challenge c) => c.status == 'completed')
          .length,
    };
  }

  // ---------------------------------------------------------------------- ai

  MockResponse _motivation(_User user, Map<String, dynamic> body) {
    final int? requestedId = body['challenge_id'] as int?;
    final List<_Challenge> mine = _challenges
        .where((_Challenge c) => c.userId == user.id)
        .toList();

    _Challenge? challenge;
    for (final _Challenge candidate in mine) {
      if (candidate.id == requestedId) challenge = candidate;
    }
    challenge ??= mine
        .where((_Challenge c) => c.status == 'active')
        .firstOrNull;

    if (challenge == null) {
      return MockResponse.ok(<String, dynamic>{
        'message':
            '${user.name.split(' ').first}, start with one small promise to '
            'yourself today. That is enough to begin.',
        'tone': 'encouraging',
        'source': 'template',
        'challenge_id': null,
        'challenge_title': null,
      });
    }

    return MockResponse.ok(<String, dynamic>{
      'message': _motivationMessage(user, challenge),
      'tone': user.currentStreak >= 3 ? 'celebratory' : 'encouraging',
      // The contract's documented fallback when no OpenAI key is configured.
      'source': 'template',
      'challenge_id': challenge.id,
      'challenge_title': challenge.title,
    });
  }

  String _motivationMessage(_User user, _Challenge challenge) {
    final String firstName = user.name.split(' ').first;
    if (user.currentStreak == 0) {
      return '$firstName, your ${challenge.title} streak can restart with five '
          'minutes today. Shoes on — that is enough.';
    }
    if (user.currentStreak >= 3) {
      return '$firstName, ${user.currentStreak} days of ${challenge.title} in a '
          'row. You are not trying anymore — you are becoming.';
    }
    return '$firstName, day ${user.currentStreak + 1} of ${challenge.title}. '
        'Small and repeatable beats big and rare.';
  }

  MockResponse _chat(_User user, Map<String, dynamic> body) {
    final String message = (body['message'] as String? ?? '').trim();
    if (message.isEmpty) {
      return MockResponse.validation(<String, List<String>>{
        'message': <String>['The message field is required.'],
      });
    }
    if (message.length > 1000) {
      return MockResponse.validation(<String, List<String>>{
        'message': <String>[
          'The message may not be greater than 1000 characters.',
        ],
      });
    }

    int? sessionId = body['session_id'] as int?;
    if (sessionId == null ||
        !_chatSessions.any((_ChatSession s) => s.id == sessionId)) {
      final _ChatSession session = _ChatSession(
        id: _nextSessionId++,
        userId: user.id,
        title: message.length > 40 ? '${message.substring(0, 40)}…' : message,
        challengeId: body['challenge_id'] as int?,
        createdAt: DateTime.now(),
      );
      _chatSessions.add(session);
      sessionId = session.id;
    }

    _chatMessages.add(
      _ChatMessage(
        id: _nextMessageId++,
        sessionId: sessionId,
        role: 'user',
        content: message,
        createdAt: DateTime.now(),
      ),
    );

    final List<_Knowledge> sources = _retrieve(message);
    final _Challenge? challenge = _challenges
        .where((_Challenge c) => c.userId == user.id && c.status == 'active')
        .firstOrNull;

    final _ChatMessage reply = _ChatMessage(
      id: _nextMessageId++,
      sessionId: sessionId,
      role: 'assistant',
      content: _composeReply(sources, challenge),
      createdAt: DateTime.now(),
    );
    _chatMessages.add(reply);

    return MockResponse.ok(<String, dynamic>{
      'session_id': sessionId,
      'message': _messageJson(reply),
      'sources': sources
          .map(
            (_Knowledge k) => <String, dynamic>{
              'title': k.title,
              'snippet': k.body,
            },
          )
          .toList(),
      'used_challenge_id': challenge?.id,
    });
  }

  /// Keyword overlap against the seeded knowledge base — a stand-in for the
  /// backend's MySQL retrieval, good enough to cite the right article.
  List<_Knowledge> _retrieve(String question) {
    final Set<String> words = question
        .toLowerCase()
        .split(RegExp(r'[^a-z]+'))
        .where((String w) => w.length > 3)
        .toSet();

    final List<_Knowledge> ranked = List<_Knowledge>.from(_knowledge);
    ranked.sort((_Knowledge a, _Knowledge b) {
      return _score(b, words).compareTo(_score(a, words));
    });

    final List<_Knowledge> hits = ranked
        .where((_Knowledge k) => _score(k, words) > 0)
        .take(2)
        .toList();
    return hits.isEmpty ? <_Knowledge>[_knowledge[1]] : hits;
  }

  int _score(_Knowledge article, Set<String> words) {
    final String haystack =
        '${article.title} ${article.category} ${article.body}'.toLowerCase();
    return words.where(haystack.contains).length;
  }

  String _composeReply(List<_Knowledge> sources, _Challenge? challenge) {
    final String grounding = sources.first.body;
    if (challenge == null) return grounding;
    return '$grounding For ${challenge.title}, that means doing the smallest '
        'version today rather than waiting for a perfect day.';
  }

  // ------------------------------------------------------------- serialising

  int _level(_User user) => (user.xpTotal ~/ xpPerLevel) + 1;

  Map<String, dynamic> _userJson(_User user) => <String, dynamic>{
    'id': user.id,
    'name': user.name,
    'email': user.email,
    'timezone': user.timezone,
    'xp_total': user.xpTotal,
    'level': _level(user),
    'current_streak': user.currentStreak,
    'longest_streak': user.longestStreak,
  };

  int _completedCount(_Challenge challenge) =>
      _checkInsFor(challenge.id)
          .where((_CheckIn c) => c.status == 'completed')
          .length;

  double _progressPercent(_Challenge challenge) {
    if (challenge.durationDays == 0) return 0;
    return _round2(_completedCount(challenge) / challenge.durationDays * 100);
  }

  Map<String, dynamic> _challengeJson(_Challenge challenge) {
    final List<_CheckIn> history = _checkInsFor(challenge.id);
    return <String, dynamic>{
      'id': challenge.id,
      'title': challenge.title,
      'description': challenge.description,
      'status': challenge.status,
      'difficulty': challenge.difficulty,
      'visibility': challenge.visibility,
      'category_id': challenge.categoryId,
      'start_date': challenge.startDate == null
          ? null
          : _dateString(challenge.startDate!),
      'end_date': challenge.endDate == null
          ? null
          : _dateString(challenge.endDate!),
      'duration_days': challenge.durationDays,
      'progress_percent': _progressPercent(challenge),
      'current_streak': _challengeStreak(history),
      'longest_streak': _challengeLongestStreak(history),
      'completed_checkins': _completedCount(challenge),
      'missed_checkins': history
          .where((_CheckIn c) => c.status != 'completed')
          .length,
      'checked_in_today': history.any(
        (_CheckIn c) => _sameDay(c.date, _today()),
      ),
      'today_check_in_status': _todayCheckInStatus(history),
      'created_at': _dateTimeString(challenge.createdAt),
      'updated_at': _dateTimeString(challenge.updatedAt ?? challenge.createdAt),
    };
  }

  String? _todayCheckInStatus(List<_CheckIn> history) {
    for (final _CheckIn checkIn in history) {
      if (_sameDay(checkIn.date, _today())) return checkIn.status;
    }
    return null;
  }

  /// Live streak: consecutive completed days ending today, or yesterday when
  /// today is still open.
  int _challengeStreak(List<_CheckIn> history) {
    final Map<String, _CheckIn> byDate = <String, _CheckIn>{
      for (final _CheckIn c in history) _dateString(c.date): c,
    };

    DateTime tip = _today();
    if (byDate[_dateString(tip)] == null) {
      tip = tip.subtract(const Duration(days: 1));
    }
    return _challengeStreakAt(history, tip);
  }

  /// Consecutive completed days ending on [tip] (inclusive). A skip or gap on
  /// that day yields zero — used for `streak_after` on a historical check-in.
  int _challengeStreakAt(List<_CheckIn> history, DateTime tip) {
    final Map<String, _CheckIn> byDate = <String, _CheckIn>{
      for (final _CheckIn c in history) _dateString(c.date): c,
    };

    if (byDate[_dateString(tip)]?.status != 'completed') return 0;

    int streak = 0;
    DateTime cursor = tip;
    while (byDate[_dateString(cursor)]?.status == 'completed') {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _challengeLongestStreak(List<_CheckIn> history) {
    int longest = 0;
    int running = 0;
    DateTime? previous;

    for (final _CheckIn checkIn in history) {
      if (checkIn.status != 'completed') {
        running = 0;
        previous = checkIn.date;
        continue;
      }
      final bool consecutive =
          previous != null &&
          _sameDay(checkIn.date, previous.add(const Duration(days: 1)));
      running = consecutive ? running + 1 : 1;
      longest = max(longest, running);
      previous = checkIn.date;
    }
    return longest;
  }

  Map<String, dynamic> _checkInJson(_CheckIn checkIn) => <String, dynamic>{
    'id': checkIn.id,
    'challenge_id': checkIn.challengeId,
    'check_in_date': _dateString(checkIn.date),
    'status': checkIn.status,
    'note': checkIn.note,
    'mood': checkIn.mood,
    'energy': checkIn.energy,
    'xp_earned': checkIn.xpEarned,
    'streak_after': checkIn.streakAfter,
    'created_at': _dateTimeString(checkIn.createdAt),
  };

  Map<String, dynamic> _xpJson(_XpEntry entry) => <String, dynamic>{
    'id': entry.id,
    'amount': entry.amount,
    'reason': entry.reason,
    'challenge_id': entry.challengeId,
    'created_at': _dateTimeString(entry.createdAt),
  };

  Map<String, dynamic> _badgeJson(_Badge badge) => <String, dynamic>{
    'id': badge.id,
    'code': badge.code,
    'name': badge.name,
    'description': badge.description,
    'unlocked_at': _dateTimeString(badge.unlockedAt),
  };

  Map<String, dynamic> _sessionJson(_ChatSession session) => <String, dynamic>{
    'id': session.id,
    'title': session.title,
    'challenge_id': session.challengeId,
    'created_at': _dateTimeString(session.createdAt),
    'updated_at': _dateTimeString(session.createdAt),
  };

  Map<String, dynamic> _messageJson(_ChatMessage message) => <String, dynamic>{
    'id': message.id,
    'session_id': message.sessionId,
    'role': message.role,
    'content': message.content,
    'created_at': _dateTimeString(message.createdAt),
  };

  // ------------------------------------------------------------------- dates

  DateTime _today() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime? _parseDate(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  String _dateString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _dateTimeString(DateTime value) =>
      '${value.toUtc().toIso8601String().split('.').first}Z';

  double _round2(double value) => (value * 100).round() / 100;

  // -------------------------------------------------------------- seed data

  /// From `docs/mvp/teams/BACKEND-TEAM-GUIDE.md` §10.
  static const List<Map<String, dynamic>> _categories = <Map<String, dynamic>>[
    <String, dynamic>{'id': 1, 'name': 'Health', 'slug': 'health'},
    <String, dynamic>{'id': 2, 'name': 'Focus', 'slug': 'focus'},
    <String, dynamic>{'id': 3, 'name': 'Wellbeing', 'slug': 'wellbeing'},
  ];

  static const List<Map<String, dynamic>> _templates = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 1,
      'title': '7-Day Morning Walk',
      'description': 'Walk 10 minutes after waking up.',
      'difficulty': 'beginner',
      'duration_days': 7,
      'category_id': 1,
    },
    <String, dynamic>{
      'id': 2,
      'title': 'No Sugar Week',
      'description': 'Skip added sugar for seven days.',
      'difficulty': 'medium',
      'duration_days': 7,
      'category_id': 1,
    },
    <String, dynamic>{
      'id': 3,
      'title': 'Night Phone Curfew',
      'description': 'Phone away one hour before bed.',
      'difficulty': 'easy',
      'duration_days': 7,
      'category_id': 2,
    },
  ];

  static const List<_Knowledge> _knowledge = <_Knowledge>[
    _Knowledge(
      'Tiny habits starter',
      'habits',
      'Start absurdly small; consistency beats intensity.',
    ),
    _Knowledge(
      'Recovery basics',
      'recovery',
      'After a miss, restart with a tiny action instead of quitting; one miss '
          'is not a failure.',
    ),
    _Knowledge(
      'Humane streaks',
      'streaks',
      'Streaks are a tool for motivation, not a measure of self-worth; a '
          'broken streak does not erase progress.',
    ),
    _Knowledge(
      'How check-ins work',
      'faq',
      'A check-in records a completed or skipped day for a challenge; each '
          'challenge allows one check-in per calendar day.',
    ),
    _Knowledge(
      'Writing a good challenge',
      'faq',
      'Good challenges are specific, small, and tied to a clear trigger or '
          'time of day.',
    ),
  ];
}

/// Status code plus the JSON body the adapter should return.
class MockResponse {
  const MockResponse(this.statusCode, this.body);

  factory MockResponse.ok(Map<String, dynamic> data) =>
      MockResponse(200, <String, dynamic>{'data': data});

  factory MockResponse.list(List<Map<String, dynamic>> data) =>
      MockResponse(200, <String, dynamic>{'data': data});

  factory MockResponse.error(int status, String message, {String? code}) =>
      MockResponse(status, <String, dynamic>{
        'message': message,
        'code': ?code,
      });

  factory MockResponse.validation(Map<String, List<String>> errors) =>
      MockResponse(422, <String, dynamic>{
        'message': 'The given data was invalid.',
        'code': 'VALIDATION_ERROR',
        'errors': errors,
      });

  final int statusCode;
  final Map<String, dynamic> body;
}

class _User {
  _User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.timezone,
  });

  final int id;
  String name;
  final String email;
  final String password;
  String? timezone;
  int xpTotal = 0;
  int currentStreak = 0;
  int longestStreak = 0;
}

class _Challenge {
  _Challenge({
    required this.id,
    required this.userId,
    required this.title,
    required this.difficulty,
    required this.visibility,
    required this.durationDays,
    required this.createdAt,
    this.description,
    this.categoryId,
  });

  final int id;
  final int userId;
  final String title;
  final String? description;
  String status = 'draft';
  final String difficulty;
  final String visibility;
  final int? categoryId;
  final int durationDays;
  DateTime? startDate;
  DateTime? endDate;
  final DateTime createdAt;
  DateTime? updatedAt;
}

class _CheckIn {
  _CheckIn({
    required this.id,
    required this.challengeId,
    required this.date,
    required this.status,
    required this.xpEarned,
    required this.streakAfter,
    required this.createdAt,
    this.note,
    this.mood,
    this.energy,
  });

  final int id;
  final int challengeId;
  final DateTime date;
  final String status;
  final String? note;
  final int? mood;
  final int? energy;
  final int xpEarned;
  int streakAfter;
  final DateTime createdAt;
}

class _XpEntry {
  _XpEntry({
    required this.id,
    required this.userId,
    required this.amount,
    required this.reason,
    required this.createdAt,
    this.challengeId,
  });

  final int id;
  final int userId;
  final int amount;
  final String reason;
  final int? challengeId;
  final DateTime createdAt;
}

class _Badge {
  _Badge({
    required this.id,
    required this.userId,
    required this.code,
    required this.name,
    required this.description,
    required this.unlockedAt,
  });

  final int id;
  final int userId;
  final String code;
  final String name;
  final String description;
  final DateTime unlockedAt;
}

class _ChatSession {
  _ChatSession({
    required this.id,
    required this.userId,
    required this.createdAt,
    this.title,
    this.challengeId,
  });

  final int id;
  final int userId;
  final String? title;
  final int? challengeId;
  final DateTime createdAt;
}

class _ChatMessage {
  _ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final int sessionId;
  final String role;
  final String content;
  final DateTime createdAt;
}

class _Knowledge {
  const _Knowledge(this.title, this.category, this.body);

  final String title;
  final String category;
  final String body;
}
