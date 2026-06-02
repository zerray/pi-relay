import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/domain/sessions/remote_session.dart';
import 'package:pi_relay/domain/sessions/runtime_status.dart';
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

    expect(find.text('user'), findsNothing);
    expect(find.text('Explain this project'), findsOneWidget);
    expect(find.text('assistant'), findsNothing);
    expect(find.text('It is a Flutter client.'), findsOneWidget);
    expect(find.text('Talk to Pi'), findsOneWidget);
  });

  testWidgets('shows runtime context subtitle and detail sheet',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionConversationPage(
          session: session,
          messages: const [],
          isLoading: false,
          errorText: null,
          runtimeStatus: runtimeStatus(),
          onBack: () {},
        ),
      ),
    );

    expect(find.text('32.5%/200k'), findsOneWidget);

    await tester.tap(find.text('32.5%/200k'));
    await tester.pumpAndSettle();

    expect(find.text('Runtime status'), findsOneWidget);
    expect(find.textContaining('Model: Claude Sonnet 4.5'), findsOneWidget);
    expect(find.textContaining('Cost: \$0.1335'), findsOneWidget);
  });

  testWidgets('renders assistant markdown code blocks in chat style',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionConversationPage(
          session: session,
          messages: [
            TranscriptMessage(
              id: 'msg_1',
              role: 'assistant',
              text: 'Run this:\n```bash\nflutter test\n```',
              createdAt: DateTime.utc(2026, 5, 9, 9, 46),
              isStreaming: false,
            ),
          ],
          isLoading: false,
          errorText: null,
          onBack: () {},
        ),
      ),
    );

    expect(find.text('Run this:'), findsOneWidget);
    expect(find.text('flutter test'), findsOneWidget);
    expect(find.byKey(const Key('markdown-code-block-0')), findsOneWidget);
  });

  testWidgets('normalizes assistant content blocks before grouping activity',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionConversationPage(
          session: session,
          messages: [
            TranscriptMessage(
              id: 'assistant_1',
              role: 'assistant',
              text: '',
              createdAt: DateTime.utc(2026, 5, 9, 9, 46),
              isStreaming: false,
              content: [
                {'type': 'thinking', 'thinking': 'Need inspect files'},
                {
                  'type': 'toolCall',
                  'id': 'read_1',
                  'name': 'read',
                  'arguments': {'path': 'Sources/App.swift'},
                },
              ],
            ),
            TranscriptMessage(
              id: 'result_1',
              role: 'toolResult',
              text: 'let app = App()',
              createdAt: DateTime.utc(2026, 5, 9, 9, 47),
              isStreaming: false,
              toolCallId: 'read_1',
            ),
            TranscriptMessage(
              id: 'assistant_2',
              role: 'assistant',
              text: 'Done',
              createdAt: DateTime.utc(2026, 5, 9, 9, 48),
              isStreaming: false,
            ),
          ],
          isLoading: false,
          errorText: null,
          onBack: () {},
        ),
      ),
    );

    expect(find.text('Ran 1 tool'), findsOneWidget);
    expect(find.text('Tool result'), findsNothing);
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.text('Ran 1 tool'));
    await tester.pumpAndSettle();
    expect(find.text('Thinking'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
  });

  testWidgets('groups activity messages and opens tool details',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionConversationPage(
          session: session,
          messages: [
            TranscriptMessage(
              id: 'think_1',
              role: 'assistant',
              kind: 'thinking',
              text: 'Need inspect files',
              createdAt: DateTime.utc(2026, 5, 9, 9, 46),
              isStreaming: false,
            ),
            TranscriptMessage(
              id: 'call_1',
              role: 'assistant',
              kind: 'toolCall',
              text: 'read',
              createdAt: DateTime.utc(2026, 5, 9, 9, 47),
              isStreaming: false,
              toolCallId: 'read_1',
              arguments: {'path': 'Sources/App.swift'},
            ),
            TranscriptMessage(
              id: 'result_1',
              role: 'toolResult',
              kind: 'toolResult',
              text: 'let app = App()',
              createdAt: DateTime.utc(2026, 5, 9, 9, 48),
              isStreaming: false,
              toolCallId: 'read_1',
            ),
          ],
          isLoading: false,
          errorText: null,
          onBack: () {},
        ),
      ),
    );

    expect(find.text('Ran 1 tool'), findsOneWidget);
    await tester.tap(find.text('Ran 1 tool'));
    await tester.pumpAndSettle();

    expect(find.text('Thinking'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    await tester.tap(find.text('Read'));
    await tester.pumpAndSettle();

    expect(find.text('Path'), findsOneWidget);
    expect(find.text('Sources/App.swift'), findsOneWidget);
    expect(find.text('Result'), findsOneWidget);
    expect(find.text('let app = App()'), findsOneWidget);
  });

  testWidgets('starts at the newest variable-height message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionConversationPage(
          session: session,
          messages: _variableHeightMessages(),
          isLoading: false,
          errorText: null,
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
        find.textContaining('Newest variable-height message'), findsOneWidget);
  });

  testWidgets('starts at the newest message and can jump back to bottom',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionConversationPage(
          session: session,
          messages: _manyMessages(),
          isLoading: false,
          errorText: null,
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final listView = tester.widget<ListView>(find.byType(ListView));
    final controller = listView.controller!;
    expect(controller.offset, controller.position.maxScrollExtent);
    expect(find.byTooltip('跳到最新消息'), findsNothing);

    controller.jumpTo(0);
    await tester.pumpAndSettle();

    expect(find.byTooltip('跳到最新消息'), findsOneWidget);

    await tester.tap(find.byTooltip('跳到最新消息'));
    await tester.pumpAndSettle();

    expect(controller.offset, controller.position.maxScrollExtent);
  });

  testWidgets('submits trimmed prompt and clears composer', (tester) async {
    String? submittedPrompt;

    await tester.pumpWidget(
      MaterialApp(
        home: SessionConversationPage(
          session: session,
          messages: _manyMessages(),
          isLoading: false,
          errorText: null,
          onPromptSubmitted: (text) async {
            submittedPrompt = text;
          },
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('session-prompt-field')),
      '  hello pi  ',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('发送消息'));
    await tester.pumpAndSettle();

    expect(submittedPrompt, 'hello pi');
    expect(find.text('hello pi'), findsNothing);
  });

  testWidgets('ignores blank prompt submissions', (tester) async {
    var submitCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SessionConversationPage(
          session: session,
          messages: _manyMessages(),
          isLoading: false,
          errorText: null,
          onPromptSubmitted: (_) async {
            submitCount += 1;
          },
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('session-prompt-field')),
      '   \n  ',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('发送消息'));
    await tester.pumpAndSettle();

    expect(submitCount, 0);
  });

  testWidgets('pulls down to load older messages', (tester) async {
    var loadOlderCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SessionConversationPage(
          session: session,
          messages: _manyMessages(),
          isLoading: false,
          errorText: null,
          hasOlderMessages: true,
          onLoadOlder: () async {
            loadOlderCount += 1;
          },
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final listView = tester.widget<ListView>(find.byType(ListView));
    listView.controller!.jumpTo(0);
    await tester.pump();
    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(loadOlderCount, 1);
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

RuntimeStatus runtimeStatus() {
  return RuntimeStatus(
    model: const RuntimeModelStatus(
      provider: 'anthropic',
      id: 'claude-sonnet-4-5',
      name: 'Claude Sonnet 4.5',
      contextWindow: 200000,
    ),
    thinkingLevel: 'medium',
    usage: const RuntimeUsageStatus(
      input: 12000,
      output: 3000,
      cacheRead: 50000,
      cacheWrite: 10000,
      cost: RuntimeCostStatus(
        input: 0.036,
        output: 0.045,
        cacheRead: 0.015,
        cacheWrite: 0.0375,
        total: 0.1335,
      ),
    ),
    context: const RuntimeContextStatus(
      tokens: 65000,
      contextWindow: 200000,
      percent: 32.5,
    ),
    updatedAt: DateTime.utc(2026, 5, 9, 9, 47),
  );
}

List<TranscriptMessage> _variableHeightMessages() {
  return List.generate(
    80,
    (index) => TranscriptMessage(
      id: 'variable_msg_$index',
      role: index.isEven ? 'user' : 'assistant',
      text: index == 79
          ? 'Newest variable-height message'
          : 'Message $index ${'with extra text ' * (index % 9)}',
      createdAt: DateTime.utc(2026, 5, 9, 9).add(Duration(minutes: index)),
      isStreaming: false,
    ),
  );
}

List<TranscriptMessage> _manyMessages() {
  return List.generate(
    30,
    (index) => TranscriptMessage(
      id: 'msg_$index',
      role: index.isEven ? 'user' : 'assistant',
      text: 'Message $index',
      createdAt: DateTime.utc(2026, 5, 9, 9, index),
      isStreaming: false,
    ),
  );
}
