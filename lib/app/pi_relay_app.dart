import 'dart:async';

import 'package:flutter/material.dart';

import '../application/pairing/daemon_pairing_service.dart';
import '../application/pairing/pairing_service.dart';
import '../application/pairing/pairing_store.dart';
import '../application/projects/daemon_project_list_service.dart';
import '../application/projects/project_list_service.dart';
import '../application/sessions/daemon_session_list_service.dart';
import '../application/sessions/daemon_session_snapshot_service.dart';
import '../application/sessions/session_list_service.dart';
import '../application/sessions/session_snapshot_service.dart';
import '../domain/projects/remote_project.dart';
import '../infrastructure/secure_store/default_pairing_store.dart';
import '../domain/sessions/remote_session.dart';
import '../domain/sessions/session_stream_event.dart';
import '../domain/sessions/session_stream_reducer.dart';
import '../domain/transcript/transcript_message.dart';
import '../presentation/pairing/pairing_start_page.dart';
import '../presentation/projects/projects_page.dart';
import '../presentation/sessions/session_conversation_page.dart';
import '../presentation/sessions/sessions_page.dart';

class PiRelayApp extends StatefulWidget {
  PiRelayApp({
    PairingService? pairingService,
    ProjectListService? projectListService,
    SessionListService? sessionListService,
    SessionSnapshotService? sessionSnapshotService,
    PairingStore? pairingStore,
    this.platform,
    super.key,
  })  : pairingService = pairingService ?? DaemonPairingService(),
        projectListService = projectListService ?? DaemonProjectListService(),
        sessionListService = sessionListService ?? DaemonSessionListService(),
        sessionSnapshotService =
            sessionSnapshotService ?? DaemonSessionSnapshotService(),
        pairingStore = pairingStore ?? createDefaultPairingStore();

  final PairingService pairingService;
  final ProjectListService projectListService;
  final SessionListService sessionListService;
  final SessionSnapshotService sessionSnapshotService;
  final PairingStore? pairingStore;
  final TargetPlatform? platform;

  @override
  State<PiRelayApp> createState() => _PiRelayAppState();
}

class _PiRelayAppState extends State<PiRelayApp> {
  static const _streamReducer = SessionStreamReducer();

  PairingResult? _pairingResult;
  RemoteProject? _selectedProject;
  List<RemoteSession> _sessions = const [];
  bool _isLoadingSessions = false;
  String? _sessionErrorText;
  RemoteSession? _selectedSession;
  List<TranscriptMessage> _transcriptMessages = const [];
  bool _isLoadingSnapshot = false;
  String? _snapshotErrorText;
  String? _promptErrorText;
  String? _olderMessagesCursor;
  bool _hasOlderMessages = false;
  bool _isLoadingOlderMessages = false;
  bool _isSubmittingPrompt = false;
  bool _isRestoringPairing = false;
  bool _isSessionStreamClosed = false;
  StreamSubscription<SessionStreamEvent>? _sessionStreamSubscription;

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
  void dispose() {
    _sessionStreamSubscription?.cancel();
    super.dispose();
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

    final selectedSession = _selectedSession;
    if (selectedSession != null) {
      return SessionConversationPage(
        session: selectedSession,
        messages: _transcriptMessages,
        isLoading: _isLoadingSnapshot,
        errorText: _snapshotErrorText,
        promptErrorText: _promptErrorText,
        hasOlderMessages: _hasOlderMessages,
        isLoadingOlder: _isLoadingOlderMessages,
        isSubmittingPrompt: _isSubmittingPrompt,
        onLoadOlder: _loadOlderMessages,
        onPromptSubmitted: _sendPrompt,
        onBack: _closeConversation,
      );
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
        onSessionSelected: _openSession,
      );
    }

