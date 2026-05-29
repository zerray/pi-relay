import '../transcript/transcript_message.dart';
import 'remote_session.dart';
import 'session_stream_event.dart';

class SessionStreamModel {
  const SessionStreamModel({
    this.session,
    this.messages = const [],
    this.olderMessagesCursor,
    this.hasOlderMessages = false,
    this.isStreaming = false,
    this.isClosed = false,
    this.lastErrorMessage,
  });

  final RemoteSession? session;
  final List<TranscriptMessage> messages;
  final String? olderMessagesCursor;
  final bool hasOlderMessages;
  final bool isStreaming;
  final bool isClosed;
  final String? lastErrorMessage;

  SessionStreamModel copyWith({
    RemoteSession? session,
    bool clearSession = false,
    List<TranscriptMessage>? messages,
    String? olderMessagesCursor,
    bool clearOlderMessagesCursor = false,
    bool? hasOlderMessages,
    bool? isStreaming,
    bool? isClosed,
    String? lastErrorMessage,
    bool clearLastErrorMessage = false,
  }) {
    return SessionStreamModel(
      session: clearSession ? null : session ?? this.session,
      messages: messages ?? this.messages,
      olderMessagesCursor: clearOlderMessagesCursor
          ? null
          : olderMessagesCursor ?? this.olderMessagesCursor,
      hasOlderMessages: hasOlderMessages ?? this.hasOlderMessages,
      isStreaming: isStreaming ?? this.isStreaming,
      isClosed: isClosed ?? this.isClosed,
      lastErrorMessage: clearLastErrorMessage
          ? null
          : lastErrorMessage ?? this.lastErrorMessage,
    );
  }
}

class SessionStreamReducer {
  const SessionStreamReducer();

  SessionStreamModel reduce(
    SessionStreamModel model,
    SessionStreamEvent event, {
    required DateTime now,
  }) {
    return switch (event) {
      SessionStateEvent(:final state) => model.copyWith(
          session: state.session,
          messages: _mergeTranscriptMessages(
            existing: _removingReconciledMessages(
              existing: model.messages,
              incoming: _normalizedMessages(state.messages),
            ),
            incoming: _normalizedMessages(state.messages),
          ),
          olderMessagesCursor: state.olderMessagesCursor,
          clearOlderMessagesCursor: state.olderMessagesCursor == null,
          hasOlderMessages: state.hasOlderMessages,
          isStreaming: state.isStreaming,
          isClosed: false,
          clearLastErrorMessage: true,
        ),
      AssistantDeltaEvent(:final itemId, :final text) => model.copyWith(
          messages: _appendDelta(
            messages: model.messages,
            itemId: itemId,
            kind: 'assistantText',
            delta: text,
            now: now,
          ),
          isStreaming: true,
        ),
      MessageUpsertEvent(:final message) => _upsertMessage(model, message),
      TranscriptMessageStartEvent(:final message) => _upsertMessage(
          model,
          message,
          forceStreaming: true,
        ),
      TranscriptMessagePatchEvent(
        :final messageId,
        :final contentIndex,
        :final patch
      ) =>
        _applyPatch(
          model,
          messageId: messageId,
          contentIndex: contentIndex,
          patch: patch,
          now: now,
        ),
      TranscriptMessageEndEvent(:final message) =>
        _finishMessage(model, message),
      TurnFinishedEvent() => model.copyWith(
          messages: _finishStreamingMessages(model.messages),
          isStreaming: false,
        ),
      SessionClosedEvent() => model.copyWith(
          messages: _finishStreamingMessages(model.messages),
          isStreaming: false,
          isClosed: true,
        ),
      SessionStreamErrorEvent(:final message) => model.copyWith(
          lastErrorMessage: message,
        ),
      IgnoredSessionStreamEvent() => model,
    };
  }

  SessionStreamModel _upsertMessage(
    SessionStreamModel model,
    TranscriptMessage message, {
    bool forceStreaming = false,
  }) {
    final incoming = _messagesFromTranscriptMessage(
      forceStreaming ? _copyMessage(message, isStreaming: true) : message,
    );
    if (incoming.isEmpty) return model;
    if (forceStreaming &&
        !_shouldAcceptNewStreamingFragment(model.messages, message.id)) {
      return model;
    }
    return model.copyWith(
      messages: _mergeTranscriptMessages(
        existing: _removingReconciledMessages(
          existing: model.messages,
          incoming: incoming,
        ),
        incoming: incoming,
      ),
    );
  }

