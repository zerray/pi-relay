import 'transcript_message.dart';

class TranscriptPage {
  const TranscriptPage({
    required this.messages,
    required this.olderMessagesCursor,
    required this.hasOlderMessages,
  });

  final List<TranscriptMessage> messages;
  final String? olderMessagesCursor;
  final bool hasOlderMessages;

  factory TranscriptPage.fromJson(Map<String, Object?> json) {
    final messagesJson = json['messages'];
    final olderMessagesCursor = json['olderMessagesCursor'];
    final hasOlderMessages = json['hasOlderMessages'];

    if (messagesJson is! List || hasOlderMessages is! bool) {
      throw const FormatException(
          'Transcript page is missing required fields.');
    }
    if (olderMessagesCursor != null && olderMessagesCursor is! String) {
      throw const FormatException(
          'Transcript page has invalid olderMessagesCursor.');
    }

    return TranscriptPage(
      messages: messagesJson.map((messageJson) {
        if (messageJson is! Map<String, Object?>) {
          throw const FormatException(
              'Transcript message entry is not an object.');
        }
        return TranscriptMessage.fromJson(messageJson);
      }).toList(growable: false),
      olderMessagesCursor: olderMessagesCursor as String?,
      hasOlderMessages: hasOlderMessages,
    );
  }
}
