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
        ),
      ),
    );

    expect(find.text('pi-relay'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows sessions for a project', (tester) async {
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
        ),
      ),
    );

    expect(find.text('Refactor auth module'), findsOneWidget);
    expect(find.text('42 messages · active'), findsOneWidget);
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
        ),
      ),
    );

    expect(find.text('session fetch failed'), findsOneWidget);
  });
}
