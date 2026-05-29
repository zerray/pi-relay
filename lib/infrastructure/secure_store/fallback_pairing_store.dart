import '../../application/pairing/pairing_store.dart';

class FallbackPairingStore implements PairingStore {
  const FallbackPairingStore({
    required PairingStore primary,
    required PairingStore fallback,
  })  : _primary = primary,
        _fallback = fallback;

  final PairingStore _primary;
  final PairingStore _fallback;

  @override
  Future<void> clear() async {
    try {
      await _primary.clear();
    } on Exception {
      // Continue clearing the fallback below.
    }
    await _fallback.clear();
  }

  @override
  Future<SavedPairing?> load() async {
    try {
      final savedPairing = await _primary.load();
      if (savedPairing != null) return savedPairing;
    } on Exception {
      return _fallback.load();
    }
    return _fallback.load();
  }

  @override
  Future<void> save(SavedPairing pairing) async {
    try {
      await _primary.save(pairing);
    } on Exception {
      await _fallback.save(pairing);
    }
  }
}
