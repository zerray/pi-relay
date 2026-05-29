import '../../domain/sessions/session_snapshot.dart';
import '../../infrastructure/remote_client/daemon_client.dart';
import 'session_snapshot_service.dart';

class DaemonSessionSnapshotService implements SessionSnapshotService {
  DaemonSessionSnapshotService({DaemonClient? client})
      : _client = client ?? DaemonClient();

  final DaemonClient _client;

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
