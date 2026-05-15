import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/domain/pairing/pairing_link.dart';

void main() {
  test('parses a raw pairing link', () {
    final link = parsePairingPayload(
      'pi-remote://pair?baseUrl=https%3A%2F%2Fmacbook.tailnet.ts.net%3A17373&code=123456&expiresAt=2026-05-09T09%3A52%3A00.000Z',
    );

    expect(link.baseUrl.toString(), 'https://macbook.tailnet.ts.net:17373');
    expect(link.code, '123456');
    expect(
        link.expiresAt.toUtc().toIso8601String(), '2026-05-09T09:52:00.000Z');
  });

  test('parses a desktop UTF-8 hex pairing payload', () {
    const hexPayload =
        '70692d72656d6f74653a2f2f706169723f6261736555726c3d68747470732533412532462532466d6163626f6f6b2e7461696c6e65742e74732e6e6574253341313733373326636f64653d313233343536266578706972657341743d323032362d30352d3039543039253341353225334130302e3030305a';

    final link = parsePairingPayload(hexPayload);

    expect(link.baseUrl.toString(), 'https://macbook.tailnet.ts.net:17373');
    expect(link.code, '123456');
  });

  test('ignores whitespace around and inside desktop hex payloads', () {
    const hexPayload = '''
70692d72656d6f74653a2f2f706169723f626173
6555726c3d687474707325334125324625324668
6f737426636f64653d313233343536266578706972657341743d323032362d30352d3039543039253341353225334130302e3030305a
''';

    final link = parsePairingPayload(hexPayload);

    expect(link.baseUrl.toString(), 'https://host');
    expect(link.code, '123456');
  });

  test('rejects non-hex desktop pairing payloads', () {
    expect(
      () => parsePairingPayload('not a pairing payload'),
      throwsA(isA<PairingLinkFormatException>()),
    );
  });

  test('rejects pairing links with invalid scheme', () {
    expect(
      () => parsePairingPayload(
        'https://example.com/pair?baseUrl=https%3A%2F%2Fhost&code=123456&expiresAt=2026-05-09T09%3A52%3A00.000Z',
      ),
      throwsA(isA<PairingLinkFormatException>()),
    );
  });

  test('rejects pairing links without six digit code', () {
    expect(
      () => parsePairingPayload(
        'pi-remote://pair?baseUrl=https%3A%2F%2Fhost&code=abc&expiresAt=2026-05-09T09%3A52%3A00.000Z',
      ),
      throwsA(isA<PairingLinkFormatException>()),
    );
  });
}
