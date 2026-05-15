import 'dart:convert';

class PairingLink {
  const PairingLink({
    required this.baseUrl,
    required this.code,
    required this.expiresAt,
  });

  final Uri baseUrl;
  final String code;
  final DateTime expiresAt;
}

class PairingLinkFormatException implements Exception {
  const PairingLinkFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

PairingLink parsePairingPayload(String input) {
  final payload = input.trim();
  if (payload.isEmpty) {
    throw const PairingLinkFormatException('Pairing payload is empty.');
  }

  final rawLink = payload.startsWith('pi-remote://')
      ? payload
      : _decodeHexPairingPayload(payload);
  final uri = Uri.tryParse(rawLink);
  if (uri == null || uri.scheme != 'pi-remote' || uri.host != 'pair') {
    throw const PairingLinkFormatException(
        'Pairing payload is not a pi-remote pair link.');
  }

  final baseUrlValue = uri.queryParameters['baseUrl'];
  final code = uri.queryParameters['code'];
  final expiresAtValue = uri.queryParameters['expiresAt'];
  if (baseUrlValue == null || code == null || expiresAtValue == null) {
    throw const PairingLinkFormatException(
        'Pairing link is missing required fields.');
  }

  final baseUrl = Uri.tryParse(baseUrlValue);
  if (baseUrl == null ||
      !baseUrl.hasScheme ||
      (baseUrl.scheme != 'http' && baseUrl.scheme != 'https') ||
      baseUrl.host.isEmpty) {
    throw const PairingLinkFormatException(
        'Pairing link has an invalid base URL.');
  }

  if (!RegExp(r'^\d{6}$').hasMatch(code)) {
    throw const PairingLinkFormatException(
        'Pairing link has an invalid pair code.');
  }

  final expiresAt = DateTime.tryParse(expiresAtValue);
  if (expiresAt == null) {
    throw const PairingLinkFormatException(
        'Pairing link has an invalid expiration time.');
  }

  return PairingLink(baseUrl: baseUrl, code: code, expiresAt: expiresAt);
}

String _decodeHexPairingPayload(String payload) {
  final compactPayload = payload.replaceAll(RegExp(r'\s+'), '');
  if (compactPayload.isEmpty || compactPayload.length.isOdd) {
    throw const PairingLinkFormatException(
        'Desktop pairing payload is not valid hex.');
  }
  if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(compactPayload)) {
    throw const PairingLinkFormatException(
        'Desktop pairing payload is not valid hex.');
  }

  final bytes = <int>[];
  for (var index = 0; index < compactPayload.length; index += 2) {
    bytes.add(int.parse(compactPayload.substring(index, index + 2), radix: 16));
  }

  try {
    return utf8.decode(bytes, allowMalformed: false);
  } on FormatException {
    throw const PairingLinkFormatException(
        'Desktop pairing payload is not valid UTF-8.');
  }
}
