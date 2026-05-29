import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/domain/transcript/transcript_message.dart';

void main() {
  test('decodes daemon transcript message JSON', () {
    final message = TranscriptMessage.fromJson({
      'id': 'msg_1',
      'role': 'assistant',
      'text': 'Recent answer text',
      'createdAt': '2026-05-09T09:47:00.000Z',
      'isStreaming': false,
      'content': [
        {'type': 'text', 'text': 'Recent answer text'},
      ],
    });

    expect(message.id, 'msg_1');
    expect(message.role, 'assistant');
    expect(message.text, 'Recent answer text');
    expect(message.createdAt, DateTime.utc(2026, 5, 9, 9, 47));
    expect(message.isStreaming, isFalse);
  });

  test('infers role for kind-only normalized transcript items', () {
    final message = TranscriptMessage.fromJson({
      'id': 'think_1',
      'kind': 'thinking',
      'text': 'Need inspect files',
      'createdAt': '2026-05-09T09:47:00.000Z',
      'isStreaming': false,
    });

    expect(message.role, 'assistant');
    expect(message.kind, 'thinking');
  });

  test('decodes normalized transcript item fields', () {
    final message = TranscriptMessage.fromJson({
      'id': 'call_1',
      'role': 'assistant',
      'kind': 'toolCall',
      'text': 'read',
      'createdAt': '2026-05-09T09:47:00.000Z',
      'isStreaming': false,
      'toolCallId': 'read_1',
      'toolName': 'read',
      'summary': 'Sources/App.swift',
      'arguments': {'path': 'Sources/App.swift'},
      'isTruncated': true,
      'originalBytes': 1024,
    });

    expect(message.kind, 'toolCall');
    expect(message.toolCallId, 'read_1');
    expect(message.toolName, 'read');
    expect(message.summary, 'Sources/App.swift');
    expect(message.arguments, {'path': 'Sources/App.swift'});
    expect(message.isTruncated, isTrue);
    expect(message.originalBytes, 1024);
  });

  test('decodes daemon preview truncation fields', () {
    final message = TranscriptMessage.fromJson({
      'id': 'msg_1',
      'role': 'toolResult',
      'text': 'preview',
      'textTruncated': true,
      'textOriginalBytes': 20480,
      'createdAt': '2026-05-09T09:47:00.000Z',
      'isStreaming': false,
      'content': const [],
    });

    expect(message.isTruncated, isTrue);
    expect(message.originalBytes, 20480);
  });

  test('falls back to text content blocks when text is absent', () {
    final message = TranscriptMessage.fromJson({
      'id': 'msg_2',
      'role': 'user',
      'createdAt': '2026-05-09T09:48:00.000Z',
      'isStreaming': false,
      'content': [
        {'type': 'text', 'text': 'Hello'},
        {'type': 'thinking', 'thinking': 'hidden'},
        {'type': 'text', 'text': 'world'},
      ],
    });

    expect(message.text, 'Hello\nworld');
  });
}
