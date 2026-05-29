import 'dart:convert';
import 'dart:io';

import '../../domain/pairing/pairing_link.dart';
import '../../domain/projects/remote_project.dart';
import '../../domain/sessions/remote_session.dart';
import '../../domain/sessions/session_snapshot.dart';

class PairClaimResult {
  const PairClaimResult({
    required this.deviceId,
    required this.token,
    required this.daemonName,
  });

  final String deviceId;
  final String token;
  final String daemonName;
}

class DaemonClientException implements Exception {
  const DaemonClientException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DaemonClient {
  DaemonClient({HttpClient? httpClient})
      : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;

  Future<PairClaimResult> claimPairing({
    required PairingLink link,
    required String deviceName,
  }) async {
    final json = await _sendJson(
      method: 'POST',
      uri: link.baseUrl.resolve('/v1/pair/claim'),
      body: {'pairCode': link.code, 'deviceName': deviceName},
    );

    final deviceId = json['deviceId'];
    final token = json['token'];
    final daemonName = json['daemonName'];
    if (deviceId is! String || token is! String || daemonName is! String) {
      throw const FormatException(
          'Pair claim response is missing required fields.');
    }

    return PairClaimResult(
      deviceId: deviceId,
      token: token,
      daemonName: daemonName,
    );
  }

  Future<List<RemoteProject>> fetchProjects({
    required Uri baseUrl,
    required String token,
  }) async {
    final json = await _sendJson(
      method: 'GET',
      uri: baseUrl.resolve('/v1/projects'),
      bearerToken: token,
    );

    final projectsJson = json['projects'];
    if (projectsJson is! List) {
      throw const FormatException('Projects response is missing projects.');
    }

    return projectsJson.map((projectJson) {
      if (projectJson is! Map<String, Object?>) {
        throw const FormatException('Project entry is not an object.');
      }
      return RemoteProject.fromJson(projectJson);
    }).toList(growable: false);
  }

  Future<List<RemoteSession>> fetchSessions({
    required Uri baseUrl,
    required String token,
    required String projectId,
  }) async {
    final json = await _sendJson(
      method: 'GET',
      uri: baseUrl
          .resolve('/v1/projects/${Uri.encodeComponent(projectId)}/sessions'),
      bearerToken: token,
    );

    final sessionsJson = json['sessions'];
    if (sessionsJson is! List) {
      throw const FormatException('Sessions response is missing sessions.');
    }

    return sessionsJson.map((sessionJson) {
      if (sessionJson is! Map<String, Object?>) {
        throw const FormatException('Session entry is not an object.');
      }
      return RemoteSession.fromJson(sessionJson);
    }).toList(growable: false);
  }

  Future<SessionSnapshot> fetchSessionSnapshot({
    required Uri baseUrl,
    required String token,
    required String sessionId,
    required int messageLimit,
  }) async {
    final uri = baseUrl
        .resolve('/v1/sessions/${Uri.encodeComponent(sessionId)}')
        .replace(
      queryParameters: {'messageLimit': messageLimit.toString()},
    );
    final json = await _sendJson(
      method: 'GET',
      uri: uri,
      bearerToken: token,
    );

    return SessionSnapshot.fromJson(json);
  }

  Future<Map<String, Object?>> _sendJson({
    required String method,
    required Uri uri,
    Map<String, Object?>? body,
    String? bearerToken,
  }) async {
    final request = await _httpClient
        .openUrl(method, uri)
        .timeout(const Duration(seconds: 15));
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    if (bearerToken != null) {
      request.headers
          .set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }

    final response = await request.close().timeout(const Duration(seconds: 15));
    final responseText = await utf8.decoder.bind(response).join();
    final decoded =
        responseText.isEmpty ? <String, Object?>{} : jsonDecode(responseText);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Daemon response is not a JSON object.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'];
      throw DaemonClientException(
          error is String ? error : 'Daemon request failed.');
    }

    return decoded;
  }
}