  SessionStreamModel _applyPatch(
    SessionStreamModel model, {
    required String messageId,
    required int contentIndex,
    required TranscriptMessagePatch patch,
    required DateTime now,
  }) {
    return switch (patch) {
      TextDeltaPatch(:final delta)
          when delta.isNotEmpty &&
              _shouldAcceptNewStreamingFragment(model.messages, messageId) =>
        model.copyWith(
          messages: _appendDelta(
            messages: model.messages,
            itemId: _assistantBlockItemId(
              messageId: messageId,
              blockKind: 'text',
              contentIndex: contentIndex,
            ),
            kind: 'assistantText',
            delta: delta,
            now: now,
          ),
          isStreaming: true,
        ),
      ThinkingDeltaPatch(:final delta)
          when delta.isNotEmpty &&
              _shouldAcceptNewStreamingFragment(model.messages, messageId) =>
        model.copyWith(
          messages: _appendDelta(
            messages: model.messages,
            itemId: _assistantBlockItemId(
              messageId: messageId,
              blockKind: 'thinking',
              contentIndex: contentIndex,
            ),
            kind: 'thinking',
            delta: delta,
            now: now,
          ),
          isStreaming: true,
        ),
      ToolCallPatch()
          when _shouldAcceptNewStreamingFragment(model.messages, messageId) =>
        model.copyWith(
          messages: _mergeTranscriptMessages(
            existing: model.messages,
            incoming: [_toolCallMessage(messageId, contentIndex, patch, now)],
          ),
          isStreaming: true,
        ),
      _ => model,
    };
  }

  SessionStreamModel _finishMessage(
    SessionStreamModel model,
    TranscriptMessage message,
  ) {
    final incoming = _messagesFromTranscriptMessage(
      _copyMessage(message, isStreaming: false),
    );
    if (incoming.isEmpty) {
      return model.copyWith(
          messages: _finishStreamingForMessage(model.messages, message.id));
    }
    return model.copyWith(
      messages: _mergeTranscriptMessages(
        existing: _removingReconciledMessages(
          existing: model.messages,
          incoming: incoming,
        ),
        incoming: incoming,
      ),
    );
  }
}

List<TranscriptMessage> _normalizedMessages(List<TranscriptMessage> messages) {
  return messages
      .expand(_messagesFromTranscriptMessage)
      .toList(growable: false);
}

List<TranscriptMessage> _messagesFromTranscriptMessage(
    TranscriptMessage message) {
  if (message.kind != null) return [message];

  if (message.role == 'assistant') {
    final blockMessages = <TranscriptMessage>[];
    for (var index = 0; index < message.content.length; index += 1) {
      final block = message.content[index];
      if (block is! Map<String, Object?>) continue;
      final createdAt = message.createdAt.add(Duration(milliseconds: index));
      switch (block['type']) {
        case 'text':
          final text = block['text'];
          if (text is! String || text.isEmpty) continue;
          blockMessages.add(TranscriptMessage(
            id: message.content.length == 1
                ? message.id
                : _assistantBlockItemId(
                    messageId: message.id,
                    blockKind: 'text',
                    contentIndex: index,
                  ),
            role: 'assistant',
            kind: 'assistantText',
            text: text,
            createdAt: createdAt,
            isStreaming: message.isStreaming,
            isTruncated: _bool(block['truncated']) || message.isTruncated,
            originalBytes:
                _intOrNull(block['originalBytes']) ?? message.originalBytes,
          ));
        case 'thinking':
          final thinking = block['thinking'];
          if (thinking is! String || thinking.isEmpty) continue;
          blockMessages.add(TranscriptMessage(
            id: _assistantBlockItemId(
              messageId: message.id,
              blockKind: 'thinking',
              contentIndex: index,
            ),
            role: 'assistant',
            kind: 'thinking',
            text: thinking,
            createdAt: createdAt,
            isStreaming: message.isStreaming,
            isTruncated: _bool(block['truncated']),
            originalBytes: _intOrNull(block['originalBytes']),
          ));
        case 'toolCall':
          final toolCallId = block['id'];
          final toolName = block['name'];
          if (toolCallId is! String || toolName is! String) continue;
          blockMessages.add(TranscriptMessage(
            id: _assistantBlockItemId(
              messageId: message.id,
              blockKind: 'tool',
              contentIndex: index,
              fallbackId: toolCallId,
            ),
            role: 'assistant',
            kind: 'toolCall',
            text: toolName,
            createdAt: createdAt,
            isStreaming: message.isStreaming,
            toolCallId: toolCallId,
            toolName: toolName,
            summary: _summarizeToolArguments(toolName, block['arguments']),
            arguments: block['arguments'],
            isTruncated: _bool(block['argumentsTruncated']),
            originalBytes: _intOrNull(block['argumentsOriginalBytes']),
          ));
      }
    }
    if (blockMessages.isNotEmpty) return blockMessages;
    if (message.text.isEmpty) return const [];
    return [_copyMessage(message, kind: 'assistantText')];
  }

  if (message.role == 'user') {
    final text = message.text.isEmpty
        ? _extractTextContent(message.content)
        : message.text;
    if (text.isEmpty) return const [];
    return [_copyMessage(message, kind: 'userText', text: text)];
  }

  if (message.role == 'toolResult') {
    final text = message.text.isEmpty
        ? _extractTextContent(message.content)
        : message.text;
    return [_copyMessage(message, kind: 'toolResult', text: text)];
  }

  if (message.role == 'system') {
    final text = message.text.isEmpty
        ? _extractTextContent(message.content)
        : message.text;
    if (text.isEmpty) return const [];
    return [_copyMessage(message, kind: 'system', text: text)];
  }

  return const [];
}

