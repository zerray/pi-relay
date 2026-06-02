import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/presentation/pairing/mobile_pairing_scanner_page.dart';

void main() {
  testWidgets('shows scanner instructions and cancel action', (tester) async {
    var cancelled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MobilePairingScannerPage(
          onPairingPayloadScanned: (_) {},
          onCancel: () {
            cancelled = true;
          },
          cameraViewBuilder: (_) => const SizedBox.expand(),
        ),
      ),
    );

    expect(find.text('扫描配对二维码'), findsOneWidget);
    expect(find.text('/remote-control-pair'), findsOneWidget);

    await tester.tap(find.byTooltip('取消扫码'));
    await tester.pumpAndSettle();

    expect(cancelled, isTrue);
  });
}
