import '../../domain/projects/remote_project.dart';

abstract interface class ProjectListService {
  Future<List<RemoteProject>> fetchProjects({
    required Uri baseUrl,
    required String token,
  });
}

class ProjectListFailure implements Exception {
  const ProjectListFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
