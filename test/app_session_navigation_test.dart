import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/app/pi_relay_app.dart';
import 'package:pi_relay/application/pairing/pairing_service.dart';
import 'package:pi_relay/application/sessions/session_list_service.dart';
import 'package:pi_relay/domain/projects/remote_project.dart';
import 'package:pi_relay/domain/sessions/remote_session.dart';

void main() {
  testWidgets('opens a project and displays its sessions', (tester) async {
    final sessionsCompleter = Completer<List<RemoteSession>>();
    final sessionListService = _FakeSessionListService(
      sessionsCompleter: sessionsCompleter,
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

    await tester.pumpWidget(
      PiRelayApp(
        pairingService: _FakePairingService(),
        sessionListService: sessionListService,
        platform: TargetPlatform.macOS,
      ),
    );
    await _pair(tester);

    await tester.tap(find.text('pi-relay'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
        sessionListService.fetchedBaseUrl.toString(), 'https://daemon.example');
    expect(sessionListService.fetchedToken, 'token_1');
    expect(sessionListService.fetchedProjectId, 'proj_1');

    sessionsCompleter.complete(sessionListService.sessions);
    await tester.pumpAndSettle();

    expect(find.text('Refactor auth module'), findsOneWidget);
    expect(find.text('42 messages · active'), findsOneWidget);
  });

  testWidgets('shows session load failures and can return to projects',
      (tester) async {
    await tester.pumpWidget(
      PiRelayApp(
        pairingService: _FakePairingService(),
        sessionListService: _FakeSessionListService(
            error: const SessionListFailure('session fetch failed')),
        platform: TargetPlatform.macOS,
      ),
    );
    await _pair(tester);

    await tester.tap(find.text('pi-relay'));
    await tester.pumpAndSettle();

    expect(find.text('session fetch failed'), findsOneWidget);

    await tester.tap(find.byTooltip('返回项目'));
    await tester.pumpAndSettle();

    expect(find.text('pi-relay'), findsOneWidget);
    expect(find.text('/repo/pi-relay'), findsOneWidget);
  });
}

Future<void> _pair(WidgetTester tester) async {
  await tester.tap(find.text('输入配对字符串'));
  await tester.pumpAndSettle();
  await tester.enterText(
      find.byKey(const Key('pairing-payload-field')), 'abc123');
  await tester.tap(find.text('配对'));
  await tester.pumpAndSettle();
}

class _FakePairingService implements PairingService {
  @override
  Future<PairingResult> pair(String pairingPayload) async {
    return PairingResult(
      daemonName: 'macbook-pro',
      baseUrl: Uri.parse('https://daemon.example'),
      token: 'token_1',
      projects: const [
        RemoteProject(id: 'proj_1', name: 'pi-relay', path: '/repo/pi-relay')
      ],
    );
  }
}

class _FakeSessionListService implements SessionListService {
  _FakeSessionListService({
    this.sessions = const [],
    this.error,
    this.sessionsCompleter,
  });

  final List<RemoteSession> sessions;
  final Object? error;
  final Completer<List<RemoteSession>>? sessionsCompleter;

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
    final sessionsCompleter = this.sessionsCompleter;
    if (sessionsCompleter != null) return sessionsCompleter.future;
    return sessions;
  }
}
