import '../../domain/sessions/remote_session.dart';

abstract interface class SessionListService {
  Future<List<RemoteSession>> fetchSessions({
    required Uri baseUrl,
    required String token,
    required String projectId,
  });
}

class SessionListFailure implements Exception {
  const SessionListFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
