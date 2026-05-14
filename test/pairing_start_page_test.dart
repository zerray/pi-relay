import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/app/pi_relay_app.dart';
import 'package:pi_relay/presentation/pairing/pairing_start_page.dart';

void main() {
  testWidgets('shows the launch page title', (tester) async {
    await tester.pumpWidget(const PiRelayApp());

    expect(find.text('Pi Relay'), findsOneWidget);
    expect(find.text('连接到 Pi Remote Control'), findsOneWidget);
  });

  testWidgets('shows disabled scan pairing button on mobile', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const PairingStartPage(),
      ),
    );

    expect(find.text('扫码配对'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('shows disabled paste pairing button on desktop', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.macOS),
        home: const PairingStartPage(),
      ),
    );

    expect(find.text('输入配对字符串'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });
}
