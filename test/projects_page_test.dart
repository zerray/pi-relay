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
        home: _projectsPage(
          projects: const [
            RemoteProject(
                id: 'proj_1', name: 'pi-relay', path: '/repo/pi-relay')
          ],
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
        home: _projectsPage(
          daemonBaseUrl: Uri.parse('https://myboat.hartley-sunfish.ts.net'),
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
        home: _projectsPage(
          daemonBaseUrl: Uri.parse('https://myboat.hartley-sunfish.ts.net'),
          onUnpair: () async {
            unpaired = true;
          },
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

  testWidgets('uses pairing string input instead of QR scanner on desktop',
      (tester) async {
    String? submittedPayload;

    await tester.pumpWidget(
      MaterialApp(
        home: _projectsPage(
          onPairingPayloadSubmitted: (payload) async {
            submittedPayload = payload;
          },
        ),
      ),
    );

    expect(find.byIcon(Icons.qr_code_scanner), findsNothing);

    await tester.tap(find.text('输入配对字符串'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pairing-payload-field')),
      '  abc123  ',
    );
    await tester.tap(find.text('配对'));
    await tester.pumpAndSettle();

    expect(submittedPayload, 'abc123');
  });

  testWidgets('can refresh the empty project list', (tester) async {
    var refreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: _projectsPage(
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

ProjectsPage _projectsPage({
  Uri? daemonBaseUrl,
  List<RemoteProject> projects = const [],
  ValueChanged<RemoteProject>? onProjectSelected,
  Future<void> Function()? onUnpair,
  Future<void> Function(String payload)? onPairingPayloadSubmitted,
  Future<void> Function()? onRefresh,
}) {
  return ProjectsPage(
    daemonName: 'macbook-pro',
    daemonBaseUrl:
        daemonBaseUrl ?? Uri.parse('https://macbook.tailnet.ts.net:17373'),
    projects: projects,
    onProjectSelected: onProjectSelected ?? (_) {},
    onUnpair: onUnpair ?? () async {},
    onPairingPayloadSubmitted: onPairingPayloadSubmitted ?? (_) async {},
    onRefresh: onRefresh ?? () async {},
  );
}
