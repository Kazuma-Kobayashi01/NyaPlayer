import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/core/log.dart';
import 'package:nyaplayer/data/db/app_database.dart' show AppDatabase;
import 'package:nyaplayer/data/library.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/data/repositories/library_repository.dart';
import 'package:nyaplayer/data/repositories/playlist_repository.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/services/library/library_scanner.dart';

/// `main` overrides this with the on-disk database. The default is an
/// in-memory one so widget tests need no setup.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(NativeDatabase.memory());
  ref.onDispose(db.close);
  return db;
});

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepository(ref.watch(databaseProvider)),
);

final playlistRepositoryProvider = Provider<PlaylistRepository>(
  (ref) => PlaylistRepository(ref.watch(databaseProvider)),
);

/// The library as stored in the database; `main` plugs it into
/// `libraryProvider`.
final databaseLibraryProvider = StreamProvider<Library>(
  (ref) => ref.watch(libraryRepositoryProvider).watchLibrary(),
);

final rootsProvider = StreamProvider<List<LibraryRoot>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchRoots(),
);

final playlistsProvider = StreamProvider<List<Playlist>>(
  (ref) => ref.watch(playlistRepositoryProvider).watchPlaylists(),
);

/// Tracks of a playlist in playlist order. Entries whose file left the
/// library are already gone (foreign key cascade).
final playlistTracksProvider = StreamProvider.family<List<Track>, int>((
  ref,
  playlistId,
) {
  final library = ref.watch(libraryProvider).value;
  return ref.watch(playlistRepositoryProvider).watchTrackIds(playlistId).map((
    ids,
  ) {
    if (library == null) return const <Track>[];
    return [for (final id in ids) ?library.trackById(id)];
  });
});

final libraryScannerProvider = Provider<LibraryScanner>(
  (ref) => LibraryScanner(ref.watch(databaseProvider)),
);

@immutable
class ScanState {
  const ScanState({this.progress, this.failed = false});

  final ScanProgress? progress;
  final bool failed;

  bool get running =>
      progress != null && progress!.phase != ScanPhase.done && !failed;
}

final scanProvider = NotifierProvider<ScanController, ScanState>(
  ScanController.new,
);

class ScanController extends Notifier<ScanState> {
  bool _rerun = false;

  @override
  ScanState build() => const ScanState();

  /// Starts an incremental scan (LIB-04/05). Asking while one is running
  /// schedules one more pass afterwards, so a folder added mid-scan is seen.
  Future<void> scan() async {
    if (state.running) {
      _rerun = true;
      return;
    }
    do {
      _rerun = false;
      state = const ScanState(progress: ScanProgress(ScanPhase.walking));
      try {
        await for (final progress in ref.read(libraryScannerProvider).scan()) {
          state = ScanState(progress: progress);
        }
      } catch (e) {
        Log.e('Scanner', 'Scan failed', e);
        state = const ScanState(failed: true);
      }
    } while (_rerun);
  }
}
