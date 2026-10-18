import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/core/log.dart';
import 'package:nyaplayer/data/db/database_providers.dart';
import 'package:nyaplayer/src/rust/api/meta.dart' as rust;
import 'package:path/path.dart' as p;

/// AI super-resolution of MP3s into SQ-AI FLACs (TECH_SPEC §4.8). The audio
/// work is native and runs on the GPU (Core ML, macOS only); this file queues
/// the files, follows the progress, copies the tags and rescans the library.

/// What the native side tells about a job.
enum SrEventKind { progress, done, error, cancelled }

class SrEvent {
  const SrEvent(this.job, this.kind, {this.fraction = 0, this.message});

  final int job;
  final SrEventKind kind;
  final double fraction;
  final String? message;
}

/// The native conversion, behind an interface so tests can stand in for it.
abstract class SrBackend {
  /// Whether this platform and build can convert (macOS with the model).
  Future<bool> isAvailable();

  /// Queues one conversion; results arrive on [events]. Jobs run one at a time.
  Future<void> convert({
    required int job,
    required String source,
    required String destination,
  });

  Future<void> cancel(int job);

  Stream<SrEvent> get events;
}

/// The macOS implementation: `nyaplayer/sr` (see `MacSuperResolution.swift`).
class MethodChannelSrBackend implements SrBackend {
  static const _method = MethodChannel('nyaplayer/sr');
  static const _events = EventChannel('nyaplayer/sr/events');

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isMacOS) return false;
    try {
      final status = await _method.invokeMapMethod<String, Object?>('status');
      return status?['available'] == true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> convert({
    required int job,
    required String source,
    required String destination,
  }) => _method.invokeMethod<void>('convert', {
    'job': job,
    'source': source,
    'destination': destination,
  });

  @override
  Future<void> cancel(int job) =>
      _method.invokeMethod<void>('cancel', {'job': job});

  @override
  Stream<SrEvent> get events => _events.receiveBroadcastStream().map((raw) {
    final map = Map<String, Object?>.from(raw as Map);
    return SrEvent(
      (map['job'] as num).toInt(),
      switch (map['kind']) {
        'progress' => SrEventKind.progress,
        'done' => SrEventKind.done,
        'cancelled' => SrEventKind.cancelled,
        _ => SrEventKind.error,
      },
      fraction: (map['fraction'] as num?)?.toDouble() ?? 0,
      message: map['message'] as String?,
    );
  });
}

final srBackendProvider = Provider<SrBackend>(
  (ref) => MethodChannelSrBackend(),
);

/// Copies the MP3's tags and cover onto the new FLAC (Rust, lofty).
typedef SrCopyTags = Future<void> Function(String source, String destination);

final srCopyTagsProvider = Provider<SrCopyTags>(
  (ref) =>
      (source, destination) => rust.copyTagsToFlac(
        source: source,
        destination: destination,
        marker: 'ai-sr',
      ),
);

/// The file the conversion writes: `Song.mp3` -> `Song.SQ-AI.flac`, beside it.
String srDestinationFor(String source) => p.join(
  p.dirname(source),
  '${p.basenameWithoutExtension(source)}.SQ-AI.flac',
);

enum SrStatus { waiting, running, done, failed, cancelled, exists }

class SrJob {
  const SrJob({
    required this.id,
    required this.source,
    required this.destination,
    this.status = SrStatus.waiting,
    this.fraction = 0,
    this.message,
  });

  final int id;
  final String source;
  final String destination;
  final SrStatus status;
  final double fraction;
  final String? message;

  bool get active => status == SrStatus.waiting || status == SrStatus.running;

  SrJob copyWith({SrStatus? status, double? fraction, String? message}) =>
      SrJob(
        id: id,
        source: source,
        destination: destination,
        status: status ?? this.status,
        fraction: fraction ?? this.fraction,
        message: message ?? this.message,
      );
}

class SrState {
  const SrState({this.available, this.jobs = const []});

  /// Null until the native side has been asked.
  final bool? available;
  final List<SrJob> jobs;

  bool get busy => jobs.any((j) => j.active);

  SrState copyWith({bool? available, List<SrJob>? jobs}) =>
      SrState(available: available ?? this.available, jobs: jobs ?? this.jobs);
}

final superResolutionProvider =
    NotifierProvider<SuperResolutionController, SrState>(
      SuperResolutionController.new,
    );

class SuperResolutionController extends Notifier<SrState> {
  int _nextJob = 1;

  StreamSubscription<SrEvent>? _events;

  @override
  SrState build() {
    final backend = ref.read(srBackendProvider);
    ref.onDispose(() => _events?.cancel());
    // Listen only where there is something to listen to: a build without the
    // native half has no event channel behind it.
    unawaited(
      backend.isAvailable().then((ok) {
        if (!ref.mounted) return;
        if (ok) _events = backend.events.listen(_onEvent, onError: (_) {});
        state = state.copyWith(available: ok);
      }),
    );
    return const SrState();
  }

  /// Queues every MP3 in [paths] that has no SQ-AI file yet.
  Future<void> add(List<String> paths) async {
    final backend = ref.read(srBackendProvider);
    for (final source in paths) {
      final destination = srDestinationFor(source);
      final id = _nextJob++;
      if (File(destination).existsSync()) {
        _put(
          SrJob(
            id: id,
            source: source,
            destination: destination,
            status: SrStatus.exists,
          ),
        );
        continue;
      }
      _put(SrJob(id: id, source: source, destination: destination));
      try {
        await backend.convert(
          job: id,
          source: source,
          destination: destination,
        );
      } on Object catch (e) {
        _update(id, (j) => j.copyWith(status: SrStatus.failed, message: '$e'));
      }
    }
  }

  Future<void> cancel(int job) async {
    final current = state.jobs.where((j) => j.id == job).firstOrNull;
    if (current == null || !current.active) return;
    await ref.read(srBackendProvider).cancel(job);
  }

  /// Drops the finished rows from the list.
  void clearFinished() => state = state.copyWith(
    jobs: [
      for (final j in state.jobs)
        if (j.active) j,
    ],
  );

  void _put(SrJob job) => state = state.copyWith(jobs: [...state.jobs, job]);

  void _update(int id, SrJob Function(SrJob) change) {
    state = state.copyWith(
      jobs: [for (final j in state.jobs) j.id == id ? change(j) : j],
    );
  }

  Future<void> _onEvent(SrEvent event) async {
    switch (event.kind) {
      case SrEventKind.progress:
        _update(
          event.job,
          (j) => j.copyWith(status: SrStatus.running, fraction: event.fraction),
        );
      case SrEventKind.cancelled:
        _update(event.job, (j) => j.copyWith(status: SrStatus.cancelled));
      case SrEventKind.error:
        _update(
          event.job,
          (j) => j.copyWith(status: SrStatus.failed, message: event.message),
        );
      case SrEventKind.done:
        final job = state.jobs.where((j) => j.id == event.job).firstOrNull;
        if (job == null) return;
        try {
          await ref.read(srCopyTagsProvider)(job.source, job.destination);
          _update(
            event.job,
            (j) => j.copyWith(status: SrStatus.done, fraction: 1),
          );
        } on Object catch (e) {
          Log.w('SQ-AI', 'copying tags failed: $e');
          _update(
            event.job,
            (j) => j.copyWith(status: SrStatus.failed, message: '$e'),
          );
        }
    }
    if (!state.busy && state.jobs.any((j) => j.status == SrStatus.done)) {
      unawaited(ref.read(scanProvider.notifier).scan());
    }
  }
}
