import 'package:flutter_test/flutter_test.dart';
import 'package:pi_relay/domain/projects/remote_project.dart';

void main() {
  test('decodes daemon project JSON', () {
    final project = RemoteProject.fromJson({
      'id': 'proj_1',
      'name': 'pi-relay',
      'path': '/Users/zerray/gitclone/pi-relay',
    });

    expect(project.id, 'proj_1');
    expect(project.name, 'pi-relay');
    expect(project.path, '/Users/zerray/gitclone/pi-relay');
  });

  test('rejects missing project fields', () {
    expect(
      () => RemoteProject.fromJson({'id': 'proj_1'}),
      throwsA(isA<FormatException>()),
    );
  });
}
