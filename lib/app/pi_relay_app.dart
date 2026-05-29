import 'package:flutter/material.dart';

import '../application/pairing/daemon_pairing_service.dart';
import '../application/pairing/pairing_service.dart';
import '../application/pairing/pairing_store.dart';
import '../application/projects/daemon_project_list_service.dart';
import '../application/projects/project_list_service.dart';
import '../application/sessions/daemon_session_list_service.dart';
import '../application/sessions/session_list_service.dart';
import '../domain/projects/remote_project.dart';
import '../infrastructure/secure_store/secure_pairing_store.dart';
import '../domain/sessions/remote_session.dart';
import '../presentation/pairing/pairing_start_page.dart';
import '../presentation/projects/projects_page.dart';
import '../presentation/sessions/sessions_page.dart';

class PiRelayApp extends StatefulWidget {
  PiRelayApp({
    PairingService? pairingService,
    ProjectListService? projectListService,
    SessionListService? sessionListService,
    PairingStore? pairingStore,
    this.platform,
    super.key,
  })  : pairingService = pairingService ?? DaemonPairingService(),
        projectListService = projectListService ?? DaemonProjectListService(),
        sessionListService = sessionListService ?? DaemonSessionListService(),
        pairingStore = pairingStore ?? SecurePairingStore();

  final PairingService pairingService;
  final ProjectListService projectListService;
  final SessionListService sessionListService;
  final PairingStore? pairingStore;
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
  bool _isRestoringPairing = false;

  @override
  void initState() {
    super.initState();
    _isRestoringPairing = widget.pairingStore != null;
    _restorePairing();
  }

  Future<void> _restorePairing() async {
    final pairingStore = widget.pairingStore;
    if (pairingStore == null) return;

    try {
      final savedPairing = await pairingStore.load();
      if (savedPairing == null) {
        if (!mounted) return;
        setState(() {
          _isRestoringPairing = false;
        });
        return;
      }

      final projects = await widget.projectListService.fetchProjects(
        baseUrl: savedPairing.baseUrl,
        token: savedPairing.token,
      );
      if (!mounted) return;
      setState(() {
        _pairingResult = PairingResult(
          daemonName: savedPairing.daemonName,
          baseUrl: savedPairing.baseUrl,
          token: savedPairing.token,
          projects: projects,
        );
        _isRestoringPairing = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _isRestoringPairing = false;
      });
    }
  }

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
    if (_isRestoringPairing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
        onRefresh: _refreshSessions,
      );
    }

    return ProjectsPage(
      daemonName: pairingResult.daemonName,
      projects: pairingResult.projects,
      onProjectSelected: _openProject,
      onRefresh: _refreshProjects,
    );
  }

  Future<void> _pair(String pairingPayload) async {
    final result = await widget.pairingService.pair(pairingPayload);
    await widget.pairingStore?.save(
      SavedPairing(
        daemonName: result.daemonName,
        baseUrl: result.baseUrl,
        token: result.token,
      ),
    );
    if (!mounted) return;
    setState(() {
      _pairingResult = result;
    });
  }

  Future<void> _refreshProjects() async {
    final pairingResult = _pairingResult;
    if (pairingResult == null) return;

    try {
      final projects = await widget.projectListService.fetchProjects(
        baseUrl: pairingResult.baseUrl,
        token: pairingResult.token,
      );
      if (!mounted) return;
      setState(() {
        _pairingResult = PairingResult(
          daemonName: pairingResult.daemonName,
          baseUrl: pairingResult.baseUrl,
          token: pairingResult.token,
          projects: projects,
        );
      });
    } on Exception {
      return;
    }
  }

  Future<void> _refreshSessions() async {
    final selectedProject = _selectedProject;
    if (selectedProject == null) return;
    await _loadSessions(selectedProject, showLoading: false);
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

    await _loadSessions(project, showLoading: true);
  }

  Future<void> _loadSessions(
    RemoteProject project, {
    required bool showLoading,
  }) async {
    final pairingResult = _pairingResult;
    if (pairingResult == null) return;

    if (showLoading) {
      setState(() {
        _isLoadingSessions = true;
        _sessionErrorText = null;
      });
    }

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
        _sessionErrorText = null;
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
