/// Fixed Amharic answers for the live demo video.
///
/// Judges hear the same lines every time — greeting, what the app is, and the
/// reading-challenge walkthrough — whether they type or speak into the mic.
abstract final class DemoAmharicScript {
  /// Spoken and shown the moment the coach opens.
  static const String greeting = 'ደህና መጡ።';

  /// "What is this app?"
  static const String whatIsApp =
      'ይህ መተግበሪያ ሰዎች ባህሪያቸውን በቀስታ እና በቀጣይነት እንዲለውጡ የሚረዳ '
      'መተግበሪያ ነው።';

  /// "How do we demo building a reading habit?"
  static const String readingDemo =
      'ለዚህ ዴሞ በአንድ ሳምንት ውስጥ የማንበብ ልማድ እንዴት መገንባት እንደሚቻል '
      'እናሳያለን። መጀመሪያ ወደ መተግበሪያው እንገባለን። ከዚያ "Challenge" የሚለውን '
      'እንመርጣለን። ከዚያ የ7 ቀን የማንበብ ቻሌንጅን እንጀምራለን።';

  /// Starter chips on the coach welcome — each maps to a scripted answer.
  static const List<String> starters = <String>[
    'ሰላም',
    'ይህ መተግበሪያ ምንድን ነው?',
    'የማንበብ ልማድ እንዴት እንገነባለን?',
  ];

  /// Returns a scripted answer when the member's words match a demo beat.
  static String? match(String raw) {
    final String text = raw.trim();
    if (text.isEmpty) return null;

    final String folded = text.toLowerCase();

    if (_hits(
      folded,
      text,
      amharic: <String>[
        'ሰላም',
        'ደህና',
        'እንደምን',
        'እንደምን አደርክ',
        'እንደምን አደረሽ',
        'ሃይ',
        'ሄሎ',
      ],
      latin: <String>['hello', 'hi ', 'hi,', 'salam', 'selam', 'greeting'],
    )) {
      return greeting;
    }

    if (_hits(
      folded,
      text,
      amharic: <String>[
        'መተግበሪያ',
        'ምንድን',
        'ምንድር',
        'ስለ መተግበሪያ',
        'ይህ ምን',
      ],
      latin: <String>[
        'what is',
        'what\'s this',
        'about the app',
        'this app',
        'what does',
      ],
    )) {
      return whatIsApp;
    }

    if (_hits(
      folded,
      text,
      amharic: <String>[
        'ማንበብ',
        'ንባብ',
        'ቻሌንጅ',
        'ሳምንት',
        'ዴሞ',
        'እንዴት',
        'ልማድ',
        '7 ቀን',
        'ሰባት',
      ],
      latin: <String>[
        'read',
        'reading',
        'challenge',
        'demo',
        'week',
        'habit',
        '7 day',
        'seven',
      ],
    )) {
      return readingDemo;
    }

    return null;
  }

  static bool _hits(
    String folded,
    String original, {
    required List<String> amharic,
    required List<String> latin,
  }) {
    for (final String needle in amharic) {
      if (original.contains(needle)) return true;
    }
    for (final String needle in latin) {
      if (folded.contains(needle)) return true;
    }
    return false;
  }
}
