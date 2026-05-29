import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/domain/sessions/remote_session.dart';

void main() {
  test('decodes daemon session JSON', () {
    final session = RemoteSession.fromJson({
      'id': 'sess_1',
      'piSessionId': 'pi_sess_1',
      'projectId': 'proj_1',
      'name': 'Refactor auth module',
      'path': '/Users/zerray/.pi/agent/sessions/sess.jsonl',
      'updatedAt': '2026-05-09T09:47:00.000Z',
      'messageCount': 42,
      'isActive': true,
    });

    expect(session.id, 'sess_1');
    expect(session.piSessionId, 'pi_sess_1');
    expect(session.projectId, 'proj_1');
    expect(session.name, 'Refactor auth module');
    expect(session.path, '/Users/zerray/.pi/agent/sessions/sess.jsonl');
    expect(session.updatedAt.toUtc().toIso8601String(),
        '2026-05-09T09:47:00.000Z');
    expect(session.messageCount, 42);
    expect(session.isActive, isTrue);
  });

  test('uses session id as display name when daemon omits name', () {
    final session = RemoteSession.fromJson({
      'id': 'sess_1',
      'piSessionId': 'pi_sess_1',
      'projectId': 'proj_1',
      'path': '/Users/zerray/.pi/agent/sessions/sess.jsonl',
      'updatedAt': '2026-05-09T09:47:00.000Z',
      'messageCount': 42,
      'isActive': true,
    });

    expect(session.name, 'sess_1');
  });

  test('rejects missing required session fields', () {
    expect(
      () => RemoteSession.fromJson({'id': 'sess_1'}),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects invalid session updatedAt', () {
    expect(
      () => RemoteSession.fromJson({
        'id': 'sess_1',
        'piSessionId': 'pi_sess_1',
        'projectId': 'proj_1',
        'path': '/path',
        'updatedAt': 'not a date',
        'messageCount': 42,
        'isActive': true,
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
