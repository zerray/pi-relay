import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/application/pairing/pairing_store.dart';
import 'package:pi_relay/infrastructure/secure_store/file_pairing_store.dart';

void main() {
  test('persists pairing credentials in a local file', () async {
    final directory = await Directory.systemTemp.createTemp('pi-relay-store-');
    addTearDown(() => directory.delete(recursive: true));

    final store =
        FilePairingStore(file: File('${directory.path}/pairing.json'));

    await store.save(
      SavedPairing(
        daemonName: 'macbook-pro',
        baseUrl: Uri.parse('https://daemon.example'),
        token: 'token_1',
      ),
    );

    final loaded = await FilePairingStore(
      file: File('${directory.path}/pairing.json'),
    ).load();

    expect(loaded?.daemonName, 'macbook-pro');
    expect(loaded?.baseUrl.toString(), 'https://daemon.example');
    expect(loaded?.token, 'token_1');

    await store.clear();
    expect(await store.load(), isNull);
  });
}
