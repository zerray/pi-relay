import '../transcript/transcript_message.dart';
import 'remote_session.dart';

sealed class SessionStreamEvent {
  const SessionStreamEvent();

  factory SessionStreamEvent.fromJson(Map<String, Object?> json) {
    final type = json['type'];
    if (type is! String || type.isEmpty) {
      throw const FormatException('Session stream event is missing type.');
    }

    return switch (type) {
      'session_state' => SessionStateEvent(
          SessionStreamState.fromJson(_object(json['state'], 'state')),
        ),
      'assistant_delta' || 'assistantDelta' => AssistantDeltaEvent(
          itemId: _string(json['messageId'], 'messageId'),
          text: _string(json['text'], 'text'),
        ),
      'message_upsert' || 'messageUpsert' => MessageUpsertEvent(
          TranscriptMessage.fromJson(_object(json['message'], 'message')),
        ),
      'transcript_message_start' => TranscriptMessageStartEvent(
          TranscriptMessage.fromJson(_object(json['message'], 'message')),
        ),
      'transcript_message_patch' => TranscriptMessagePatchEvent(
          messageId: _string(json['messageId'], 'messageId'),
          contentIndex: _int(json['contentIndex'], 'contentIndex'),
          patch:
              TranscriptMessagePatch.fromJson(_object(json['patch'], 'patch')),
        ),
      'transcript_message_end' => TranscriptMessageEndEvent(
          TranscriptMessage.fromJson(_object(json['message'], 'message')),
        ),
      'turn_end' || 'agent_done' || 'agentDone' => const TurnFinishedEvent(),
      'session_closed' => const SessionClosedEvent(),
      'error' => SessionStreamErrorEvent(_string(json['message'], 'message')),
      _ => const IgnoredSessionStreamEvent(),
    };
  }
}

class SessionStateEvent extends SessionStreamEvent {
  const SessionStateEvent(this.state);

  final SessionStreamState state;
}

class AssistantDeltaEvent extends SessionStreamEvent {
  const AssistantDeltaEvent({required this.itemId, required this.text});

  final String itemId;
  final String text;
}

class MessageUpsertEvent extends SessionStreamEvent {
  const MessageUpsertEvent(this.message);

  final TranscriptMessage message;
}

class TranscriptMessageStartEvent extends SessionStreamEvent {
  const TranscriptMessageStartEvent(this.message);

  final TranscriptMessage message;
}

class TranscriptMessagePatchEvent extends SessionStreamEvent {
  const TranscriptMessagePatchEvent({
    required this.messageId,
    required this.contentIndex,
    required this.patch,
  });

  final String messageId;
  final int contentIndex;
  final TranscriptMessagePatch patch;
}

class TranscriptMessageEndEvent extends SessionStreamEvent {
  const TranscriptMessageEndEvent(this.message);

  final TranscriptMessage message;
}

class TurnFinishedEvent extends SessionStreamEvent {
  const TurnFinishedEvent();
}

class SessionClosedEvent extends SessionStreamEvent {
  const SessionClosedEvent();
}

class SessionStreamErrorEvent extends SessionStreamEvent {
  const SessionStreamErrorEvent(this.message);

  final String message;
}

class IgnoredSessionStreamEvent extends SessionStreamEvent {
  const IgnoredSessionStreamEvent();
}

class SessionStreamState {
  const SessionStreamState({
    required this.messages,
    required this.hasOlderMessages,
    required this.isStreaming,
    this.session,
    this.olderMessagesCursor,
  });

  final RemoteSession? session;
  final List<TranscriptMessage> messages;
  final String? olderMessagesCursor;
  final bool hasOlderMessages;
  final bool isStreaming;

  factory SessionStreamState.fromJson(Map<String, Object?> json) {
    final messagesJson = json['messages'];
    if (messagesJson is! List) {
      throw const FormatException('Session stream state is missing messages.');
    }

    RemoteSession? session;
    final sessionJson = json['session'];
    if (sessionJson is Map<String, Object?>) {
      try {
        session = RemoteSession.fromJson(sessionJson);
      } on FormatException {
        session = null;
      }
    }

    final olderMessagesCursor = json['olderMessagesCursor'];
    final hasOlderMessages = json['hasOlderMessages'];
    final isStreaming = json['isStreaming'];
    if (olderMessagesCursor != null && olderMessagesCursor is! String ||
        hasOlderMessages is! bool ||
        isStreaming is! bool) {
      throw const FormatException('Session stream state has invalid fields.');
    }

    return SessionStreamState(
      session: session,
      messages: messagesJson.map((messageJson) {
        if (messageJson is! Map<String, Object?>) {
          throw const FormatException('Stream transcript message is invalid.');
        }
        return TranscriptMessage.fromJson(messageJson);
      }).toList(growable: false),
      olderMessagesCursor: olderMessagesCursor as String?,
      hasOlderMessages: hasOlderMessages,
      isStreaming: isStreaming,
    );
  }
}

sealed class TranscriptMessagePatch {
  const TranscriptMessagePatch();

  factory TranscriptMessagePatch.fromJson(Map<String, Object?> json) {
    final type = json['type'];
    return switch (type) {
      'text_delta' => TextDeltaPatch(_string(json['delta'], 'delta')),
      'thinking_delta' => ThinkingDeltaPatch(_string(json['delta'], 'delta')),
      'toolCall' || 'tool_call' => ToolCallPatch.fromJson(
          _object(json['toolCall'], 'toolCall'),
        ),
      _ => const IgnoredTranscriptMessagePatch(),
    };
  }
}

class TextDeltaPatch extends TranscriptMessagePatch {
  const TextDeltaPatch(this.delta);

  final String delta;
}

class ThinkingDeltaPatch extends TranscriptMessagePatch {
  const ThinkingDeltaPatch(this.delta);

  final String delta;
}

class ToolCallPatch extends TranscriptMessagePatch {
  const ToolCallPatch({
    required this.id,
    required this.name,
    required this.arguments,
    this.argumentsTruncated = false,
    this.argumentsOriginalBytes,
  });

  final String id;
  final String name;
  final Object? arguments;
  final bool argumentsTruncated;
  final int? argumentsOriginalBytes;

  factory ToolCallPatch.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final name = json['name'];
    final argumentsTruncated = json['argumentsTruncated'];
    final argumentsOriginalBytes = json['argumentsOriginalBytes'];
    if (id is! String ||
        name is! String ||
        argumentsTruncated != null && argumentsTruncated is! bool ||
        argumentsOriginalBytes != null && argumentsOriginalBytes is! int) {
      throw const FormatException('Tool call patch is invalid.');
    }
    return ToolCallPatch(
      id: id,
      name: name,
      arguments: json['arguments'],
      argumentsTruncated: argumentsTruncated as bool? ?? false,
      argumentsOriginalBytes: argumentsOriginalBytes as int?,
    );
  }
}

class IgnoredTranscriptMessagePatch extends TranscriptMessagePatch {
  const IgnoredTranscriptMessagePatch();
}

Map<String, Object?> _object(Object? value, String field) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('Session stream event field $field is not an object.');
}

String _string(Object? value, String field) {
  if (value is String) return value;
  throw FormatException('Session stream event field $field is not a string.');
}

int _int(Object? value, String field) {
  if (value is int) return value;
  throw FormatException('Session stream event field $field is not an int.');
}
