import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/app/start_page.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';
import 'package:nyaplayer/data/db/app_database.dart' hide Track;
import 'package:nyaplayer/data/db/database_providers.dart'
    show savedEqPresetsProvider;
import 'package:nyaplayer/data/library_filter.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/data/repositories/favorites_repository.dart';
import 'package:nyaplayer/data/repositories/settings_repository.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/lyrics/lyrics_settings.dart';
import 'package:nyaplayer/features/now_playing/player_artwork.dart';
import 'package:nyaplayer/services/eq/eq_state.dart';

Track _track(int id) => Track(
  id: id,
  title: 't$id',
  artist: 'a',
  albumId: 1,
  album: 'al',
  trackNo: id,
  duration: const Duration(minutes: 3),
  path: '/m/$id.flac',
  codec: 'FLAC',
  sampleRate: 44100,
  bitDepth: 16,
  bitrateKbps: 900,
  addedAt: DateTime(2026),
  coverSeed: 0xFF6750A4,
);

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('DbSettingsStore', () {
    test('values survive reopening the store', () async {
      final first = await DbSettingsStore.open(db);
      first.put('a', '1');
      first.put('a', '2');
      first.put('b', 'x');
      await first.flush();

      final second = await DbSettingsStore.open(db);
      expect(second.get('a'), '2');
      expect(second.get('b'), 'x');
      expect(second.get('missing'), isNull);
    });

    test('writes are skipped while persistence is off', () async {
      final store = await DbSettingsStore.open(db);
      store.persist = false;
      store.put('preview', 'on');
      await store.flush();

      expect(store.get('preview'), 'on', reason: 'still applies in memory');
      expect(await db.select(db.settings).get(), isEmpty);
    });
  });

  group('controllers restore what was saved', () {
    late MemorySettingsStore store;

    ProviderContainer container() {
      final c = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(c.dispose);
      return c;
    }

    setUp(() => store = MemorySettingsStore());

    test('theme, player and locale settings', () {
      final first = container();
      first.read(themeSettingsProvider.notifier)
        ..setMode(ThemeMode.dark)
        ..setSource(ColorSource.fixed)
        ..setSeed(seedColorChoices[3])
        ..setFont(AppFont.serif)
        ..setPlayerBackground(PlayerBackgroundStyle.gradient)
        ..setProgressStyle(ProgressStyle.wave);
      first.read(localeProvider.notifier).set(const Locale('en'));
      first.read(startPageProvider.notifier).set(StartPage.albums);
      first.read(coverShapeProvider.notifier).set(CoverShape.turntable);

      final second = container();
      final theme = second.read(themeSettingsProvider);
      expect(theme.mode, ThemeMode.dark);
      expect(theme.source, ColorSource.fixed);
      expect(theme.seed, seedColorChoices[3]);
      expect(theme.font, AppFont.serif);
      expect(theme.playerBackground, PlayerBackgroundStyle.gradient);
      expect(theme.progressStyle, ProgressStyle.wave);
      expect(second.read(localeProvider), const Locale('en'));
      expect(second.read(startPageProvider), StartPage.albums);
      expect(second.read(coverShapeProvider), CoverShape.turntable);
    });

    test('"follow the system language" is remembered as such', () {
      final first = container();
      first.read(localeProvider.notifier).set(const Locale('zh'));
      first.read(localeProvider.notifier).set(null);

      expect(container().read(localeProvider), isNull);
    });

    test('flowing light is on and the material standard until changed', () {
      final defaults = container().read(themeSettingsProvider);
      expect(defaults.flowingLight, isTrue);
      expect(defaults.material, SurfaceMaterial.standard);

      container().read(themeSettingsProvider.notifier)
        ..setFlowingLight(false)
        ..setMaterial(SurfaceMaterial.glass);
      final restored = container().read(themeSettingsProvider);
      expect(restored.flowingLight, isFalse);
      expect(restored.material, SurfaceMaterial.glass);

      store.put('theme.material', 'marble');
      expect(
        container().read(themeSettingsProvider).material,
        SurfaceMaterial.standard,
        reason: 'an unknown value falls back to the default',
      );
    });

    test('the minimum track length is one minute until changed', () {
      expect(
        container().read(minTrackDurationProvider),
        const Duration(minutes: 1),
      );

      container().read(minTrackDurationProvider.notifier).set(Duration.zero);
      expect(container().read(minTrackDurationProvider), Duration.zero);

      store.put('library.minDurationSec', 'garbage');
      expect(
        container().read(minTrackDurationProvider),
        const Duration(minutes: 1),
      );
    });

    test('saved EQ presets: save, select, edit, delete', () async {
      final c = container();
      // Riverpod pauses a stream provider nobody listens to.
      c.listen(savedEqPresetsProvider, (_, _) {});
      final eq = c.read(eqProvider.notifier);
      eq.setGain(0, 5);
      expect(c.read(eqProvider).presetId, customPresetId);

      await eq.saveCurrent('Mine');
      final id = userPresetIdOf(c.read(eqProvider).presetId)!;
      await pumpEventQueue();
      final saved = c.read(savedEqPresetsProvider).value!.single;
      expect((saved.id, saved.name, saved.gains[0]), (id, 'Mine', 5));

      eq.selectPreset('rock');
      expect(c.read(eqProvider).gains[0], 4);
      eq.selectSaved(saved);
      expect(c.read(eqProvider).presetId, saved.presetId);
      expect(c.read(eqProvider).gains[0], 5);

      // Touching a band leaves the saved preset: the curve is now unnamed.
      eq.setGain(1, 3);
      expect(c.read(eqProvider).presetId, customPresetId);

      eq.selectSaved(saved);
      await eq.deleteSaved(id);
      expect(c.read(eqProvider).presetId, customPresetId);
      expect(c.read(eqProvider).gains[0], 5, reason: 'the curve is kept');
      await pumpEventQueue();
      expect(c.read(savedEqPresetsProvider).value, isEmpty);
    });

    test('lyrics display options', () {
      final first = container();
      first.read(lyricsSettingsProvider.notifier)
        ..setFontSize(26)
        ..setLineHeight(1.6)
        ..setCentered(true)
        ..setShowTranslation(false);

      final s = container().read(lyricsSettingsProvider);
      expect(s.fontSize, 26);
      expect(s.lineHeight, 1.6);
      expect(s.centered, isTrue);
      expect(s.showTranslation, isFalse);
    });

    test('equaliser state, including a custom curve', () {
      final first = container();
      first.read(eqProvider.notifier)
        ..selectPreset('rock')
        ..setGain(2, 7.5)
        ..setEnabled(false)
        ..setAutoPreventClipping(false)
        ..setPreamp(-3);

      final eq = container().read(eqProvider);
      expect(eq.gains[2], 7.5);
      expect(eq.presetId, customPresetId);
      expect(eq.enabled, isFalse);
      expect(eq.autoPreventClipping, isFalse);
      expect(eq.preamp, -3);
    });

    test('defaults apply when nothing was saved', () {
      final c = container();
      expect(c.read(themeSettingsProvider).mode, ThemeMode.system);
      expect(c.read(startPageProvider), StartPage.songs);
      expect(c.read(lyricsSettingsProvider).fontSize, 20);
      expect(c.read(eqProvider).enabled, isTrue);
      expect(store.get('theme.mode'), isNull, reason: 'nothing written yet');
    });

    test('unknown or damaged values fall back instead of failing', () {
      store
        ..put('theme.mode', 'rainbow')
        ..put('theme.seed', 'not a number')
        ..put('ui.startPage', 'moon')
        ..put('lyrics.fontSize', '9999')
        ..put('lyrics.lineHeight', 'abc')
        ..put('lyrics.centered', 'maybe')
        ..put('eq.state', '{broken')
        ..put('player.coverShape', '');

      final c = container();
      expect(c.read(themeSettingsProvider).mode, ThemeMode.system);
      expect(c.read(themeSettingsProvider).seed, const Color(0xFF6750A4));
      expect(c.read(startPageProvider), StartPage.songs);
      expect(
        c.read(lyricsSettingsProvider).fontSize,
        LyricsSettings.maxFontSize,
      );
      expect(c.read(lyricsSettingsProvider).lineHeight, 1.2);
      expect(c.read(lyricsSettingsProvider).centered, isFalse);
      expect(c.read(eqProvider), isA<EqState>());
      expect(c.read(eqProvider).gains, everyElement(0));
      expect(c.read(coverShapeProvider), CoverShape.square);
    });

    test('an equaliser with the wrong number of bands is ignored', () {
      store.put('eq.state', '{"gains":[1,2,3]}');
      expect(container().read(eqProvider).gains, everyElement(0));
    });
  });

  group('favourites', () {
    Future<int> addTrack(String path) =>
        db.into(db.tracks).insert(TracksCompanion.insert(path: path));

    test('are stored, restored and removed', () async {
      final a = await addTrack('/a.flac');
      final b = await addTrack('/b.flac');

      final first = await DbFavoritesStore.open(db);
      expect(first.initial, isEmpty);
      first.set(a, favorite: true);
      first.set(b, favorite: true);
      first.set(a, favorite: true); // repeating is harmless
      first.set(b, favorite: false);
      await first.flush();

      final second = await DbFavoritesStore.open(db);
      expect(second.initial, {a});
    });

    test(
      'the controller starts from the saved set and saves toggles',
      () async {
        final a = await addTrack('/a.flac');
        final seed = await DbFavoritesStore.open(db);
        seed.set(a, favorite: true);
        await seed.flush();

        final store = await DbFavoritesStore.open(db);
        final c = ProviderContainer(
          overrides: [favoritesStoreProvider.overrideWithValue(store)],
        );
        addTearDown(c.dispose);
        expect(c.read(favoritesProvider), {a});

        final b = await addTrack('/b.flac');
        c.read(favoritesProvider.notifier)
          ..toggle(_track(b))
          ..toggle(_track(a));
        expect(c.read(favoritesProvider), {b});
        await store.flush();

        expect((await DbFavoritesStore.open(db)).initial, {b});
      },
    );

    test('a favourite whose file left the library is dropped', () async {
      final a = await addTrack('/a.flac');
      final store = await DbFavoritesStore.open(db);
      store.set(a, favorite: true);
      await store.flush();

      await (db.delete(db.tracks)..where((t) => t.id.equals(a))).go();

      expect((await DbFavoritesStore.open(db)).initial, isEmpty);
    });
  });
}
