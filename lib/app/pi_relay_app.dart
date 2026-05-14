import 'package:flutter/material.dart';

import '../presentation/pairing/pairing_start_page.dart';

class PiRelayApp extends StatelessWidget {
  const PiRelayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pi Relay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4F46E5),
        useMaterial3: true,
      ),
      home: const PairingStartPage(),
    );
  }
}
