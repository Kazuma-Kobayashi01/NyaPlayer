import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/app/app.dart';
import 'package:nyaplayer/app/router.dart';
import 'package:nyaplayer/data/db/app_database.dart';
import 'package:nyaplayer/data/db/database_providers.dart';
import 'package:nyaplayer/data/library_filter.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/features/settings/settings_page.dart';
import 'package:nyaplayer/services/eq/eq_state.dart';
import 'package:nyaplayer/services/player/fake_player_engine.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Two frames: a menu or dialog is built one frame after the route settles.
Future<void> advance(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
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

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    engine = FakePlayerEngine(durationOf: (_) => const Duration(minutes: 3));
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
      for (final (title, ms) in [('Jingle', 20000), ('Real song', 200000)]) {
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                path: '/m/$title.flac',
                title: Value(title),
                durationMs: Value(ms),
              ),
            );
      }
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerEngineProvider.overrideWithValue(engine),
          databaseProvider.overrideWithValue(db),
          libraryProvider.overrideWith(
            (ref) => ref
                .watch(libraryRepositoryProvider)
                .watchLibrary(
                  debounce: const Duration(milliseconds: 1),
                  minDuration: ref.watch(minTrackDurationProvider),
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

  testWidgets('short tracks are hidden by default and shown on request', (
    tester,
  ) async {
    final container = await pump(tester);
    container.read(routerProvider).go('/songs');
    await settle(tester);
    expect(find.text('Real song'), findsWidgets);
    expect(find.text('Jingle'), findsNothing);

    container.read(routerProvider).go('/settings');
    await settle(tester);
    // The settings list is lazy; the Android-only playback core tile sits above.
    await tester.scrollUntilVisible(
      find.text('Minimum track length'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(SettingsPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Minimum track length')),
      alignment: 0.5,
    );
    await tester.pump();
    await tester.tap(find.text('Minimum track length'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show all tracks'));
    await settle(tester);
    expect(container.read(minTrackDurationProvider), Duration.zero);

    container.read(routerProvider).go('/songs');
    await settle(tester);
    expect(find.text('Jingle'), findsWidgets);
    await finish(tester);
  });

  testWidgets('the equalizer has 15 bands that scroll on a narrow phone', (
    tester,
  ) async {
    final container = await pump(tester);
    tester.view.physicalSize = const Size(360, 740);
    container.read(routerProvider).go('/equalizer');
    await settle(tester);

    // 15 band sliders and the preamp.
    expect(find.byType(Slider), findsNWidgets(16));
    for (final label in ['25', '160', '1k', '1.6k', '6.3k', '16k']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(tester.takeException(), isNull);

    // Everything fits at 360 dp only by scrolling sideways.
    final scroller = find.byWidgetPredicate(
      (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
    );
    expect(scroller, findsWidgets);
    // The preset row is lazy, so only the first chips are built: Flat leads.
    expect(find.widgetWithText(ChoiceChip, 'Flat'), findsOneWidget);
    await finish(tester);
  });

  // pumpAndSettle never returns on the equalizer page (its sliders keep a
  // frame scheduled), so time is advanced by hand.
  testWidgets('the equalizer saves, renames and deletes a preset', (
    tester,
  ) async {
    final container = await pump(tester);
    container.read(routerProvider).go('/equalizer');
    await settle(tester);

    container.read(eqProvider.notifier).selectPreset('rock');
    await settle(tester);
    await tester.tap(find.text('Save as preset'));
    await advance(tester);
    await tester.enterText(find.byType(TextField), 'My rock');
    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(find.widgetWithText(ChoiceChip, 'My rock'), findsOneWidget);
    expect(userPresetIdOf(container.read(eqProvider).presetId), isNotNull);

    await tester.tap(find.byTooltip('More options'));
    await advance(tester);
    await tester.tap(find.text('Rename'));
    await advance(tester);
    await tester.enterText(find.byType(TextField), 'Loud');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.widgetWithText(ChoiceChip, 'Loud'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'My rock'), findsNothing);

    await tester.tap(find.byTooltip('More options'));
    await advance(tester);
    await tester.tap(find.text('Delete'));
    await advance(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);
    expect(find.widgetWithText(ChoiceChip, 'Loud'), findsNothing);
    // The curve itself stays, now unnamed.
    expect(container.read(eqProvider).presetId, customPresetId);
    expect(container.read(eqProvider).gains[0], 4);
    await finish(tester);
  });
}
