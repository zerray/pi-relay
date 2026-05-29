import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/domain/projects/remote_project.dart';
import 'package:pi_relay/domain/sessions/remote_session.dart';
import 'package:pi_relay/presentation/sessions/sessions_page.dart';

void main() {
  const project =
      RemoteProject(id: 'proj_1', name: 'pi-relay', path: '/repo/pi-relay');

  testWidgets('shows loading state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionsPage(
          project: project,
          sessions: const [],
          isLoading: true,
          errorText: null,
          onBack: () {},
          onRefresh: () async {},
          onSessionSelected: (_) {},
        ),
      ),
    );

    expect(find.text('pi-relay'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows session.name prominently for a project', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionsPage(
          project: project,
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
          isLoading: false,
          errorText: null,
          onBack: () {},
          onRefresh: () async {},
          onSessionSelected: (_) {},
        ),
      ),
    );

    expect(find.byKey(const Key('session-name-sess_1')), findsOneWidget);
    expect(find.text('Refactor auth module'), findsOneWidget);
    expect(find.text('42 messages · active'), findsOneWidget);
  });

  testWidgets('selects a session', (tester) async {
    RemoteSession? selectedSession;
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

    await tester.pumpWidget(
      MaterialApp(
        home: SessionsPage(
          project: project,
          sessions: [session],
          isLoading: false,
          errorText: null,
          onBack: () {},
          onRefresh: () async {},
          onSessionSelected: (session) {
            selectedSession = session;
          },
        ),
      ),
    );

    await tester.tap(find.text('Refactor auth module'));

    expect(selectedSession?.id, 'sess_1');
  });

  testWidgets('refreshes the session list', (tester) async {
    var refreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SessionsPage(
          project: project,
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
          isLoading: false,
          errorText: null,
          onBack: () {},
          onRefresh: () async {
            refreshCount += 1;
          },
          onSessionSelected: (_) {},
        ),
      ),
    );

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(refreshCount, 1);
  });

  testWidgets('shows empty and error states', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionsPage(
          project: project,
          sessions: const [],
          isLoading: false,
          errorText: 'session fetch failed',
          onBack: () {},
          onRefresh: () async {},
          onSessionSelected: (_) {},
        ),
      ),
    );

    expect(find.text('session fetch failed'), findsOneWidget);
  });
}
