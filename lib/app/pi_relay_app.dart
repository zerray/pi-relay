import 'package:flutter/material.dart';

import '../application/pairing/daemon_pairing_service.dart';
import '../application/pairing/pairing_service.dart';
import '../presentation/pairing/pairing_start_page.dart';
import '../presentation/projects/projects_page.dart';

class PiRelayApp extends StatefulWidget {
  PiRelayApp({
    PairingService? pairingService,
    this.platform,
    super.key,
  }) : pairingService = pairingService ?? DaemonPairingService();

  final PairingService pairingService;
  final TargetPlatform? platform;

  @override
  State<PiRelayApp> createState() => _PiRelayAppState();
}

class _PiRelayAppState extends State<PiRelayApp> {
  PairingResult? _pairingResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pi Relay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4F46E5),
        platform: widget.platform,
        useMaterial3: true,
      ),
      home: _pairingResult == null
          ? PairingStartPage(onPairingPayloadSubmitted: _pair)
          : ProjectsPage(
              daemonName: _pairingResult!.daemonName,
              projects: _pairingResult!.projects,
            ),
    );
  }

  Future<void> _pair(String pairingPayload) async {
    final result = await widget.pairingService.pair(pairingPayload);
    if (!mounted) return;
    setState(() {
      _pairingResult = result;
    });
  }
}
