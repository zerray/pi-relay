import 'dart:convert';
import 'dart:io';

import '../../application/pairing/pairing_store.dart';

class FilePairingStore implements PairingStore {
  FilePairingStore({File? file}) : _file = file ?? _defaultFile();

  final File _file;

  @override
  Future<void> clear() async {
    if (await _file.exists()) {
      await _file.delete();
    }
  }

  @override
  Future<SavedPairing?> load() async {
    if (!await _file.exists()) return null;

    final raw = await _file.readAsString();
    final json = jsonDecode(raw);
    if (json is! Map<String, Object?>) return null;

    final daemonName = json['daemonName'];
    final baseUrl = json['baseUrl'];
    final token = json['token'];
    if (daemonName is! String || baseUrl is! String || token is! String) {
      return null;
    }

    return SavedPairing(
      daemonName: daemonName,
      baseUrl: Uri.parse(baseUrl),
      token: token,
    );
  }

  @override
  Future<void> save(SavedPairing pairing) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(
      jsonEncode({
        'daemonName': pairing.daemonName,
        'baseUrl': pairing.baseUrl.toString(),
        'token': pairing.token,
      }),
      flush: true,
    );
  }

  static File _defaultFile() {
    final home = Platform.environment['HOME'];
    if (Platform.isMacOS && home != null && home.isNotEmpty) {
      return File(
        '$home/Library/Application Support/Pi Relay/pairing.json',
      );
    }

    final appData = Platform.environment['APPDATA'];
    if (Platform.isWindows && appData != null && appData.isNotEmpty) {
      return File('$appData\\Pi Relay\\pairing.json');
    }

    if (home != null && home.isNotEmpty) {
      return File('$home/.config/pi-relay/pairing.json');
    }

    return File('${Directory.systemTemp.path}/pi-relay/pairing.json');
  }
}
