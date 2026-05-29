import '../../domain/sessions/remote_session.dart';
import '../../infrastructure/remote_client/daemon_client.dart';
import 'session_list_service.dart';

class DaemonSessionListService implements SessionListService {
  DaemonSessionListService({DaemonClient? client})
      : _client = client ?? DaemonClient();

  final DaemonClient _client;

  @override
  Future<List<RemoteSession>> fetchSessions({
    required Uri baseUrl,
    required String token,
    required String projectId,
  }) async {
    try {
      return await _client.fetchSessions(
        baseUrl: baseUrl,
        token: token,
        projectId: projectId,
      );
    } on DaemonClientException catch (error) {
      throw SessionListFailure(error.message);
    } on FormatException catch (error) {
      throw SessionListFailure(error.message);
    }
  }
}
