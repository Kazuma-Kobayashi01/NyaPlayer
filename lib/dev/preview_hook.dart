import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/app/layout/adaptive_shell.dart';
import 'package:nyaplayer/app/router.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/data/repositories/settings_repository.dart';
import 'package:nyaplayer/features/lyrics/lyrics_settings.dart';
import 'package:nyaplayer/features/now_playing/now_playing_page.dart';
import 'package:nyaplayer/features/now_playing/player_artwork.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// Debug-only: lets a screenshot script put the app in a known state.
///   NYA_PREVIEW=player   start a track and open the full player
///   NYA_PREVIEW=panel    start a track only (desktop side panel)
///   NYA_TRACK=`index`    which sample track (default 0)
///   NYA_SHAPE=disc       use the spinning disc cover
///   NYA_PAUSE=1          start paused
///   NYA_FONT=serif       use the serif font
///   NYA_VOLUME=0..1      engine output volume (e.g. 0 for silent tests)
///   NYA_THEME=light|dark force the theme mode
///   NYA_QUEUE=1          open the queue sheet of the phone player
///   NYA_DRAWER=1         open the phone navigation drawer
///   NYA_LYRICS=center,large,notrans   lyrics display options
///   NYA_ROUTE=/albums    open this page after launch
void applyPreviewEnv(ProviderContainer container) {
  final env = Platform.environment;
  // Forced preview settings must not overwrite the developer's saved ones.
  const settingKeys = ['NYA_SHAPE', 'NYA_FONT', 'NYA_THEME', 'NYA_LYRICS'];
  if (settingKeys.any(env.containsKey)) {
    container.read(settingsStoreProvider).persist = false;
  }
  if (env['NYA_SHAPE'] == 'disc') {
    container.read(coverShapeProvider.notifier).set(CoverShape.disc);
  }
  if (env['NYA_FONT'] == 'serif') {
    container.read(themeSettingsProvider.notifier).setFont(AppFont.serif);
  }
  final volume = double.tryParse(env['NYA_VOLUME'] ?? '');
  if (volume != null) {
    unawaited(container.read(playerEngineProvider).setVolume(volume));
  }
  switch (env['NYA_THEME']) {
    case 'light':
      container.read(themeSettingsProvider.notifier).setMode(ThemeMode.light);
    case 'dark':
      container.read(themeSettingsProvider.notifier).setMode(ThemeMode.dark);
  }
  if (env['NYA_QUEUE'] == '1') debugOpenQueueOnLaunch = true;
  if (env['NYA_DRAWER'] == '1') debugOpenDrawerOnLaunch = true;
  final lyrics = (env['NYA_LYRICS'] ?? '').split(',');
  final lyricsSettings = container.read(lyricsSettingsProvider.notifier);
  if (lyrics.contains('center')) lyricsSettings.setCentered(true);
  if (lyrics.contains('large')) {
    lyricsSettings.setFontSize(22);
  }
  if (lyrics.contains('notrans')) lyricsSettings.setShowTranslation(false);
  final route = env['NYA_ROUTE'];
  if (route != null) {
    Future<void>.delayed(
      const Duration(milliseconds: 400),
      () => container.read(routerProvider).go(route),
    );
  }
  final mode = env['NYA_PREVIEW'];
  if (mode != 'player' && mode != 'panel') return;
  final index = int.tryParse(env['NYA_TRACK'] ?? '') ?? 0;
  Future<void>.delayed(const Duration(milliseconds: 800), () async {
    // Sample data, or the scanned library (wait for the first scan results).
    var tracks = (await container.read(libraryProvider.future)).tracks;
    for (var i = 0; tracks.isEmpty && i < 60; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      tracks = container.read(libraryProvider).value?.tracks ?? const [];
    }
    if (tracks.isEmpty) return;
    await container
        .read(queueProvider.notifier)
        .playTracks(tracks, startIndex: index % tracks.length);
    if (env['NYA_PAUSE'] == '1') {
      await container.read(queueProvider.notifier).togglePlay();
    }
    if (mode == 'player') {
      unawaited(container.read(routerProvider).push('/now-playing'));
    }
  });
}
