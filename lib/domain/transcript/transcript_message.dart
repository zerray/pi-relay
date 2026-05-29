class TranscriptMessage {
  const TranscriptMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    required this.isStreaming,
    this.kind,
    this.toolCallId,
    this.toolName,
    this.summary,
    this.arguments,
    this.content = const [],
    this.isTruncated = false,
    this.originalBytes,
  });

  final String id;
  final String role;
  final String text;
  final DateTime createdAt;
  final bool isStreaming;
  final String? kind;
  final String? toolCallId;
  final String? toolName;
  final String? summary;
  final Object? arguments;
  final List<Object?> content;
  final bool isTruncated;
  final int? originalBytes;

  factory TranscriptMessage.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final roleValue = json['role'];
    final rawText = json['text'];
    final createdAtValue = json['createdAt'];
    final isStreaming = json['isStreaming'];
    final kind = json['kind'];
    final toolCallId = json['toolCallId'];
    final toolName = json['toolName'];
    final summary = json['summary'];
    final isTruncated = json['isTruncated'];
    final originalBytes = json['originalBytes'];

    if (id is! String || createdAtValue is! String || isStreaming is! bool) {
      throw const FormatException(
          'Transcript message JSON is missing required fields.');
    }
    if (roleValue != null && roleValue is! String) {
      throw const FormatException('Transcript message JSON has invalid role.');
    }
    if (rawText != null && rawText is! String) {
      throw const FormatException('Transcript message JSON has invalid text.');
    }
    if (kind != null && kind is! String ||
        toolCallId != null && toolCallId is! String ||
        toolName != null && toolName is! String ||
        summary != null && summary is! String ||
        isTruncated != null && isTruncated is! bool ||
        originalBytes != null && originalBytes is! int) {
      throw const FormatException(
          'Transcript message JSON has invalid optional fields.');
    }

    final role = roleValue as String? ?? _roleFromKind(kind as String?);
    if (role == null) {
      throw const FormatException(
          'Transcript message JSON is missing required fields.');
    }

    final createdAt = DateTime.tryParse(createdAtValue);
    if (createdAt == null) {
      throw const FormatException(
          'Transcript message JSON has invalid createdAt.');
    }

    return TranscriptMessage(
      id: id,
      role: role,
      text: rawText as String? ??
          _textFromContent(json['content'], kind: kind as String?),
      createdAt: createdAt,
      isStreaming: isStreaming,
      kind: kind as String?,
      toolCallId: toolCallId as String?,
      toolName: toolName as String?,
      summary: summary as String?,
      arguments: json['arguments'],
      content: json['content'] is List
          ? (json['content'] as List).toList(growable: false)
          : const [],
      isTruncated: isTruncated as bool? ?? false,
      originalBytes: originalBytes as int?,
    );
  }

  static String? _roleFromKind(String? kind) {
    return switch (kind) {
      'userText' => 'user',
      'assistantText' || 'thinking' || 'toolCall' => 'assistant',
      'toolResult' => 'toolResult',
      'system' => 'system',
      _ => null,
    };
  }

  static String _textFromContent(Object? content, {String? kind}) {
    if (content is! List) return '';

    final parts = <String>[];
    for (final block in content) {
      if (block is Map<String, Object?>) {
        final type = block['type'];
        final text = type == 'thinking' && kind == 'thinking'
            ? block['thinking']
            : type == 'text'
                ? block['text']
                : null;
        if (text is String && text.isNotEmpty) parts.add(text);
      }
    }
    return parts.join('\n');
  }
}
