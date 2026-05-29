import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/domain/projects/remote_project.dart';
import 'package:pi_relay/presentation/projects/projects_page.dart';

void main() {
  testWidgets('renders session-visible project names and refreshes',
      (tester) async {
    var refreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ProjectsPage(
          daemonName: 'macbook-pro',
          daemonBaseUrl: Uri.parse('https://macbook.tailnet.ts.net:17373'),
          projects: const [
            RemoteProject(
                id: 'proj_1', name: 'pi-relay', path: '/repo/pi-relay')
          ],
          onProjectSelected: (_) {},
          onUnpair: () async {},
          onRefresh: () async {
            refreshCount += 1;
          },
        ),
      ),
    );

    expect(find.text('pi-relay'), findsOneWidget);

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(refreshCount, 1);
  });

  testWidgets('renders paired daemon host as selected remote chip',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProjectsPage(
          daemonName: 'macbook-pro',
          daemonBaseUrl: Uri.parse('https://myboat.hartley-sunfish.ts.net'),
          projects: const [],
          onProjectSelected: (_) {},
          onUnpair: () async {},
          onRefresh: () async {},
        ),
      ),
    );

    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('REMOTES'), findsOneWidget);
    expect(find.text('myboat.hartley-sunfish.ts.net'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('shows unpair action for selected daemon chip', (tester) async {
    var unpaired = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ProjectsPage(
          daemonName: 'macbook-pro',
          daemonBaseUrl: Uri.parse('https://myboat.hartley-sunfish.ts.net'),
          projects: const [],
          onProjectSelected: (_) {},
          onUnpair: () async {
            unpaired = true;
          },
          onRefresh: () async {},
        ),
      ),
    );

    await tester.tap(find.text('myboat.hartley-sunfish.ts.net'));
    await tester.pumpAndSettle();

    expect(find.text('Unpair'), findsOneWidget);

    await tester.tap(find.text('Unpair'));
    await tester.pumpAndSettle();

    expect(unpaired, isTrue);
  });

  testWidgets('can refresh the empty project list', (tester) async {
    var refreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ProjectsPage(
          daemonName: 'macbook-pro',
          daemonBaseUrl: Uri.parse('https://macbook.tailnet.ts.net:17373'),
          projects: const [],
          onProjectSelected: (_) {},
          onUnpair: () async {},
          onRefresh: () async {
            refreshCount += 1;
          },
        ),
      ),
    );

    expect(find.text('暂无项目'), findsOneWidget);

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(refreshCount, 1);
  });
}