bool _shouldAcceptNewStreamingFragment(
  List<TranscriptMessage> messages,
  String messageId,
) {
  final hasRelatedMessage = messages.any(
    (message) =>
        message.id == messageId || message.id.startsWith('$messageId-'),
  );
  if (hasRelatedMessage || messages.isEmpty) return true;

  final lastMessage = messages.last;
  return !(!lastMessage.isStreaming &&
      _messageKind(lastMessage) == 'assistantText');
}

List<TranscriptMessage> _appendDelta({
  required List<TranscriptMessage> messages,
  required String itemId,
  required String kind,
  required String delta,
  required DateTime now,
}) {
  final index = messages.indexWhere((message) => message.id == itemId);
  if (index == -1) {
    return _mergeTranscriptMessages(
      existing: messages,
      incoming: [
        TranscriptMessage(
          id: itemId,
          role: 'assistant',
          kind: kind,
          text: delta,
          createdAt: now,
          isStreaming: true,
        ),
      ],
    );
  }

  final copy = messages.toList();
  final existing = copy[index];
  copy[index] = _copyMessage(
    existing,
    text: existing.text + delta,
    isStreaming: true,
  );
  return copy;
}

TranscriptMessage _toolCallMessage(
  String messageId,
  int contentIndex,
  ToolCallPatch patch,
  DateTime now,
) {
  return TranscriptMessage(
    id: _assistantBlockItemId(
      messageId: messageId,
      blockKind: 'tool',
      contentIndex: contentIndex,
      fallbackId: patch.id,
    ),
    role: 'assistant',
    kind: 'toolCall',
    text: patch.name,
    createdAt: now,
    isStreaming: false,
    toolCallId: patch.id,
    toolName: patch.name,
    summary: _summarizeToolArguments(patch.name, patch.arguments),
    arguments: patch.arguments,
    isTruncated: patch.argumentsTruncated,
    originalBytes: patch.argumentsOriginalBytes,
  );
}

List<TranscriptMessage> _finishStreamingMessages(
    List<TranscriptMessage> messages) {
  return messages
      .map((message) => message.isStreaming
          ? _copyMessage(message, isStreaming: false)
          : message)
      .toList(growable: false);
}

List<TranscriptMessage> _finishStreamingForMessage(
  List<TranscriptMessage> messages,
  String messageId,
) {
  return messages.map((message) {
    if (message.id == messageId || message.id.startsWith('$messageId-')) {
      return _copyMessage(message, isStreaming: false);
    }
    return message;
  }).toList(growable: false);
}

