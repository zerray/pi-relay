import '../../domain/sessions/session_snapshot.dart';

abstract interface class SessionSnapshotService {
  Future<SessionSnapshot> fetchSnapshot({
    required Uri baseUrl,
    required String token,
    required String sessionId,
    required int messageLimit,
  });
}

class SessionSnapshotFailure implements Exception {
  const SessionSnapshotFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
