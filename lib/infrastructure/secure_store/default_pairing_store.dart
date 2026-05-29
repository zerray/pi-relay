import 'dart:io';

import '../../application/pairing/pairing_store.dart';
import 'fallback_pairing_store.dart';
import 'file_pairing_store.dart';
import 'secure_pairing_store.dart';

PairingStore createDefaultPairingStore() {
  final secureStore = SecurePairingStore();

  if (Platform.isMacOS) {
    return FallbackPairingStore(
      primary: secureStore,
      fallback: FilePairingStore(),
    );
  }

  return secureStore;
}
