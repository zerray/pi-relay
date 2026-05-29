import '../../domain/projects/remote_project.dart';
import '../../infrastructure/remote_client/daemon_client.dart';
import 'project_list_service.dart';

class DaemonProjectListService implements ProjectListService {
  DaemonProjectListService({DaemonClient? client})
      : _client = client ?? DaemonClient();

  final DaemonClient _client;

  @override
  Future<List<RemoteProject>> fetchProjects({
    required Uri baseUrl,
    required String token,
  }) async {
    try {
      return await _client.fetchProjects(baseUrl: baseUrl, token: token);
    } on DaemonClientException catch (error) {
      throw ProjectListFailure(error.message);
    } on FormatException catch (error) {
      throw ProjectListFailure(error.message);
    }
  }
}
