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
