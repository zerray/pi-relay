import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/domain/transcript/transcript_page.dart';

void main() {
  test('decodes daemon transcript page JSON', () {
    final page = TranscriptPage.fromJson({
      'messages': [
        {
          'id': 'msg_older',
          'role': 'user',
          'text': 'Older prompt text',
          'createdAt': '2026-05-09T09:30:00.000Z',
          'isStreaming': false,
          'content': [],
        },
      ],
      'olderMessagesCursor': 'cursor_2',
      'hasOlderMessages': true,
    });

    expect(page.messages.single.text, 'Older prompt text');
    expect(page.olderMessagesCursor, 'cursor_2');
    expect(page.hasOlderMessages, isTrue);
  });
}
