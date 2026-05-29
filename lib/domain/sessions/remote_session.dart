class RemoteSession {
  const RemoteSession({
    required this.id,
    required this.piSessionId,
    required this.projectId,
    required this.name,
    required this.path,
    required this.updatedAt,
    required this.messageCount,
    required this.isActive,
  });

  final String id;
  final String piSessionId;
  final String projectId;
  final String name;
  final String path;
  final DateTime updatedAt;
  final int messageCount;
  final bool isActive;

  factory RemoteSession.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final piSessionId = json['piSessionId'];
    final projectId = json['projectId'];
    final rawName = json['name'];
    final path = json['path'];
    final updatedAtValue = json['updatedAt'];
    final messageCount = json['messageCount'];
    final isActive = json['isActive'];

    if (id is! String ||
        piSessionId is! String ||
        projectId is! String ||
        path is! String ||
        updatedAtValue is! String ||
        messageCount is! int ||
        isActive is! bool) {
      throw const FormatException('Session JSON is missing required fields.');
    }
    if (rawName != null && rawName is! String) {
      throw const FormatException('Session JSON has an invalid name.');
    }

    final updatedAt = DateTime.tryParse(updatedAtValue);
    if (updatedAt == null) {
      throw const FormatException('Session JSON has an invalid updatedAt.');
    }
    final name = rawName as String?;

    return RemoteSession(
      id: id,
      piSessionId: piSessionId,
      projectId: projectId,
      name: name == null || name.trim().isEmpty ? id : name,
      path: path,
      updatedAt: updatedAt,
      messageCount: messageCount,
      isActive: isActive,
    );
  }
}
