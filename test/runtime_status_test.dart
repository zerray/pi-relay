import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/domain/sessions/runtime_status.dart';

void main() {
  test('decodes daemon runtime status snapshots', () {
    final status = RuntimeStatus.fromJson({
      'model': {
        'provider': 'anthropic',
        'id': 'claude-sonnet-4-5',
        'name': 'Claude Sonnet 4.5',
        'contextWindow': 200000,
      },
      'thinkingLevel': 'medium',
      'usage': {
        'input': 12000,
        'output': 3000,
        'cacheRead': 50000,
        'cacheWrite': 10000,
        'cost': {
          'input': 0.036,
          'output': 0.045,
          'cacheRead': 0.015,
          'cacheWrite': 0.0375,
          'total': 0.1335,
        },
      },
      'context': {
        'tokens': 65000,
        'contextWindow': 200000,
        'percent': 32.5,
      },
      'updatedAt': '2026-05-09T09:47:00.000Z',
    });

    expect(status.model?.id, 'claude-sonnet-4-5');
    expect(status.model?.displayName, 'Claude Sonnet 4.5');
    expect(status.thinkingLevel, 'medium');
    expect(status.usage.cacheRead, 50000);
    expect(status.usage.cost.total, 0.1335);
    expect(status.context?.tokens, 65000);
    expect(status.context?.percent, 32.5);
    expect(status.updatedAt, DateTime.utc(2026, 5, 9, 9, 47));
  });
}
