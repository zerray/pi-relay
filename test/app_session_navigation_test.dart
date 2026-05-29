import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/app/pi_relay_app.dart';
import 'package:pi_relay/application/pairing/pairing_service.dart';
import 'package:pi_relay/application/pairing/pairing_store.dart';
import 'package:pi_relay/application/projects/project_list_service.dart';
import 'package:pi_relay/application/sessions/session_list_service.dart';
import 'package:pi_relay/application/sessions/session_snapshot_service.dart';
import 'package:pi_relay/domain/projects/remote_project.dart';
import 'package:pi_relay/domain/sessions/remote_session.dart';
import 'package:pi_relay/domain/sessions/session_snapshot.dart';
import 'package:pi_relay/domain/transcript/transcript_message.dart';
import 'package:pi_relay/domain/transcript/transcript_page.dart';

void main() {
  testWidgets('restores saved pairing and opens the project list',
      (tester) async {
    final projectListService = _FakeProjectListService(
      projects: const [
        RemoteProject(id: 'proj_1', name: 'pi-relay', path: '/repo/pi-relay'),
      ],
    );

    await tester.pumpWidget(
      PiRelayApp(
        pairingService: _FailingPairingService(),
        projectListService: projectListService,
        pairingStore: _FakePairingStore(
          savedPairing: SavedPairing(
            daemonName: 'macbook-pro',
            baseUrl: Uri.parse('https://daemon.example'),
            token: 'token_1',
          ),
        ),
        platform: TargetPlatform.macOS,
      ),
    );
    await tester.pumpAndSettle();

    expect(
        projectListService.fetchedBaseUrl.toString(), 'https://daemon.example');
    expect(projectListService.fetchedToken, 'token_1');
    expect(find.text('pi-relay'), findsOneWidget);
    expect(find.text('输入配对字符串'), findsNothing);
  });

  testWidgets('saves pairing credentials after successful pairing',
      (tester) async {
    final pairingStore = _FakePairingStore();

    await tester.pumpWidget(
      PiRelayApp(
        pairingService: _FakePairingService(),
        sessionListService: _FakeSessionListService(),
        pairingStore: pairingStore,
        platform: TargetPlatform.macOS,
      ),
    );
    await tester.pumpAndSettle();
    await _pair(tester);

    expect(pairingStore.savedPairing?.daemonName, 'macbook-pro');
    expect(pairingStore.savedPairing?.baseUrl.toString(),
        'https://daemon.example');
    expect(pairingStore.savedPairing?.token, 'token_1');
  });

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
        pairingStore: _FakePairingStore(),
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

  testWidgets('opens a session and displays its transcript snapshot',
      (tester) async {
    final session = RemoteSession(
      id: 'sess_1',
      piSessionId: 'pi_sess_1',
      projectId: 'proj_1',
      name: 'Refactor auth module',
      path: '/repo/session.jsonl',
      updatedAt: DateTime.utc(2026, 5, 9, 9, 47),
      messageCount: 42,
      isActive: true,
    );
    final snapshotService = _FakeSessionSnapshotService(
      snapshot: SessionSnapshot(
        session: session,
        messages: [
          TranscriptMessage(
            id: 'msg_1',
            role: 'user',
            text: 'Explain this project',
            createdAt: DateTime.utc(2026, 5, 9, 9, 46),
            isStreaming: false,
          ),
          TranscriptMessage(
            id: 'msg_2',
            role: 'assistant',
            text: 'It is a Flutter client.',
            createdAt: DateTime.utc(2026, 5, 9, 9, 47),
            isStreaming: false,
          ),
        ],
        olderMessagesCursor: null,
        hasOlderMessages: false,
        isStreaming: false,
      ),
    );

    await tester.pumpWidget(
      PiRelayApp(
        pairingService: _FakePairingService(),
        sessionListService: _FakeSessionListService(sessions: [session]),
        sessionSnapshotService: snapshotService,
        pairingStore: _FakePairingStore(),
        platform: TargetPlatform.macOS,
      ),
    );
    await _pair(tester);

    await tester.tap(find.text('pi-relay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refactor auth module'));
    await tester.pumpAndSettle();

    expect(snapshotService.fetchedBaseUrl.toString(), 'https://daemon.example');
    expect(snapshotService.fetchedToken, 'token_1');
    expect(snapshotService.fetchedSessionId, 'sess_1');
    expect(snapshotService.fetchedMessageLimit, 50);
    expect(find.text('Explain this project'), findsOneWidget);
    expect(find.text('It is a Flutter client.'), findsOneWidget);
  });

  testWidgets('opens a long session transcript at the latest message',
      (tester) async {
    final session = RemoteSession(
      id: 'sess_1',
      piSessionId: 'pi_sess_1',
      projectId: 'proj_1',
      name: 'Refactor auth module',
      path: '/repo/session.jsonl',
      updatedAt: DateTime.utc(2026, 5, 9, 9, 47),
      messageCount: 80,
      isActive: true,
    );
    final snapshotService = _FakeSessionSnapshotService(
      snapshot: SessionSnapshot(
        session: session,
        messages: List.generate(
          80,
          (index) => TranscriptMessage(
            id: 'msg_$index',
            role: index.isEven ? 'user' : 'assistant',
            text: 'Transcript message $index',
            createdAt: DateTime.utc(2026, 5, 9, 9).add(
              Duration(minutes: index),
            ),
            isStreaming: false,
          ),
        ),
        olderMessagesCursor: 'cursor_1',
        hasOlderMessages: true,
        isStreaming: false,
      ),
    );

    await tester.pumpWidget(
      PiRelayApp(
        pairingService: _FakePairingService(),
        sessionListService: _FakeSessionListService(sessions: [session]),
        sessionSnapshotService: snapshotService,
        pairingStore: _FakePairingStore(),
        platform: TargetPlatform.macOS,
      ),
    );
    await _pair(tester);

    await tester.tap(find.text('pi-relay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refactor auth module'));
    await tester.pumpAndSettle();

    expect(find.text('Transcript message 79'), findsOneWidget);
  });

  testWidgets('sends prompt through paired daemon without optimistic append',
      (tester) async {
    final session = RemoteSession(
      id: 'sess_1',
      piSessionId: 'pi_sess_1',
      projectId: 'proj_1',
      name: 'Refactor auth module',
      path: '/repo/session.jsonl',
      updatedAt: DateTime.utc(2026, 5, 9, 9, 47),
      messageCount: 42,
      isActive: true,
    );
    final snapshotService = _FakeSessionSnapshotService(
      snapshot: SessionSnapshot(
        session: session,
        messages: [
          TranscriptMessage(
            id: 'msg_1',
            role: 'assistant',
            text: 'Ready',
            createdAt: DateTime.utc(2026, 5, 9, 9, 46),
            isStreaming: false,
          ),
        ],
        olderMessagesCursor: null,
        hasOlderMessages: false,
        isStreaming: false,
      ),
    );

    await tester.pumpWidget(
      PiRelayApp(
        pairingService: _FakePairingService(),
        sessionListService: _FakeSessionListService(sessions: [session]),
        sessionSnapshotService: snapshotService,
        pairingStore: _FakePairingStore(),
        platform: TargetPlatform.macOS,
      ),
    );
    await _pair(tester);

    await tester.tap(find.text('pi-relay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refactor auth module'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('session-prompt-field')),
      '  hello pi  ',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('发送消息'));
    await tester.pumpAndSettle();

    expect(
        snapshotService.sentPromptBaseUrl.toString(), 'https://daemon.example');
    expect(snapshotService.sentPromptToken, 'token_1');
    expect(snapshotService.sentPromptSessionId, 'sess_1');
    expect(snapshotService.sentPromptText, 'hello pi');
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('hello pi'), findsNothing);
  });

  testWidgets('loads older transcript messages by pulling down',
      (tester) async {
    final session = RemoteSession(
      id: 'sess_1',
      piSessionId: 'pi_sess_1',
      projectId: 'proj_1',
      name: 'Refactor auth module',
      path: '/repo/session.jsonl',
      updatedAt: DateTime.utc(2026, 5, 9, 9, 47),
      messageCount: 42,
      isActive: true,
    );
    final snapshotService = _FakeSessionSnapshotService(
      snapshot: SessionSnapshot(
        session: session,
        messages: List.generate(
          25,
          (index) => TranscriptMessage(
            id: 'msg_$index',
            role: index.isEven ? 'user' : 'assistant',
            text: 'Recent message $index',
            createdAt: DateTime.utc(2026, 5, 9, 9, index),
            isStreaming: false,
          ),
        ),
        olderMessagesCursor: 'cursor_1',
        hasOlderMessages: true,
        isStreaming: false,
      ),
      olderMessages: TranscriptPage(
        messages: [
          TranscriptMessage(
            id: 'msg_older',
            role: 'user',
            text: 'Older prompt text',
            createdAt: DateTime.utc(2026, 5, 9, 8),
            isStreaming: false,
          ),
        ],
        olderMessagesCursor: null,
        hasOlderMessages: false,
      ),
    );

    await tester.pumpWidget(
      PiRelayApp(
        pairingService: _FakePairingService(),
        sessionListService: _FakeSessionListService(sessions: [session]),
        sessionSnapshotService: snapshotService,
        pairingStore: _FakePairingStore(),
        platform: TargetPlatform.macOS,
      ),
    );
    await _pair(tester);

    await tester.tap(find.text('pi-relay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refactor auth module'));
    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsOneWidget);
    final listView = tester.widget<ListView>(find.byType(ListView));
    listView.controller!.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(snapshotService.fetchedBefore, 'cursor_1');
    expect(snapshotService.fetchedOlderSessionId, 'sess_1');
    expect(find.text('Older prompt text'), findsOneWidget);
  });

  testWidgets('refreshes projects from the paired daemon', (tester) async {
    final projectListService = _FakeProjectListService(
      projects: const [
        RemoteProject(
          id: 'proj_2',
          name: 'pi-remote-control',
          path: '/repo/pi-remote-control',
        ),
      ],
    );

    await tester.pumpWidget(
      PiRelayApp(
        pairingService: _FakePairingService(),
        projectListService: projectListService,
        sessionListService: _FakeSessionListService(),
        pairingStore: _FakePairingStore(),
        platform: TargetPlatform.macOS,
      ),
    );
    await _pair(tester);

    await tester.drag(find.text('pi-relay'), const Offset(0, 400));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
        projectListService.fetchedBaseUrl.toString(), 'https://daemon.example');
    expect(projectListService.fetchedToken, 'token_1');
    expect(find.text('pi-remote-control'), findsOneWidget);
  });

  testWidgets('refreshes sessions for the selected project', (tester) async {
    final sessionListService = _FakeSessionListService(
      sessions: [
        RemoteSession(
          id: 'sess_2',
          piSessionId: 'pi_sess_2',
          projectId: 'proj_1',
          name: 'Investigate pairing',
          path: '/repo/session-2.jsonl',
          updatedAt: DateTime.utc(2026, 5, 9, 9, 48),
          messageCount: 7,
          isActive: true,
        ),
      ],
    );

    await tester.pumpWidget(
      PiRelayApp(
        pairingService: _FakePairingService(),
        sessionListService: sessionListService,
        pairingStore: _FakePairingStore(),
        platform: TargetPlatform.macOS,
      ),
    );
    await _pair(tester);

    await tester.tap(find.text('pi-relay'));
    await tester.pumpAndSettle();
    expect(find.text('Investigate pairing'), findsOneWidget);

    sessionListService.sessions = [
      RemoteSession(
        id: 'sess_3',
        piSessionId: 'pi_sess_3',
        projectId: 'proj_1',
        name: 'Review session list',
        path: '/repo/session-3.jsonl',
        updatedAt: DateTime.utc(2026, 5, 9, 9, 49),
        messageCount: 9,
        isActive: true,
      ),
    ];

    await tester.drag(find.text('Investigate pairing'), const Offset(0, 400));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Review session list'), findsOneWidget);
  });

  testWidgets('shows session load failures and can return to projects',
      (tester) async {
    await tester.pumpWidget(
      PiRelayApp(
        pairingService: _FakePairingService(),
        sessionListService: _FakeSessionListService(
            error: const SessionListFailure('session fetch failed')),
        pairingStore: _FakePairingStore(),
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
  await tester.pumpAndSettle();
  await tester.tap(find.text('输入配对字符串'));
  await tester.pumpAndSettle();
  await tester.enterText(
      find.byKey(const Key('pairing-payload-field')), 'abc123');
  await tester.tap(find.text('配对'));
  await tester.pumpAndSettle();
}

class _FailingPairingService implements PairingService {
  @override
  Future<PairingResult> pair(String pairingPayload) async {
    throw StateError('pairing should not be called');
  }
}

class _FakePairingStore implements PairingStore {
  _FakePairingStore({this.savedPairing});

  SavedPairing? savedPairing;
  var cleared = false;

  @override
  Future<SavedPairing?> load() async => savedPairing;

  @override
  Future<void> save(SavedPairing pairing) async {
    savedPairing = pairing;
  }

  @override
  Future<void> clear() async {
    cleared = true;
    savedPairing = null;
  }
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

class _FakeProjectListService implements ProjectListService {
  _FakeProjectListService({this.projects = const []});

  final List<RemoteProject> projects;

  Uri? fetchedBaseUrl;
  String? fetchedToken;

  @override
  Future<List<RemoteProject>> fetchProjects({
    required Uri baseUrl,
    required String token,
  }) async {
    fetchedBaseUrl = baseUrl;
    fetchedToken = token;
    return projects;
  }
}

class _FakeSessionSnapshotService implements SessionSnapshotService {
  _FakeSessionSnapshotService({required this.snapshot, this.olderMessages});

  final SessionSnapshot snapshot;
  final TranscriptPage? olderMessages;

  Uri? fetchedBaseUrl;
  String? fetchedToken;
  String? fetchedSessionId;
  int? fetchedMessageLimit;
  String? fetchedOlderSessionId;
  String? fetchedBefore;
  Uri? sentPromptBaseUrl;
  String? sentPromptToken;
  String? sentPromptSessionId;
  String? sentPromptText;

  @override
  @override
  Future<TranscriptPage> fetchOlderMessages({
    required Uri baseUrl,
    required String token,
    required String sessionId,
    required String before,
    required int limit,
  }) async {
    fetchedOlderSessionId = sessionId;
    fetchedBefore = before;
    return olderMessages!;
  }

  @override
  Future<void> sendPrompt({
    required Uri baseUrl,
    required String token,
    required String sessionId,
    required String text,
  }) async {
    sentPromptBaseUrl = baseUrl;
    sentPromptToken = token;
    sentPromptSessionId = sessionId;
    sentPromptText = text;
  }

  @override
  Future<SessionSnapshot> fetchSnapshot({
    required Uri baseUrl,
    required String token,
    required String sessionId,
    required int messageLimit,
  }) async {
    fetchedBaseUrl = baseUrl;
    fetchedToken = token;
    fetchedSessionId = sessionId;
    fetchedMessageLimit = messageLimit;
    return snapshot;
  }
}

class _FakeSessionListService implements SessionListService {
  _FakeSessionListService({
    this.sessions = const [],
    this.error,
    this.sessionsCompleter,
  });

  List<RemoteSession> sessions;
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
