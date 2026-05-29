import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/domain/sessions/session_snapshot.dart';

void main() {
  test('decodes daemon session snapshot JSON', () {
    final snapshot = SessionSnapshot.fromJson({
      'session': {
        'id': 'sess_1',
        'piSessionId': 'pi_sess_1',
        'projectId': 'proj_1',
        'name': 'Refactor auth module',
        'path': '/repo/session.jsonl',
        'updatedAt': '2026-05-09T09:47:00.000Z',
        'messageCount': 42,
        'isActive': true,
      },
      'messages': [
        {
          'id': 'msg_1',
          'role': 'user',
          'text': 'Explain this project',
          'createdAt': '2026-05-09T09:46:00.000Z',
          'isStreaming': false,
          'content': [],
        },
        {
          'id': 'msg_2',
          'role': 'assistant',
          'text': 'It is a Flutter client.',
          'createdAt': '2026-05-09T09:47:00.000Z',
          'isStreaming': false,
          'content': [],
        },
      ],
      'olderMessagesCursor': 'cursor_1',
      'hasOlderMessages': true,
      'isStreaming': false,
    });

    expect(snapshot.session.id, 'sess_1');
    expect(snapshot.messages.map((message) => message.text), [
      'Explain this project',
      'It is a Flutter client.',
    ]);
    expect(snapshot.olderMessagesCursor, 'cursor_1');
    expect(snapshot.hasOlderMessages, isTrue);
    expect(snapshot.isStreaming, isFalse);
  });
}