List<TranscriptMessage> _removingReconciledMessages({
  required List<TranscriptMessage> existing,
  required List<TranscriptMessage> incoming,
}) {
  final assistantIdToReplace = _assistantIdToReplace(existing, incoming);
  return existing.where((message) {
    if (assistantIdToReplace != null && message.id == assistantIdToReplace) {
      return false;
    }
    return !incoming.any((incomingMessage) =>
        incomingMessage.id != message.id &&
        _messageKind(incomingMessage) == _messageKind(message) &&
        incomingMessage.text == message.text &&
        message.isStreaming);
  }).toList(growable: false);
}

String? _assistantIdToReplace(
  List<TranscriptMessage> existing,
  List<TranscriptMessage> incoming,
) {
  final incomingAssistant = incoming.cast<TranscriptMessage?>().firstWhere(
        (message) =>
            message != null &&
            _messageKind(message) == 'assistantText' &&
            !message.isStreaming,
        orElse: () => null,
      );
  if (incomingAssistant == null) return null;

  for (var index = existing.length - 1; index >= 0; index -= 1) {
    final message = existing[index];
    if (_messageKind(message) != 'assistantText') continue;
    if (message.isStreaming) return message.id;
    if (incomingAssistant.text.isEmpty || message.text.isEmpty) continue;
    if (incomingAssistant.text.contains(message.text) ||
        message.text.contains(incomingAssistant.text)) {
      return message.id;
    }
  }
  return null;
}

List<TranscriptMessage> _mergeTranscriptMessages({
  required List<TranscriptMessage> existing,
  required List<TranscriptMessage> incoming,
}) {
  final messagesById = <String, TranscriptMessage>{
    for (final message in existing) message.id: message,
  };
  for (final message in incoming) {
    final existingMessage = messagesById[message.id];
    if (existingMessage != null &&
        message.isTruncated &&
        !existingMessage.isTruncated) {
      continue;
    }
    messagesById[message.id] = message;
  }
  final messages = messagesById.values.toList(growable: false);
  return messages.toList()
    ..sort((left, right) {
      final timeComparison = left.createdAt.compareTo(right.createdAt);
      if (timeComparison != 0) return timeComparison;
      return left.id.compareTo(right.id);
    });
}

TranscriptMessage _copyMessage(
  TranscriptMessage message, {
  String? id,
  String? role,
  String? text,
  DateTime? createdAt,
  bool? isStreaming,
  String? kind,
  String? toolCallId,
  String? toolName,
  String? summary,
  Object? arguments,
  List<Object?>? content,
  bool? isTruncated,
  int? originalBytes,
}) {
  return TranscriptMessage(
    id: id ?? message.id,
    role: role ?? message.role,
    text: text ?? message.text,
    createdAt: createdAt ?? message.createdAt,
    isStreaming: isStreaming ?? message.isStreaming,
    kind: kind ?? message.kind,
    toolCallId: toolCallId ?? message.toolCallId,
    toolName: toolName ?? message.toolName,
    summary: summary ?? message.summary,
    arguments: arguments ?? message.arguments,
    content: content ?? message.content,
    isTruncated: isTruncated ?? message.isTruncated,
    originalBytes: originalBytes ?? message.originalBytes,
  );
}

String _messageKind(TranscriptMessage message) {
  if (message.kind != null) return message.kind!;
  return switch (message.role) {
    'user' => 'userText',
    'assistant' => 'assistantText',
    'toolResult' => 'toolResult',
    'system' => 'system',
    _ => message.role,
  };
}

String _assistantBlockItemId({
  required String messageId,
  required String blockKind,
  required int contentIndex,
  String? fallbackId,
}) {
  final base =
      messageId.isNotEmpty ? messageId : fallbackId ?? 'streaming-assistant';
  return '$base-$blockKind-$contentIndex';
}

String? _summarizeToolArguments(String toolName, Object? arguments) {
  if (arguments is! Map) return null;
  final key = toolName.toLowerCase() == 'bash' ? 'command' : 'path';
  final value = arguments[key];
  return value is String ? value : null;
}

String _extractTextContent(List<Object?> content) {
  return content
      .whereType<Map<String, Object?>>()
      .where((block) => block['type'] == 'text' && block['text'] is String)
      .map((block) => block['text'] as String)
      .join();
}

bool _bool(Object? value) => value is bool && value;

int? _intOrNull(Object? value) => value is int ? value : null;
