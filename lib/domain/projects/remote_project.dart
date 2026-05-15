class RemoteProject {
  const RemoteProject({
    required this.id,
    required this.name,
    required this.path,
  });

  final String id;
  final String name;
  final String path;

  factory RemoteProject.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final name = json['name'];
    final path = json['path'];
    if (id is! String || name is! String || path is! String) {
      throw const FormatException('Project JSON is missing id, name, or path.');
    }

    return RemoteProject(id: id, name: name, path: path);
  }
}
