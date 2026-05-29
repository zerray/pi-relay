import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/domain/pairing/pairing_link.dart';
import 'package:pi_relay/infrastructure/remote_client/daemon_client.dart';

void main() {
  test('claims pair code with daemon', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final requests = <HttpRequest>[];
    _serve(server, (request) async {
      requests.add(request);
      expect(request.method, 'POST');
      expect(request.uri.path, '/v1/pair/claim');
      expect(request.headers.contentType?.mimeType, 'application/json');
      final body = jsonDecode(await utf8.decoder.bind(request).join())
          as Map<String, Object?>;
      expect(body, {'pairCode': '123456', 'deviceName': 'Test Device'});
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'deviceId': 'dev_1',
          'token': 'token_1',
          'daemonName': 'macbook-pro'
        }));
    });

    final client = DaemonClient();
    final result = await client.claimPairing(
      link: PairingLink(
        baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
        code: '123456',
        expiresAt: DateTime.utc(2026, 5, 9, 9, 52),
      ),
      deviceName: 'Test Device',
    );

    expect(requests, hasLength(1));
    expect(result.deviceId, 'dev_1');
    expect(result.token, 'token_1');
    expect(result.daemonName, 'macbook-pro');
  });

  test('fetches projects with bearer token', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    _serve(server, (request) async {
      expect(request.method, 'GET');
      expect(request.uri.path, '/v1/projects');
      expect(request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer token_1');
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'projects': [
            {'id': 'proj_1', 'name': 'pi-relay', 'path': '/repo/pi-relay'},
          ],
        }));
    });

    final client = DaemonClient();
    final projects = await client.fetchProjects(
      baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
      token: 'token_1',
    );

    expect(projects.single.id, 'proj_1');
    expect(projects.single.name, 'pi-relay');
  });

  test('fetches project sessions with bearer token', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    _serve(server, (request) async {
      expect(request.method, 'GET');
      expect(request.uri.path, '/v1/projects/proj_1/sessions');
      expect(request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer token_1');
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'sessions': [
            {
              'id': 'sess_1',
              'piSessionId': 'pi_sess_1',
              'projectId': 'proj_1',
              'name': 'Refactor auth module',
              'path': '/repo/session.jsonl',
              'updatedAt': '2026-05-09T09:47:00.000Z',
              'messageCount': 42,
              'isActive': true,
            },
          ],
        }));
    });

    final client = DaemonClient();
    final sessions = await client.fetchSessions(
      baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
      token: 'token_1',
      projectId: 'proj_1',
    );

    expect(sessions.single.id, 'sess_1');
    expect(sessions.single.name, 'Refactor auth module');
  });

  test('throws daemon client exception for non-success responses', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    _serve(server, (request) async {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'invalid_pairing_code'}));
    });

    final client = DaemonClient();

    await expectLater(
      client.claimPairing(
        link: PairingLink(
          baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
          code: '123456',
          expiresAt: DateTime.utc(2026, 5, 9, 9, 52),
        ),
        deviceName: 'Test Device',
      ),
      throwsA(isA<DaemonClientException>()),
    );
  });
}

void _serve(
    HttpServer server, Future<void> Function(HttpRequest request) handler) {
  server.listen((request) async {
    try {
      await handler(request);
    } finally {
      await request.response.close();
    }
  });
}
