import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/data/repositories/settings_repository.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/settings/notification_prompt.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/platform/notification_permission.dart';
import 'package:nyaplayer/services/player/fake_player_engine.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

Track _t(int id) => Track(
  id: id,
  title: 't$id',
  artist: 'a',
  albumId: 1,
  album: 'al',
  trackNo: id,
  duration: const Duration(seconds: 200),
  path: '/m/$id.flac',
  codec: 'FLAC',
  sampleRate: 44100,
  bitDepth: 16,
  bitrateKbps: 900,
  addedAt: DateTime(2026),
  coverSeed: 0xFF6750A4,
);

class _FakePermission implements NotificationPermission {
  _FakePermission(this.current);

  NotificationAccess current;
  int requests = 0;

  @override
  Future<NotificationAccess> status() async => current;

  @override
  Future<NotificationAccess> request() async {
    requests++;
    return current = NotificationAccess.granted;
  }
}

void main() {
  late FakePlayerEngine engine;
  late MemorySettingsStore store;

  setUp(() {
    engine = FakePlayerEngine(
      durationOf: (_) => const Duration(seconds: 200),
      tick: const Duration(milliseconds: 10),
    );
    store = MemorySettingsStore();
  });
  tearDown(() => engine.dispose());

  Future<ProviderContainer> pump(
    WidgetTester tester,
    _FakePermission permission,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerEngineProvider.overrideWithValue(engine),
          settingsStoreProvider.overrideWithValue(store),
          notificationPermissionProvider.overrideWithValue(permission),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: NotificationPrompt(child: Scaffold(body: SizedBox())),
        ),
      ),
    );
    return ProviderScope.containerOf(tester.element(find.byType(Scaffold)));
  }

  testWidgets('explains and asks the first time something plays', (
    tester,
  ) async {
    final permission = _FakePermission(NotificationAccess.denied);
    final container = await pump(tester, permission);
    await tester.runAsync(
      () => container.read(queueProvider.notifier).playTracks([_t(1)]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Show playback controls?'), findsOneWidget);
    expect(permission.requests, 0, reason: 'explained before the system asks');

    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(permission.requests, 1);
    expect(store.get('android.notificationPromptShown'), 'true');
  });

  testWidgets('"Not now" is respected and never asked again', (tester) async {
    final permission = _FakePermission(NotificationAccess.denied);
    final container = await pump(tester, permission);
    final queue = container.read(queueProvider.notifier);
    await tester.runAsync(() => queue.playTracks([_t(1)]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(permission.requests, 0);

    await tester.runAsync(() async {
      await queue.pause();
      await queue.play();
    });
    await tester.pumpAndSettle();
    expect(find.text('Show playback controls?'), findsNothing);
  });

  testWidgets('nothing is asked when it is already granted', (tester) async {
    final permission = _FakePermission(NotificationAccess.granted);
    final container = await pump(tester, permission);
    await tester.runAsync(
      () => container.read(queueProvider.notifier).playTracks([_t(1)]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Show playback controls?'), findsNothing);
  });
}
