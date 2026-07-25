/// `ChatSource` from `docs/mvp/teams/SHARED-DATA-CONTRACT.md` §3.17 — the
/// knowledge chunk the answer was grounded in.
class ChatSource {
  const ChatSource({required this.title, required this.snippet});

  final String title;
  final String snippet;

  factory ChatSource.fromJson(Map<String, dynamic> json) {
    return ChatSource(
      title: json['title'] as String? ?? 'Coach notes',
      snippet: json['snippet'] as String? ?? '',
    );
  }
}
