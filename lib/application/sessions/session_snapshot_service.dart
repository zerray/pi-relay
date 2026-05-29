import '../../domain/sessions/session_snapshot.dart';
import '../../domain/sessions/session_stream_event.dart';
import '../../domain/transcript/transcript_page.dart';

abstract interface class SessionSnapshotService {
  Future<SessionSnapshot> fetchSnapshot({
    required Uri baseUrl,
    required String token,
    required String sessionId,
    required int messageLimit,
  });

  Future<TranscriptPage> fetchOlderMessages({
    required Uri baseUrl,
    required String token,
    required String sessionId,
    required String before,
    required int limit,
  });

  Future<void> sendPrompt({
    required Uri baseUrl,
    required String token,
    required String sessionId,
    required String text,
  });

  Stream<SessionStreamEvent> watchSession({
    required Uri baseUrl,
    required String token,
    required String sessionId,
  });
}

class SessionSnapshotFailure implements Exception {
  const SessionSnapshotFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
