abstract interface class PairingStore {
  Future<SavedPairing?> load();
  Future<void> save(SavedPairing pairing);
  Future<void> clear();
}

class SavedPairing {
  const SavedPairing({
    required this.daemonName,
    required this.baseUrl,
    required this.token,
  });

  final String daemonName;
  final Uri baseUrl;
  final String token;
}