    return ProjectsPage(
      daemonName: pairingResult.daemonName,
      daemonBaseUrl: pairingResult.baseUrl,
      projects: pairingResult.projects,
      onProjectSelected: _openProject,
      onUnpair: _unpair,
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

  Future<void> _unpair() async {
    await widget.pairingStore?.clear();
    if (!mounted) return;
    await _sessionStreamSubscription?.cancel();
    _sessionStreamSubscription = null;
    setState(() {
      _pairingResult = null;
      _selectedProject = null;
      _sessions = const [];
      _isLoadingSessions = false;
      _sessionErrorText = null;
      _selectedSession = null;
      _transcriptMessages = const [];
      _isLoadingSnapshot = false;
      _snapshotErrorText = null;
      _promptErrorText = null;
      _olderMessagesCursor = null;
      _hasOlderMessages = false;
      _isLoadingOlderMessages = false;
      _isSubmittingPrompt = false;
      _isSessionStreamClosed = false;
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

  Future<void> _openSession(RemoteSession session) async {
    final pairingResult = _pairingResult;
    if (pairingResult == null) return;

    setState(() {
      _selectedSession = session;
      _transcriptMessages = const [];
      _isLoadingSnapshot = true;
      _snapshotErrorText = null;
      _promptErrorText = null;
      _olderMessagesCursor = null;
      _hasOlderMessages = false;
      _isLoadingOlderMessages = false;
      _isSubmittingPrompt = false;
      _isSessionStreamClosed = false;
    });

    await _sessionStreamSubscription?.cancel();

    try {
      final snapshot = await widget.sessionSnapshotService.fetchSnapshot(
        baseUrl: pairingResult.baseUrl,
        token: pairingResult.token,
        sessionId: session.id,
        messageLimit: 50,
      );
      if (!mounted || _selectedSession?.id != session.id) return;
      setState(() {
        _selectedSession = snapshot.session;
        _transcriptMessages = snapshot.messages;
        _isLoadingSnapshot = false;
        _snapshotErrorText = null;
        _promptErrorText = null;
        _olderMessagesCursor = snapshot.olderMessagesCursor;
        _hasOlderMessages = snapshot.hasOlderMessages;
      });
      _watchSessionStream(session.id, pairingResult);
    } on Exception catch (error) {
      if (!mounted || _selectedSession?.id != session.id) return;
      setState(() {
        _transcriptMessages = const [];
        _isLoadingSnapshot = false;
        _snapshotErrorText = error.toString();
        _promptErrorText = null;
        _olderMessagesCursor = null;
        _hasOlderMessages = false;
      });
    }
  }

  void _watchSessionStream(String sessionId, PairingResult pairingResult) {
    _sessionStreamSubscription = widget.sessionSnapshotService
        .watchSession(
          baseUrl: pairingResult.baseUrl,
          token: pairingResult.token,
          sessionId: sessionId,
        )
        .listen(
          (event) => _receiveSessionStreamEvent(sessionId, event),
          onError: (Object error) => _receiveSessionStreamError(
            sessionId,
            error,
          ),
        );
  }

  void _receiveSessionStreamEvent(
    String sessionId,
    SessionStreamEvent event,
  ) {
    if (!mounted || _selectedSession?.id != sessionId) return;
    final model = _streamReducer.reduce(
      SessionStreamModel(
        session: _selectedSession,
        messages: _transcriptMessages,
        olderMessagesCursor: _olderMessagesCursor,
        hasOlderMessages: _hasOlderMessages,
        isClosed: _isSessionStreamClosed,
        lastErrorMessage: _promptErrorText,
      ),
      event,
      now: DateTime.now().toUtc(),
    );
    setState(() {
      _selectedSession = model.session ?? _selectedSession;
      _transcriptMessages = model.messages;
      _olderMessagesCursor = model.olderMessagesCursor;
      _hasOlderMessages = model.hasOlderMessages;
      _isSessionStreamClosed = model.isClosed;
      _promptErrorText = model.lastErrorMessage;
    });
  }

  void _receiveSessionStreamError(String sessionId, Object error) {
    if (!mounted || _selectedSession?.id != sessionId) return;
    setState(() {
      _promptErrorText = error.toString();
    });
  }

  Future<void> _loadOlderMessages() async {
    final pairingResult = _pairingResult;
    final selectedSession = _selectedSession;
    final before = _olderMessagesCursor;
    if (pairingResult == null || selectedSession == null || before == null) {
      return;
    }
    if (!_hasOlderMessages || _isLoadingOlderMessages) return;

    setState(() {
      _isLoadingOlderMessages = true;
    });

    try {
      final page = await widget.sessionSnapshotService.fetchOlderMessages(
        baseUrl: pairingResult.baseUrl,
        token: pairingResult.token,
        sessionId: selectedSession.id,
        before: before,
        limit: 50,
      );
      if (!mounted || _selectedSession?.id != selectedSession.id) return;
      final existingIds =
          _transcriptMessages.map((message) => message.id).toSet();
      final olderMessages = page.messages
          .where((message) => !existingIds.contains(message.id))
          .toList(growable: false);
      setState(() {
        _transcriptMessages = [
          ...olderMessages,
          ..._transcriptMessages,
        ];
        _olderMessagesCursor = page.olderMessagesCursor;
        _hasOlderMessages = page.hasOlderMessages;
        _isLoadingOlderMessages = false;
      });
    } on Exception {
      if (!mounted || _selectedSession?.id != selectedSession.id) return;
      setState(() {
        _isLoadingOlderMessages = false;
      });
    }
  }

  Future<void> _sendPrompt(String text) async {
    final pairingResult = _pairingResult;
    final selectedSession = _selectedSession;
    final textToSend = text.trim();
    if (pairingResult == null ||
        selectedSession == null ||
        textToSend.isEmpty) {
      return;
    }
    if (_isSubmittingPrompt) return;

    setState(() {
      _isSubmittingPrompt = true;
      _promptErrorText = null;
    });

    try {
      await widget.sessionSnapshotService.sendPrompt(
        baseUrl: pairingResult.baseUrl,
        token: pairingResult.token,
        sessionId: selectedSession.id,
        text: textToSend,
      );
      if (!mounted || _selectedSession?.id != selectedSession.id) return;
      setState(() {
        _isSubmittingPrompt = false;
        _promptErrorText = null;
      });
    } on Exception catch (error) {
      if (!mounted || _selectedSession?.id != selectedSession.id) return;
      setState(() {
        _isSubmittingPrompt = false;
        _promptErrorText = error.toString();
      });
    }
  }

  void _closeConversation() {
    _sessionStreamSubscription?.cancel();
    _sessionStreamSubscription = null;
    setState(() {
      _selectedSession = null;
      _transcriptMessages = const [];
      _isLoadingSnapshot = false;
      _snapshotErrorText = null;
      _promptErrorText = null;
      _olderMessagesCursor = null;
      _hasOlderMessages = false;
      _isLoadingOlderMessages = false;
      _isSubmittingPrompt = false;
      _isSessionStreamClosed = false;
    });
  }

  void _closeSessions() {
    _sessionStreamSubscription?.cancel();
    _sessionStreamSubscription = null;
    setState(() {
      _selectedProject = null;
      _sessions = const [];
      _isLoadingSessions = false;
      _sessionErrorText = null;
      _selectedSession = null;
      _transcriptMessages = const [];
      _isLoadingSnapshot = false;
      _snapshotErrorText = null;
      _promptErrorText = null;
      _olderMessagesCursor = null;
      _hasOlderMessages = false;
      _isLoadingOlderMessages = false;
      _isSubmittingPrompt = false;
      _isSessionStreamClosed = false;
    });
  }
}
