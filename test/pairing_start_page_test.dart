import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/app/pi_relay_app.dart';
import 'package:pi_relay/application/pairing/pairing_service.dart';
import 'package:pi_relay/domain/projects/remote_project.dart';
import 'package:pi_relay/presentation/pairing/pairing_start_page.dart';

void main() {
  testWidgets('shows the launch page title', (tester) async {
    await tester.pumpWidget(PiRelayApp(pairingService: _FakePairingService()));

    expect(find.text('Pi Relay'), findsOneWidget);
    expect(find.text('连接到 Pi Remote Control'), findsOneWidget);
  });

  testWidgets('shows scan pairing button on mobile', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: PairingStartPage(onPairingPayloadSubmitted: (_) async {}),
      ),
    );

    expect(find.text('扫码配对'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('mobile scan button reports scanner is not connected yet',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: PairingStartPage(onPairingPayloadSubmitted: (_) async {}),
      ),
    );

    await tester.tap(find.text('扫码配对'));
    await tester.pumpAndSettle();

    expect(find.text('扫码配对将在接入摄像头后启用'), findsOneWidget);
  });

  testWidgets('shows paste pairing button on desktop', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.macOS),
        home: PairingStartPage(onPairingPayloadSubmitted: (_) async {}),
      ),
    );

    expect(find.text('输入配对字符串'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('desktop pairing submits payload and shows returned projects',
      (tester) async {
    final service = _FakePairingService(
      result: PairingResult(
        daemonName: 'macbook-pro',
        baseUrl: Uri.parse('https://daemon.example'),
        token: 'token_1',
        projects: const [
          RemoteProject(
            id: 'proj_1',
            name: 'pi-relay',
            path: '/Users/zerray/gitclone/pi-relay',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      PiRelayApp(
        pairingService: service,
        platform: TargetPlatform.macOS,
      ),
    );

    await tester.tap(find.text('输入配对字符串'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('pairing-payload-field')), 'abc123');
    await tester.tap(find.text('配对'));
    await tester.pumpAndSettle();

    expect(service.submittedPayload, 'abc123');
    expect(find.text('macbook-pro'), findsOneWidget);
    expect(find.text('pi-relay'), findsOneWidget);
    expect(find.text('/Users/zerray/gitclone/pi-relay'), findsOneWidget);
  });

  testWidgets('shows pairing error when pairing fails', (tester) async {
    await tester.pumpWidget(
      PiRelayApp(
        pairingService:
            _FakePairingService(error: const PairingFailure('配对失败')),
        platform: TargetPlatform.macOS,
      ),
    );

    await tester.tap(find.text('输入配对字符串'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('pairing-payload-field')), 'bad');
    await tester.tap(find.text('配对'));
    await tester.pumpAndSettle();

    expect(find.text('配对失败'), findsOneWidget);
    expect(find.text('Pi Relay'), findsOneWidget);
  });
}

class _FakePairingService implements PairingService {
  _FakePairingService({
    PairingResult? result,
    this.error,
  }) : result = result ??
            PairingResult(
              daemonName: 'daemon',
              baseUrl: Uri.parse('https://daemon.example'),
              token: 'token_1',
              projects: const [],
            );

  final PairingResult result;
  final Object? error;
  String? submittedPayload;

  @override
  Future<PairingResult> pair(String pairingPayload) async {
    submittedPayload = pairingPayload;
    final error = this.error;
    if (error != null) throw error;
    return result;
  }
}
