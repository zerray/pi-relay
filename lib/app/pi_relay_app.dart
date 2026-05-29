import 'package:flutter/material.dart';

import '../application/pairing/daemon_pairing_service.dart';
import '../application/pairing/pairing_service.dart';
import '../application/sessions/daemon_session_list_service.dart';
import '../application/sessions/session_list_service.dart';
import '../domain/projects/remote_project.dart';
import '../domain/sessions/remote_session.dart';
import '../presentation/pairing/pairing_start_page.dart';
import '../presentation/projects/projects_page.dart';
import '../presentation/sessions/sessions_page.dart';

class PiRelayApp extends StatefulWidget {
  PiRelayApp({
    PairingService? pairingService,
    SessionListService? sessionListService,
    this.platform,
    super.key,
  })  : pairingService = pairingService ?? DaemonPairingService(),
        sessionListService = sessionListService ?? DaemonSessionListService();

  final PairingService pairingService;
  final SessionListService sessionListService;
  final TargetPlatform? platform;

  @override
  State<PiRelayApp> createState() => _PiRelayAppState();
}

class _PiRelayAppState extends State<PiRelayApp> {
  PairingResult? _pairingResult;
  RemoteProject? _selectedProject;
  List<RemoteSession> _sessions = const [];
  bool _isLoadingSessions = false;
  String? _sessionErrorText;

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
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    final pairingResult = _pairingResult;
    if (pairingResult == null) {
      return PairingStartPage(onPairingPayloadSubmitted: _pair);
    }

    final selectedProject = _selectedProject;
    if (selectedProject != null) {
      return SessionsPage(
        project: selectedProject,
        sessions: _sessions,
        isLoading: _isLoadingSessions,
        errorText: _sessionErrorText,
        onBack: _closeSessions,
      );
    }

    return ProjectsPage(
      daemonName: pairingResult.daemonName,
      projects: pairingResult.projects,
      onProjectSelected: _openProject,
    );
  }

  Future<void> _pair(String pairingPayload) async {
    final result = await widget.pairingService.pair(pairingPayload);
    if (!mounted) return;
    setState(() {
      _pairingResult = result;
    });
  }

  Future<void> _openProject(RemoteProject project) async {
    final pairingResult = _pairingResult;
    if (pairingResult == null) return;

    setState(() {
      _selectedProject = project;
      _sessions = const [];
      _isLoadingSessions = true;
      _sessionErrorText = null;
    });

    try {
      final sessions = await widget.sessionListService.fetchSessions(
        baseUrl: pairingResult.baseUrl,
        token: pairingResult.token,
        projectId: project.id,
      );
      if (!mounted || _selectedProject?.id != project.id) return;
      setState(() {
        _sessions = sessions;
        _isLoadingSessions = false;
      });
    } on Exception catch (error) {
      if (!mounted || _selectedProject?.id != project.id) return;
      setState(() {
        _sessions = const [];
        _isLoadingSessions = false;
        _sessionErrorText = error.toString();
      });
    }
  }

  void _closeSessions() {
    setState(() {
      _selectedProject = null;
      _sessions = const [];
      _isLoadingSessions = false;
      _sessionErrorText = null;
    });
  }
}
