import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/data/db/database_providers.dart';
import 'package:nyaplayer/services/sr/super_resolution.dart';

class _FakeBackend implements SrBackend {
  _FakeBackend({this.available = true});

  final bool available;
  final events$ = StreamController<SrEvent>.broadcast();
  final converted = <(int, String, String)>[];
  final cancelled = <int>[];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> convert({
    required int job,
    required String source,
    required String destination,
  }) async => converted.add((job, source, destination));

  @override
  Future<void> cancel(int job) async => cancelled.add(job);

  @override
  Stream<SrEvent> get events => events$.stream;
}

class _CountingScan extends ScanController {
  static int scans = 0;

  @override
  Future<void> scan() async => scans++;
}

void main() {
  late _FakeBackend backend;
  late List<(String, String)> tagCopies;
  late Object? tagError;
  late ProviderContainer container;
  late Directory dir;

  Future<void> pump() => Future<void>.delayed(Duration.zero);
  SuperResolutionController ctl() =>
      container.read(superResolutionProvider.notifier);
  SrState state() => container.read(superResolutionProvider);

  setUp(() {
    backend = _FakeBackend();
    tagCopies = [];
    tagError = null;
    _CountingScan.scans = 0;
    dir = Directory.systemTemp.createTempSync('sr_test_');
    container = ProviderContainer(
      overrides: [
        srBackendProvider.overrideWithValue(backend),
        srCopyTagsProvider.overrideWithValue((source, destination) async {
          if (tagError != null) throw tagError!;
          tagCopies.add((source, destination));
        }),
        scanProvider.overrideWith(_CountingScan.new),
      ],
    );
    container.read(superResolutionProvider);
  });

  tearDown(() {
    container.dispose();
    dir.deleteSync(recursive: true);
  });

  test('the SQ-AI file is named beside the MP3', () {
    expect(srDestinationFor('/music/a/Song.mp3'), '/music/a/Song.SQ-AI.flac');
    expect(srDestinationFor('/m/x.y.mp3'), '/m/x.y.SQ-AI.flac');
  });

  test('availability comes from the native side', () async {
    await pump();
    expect(state().available, isTrue);
    final off = ProviderContainer(
      overrides: [
        srBackendProvider.overrideWithValue(_FakeBackend(available: false)),
      ],
    );
    addTearDown(off.dispose);
    off.read(superResolutionProvider);
    await pump();
    expect(off.read(superResolutionProvider).available, isFalse);
  });

  test(
    'a job goes waiting, running, done; tags are copied; library rescanned',
    () async {
      final mp3 = '${dir.path}/Song.mp3';
      await ctl().add([mp3]);
      expect(backend.converted.single.$2, mp3);
      expect(backend.converted.single.$3, '${dir.path}/Song.SQ-AI.flac');
      expect(state().jobs.single.status, SrStatus.waiting);
      expect(state().busy, isTrue);

      backend.events$.add(
        const SrEvent(1, SrEventKind.progress, fraction: 0.4),
      );
      await pump();
      expect(state().jobs.single.status, SrStatus.running);
      expect(state().jobs.single.fraction, 0.4);

      backend.events$.add(const SrEvent(1, SrEventKind.done));
      await pump();
      await pump();
      expect(state().jobs.single.status, SrStatus.done);
      expect(tagCopies.single, (mp3, '${dir.path}/Song.SQ-AI.flac'));
      expect(_CountingScan.scans, 1);
      expect(state().busy, isFalse);
    },
  );

  test('the library is rescanned once, after the last job', () async {
    await ctl().add(['${dir.path}/A.mp3', '${dir.path}/B.mp3']);
    backend.events$.add(const SrEvent(1, SrEventKind.done));
    await pump();
    await pump();
    expect(_CountingScan.scans, 0, reason: 'job 2 is still waiting');
    backend.events$.add(const SrEvent(2, SrEventKind.done));
    await pump();
    await pump();
    expect(_CountingScan.scans, 1);
  });

  test(
    'a file that already has its SQ-AI twin is not converted again',
    () async {
      File('${dir.path}/Song.SQ-AI.flac').writeAsBytesSync([1]);
      await ctl().add(['${dir.path}/Song.mp3']);
      expect(backend.converted, isEmpty);
      expect(state().jobs.single.status, SrStatus.exists);
      expect(state().busy, isFalse);
    },
  );

  test('errors, cancelling and failing tag copies show on the job', () async {
    await ctl().add([
      '${dir.path}/A.mp3',
      '${dir.path}/B.mp3',
      '${dir.path}/C.mp3',
    ]);
    backend.events$.add(
      const SrEvent(1, SrEventKind.error, message: 'no model'),
    );
    backend.events$.add(const SrEvent(2, SrEventKind.cancelled));
    await pump();
    expect(state().jobs[0].status, SrStatus.failed);
    expect(state().jobs[0].message, 'no model');
    expect(state().jobs[1].status, SrStatus.cancelled);

    tagError = StateError('disk full');
    backend.events$.add(const SrEvent(3, SrEventKind.done));
    await pump();
    await pump();
    expect(state().jobs[2].status, SrStatus.failed);
    expect(state().jobs[2].message, contains('disk full'));
    expect(_CountingScan.scans, 0, reason: 'nothing finished');
  });

  test('cancel is only sent for a job still in progress', () async {
    await ctl().add(['${dir.path}/A.mp3']);
    await ctl().cancel(1);
    expect(backend.cancelled, [1]);
    backend.events$.add(const SrEvent(1, SrEventKind.cancelled));
    await pump();
    await ctl().cancel(1);
    expect(backend.cancelled, [1]);
    ctl().clearFinished();
    expect(state().jobs, isEmpty);
  });
}
