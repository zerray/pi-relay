import '../transcript/transcript_message.dart';
import 'remote_session.dart';
import 'runtime_status.dart';

class SessionSnapshot {
  const SessionSnapshot({
    required this.session,
    required this.messages,
    required this.olderMessagesCursor,
    required this.hasOlderMessages,
    required this.isStreaming,
    this.runtimeStatus,
  });

  final RemoteSession session;
  final List<TranscriptMessage> messages;
  final String? olderMessagesCursor;
  final bool hasOlderMessages;
  final bool isStreaming;
  final RuntimeStatus? runtimeStatus;

  factory SessionSnapshot.fromJson(Map<String, Object?> json) {
    final sessionJson = json['session'];
    final messagesJson = json['messages'];
    final olderMessagesCursor = json['olderMessagesCursor'];
    final hasOlderMessages = json['hasOlderMessages'];
    final isStreaming = json['isStreaming'];
    final runtimeStatusJson = json['runtimeStatus'];

    if (sessionJson is! Map<String, Object?> ||
        messagesJson is! List ||
        hasOlderMessages is! bool ||
        isStreaming is! bool) {
      throw const FormatException(
          'Session snapshot is missing required fields.');
    }
    if (olderMessagesCursor != null && olderMessagesCursor is! String) {
      throw const FormatException(
          'Session snapshot has invalid olderMessagesCursor.');
    }

    return SessionSnapshot(
      session: RemoteSession.fromJson(sessionJson),
      messages: messagesJson.map((messageJson) {
        if (messageJson is! Map<String, Object?>) {
          throw const FormatException(
              'Transcript message entry is not an object.');
        }
        return TranscriptMessage.fromJson(messageJson);
      }).toList(growable: false),
      olderMessagesCursor: olderMessagesCursor as String?,
      hasOlderMessages: hasOlderMessages,
      isStreaming: isStreaming,
      runtimeStatus: runtimeStatusJson == null
          ? null
          : RuntimeStatus.fromJson(_object(runtimeStatusJson, 'runtimeStatus')),
    );
  }
}

Map<String, Object?> _object(Object? value, String field) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('Session snapshot field $field is not an object.');
}
