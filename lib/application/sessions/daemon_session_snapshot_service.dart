import '../../domain/sessions/session_snapshot.dart';
import '../../domain/sessions/session_stream_event.dart';
import '../../domain/transcript/transcript_page.dart';
import '../../infrastructure/remote_client/daemon_client.dart';
import 'session_snapshot_service.dart';

class DaemonSessionSnapshotService implements SessionSnapshotService {
  DaemonSessionSnapshotService({DaemonClient? client})
      : _client = client ?? DaemonClient();

  final DaemonClient _client;

  @override
  Future<TranscriptPage> fetchOlderMessages({
    required Uri baseUrl,
    required String token,
    required String sessionId,
    required String before,
    required int limit,
  }) async {
    try {
      return await _client.fetchOlderMessages(
        baseUrl: baseUrl,
        token: token,
        sessionId: sessionId,
        before: before,
        limit: limit,
      );
    } on DaemonClientException catch (error) {
      throw SessionSnapshotFailure(error.message);
    } on FormatException catch (error) {
      throw SessionSnapshotFailure(error.message);
    }
  }

  @override
  Future<void> sendPrompt({
    required Uri baseUrl,
    required String token,
    required String sessionId,
    required String text,
  }) async {
    try {
      await _client.sendPrompt(
        baseUrl: baseUrl,
        token: token,
        sessionId: sessionId,
        text: text,
      );
    } on DaemonClientException catch (error) {
      throw SessionSnapshotFailure(error.message);
    } on FormatException catch (error) {
      throw SessionSnapshotFailure(error.message);
    }
  }

  @override
  Stream<SessionStreamEvent> watchSession({
    required Uri baseUrl,
    required String token,
    required String sessionId,
  }) {
    return _client
        .watchSession(
      baseUrl: baseUrl,
      token: token,
      sessionId: sessionId,
    )
        .handleError((Object error) {
      if (error is DaemonClientException) {
        throw SessionSnapshotFailure(error.message);
      }
      if (error is FormatException) {
        throw SessionSnapshotFailure(error.message);
      }
      throw error;
    });
  }

  @override
  Future<SessionSnapshot> fetchSnapshot({
    required Uri baseUrl,
    required String token,
    required String sessionId,
    required int messageLimit,
  }) async {
    try {
      return await _client.fetchSessionSnapshot(
        baseUrl: baseUrl,
        token: token,
        sessionId: sessionId,
        messageLimit: messageLimit,
      );
    } on DaemonClientException catch (error) {
      throw SessionSnapshotFailure(error.message);
    } on FormatException catch (error) {
      throw SessionSnapshotFailure(error.message);
    }
  }
}
