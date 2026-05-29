class TranscriptMessage {
  const TranscriptMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    required this.isStreaming,
  });

  final String id;
  final String role;
  final String text;
  final DateTime createdAt;
  final bool isStreaming;

  factory TranscriptMessage.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final role = json['role'];
    final rawText = json['text'];
    final createdAtValue = json['createdAt'];
    final isStreaming = json['isStreaming'];

    if (id is! String ||
        role is! String ||
        createdAtValue is! String ||
        isStreaming is! bool) {
      throw const FormatException(
          'Transcript message JSON is missing required fields.');
    }
    if (rawText != null && rawText is! String) {
      throw const FormatException('Transcript message JSON has invalid text.');
    }

    final createdAt = DateTime.tryParse(createdAtValue);
    if (createdAt == null) {
      throw const FormatException(
          'Transcript message JSON has invalid createdAt.');
    }

    return TranscriptMessage(
      id: id,
      role: role,
      text: rawText as String? ?? _textFromContent(json['content']),
      createdAt: createdAt,
      isStreaming: isStreaming,
    );
  }

  static String _textFromContent(Object? content) {
    if (content is! List) return '';

    final parts = <String>[];
    for (final block in content) {
      if (block is Map<String, Object?> && block['type'] == 'text') {
        final text = block['text'];
        if (text is String && text.isNotEmpty) parts.add(text);
      }
    }
    return parts.join('\n');
  }
}
