import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/application/pairing/pairing_store.dart';
import 'package:pi_relay/infrastructure/secure_store/fallback_pairing_store.dart';

void main() {
  test(
      'uses fallback store when primary secure storage is missing entitlements',
      () async {
    final fallback = _MemoryPairingStore();
    final store = FallbackPairingStore(
      primary: _ThrowingPairingStore(
        PlatformException(
          code: 'Unexpected security result code',
          message: "A required entitlement isn't present.",
          details: -34018,
        ),
      ),
      fallback: fallback,
    );

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
  });
}

class _ThrowingPairingStore implements PairingStore {
  _ThrowingPairingStore(this.error);

  final Object error;

  @override
  Future<void> clear() async => throw error;

  @override
  Future<SavedPairing?> load() async => throw error;

  @override
  Future<void> save(SavedPairing pairing) async => throw error;
}

class _MemoryPairingStore implements PairingStore {
  SavedPairing? savedPairing;

  @override
  Future<void> clear() async {
    savedPairing = null;
  }

  @override
  Future<SavedPairing?> load() async => savedPairing;

  @override
  Future<void> save(SavedPairing pairing) async {
    savedPairing = pairing;
  }
}
