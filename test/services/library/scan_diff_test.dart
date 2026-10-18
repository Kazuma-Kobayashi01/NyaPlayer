import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/services/library/scan_diff.dart';

FileStamp _f(String path, {int size = 10, int mtime = 1}) =>
    FileStamp(path, size, mtime);

Map<String, FileStamp> _map(List<FileStamp> files) => {
  for (final f in files) f.path: f,
};

void main() {
  test('identical sets produce an empty diff', () {
    final files = _map([_f('/a'), _f('/b')]);
    expect(diffScan(onDisk: files, known: files).isEmpty, isTrue);
  });

  test('new, changed and missing files are told apart', () {
    final diff = diffScan(
      onDisk: _map([
        _f('/same'),
        _f('/new'),
        _f('/size', size: 99),
        _f('/time', mtime: 9),
      ]),
      known: _map([_f('/same'), _f('/size'), _f('/time'), _f('/gone')]),
    );
    expect(diff.added.map((f) => f.path), ['/new']);
    expect(
      diff.modified.map((f) => f.path),
      unorderedEquals(['/size', '/time']),
    );
    expect(diff.removed, ['/gone']);
    expect(diff.toRead, hasLength(3));
  });

  test('preserved paths are never reported as removed', () {
    final diff = diffScan(
      onDisk: const {},
      known: _map([_f('/usb/a'), _f('/home/b')]),
      preserve: (path) => path.startsWith('/usb'),
    );
    expect(diff.removed, ['/home/b']);
  });
}
