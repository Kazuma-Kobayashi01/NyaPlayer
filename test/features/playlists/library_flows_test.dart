import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/app/app.dart';
import 'package:nyaplayer/app/router.dart';
import 'package:nyaplayer/data/db/app_database.dart';
import 'package:nyaplayer/data/db/database_providers.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/services/library/library_scanner.dart';
import 'package:nyaplayer/services/library/scan_diff.dart';
import 'package:nyaplayer/services/platform/folder_picker.dart';
import 'package:nyaplayer/services/platform/music_permission.dart';
import 'package:nyaplayer/services/player/fake_player_engine.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';
import 'package:nyaplayer/src/rust/api/meta.dart';

class _FakePicker implements FolderPicker {
  _FakePicker(String? answer) : answers = [?answer];

  List<String> answers;
  Object? failWith;
  int calls = 0;

  set answer(String? value) => answers = [?value];

  @override
  Future<List<String>> pickDirectories({
    String? title,
    String? message,
    String? prompt,
  }) async {
    calls++;
    if (failWith != null) throw failWith!;
    return answers;
  }
}

class _FakePermission implements MusicPermission {
  _FakePermission(this.access);

  MusicAccess access;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<MusicAccess> status() async => access;

  @override
  Future<MusicAccess> request() async {
    requests++;
    return access;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

// drift cancels its stream queries with a zero-length timer; let it run
// before the framework checks for pending timers.
Future<void> finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  late AppDatabase db;
  late FakePlayerEngine engine;
  late _FakePicker picker;
  late _FakePermission permission;
  late List<int> trackIds;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    engine = FakePlayerEngine(durationOf: (_) => const Duration(minutes: 3));
    picker = _FakePicker(null);
    permission = _FakePermission(MusicAccess.granted);
  });

  tearDown(() async {
    await engine.dispose();
    await db.close();
  });

  Future<ProviderContainer> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      trackIds = [
        for (final name in ['Alpha', 'Bravo', 'Charlie', 'Delta'])
          await db
              .into(db.tracks)
              .insert(TracksCompanion.insert(path: '/m/$name.flac')),
      ];
      for (var i = 0; i < trackIds.length; i++) {
        await (db.update(
          db.tracks,
        )..where((t) => t.id.equals(trackIds[i]))).write(
          TracksCompanion(
            title: Value(['Alpha', 'Bravo', 'Charlie', 'Delta'][i]),
            durationMs: const Value(180000),
          ),
        );
      }
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerEngineProvider.overrideWithValue(engine),
          databaseProvider.overrideWithValue(db),
          folderPickerProvider.overrideWithValue(picker),
          musicPermissionProvider.overrideWithValue(permission),
          libraryProvider.overrideWith(
            (ref) => ref
                .watch(libraryRepositoryProvider)
                .watchLibrary(debounce: const Duration(milliseconds: 1)),
          ),
          libraryScannerProvider.overrideWithValue(
            LibraryScanner(
              db,
              walker: (roots, excluded) async => WalkResult(
                files: [FileStamp('${roots.first}/New.flac', 1, 1)],
                missingRoots: const [],
              ),
              reader: (paths) async => [
                for (final path in paths)
                  MetaResult(
                    path: path,
                    meta: TrackMeta(
                      title: 'New',
                      durationMs: BigInt.from(1000),
                      codec: 'FLAC',
                      hasCover: false,
                    ),
                  ),
              ],
            ),
          ),
        ],
        child: const NyaPlayerApp(),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NyaPlayerApp)),
    );
    await settle(tester);
    return container;
  }

  testWidgets('create, rename and delete a playlist', (tester) async {
    final container = await pump(tester);
    container.read(routerProvider).go('/playlists');
    await settle(tester);
    expect(find.text('No playlists yet'), findsOneWidget);

    await tester.tap(find.text('New playlist'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Road trip');
    await tester.tap(find.text('Create'));
    await settle(tester);
    expect(find.text('Road trip'), findsOneWidget);

    await tester.tap(find.byTooltip('More options').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Night drive');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Night drive'), findsOneWidget);
    expect(find.text('Road trip'), findsNothing);

    await tester.tap(find.byTooltip('More options').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);
    expect(find.text('Night drive'), findsNothing);
    expect(find.text('No playlists yet'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('a song in the library and a playlist plays the tapped list', (
    tester,
  ) async {
    final container = await pump(tester);
    final repo = container.read(playlistRepositoryProvider);
    final playlistId = (await tester.runAsync(() async {
      final id = await repo.create('Mine');
      // Charlie is also in the library; here it comes first.
      await repo.addTracks(id, [trackIds[2], trackIds[0]]);
      return id;
    }))!;
    final router = container.read(routerProvider);

    // From the library: the queue is the whole library.
    router.go('/songs');
    await settle(tester);
    await tester.tap(find.text('Charlie'));
    await settle(tester);
    expect(container.read(queueProvider).queue.map((t) => t.title), [
      'Alpha',
      'Bravo',
      'Charlie',
      'Delta',
    ]);
    expect(container.read(queueProvider).current!.title, 'Charlie');

    // From the playlist: the queue is the playlist, Charlie first.
    router.go('/playlists/$playlistId');
    await settle(tester);
    expect(find.widgetWithText(ListTile, 'Charlie'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'Charlie'));
    await settle(tester);
    final queue = container.read(queueProvider);
    expect(queue.queue.map((t) => t.title), ['Charlie', 'Alpha']);
    expect(queue.current!.title, 'Charlie');
    await container.read(queueProvider.notifier).skipNext();
    await settle(tester);
    expect(container.read(queueProvider).current!.title, 'Alpha');
    await engine.pause(); // the fake engine ticks while playing
    await finish(tester);
  });

  testWidgets('add a song to a playlist from its menu, remove it again', (
    tester,
  ) async {
    final container = await pump(tester);
    final repo = container.read(playlistRepositoryProvider);
    final playlistId = (await tester.runAsync(() => repo.create('Mine')))!;
    container.read(routerProvider).go('/songs');
    await settle(tester);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Bravo'),
        matching: find.byTooltip('More options'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to playlist'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('add-to-$playlistId')));
    await settle(tester);
    expect(find.textContaining('Added to'), findsOneWidget);
    expect(await tester.runAsync(() => repo.watchTrackIds(playlistId).first), [
      trackIds[1],
    ]);

    container.read(routerProvider).go('/playlists/$playlistId');
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Bravo'),
        matching: find.byTooltip('More options'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from this playlist'));
    await settle(tester);
    expect(
      await tester.runAsync(() => repo.watchTrackIds(playlistId).first),
      isEmpty,
    );
    await finish(tester);
  });

  testWidgets('adding a music folder in settings stores it and scans', (
    tester,
  ) async {
    final tmp = Directory.systemTemp.createTempSync('nya_pick_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    picker.answer = tmp.path;
    final container = await pump(tester);
    container.read(routerProvider).go('/settings');
    await settle(tester);

    await tester.ensureVisible(find.text('Add folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add folder'));
    await settle(tester);
    await settle(tester);

    expect(find.text(tmp.path), findsOneWidget);
    expect(find.text('Scan finished'), findsOneWidget);
    final titles = (await tester.runAsync(() => db.select(db.tracks).get()))!
        .map((t) => t.title);
    expect(titles, contains('New'));

    // Picking the same folder again is refused.
    await tester.ensureVisible(find.text('Add folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add folder'));
    await settle(tester);
    expect(find.text('That folder is already in the list'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Remove this folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove this folder'));
    await settle(tester);
    expect(find.text(tmp.path), findsNothing);
    await finish(tester);
  });

  testWidgets('several folders chosen at once are all added', (tester) async {
    final a = Directory.systemTemp.createTempSync('nya_a_');
    final b = Directory.systemTemp.createTempSync('nya_b_');
    addTearDown(() {
      a.deleteSync(recursive: true);
      b.deleteSync(recursive: true);
    });
    picker.answers = [a.path, b.path];
    final container = await pump(tester);
    container.read(routerProvider).go('/settings');
    await settle(tester);

    await tester.ensureVisible(find.text('Add folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add folder'));
    await settle(tester);
    await settle(tester);

    expect(find.text(a.path), findsOneWidget);
    expect(find.text(b.path), findsOneWidget);
    await finish(tester);
  });

  testWidgets('without permission nothing is picked and settings are offered', (
    tester,
  ) async {
    permission.access = MusicAccess.permanentlyDenied;
    picker.answer = '/music/never';
    final container = await pump(tester);
    container.read(routerProvider).go('/settings');
    await settle(tester);

    await tester.ensureVisible(find.text('Add folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add folder'));
    await tester.pumpAndSettle();

    expect(find.text('Permission to read music'), findsOneWidget);
    expect(permission.requests, 0, reason: 'the system will not ask again');
    expect(picker.calls, 0);
    await tester.tap(find.text('Open system settings'));
    await tester.pumpAndSettle();
    expect(permission.settingsOpened, 1);
    expect(
      await tester.runAsync(() => db.select(db.libraryRoots).get()),
      isEmpty,
    );
    await finish(tester);
  });

  testWidgets('a denied permission is asked for once, then the picker opens', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('nya_p_');
    addTearDown(() => dir.deleteSync(recursive: true));
    permission.access = MusicAccess.denied;
    picker.answer = dir.path;
    final container = await pump(tester);
    container.read(routerProvider).go('/settings');
    await settle(tester);

    await tester.ensureVisible(find.text('Add folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add folder'));
    await tester.pumpAndSettle();

    expect(permission.requests, 1);
    expect(find.text('Permission to read music'), findsOneWidget);
    expect(
      find.text('Open system settings'),
      findsNothing,
      reason: 'still askable: no settings shortcut yet',
    );
    expect(picker.calls, 0);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    permission.access = MusicAccess.granted;
    await tester.tap(find.text('Add folder'));
    await settle(tester);
    await settle(tester);
    expect(find.text(dir.path), findsOneWidget);
    await finish(tester);
  });

  testWidgets('excluding a folder needs no permission', (tester) async {
    final dir = Directory.systemTemp.createTempSync('nya_x_');
    addTearDown(() => dir.deleteSync(recursive: true));
    permission.access = MusicAccess.denied;
    await tester.runAsync(
      () => db
          .into(db.libraryRoots)
          .insert(LibraryRootsCompanion.insert(path: '/some/music')),
    );
    picker.answer = '/some/music/skip';
    final container = await pump(tester);
    container.read(routerProvider).go('/settings');
    await settle(tester);

    await tester.ensureVisible(find.text('Exclude folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exclude folder'));
    await settle(tester);

    expect(permission.requests, 0);
    expect(picker.calls, 1);
    expect(find.text('/some/music/skip'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('a folder the system hands back unusable is explained', (
    tester,
  ) async {
    picker.failWith = const FolderPickException('content://tree/abc');
    final container = await pump(tester);
    container.read(routerProvider).go('/settings');
    await settle(tester);

    await tester.ensureVisible(find.text('Add folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add folder'));
    await settle(tester);

    expect(
      find.text('That folder cannot be read. Please choose another location.'),
      findsOneWidget,
    );
    expect(
      await tester.runAsync(() => db.select(db.libraryRoots).get()),
      isEmpty,
    );

    // Any other failure of the chooser is reported too, never thrown.
    picker.failWith = StateError('dialog crashed');
    await tester.tap(find.text('Add folder'));
    await settle(tester);
    expect(find.text('Could not open the folder chooser'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('cancelling the chooser changes nothing', (tester) async {
    final container = await pump(tester);
    container.read(routerProvider).go('/settings');
    await settle(tester);

    await tester.ensureVisible(find.text('Add folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add folder'));
    await settle(tester);

    expect(picker.calls, 1);
    expect(
      await tester.runAsync(() => db.select(db.libraryRoots).get()),
      isEmpty,
    );
    await finish(tester);
  });
}
