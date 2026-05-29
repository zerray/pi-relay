import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/application/sessions/daemon_session_list_service.dart';
import 'package:pi_relay/application/sessions/session_list_service.dart';
import 'package:pi_relay/domain/sessions/remote_session.dart';
import 'package:pi_relay/infrastructure/remote_client/daemon_client.dart';

void main() {
  test('fetches project sessions through daemon client', () async {
    final client = _FakeDaemonClient(
      sessions: [
        RemoteSession(
          id: 'sess_1',
          piSessionId: 'pi_sess_1',
          projectId: 'proj_1',
          name: 'Refactor auth module',
          path: '/repo/session.jsonl',
          updatedAt: DateTime.utc(2026, 5, 9, 9, 47),
          messageCount: 42,
          isActive: true,
        ),
      ],
    );
    final service = DaemonSessionListService(client: client);

    final sessions = await service.fetchSessions(
      baseUrl: Uri.parse('https://daemon.example'),
      token: 'token_1',
      projectId: 'proj_1',
    );

    expect(client.fetchedBaseUrl.toString(), 'https://daemon.example');
    expect(client.fetchedToken, 'token_1');
    expect(client.fetchedProjectId, 'proj_1');
    expect(sessions.single.id, 'sess_1');
  });

  test('turns daemon failures into session list failures', () async {
    final service = DaemonSessionListService(
      client: _FakeDaemonClient(
          error: const DaemonClientException('session fetch failed')),
    );

    await expectLater(
      service.fetchSessions(
        baseUrl: Uri.parse('https://daemon.example'),
        token: 'token_1',
        projectId: 'proj_1',
      ),
      throwsA(isA<SessionListFailure>()),
    );
  });
}

class _FakeDaemonClient extends DaemonClient {
  _FakeDaemonClient({this.sessions = const [], this.error});

  final List<RemoteSession> sessions;
  final Object? error;

  Uri? fetchedBaseUrl;
  String? fetchedToken;
  String? fetchedProjectId;

  @override
  Future<List<RemoteSession>> fetchSessions({
    required Uri baseUrl,
    required String token,
    required String projectId,
  }) async {
    fetchedBaseUrl = baseUrl;
    fetchedToken = token;
    fetchedProjectId = projectId;
    final error = this.error;
    if (error != null) throw error;
    return sessions;
  }
}
