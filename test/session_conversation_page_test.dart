import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/domain/sessions/remote_session.dart';
import 'package:pi_relay/domain/transcript/transcript_message.dart';
import 'package:pi_relay/presentation/sessions/session_conversation_page.dart';

void main() {
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

  testWidgets('shows loading state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionConversationPage(
          session: session,
          messages: const [],
          isLoading: true,
          errorText: null,
          onBack: () {},
        ),
      ),
    );

    expect(find.text('Refactor auth module'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows transcript messages', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionConversationPage(
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
          isLoading: false,
          errorText: null,
          onBack: () {},
        ),
      ),
    );

    expect(find.text('user'), findsOneWidget);
    expect(find.text('Explain this project'), findsOneWidget);
    expect(find.text('assistant'), findsOneWidget);
    expect(find.text('It is a Flutter client.'), findsOneWidget);
  });

  testWidgets('shows snapshot error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionConversationPage(
          session: session,
          messages: const [],
          isLoading: false,
          errorText: 'snapshot fetch failed',
          onBack: () {},
        ),
      ),
    );

    expect(find.text('snapshot fetch failed'), findsOneWidget);
  });
}
