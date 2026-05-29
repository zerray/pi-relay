import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/domain/sessions/session_stream_event.dart';
import 'package:pi_relay/domain/sessions/session_stream_reducer.dart';
import 'package:pi_relay/domain/transcript/transcript_message.dart';

void main() {
  test('ignores stale streaming assistant fragments after a finalized answer',
      () {
    final reducer = const SessionStreamReducer();
    final now = DateTime.utc(2026, 5, 29, 7, 38);
    final model = SessionStreamModel(
      messages: [
        TranscriptMessage(
          id: 'msg_user',
          role: 'user',
          kind: 'userText',
          text: 'hello from macos',
          createdAt: now,
          isStreaming: false,
        ),
        TranscriptMessage(
          id: 'msg_answer',
          role: 'assistant',
          kind: 'assistantText',
          text: '收到：`hello from macos`',
          createdAt: now.add(const Duration(seconds: 1)),
          isStreaming: false,
        ),
      ],
    );

    final reduced = reducer.reduce(
      model,
      const TranscriptMessagePatchEvent(
        messageId: 'stale_tmp',
        contentIndex: 0,
        patch: TextDeltaPatch('hello'),
      ),
      now: now.add(const Duration(seconds: 2)),
    );

    expect(reduced.messages.map((message) => message.text), [
      'hello from macos',
      '收到：`hello from macos`',
    ]);
  });

  test('applies text deltas and reconciles the final transcript message', () {
    final reducer = const SessionStreamReducer();
    var model = const SessionStreamModel();
    final now = DateTime.utc(2026, 5, 9, 9, 47);

    model = reducer.reduce(
      model,
      const TranscriptMessagePatchEvent(
        messageId: 'msg_assistant',
        contentIndex: 0,
        patch: TextDeltaPatch('Hel'),
      ),
      now: now,
    );
    model = reducer.reduce(
      model,
      const TranscriptMessagePatchEvent(
        messageId: 'msg_assistant',
        contentIndex: 0,
        patch: TextDeltaPatch('lo'),
      ),
      now: now.add(const Duration(milliseconds: 1)),
    );

    expect(model.messages, hasLength(1));
    expect(model.messages.single.id, 'msg_assistant-text-0');
    expect(model.messages.single.text, 'Hello');
    expect(model.messages.single.isStreaming, isTrue);

    model = reducer.reduce(
      model,
      TranscriptMessageEndEvent(
        TranscriptMessage(
          id: 'msg_assistant',
          role: 'assistant',
          text: 'Hello from Pi',
          content: const [
            {'type': 'text', 'text': 'Hello from Pi'},
          ],
          createdAt: now.add(const Duration(seconds: 1)),
          isStreaming: false,
        ),
      ),
      now: now.add(const Duration(seconds: 1)),
    );

    expect(model.messages, hasLength(1));
    expect(model.messages.single.id, 'msg_assistant');
    expect(model.messages.single.text, 'Hello from Pi');
    expect(model.messages.single.isStreaming, isFalse);
  });
}
