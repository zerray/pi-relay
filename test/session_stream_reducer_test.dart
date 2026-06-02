import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/domain/sessions/session_stream_event.dart';
import 'package:pi_relay/domain/sessions/session_stream_reducer.dart';
import 'package:pi_relay/domain/transcript/transcript_message.dart';

void main() {
  test('decodes runtime status stream events and updates the model', () {
    final reducer = const SessionStreamReducer();
    const eventJson = {
      'type': 'runtime_status',
      'status': {
        'model': {
          'provider': 'anthropic',
          'id': 'claude-sonnet-4-5',
          'contextWindow': 200000,
        },
        'thinkingLevel': 'medium',
        'usage': {
          'input': 12000,
          'output': 3000,
          'cacheRead': 50000,
          'cacheWrite': 10000,
          'cost': {
            'input': 0.036,
            'output': 0.045,
            'cacheRead': 0.015,
            'cacheWrite': 0.0375,
            'total': 0.1335,
          },
        },
        'context': {
          'tokens': 65000,
          'contextWindow': 200000,
          'percent': 32.5,
        },
        'updatedAt': '2026-05-09T09:47:00.000Z',
      },
    };

    final event = SessionStreamEvent.fromJson(eventJson);
    final reduced = reducer.reduce(
      const SessionStreamModel(),
      event,
      now: DateTime.utc(2026, 5, 9, 9, 47),
    );

    expect(reduced.runtimeStatus?.context?.percent, 32.5);
    expect(reduced.runtimeStatus?.context?.contextWindow, 200000);
  });

  test('copies runtime status from session state', () {
    final reducer = const SessionStreamReducer();
    const eventJson = {
      'type': 'session_state',
      'state': {
        'session': {
          'id': 'sess_1',
          'piSessionId': 'pi_sess_1',
          'projectId': 'proj_1',
          'name': 'Runtime session',
          'path': '/repo/session.jsonl',
          'updatedAt': '2026-05-09T09:47:00.000Z',
          'messageCount': 0,
          'isActive': true,
        },
        'messages': [],
        'olderMessagesCursor': null,
        'hasOlderMessages': false,
        'isStreaming': false,
        'runtimeStatus': {
          'model': null,
          'thinkingLevel': null,
          'usage': {
            'input': 1,
            'output': 2,
            'cacheRead': 3,
            'cacheWrite': 4,
            'cost': {
              'input': 0,
              'output': 0,
              'cacheRead': 0,
              'cacheWrite': 0,
              'total': 0,
            },
          },
          'context': {
            'tokens': null,
            'contextWindow': 1000000,
            'percent': null,
          },
          'updatedAt': '2026-05-09T09:47:00.000Z',
        },
      },
    };

    final reduced = reducer.reduce(
      const SessionStreamModel(),
      SessionStreamEvent.fromJson(eventJson),
      now: DateTime.utc(2026, 5, 9, 9, 47),
    );

    expect(reduced.runtimeStatus?.context?.contextWindow, 1000000);
  });

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
