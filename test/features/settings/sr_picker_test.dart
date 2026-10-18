import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/data/db/database_providers.dart';
import 'package:nyaplayer/data/library.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/settings/sr_picker_page.dart';
import 'package:nyaplayer/features/settings/super_resolution_tile.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/sr/super_resolution.dart';

Track _track(int id, String title, {String codec = 'MP3', int kbps = 320}) =>
    Track(
      id: id,
      title: title,
      artist: 'Artist $id',
      albumId: 1,
      album: 'Album',
      trackNo: id,
      duration: const Duration(minutes: 3),
      path: '/m/$title.${codec.toLowerCase()}',
      codec: codec,
      sampleRate: 44100,
      bitDepth: 16,
      bitrateKbps: kbps,
      addedAt: DateTime(2026),
      coverSeed: 0xFF6750A4,
    );

class _Backend implements SrBackend {
  final events$ = StreamController<SrEvent>.broadcast();
  final converted = <String>[];

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> convert({
    required int job,
    required String source,
    required String destination,
  }) async => converted.add(source);

  @override
  Future<void> cancel(int job) async {}

  @override
  Stream<SrEvent> get events => events$.stream;
}

class _NoScan extends ScanController {
  @override
  Future<void> scan() async {}
}

/// A waiting job shows an endless progress bar, so the page never settles:
/// move time on by hand instead of pumpAndSettle.
Future<void> _advance(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// The conversion exists on the desktop only.
final _desktop = TargetPlatformVariant.only(TargetPlatform.macOS);

void main() {
  late _Backend backend;

  Future<void> pump(WidgetTester tester, List<Track> tracks) async {
    backend = _Backend();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: SingleChildScrollView(child: SuperResolutionTile()),
          ),
        ),
        GoRoute(path: '/sr-picker', builder: (_, _) => const SrPickerPage()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          srBackendProvider.overrideWithValue(backend),
          srCopyTagsProvider.overrideWithValue((_, _) async {}),
          scanProvider.overrideWith(_NoScan.new),
          libraryProvider.overrideWith(
            (ref) => Stream.value(Library(tracks: tracks, albums: const [])),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Choose songs…'));
    await _advance(tester);
  }

  test('only MP3 can become SQ-AI', () {
    expect(canBecomeSqAi(_track(1, 'a')), isTrue);
    expect(canBecomeSqAi(_track(1, 'a', codec: 'FLAC')), isFalse);
    expect(canBecomeSqAi(_track(1, 'a', codec: 'mp3')), isTrue, reason: 'case');
  });

  testWidgets(
    'the picker lists the library MP3s only, by title',
    variant: _desktop,
    (tester) async {
      await pump(tester, [
        _track(1, 'Zebra'),
        _track(2, 'Lossless', codec: 'FLAC'),
        _track(3, 'Apple', kbps: 128),
      ]);
      await openPicker(tester);
      expect(find.text('MP3 songs to convert'), findsOneWidget);
      expect(find.text('Lossless'), findsNothing);
      expect(find.text('128 kbps'), findsOneWidget);
      final apple = tester.getTopLeft(find.text('Apple')).dy;
      final zebra = tester.getTopLeft(find.text('Zebra')).dy;
      expect(apple, lessThan(zebra));
      // Nothing chosen: the button is off.
      final button = find.widgetWithText(FilledButton, 'Convert 0');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
    },
  );

  testWidgets(
    'choosing songs converts them and returns to the settings',
    variant: _desktop,
    (tester) async {
      await pump(tester, [
        _track(1, 'One'),
        _track(2, 'Two'),
        _track(3, 'Three'),
      ]);
      await openPicker(tester);
      await tester.tap(find.byKey(const ValueKey('sr-pick-1')));
      await tester.tap(find.byKey(const ValueKey('sr-pick-3')));
      await tester.pump();
      expect(find.widgetWithText(FilledButton, 'Convert 2'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Convert 2'));
      await _advance(tester);

      expect(backend.converted, ['/m/One.mp3', '/m/Three.mp3']);
      expect(
        find.byType(SrPickerPage),
        findsNothing,
        reason: 'back on the settings',
      );
      expect(find.text('One.mp3'), findsOneWidget);
      expect(find.text('Three.mp3'), findsOneWidget);
      expect(find.text('Two.mp3'), findsNothing);
    },
  );

  testWidgets(
    'select all and clear; songs already converting are not offered',
    variant: _desktop,
    (tester) async {
      await pump(tester, [_track(1, 'One'), _track(2, 'Two')]);
      await openPicker(tester);
      await tester.tap(find.text('Select all'));
      await tester.pump();
      expect(find.widgetWithText(FilledButton, 'Convert 2'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pump();
      expect(find.widgetWithText(FilledButton, 'Convert 0'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('sr-pick-1')));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Convert 1'));
      await _advance(tester);
      await openPicker(tester);
      expect(
        find.byKey(const ValueKey('sr-pick-1')),
        findsNothing,
        reason: 'in progress',
      );
      expect(find.byKey(const ValueKey('sr-pick-2')), findsOneWidget);
    },
  );

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets(
      'on a ${platform.name} device the row is there but switched off',
      variant: TargetPlatformVariant.only(platform),
      (tester) async {
        await pump(tester, [_track(1, 'One')]);
        expect(find.text('AI super-resolution (SQ-AI)'), findsOneWidget);
        expect(
          find.text('Desktop only. Not available on phones and tablets.'),
          findsOneWidget,
        );
        final button = find.widgetWithText(FilledButton, 'Choose songs…');
        expect(tester.widget<FilledButton>(button).onPressed, isNull);
        // Even a tap does nothing: no picker, nothing queued.
        await tester.tap(button, warnIfMissed: false);
        await _advance(tester);
        expect(find.byType(SrPickerPage), findsNothing);
        expect(backend.converted, isEmpty);
        expect(
          find.text('The AI model is not installed in this build.'),
          findsNothing,
        );
      },
    );
  }

  testWidgets('a library without MP3s says so', variant: _desktop, (
    tester,
  ) async {
    await pump(tester, [_track(1, 'Lossless', codec: 'FLAC')]);
    await openPicker(tester);
    expect(
      find.text('No MP3 songs to convert in your library.'),
      findsOneWidget,
    );
    expect(find.text('Select all'), findsNothing);
  });
}
