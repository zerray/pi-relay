import 'dart:io';

import '../../domain/pairing/pairing_link.dart';
import '../../infrastructure/remote_client/daemon_client.dart';
import 'pairing_service.dart';

class DaemonPairingService implements PairingService {
  DaemonPairingService({
    DaemonClient? client,
    String Function()? deviceNameProvider,
  })  : _client = client ?? DaemonClient(),
        _deviceNameProvider = deviceNameProvider ?? _defaultDeviceName;

  final DaemonClient _client;
  final String Function() _deviceNameProvider;

  @override
  Future<PairingResult> pair(String pairingPayload) async {
    try {
      final link = parsePairingPayload(pairingPayload);
      final claim = await _client.claimPairing(
        link: link,
        deviceName: _deviceNameProvider(),
      );
      final projects = await _client.fetchProjects(
        baseUrl: link.baseUrl,
        token: claim.token,
      );

      return PairingResult(daemonName: claim.daemonName, projects: projects);
    } on PairingLinkFormatException catch (error) {
      throw PairingFailure(error.message);
    } on DaemonClientException catch (error) {
      throw PairingFailure(error.message);
    } on FormatException catch (error) {
      throw PairingFailure(error.message);
    }
  }

  static String _defaultDeviceName() {
    final host = Platform.localHostname.trim();
    return host.isEmpty ? 'Pi Relay' : 'Pi Relay ($host)';
  }
}
