import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/application/pairing/pairing_store.dart';
import 'package:pi_relay/infrastructure/secure_store/secure_pairing_store.dart';

void main() {
  test('saves, loads, and clears pairing credentials', () async {
    final storage = _MemorySecureStorage();
    final store = SecurePairingStore(storage: storage);

    await store.save(
      SavedPairing(
        daemonName: 'macbook-pro',
        baseUrl: Uri.parse('https://daemon.example'),
        token: 'token_1',
      ),
    );

    final loaded = await store.load();
    expect(loaded?.daemonName, 'macbook-pro');
    expect(loaded?.baseUrl.toString(), 'https://daemon.example');
    expect(loaded?.token, 'token_1');

    await store.clear();
    expect(await store.load(), isNull);
  });
}

class _MemorySecureStorage implements SecurePairingStorage {
  final _values = <String, String>{};

  @override
  Future<void> delete({required String key}) async {
    _values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async {
    return _values[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }
}
