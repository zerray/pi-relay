import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../application/pairing/pairing_store.dart';

abstract interface class SecurePairingStorage {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

class FlutterSecurePairingStorage implements SecurePairingStorage {
  FlutterSecurePairingStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete({required String key}) {
    return _storage.delete(key: key);
  }

  @override
  Future<String?> read({required String key}) {
    return _storage.read(key: key);
  }

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }
}

class SecurePairingStore implements PairingStore {
  SecurePairingStore({SecurePairingStorage? storage})
      : _storage = storage ?? FlutterSecurePairingStorage();

  static const _daemonNameKey = 'pairedDaemonName';
  static const _baseUrlKey = 'pairedDaemonBaseUrl';
  static const _tokenKey = 'pairedDaemonToken';

  final SecurePairingStorage _storage;

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _daemonNameKey),
      _storage.delete(key: _baseUrlKey),
      _storage.delete(key: _tokenKey),
    ]);
  }

  @override
  Future<SavedPairing?> load() async {
    final daemonName = await _storage.read(key: _daemonNameKey);
    final baseUrlText = await _storage.read(key: _baseUrlKey);
    final token = await _storage.read(key: _tokenKey);

    if (daemonName == null || baseUrlText == null || token == null) {
      return null;
    }

    return SavedPairing(
      daemonName: daemonName,
      baseUrl: Uri.parse(baseUrlText),
      token: token,
    );
  }

  @override
  Future<void> save(SavedPairing pairing) async {
    await Future.wait([
      _storage.write(key: _daemonNameKey, value: pairing.daemonName),
      _storage.write(key: _baseUrlKey, value: pairing.baseUrl.toString()),
      _storage.write(key: _tokenKey, value: pairing.token),
    ]);
  }
}
