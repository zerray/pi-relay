import '../../domain/projects/remote_project.dart';

abstract interface class PairingService {
  Future<PairingResult> pair(String pairingPayload);
}

class PairingResult {
  const PairingResult({
    required this.daemonName,
    required this.projects,
  });

  final String daemonName;
  final List<RemoteProject> projects;
}

class PairingFailure implements Exception {
  const PairingFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
