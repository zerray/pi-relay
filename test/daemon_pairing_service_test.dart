import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/application/pairing/daemon_pairing_service.dart';
import 'package:pi_relay/application/pairing/pairing_service.dart';
import 'package:pi_relay/domain/pairing/pairing_link.dart';
import 'package:pi_relay/domain/projects/remote_project.dart';
import 'package:pi_relay/infrastructure/remote_client/daemon_client.dart';

void main() {
  test('claims pairing payload and fetches projects', () async {
    final client = _FakeDaemonClient(
      claimResult: const PairClaimResult(
        deviceId: 'dev_1',
        token: 'token_1',
        daemonName: 'macbook-pro',
      ),
      projects: const [
        RemoteProject(id: 'proj_1', name: 'pi-relay', path: '/repo/pi-relay')
      ],
    );
    final service = DaemonPairingService(
      client: client,
      deviceNameProvider: () => 'Test Device',
    );

    final result = await service.pair(
      'pi-remote://pair?baseUrl=https%3A%2F%2Fmacbook.tailnet.ts.net%3A17373&code=123456&expiresAt=2026-05-09T09%3A52%3A00.000Z',
    );

    expect(client.claimedCode, '123456');
    expect(client.claimedDeviceName, 'Test Device');
    expect(client.fetchedBaseUrl.toString(),
        'https://macbook.tailnet.ts.net:17373');
    expect(client.fetchedToken, 'token_1');
    expect(result.daemonName, 'macbook-pro');
    expect(result.baseUrl.toString(), 'https://macbook.tailnet.ts.net:17373');
    expect(result.token, 'token_1');
    expect(result.projects.single.name, 'pi-relay');
  });

  test('turns invalid pairing payloads into pairing failures', () async {
    final service = DaemonPairingService(
      client: _FakeDaemonClient(),
      deviceNameProvider: () => 'Test Device',
    );

    await expectLater(
      service.pair('bad input'),
      throwsA(isA<PairingFailure>()),
    );
  });
}

class _FakeDaemonClient extends DaemonClient {
  _FakeDaemonClient({
    this.claimResult = const PairClaimResult(
      deviceId: 'dev_1',
      token: 'token_1',
      daemonName: 'daemon',
    ),
    this.projects = const [],
  });

  final PairClaimResult claimResult;
  final List<RemoteProject> projects;

  String? claimedCode;
  String? claimedDeviceName;
  Uri? fetchedBaseUrl;
  String? fetchedToken;

  @override
  Future<PairClaimResult> claimPairing({
    required PairingLink link,
    required String deviceName,
  }) async {
    claimedCode = link.code;
    claimedDeviceName = deviceName;
    return claimResult;
  }

  @override
  Future<List<RemoteProject>> fetchProjects({
    required Uri baseUrl,
    required String token,
  }) async {
    fetchedBaseUrl = baseUrl;
    fetchedToken = token;
    return projects;
  }
}
