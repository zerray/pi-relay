import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/application/sessions/daemon_session_snapshot_service.dart';
import 'package:pi_relay/application/sessions/session_snapshot_service.dart';
import 'package:pi_relay/domain/sessions/remote_session.dart';
import 'package:pi_relay/domain/sessions/session_snapshot.dart';
import 'package:pi_relay/domain/transcript/transcript_message.dart';
import 'package:pi_relay/domain/transcript/transcript_page.dart';
import 'package:pi_relay/infrastructure/remote_client/daemon_client.dart';

void main() {
  test('fetches session snapshot through daemon client', () async {
    final client = _FakeDaemonClient(snapshot: _snapshot());
    final service = DaemonSessionSnapshotService(client: client);

    final snapshot = await service.fetchSnapshot(
      baseUrl: Uri.parse('https://daemon.example'),
      token: 'token_1',
      sessionId: 'sess_1',
      messageLimit: 50,
    );

    expect(client.fetchedBaseUrl.toString(), 'https://daemon.example');
    expect(client.fetchedToken, 'token_1');
    expect(client.fetchedSessionId, 'sess_1');
    expect(client.fetchedMessageLimit, 50);
    expect(snapshot.messages.single.text, 'Explain this project');
  });

  test('fetches older messages through daemon client', () async {
    final client = _FakeDaemonClient(olderMessages: _olderPage());
    final service = DaemonSessionSnapshotService(client: client);

    final page = await service.fetchOlderMessages(
      baseUrl: Uri.parse('https://daemon.example'),
      token: 'token_1',
      sessionId: 'sess_1',
      before: 'cursor_1',
      limit: 50,
    );

    expect(client.fetchedOlderBaseUrl.toString(), 'https://daemon.example');
    expect(client.fetchedOlderToken, 'token_1');
    expect(client.fetchedOlderSessionId, 'sess_1');
    expect(client.fetchedBefore, 'cursor_1');
    expect(client.fetchedLimit, 50);
    expect(page.messages.single.text, 'Older prompt text');
  });

  test('turns daemon failures into session snapshot failures', () async {
    final service = DaemonSessionSnapshotService(
      client: _FakeDaemonClient(
          error: const DaemonClientException('snapshot fetch failed')),
    );

    await expectLater(
      service.fetchSnapshot(
        baseUrl: Uri.parse('https://daemon.example'),
        token: 'token_1',
        sessionId: 'sess_1',
        messageLimit: 50,
      ),
      throwsA(isA<SessionSnapshotFailure>()),
    );
  });
}

SessionSnapshot _snapshot() {
  return SessionSnapshot(
    session: RemoteSession(
      id: 'sess_1',
      piSessionId: 'pi_sess_1',
      projectId: 'proj_1',
      name: 'Refactor auth module',
      path: '/repo/session.jsonl',
      updatedAt: DateTime.utc(2026, 5, 9, 9, 47),
      messageCount: 42,
      isActive: true,
    ),
    messages: [
      TranscriptMessage(
        id: 'msg_1',
        role: 'user',
        text: 'Explain this project',
        createdAt: DateTime.utc(2026, 5, 9, 9, 46),
        isStreaming: false,
      ),
    ],
    olderMessagesCursor: null,
    hasOlderMessages: false,
    isStreaming: false,
  );
}

TranscriptPage _olderPage() {
  return TranscriptPage(
    messages: [
      TranscriptMessage(
        id: 'msg_older',
        role: 'user',
        text: 'Older prompt text',
        createdAt: DateTime.utc(2026, 5, 9, 9, 30),
        isStreaming: false,
      ),
    ],
    olderMessagesCursor: null,
    hasOlderMessages: false,
  );
}

class _FakeDaemonClient extends DaemonClient {
  _FakeDaemonClient({this.snapshot, this.olderMessages, this.error});

  final SessionSnapshot? snapshot;
  final TranscriptPage? olderMessages;
  final Object? error;

  Uri? fetchedBaseUrl;
  String? fetchedToken;
  String? fetchedSessionId;
  int? fetchedMessageLimit;
  Uri? fetchedOlderBaseUrl;
  String? fetchedOlderToken;
  String? fetchedOlderSessionId;
  String? fetchedBefore;
  int? fetchedLimit;

  @override
  @override
  Future<TranscriptPage> fetchOlderMessages({
    required Uri baseUrl,
    required String token,
    required String sessionId,
    required String before,
    required int limit,
  }) async {
    fetchedOlderBaseUrl = baseUrl;
    fetchedOlderToken = token;
    fetchedOlderSessionId = sessionId;
    fetchedBefore = before;
    fetchedLimit = limit;
    final error = this.error;
    if (error != null) throw error;
    return olderMessages!;
  }

  @override
  Future<SessionSnapshot> fetchSessionSnapshot({
    required Uri baseUrl,
    required String token,
    required String sessionId,
    required int messageLimit,
  }) async {
    fetchedBaseUrl = baseUrl;
    fetchedToken = token;
    fetchedSessionId = sessionId;
    fetchedMessageLimit = messageLimit;
    final error = this.error;
    if (error != null) throw error;
    return snapshot!;
  }
}
