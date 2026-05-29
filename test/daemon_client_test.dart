import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/domain/pairing/pairing_link.dart';
import 'package:pi_relay/domain/sessions/session_stream_event.dart';
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

  test('fetches session snapshot with bearer token and message limit',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    _serve(server, (request) async {
      expect(request.method, 'GET');
      expect(request.uri.path, '/v1/sessions/sess_1');
      expect(request.uri.queryParameters['messageLimit'], '50');
      expect(request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer token_1');
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'session': {
            'id': 'sess_1',
            'piSessionId': 'pi_sess_1',
            'projectId': 'proj_1',
            'name': 'Refactor auth module',
            'path': '/repo/session.jsonl',
            'updatedAt': '2026-05-09T09:47:00.000Z',
            'messageCount': 42,
            'isActive': true,
          },
          'messages': [
            {
              'id': 'msg_1',
              'role': 'user',
              'text': 'Explain this project',
              'createdAt': '2026-05-09T09:46:00.000Z',
              'isStreaming': false,
              'content': [],
            },
          ],
          'olderMessagesCursor': null,
          'hasOlderMessages': false,
          'isStreaming': false,
        }));
    });

    final client = DaemonClient();
    final snapshot = await client.fetchSessionSnapshot(
      baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
      token: 'token_1',
      sessionId: 'sess_1',
      messageLimit: 50,
    );

    expect(snapshot.session.id, 'sess_1');
    expect(snapshot.messages.single.text, 'Explain this project');
  });

  test('sends prompt with bearer token and JSON body', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    _serve(server, (request) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/v1/sessions/sess_1/prompt');
      expect(request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer token_1');
      expect(request.headers.contentType?.mimeType, 'application/json');
      final body = jsonDecode(await utf8.decoder.bind(request).join())
          as Map<String, Object?>;
      expect(body, {'text': 'hello pi'});
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'accepted': true}));
    });

    final client = DaemonClient();
    await client.sendPrompt(
      baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
      token: 'token_1',
      sessionId: 'sess_1',
      text: 'hello pi',
    );
  });

  test('streams session events with bearer token', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      expect(request.uri.path, '/v1/sessions/sess_1/stream');
      expect(request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer token_1');
      final socket = await WebSocketTransformer.upgrade(request);
      socket.add(jsonEncode({
        'type': 'transcript_message_end',
        'message': {
          'id': 'msg_live',
          'role': 'assistant',
          'text': 'Live response',
          'createdAt': '2026-05-09T09:47:00.000Z',
          'isStreaming': false,
          'content': [
            {'type': 'text', 'text': 'Live response'},
          ],
        },
      }));
      await socket.close();
    });

    final client = DaemonClient();
    final event = await client
        .watchSession(
          baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
          token: 'token_1',
          sessionId: 'sess_1',
        )
        .first;

    expect(event, isA<TranscriptMessageEndEvent>());
    expect((event as TranscriptMessageEndEvent).message.text, 'Live response');
  });

  test('fetches older session messages with bearer token', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    _serve(server, (request) async {
      expect(request.method, 'GET');
      expect(request.uri.path, '/v1/sessions/sess_1/messages');
      expect(request.uri.queryParameters['before'], 'cursor_1');
      expect(request.uri.queryParameters['limit'], '50');
      expect(request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer token_1');
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'messages': [
            {
              'id': 'msg_older',
              'role': 'user',
              'text': 'Older prompt text',
              'createdAt': '2026-05-09T09:30:00.000Z',
              'isStreaming': false,
              'content': [],
            },
          ],
          'olderMessagesCursor': null,
          'hasOlderMessages': false,
        }));
    });

    final client = DaemonClient();
    final page = await client.fetchOlderMessages(
      baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
      token: 'token_1',
      sessionId: 'sess_1',
      before: 'cursor_1',
      limit: 50,
    );

    expect(page.messages.single.text, 'Older prompt text');
    expect(page.hasOlderMessages, isFalse);
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
