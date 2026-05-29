import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/application/projects/daemon_project_list_service.dart';
import 'package:pi_relay/application/projects/project_list_service.dart';
import 'package:pi_relay/domain/projects/remote_project.dart';
import 'package:pi_relay/infrastructure/remote_client/daemon_client.dart';

void main() {
  test('fetches projects through daemon client', () async {
    final client = _FakeDaemonClient(
      projects: const [
        RemoteProject(id: 'proj_1', name: 'pi-relay', path: '/repo/pi-relay')
      ],
    );
    final service = DaemonProjectListService(client: client);

    final projects = await service.fetchProjects(
      baseUrl: Uri.parse('https://daemon.example'),
      token: 'token_1',
    );

    expect(client.fetchedBaseUrl.toString(), 'https://daemon.example');
    expect(client.fetchedToken, 'token_1');
    expect(projects.single.name, 'pi-relay');
  });

  test('turns daemon failures into project list failures', () async {
    final service = DaemonProjectListService(
      client: _FakeDaemonClient(
          error: const DaemonClientException('project fetch failed')),
    );

    await expectLater(
      service.fetchProjects(
        baseUrl: Uri.parse('https://daemon.example'),
        token: 'token_1',
      ),
      throwsA(isA<ProjectListFailure>()),
    );
  });
}

class _FakeDaemonClient extends DaemonClient {
  _FakeDaemonClient({this.projects = const [], this.error});

  final List<RemoteProject> projects;
  final Object? error;

  Uri? fetchedBaseUrl;
  String? fetchedToken;

  @override
  Future<List<RemoteProject>> fetchProjects({
    required Uri baseUrl,
    required String token,
  }) async {
    fetchedBaseUrl = baseUrl;
    fetchedToken = token;
    final error = this.error;
    if (error != null) throw error;
    return projects;
  }
}
