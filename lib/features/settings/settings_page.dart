import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nyaplayer/app/window_chrome.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/app/start_page.dart';
import 'package:nyaplayer/app/theme/app_theme.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';
import 'package:nyaplayer/features/now_playing/player_artwork.dart';
import 'package:nyaplayer/features/now_playing/progress_slider.dart';
import 'package:nyaplayer/features/search/library_app_bar.dart';
import 'package:nyaplayer/features/settings/language_dialog.dart';
import 'package:nyaplayer/features/settings/library_folders.dart';
import 'package:nyaplayer/features/settings/min_length_tile.dart';
import 'package:nyaplayer/features/settings/super_resolution_tile.dart';
import 'package:nyaplayer/services/player/playback_core.dart';
import 'package:nyaplayer/features/shared/glass_surface.dart'
    show glassMaterialProvider;
import 'package:nyaplayer/l10n/app_localizations.dart';

const _appVersion = '0.1.0';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key, this.standalone = false});

  final bool standalone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(themeSettingsProvider);
    final controller = ref.read(themeSettingsProvider.notifier);

    final page = Scaffold(
      appBar: standalone
          ? AppBar(title: Text(l10n.navSettings))
          : LibraryAppBar(title: l10n.navSettings, showSearch: false),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              _SectionTitle(l10n.settingsGeneral),
              _Group(
                children: [
                  const _StartPageTile(),
                  if (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.macOS)
                    const _PlaybackCoreTile(),
                ],
              ),
              _SectionTitle(l10n.settingsLibrary),
              const _Group(children: [LibraryFoldersTile(), MinLengthTile()]),
              _SectionTitle(l10n.settingsSuperRes),
              const _Group(children: [SuperResolutionTile()]),
              _SectionTitle(l10n.settingsAppearance),
              _Group(
                children: [
                  _Labeled(
                    label: l10n.settingsThemeMode,
                    child: SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: const Icon(Icons.light_mode_outlined),
                          label: Text(l10n.themeLight),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: const Icon(Icons.dark_mode_outlined),
                          label: Text(l10n.themeDark),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: const Icon(Icons.brightness_auto_outlined),
                          label: Text(l10n.themeSystem),
                        ),
                      ],
                      selected: {settings.mode},
                      onSelectionChanged: (s) => controller.setMode(s.first),
                    ),
                  ),
                  _Labeled(
                    label: l10n.settingsColorSource,
                    hint: l10n.colorSourceHint,
                    child: SegmentedButton<ColorSource>(
                      segments: [
                        ButtonSegment(
                          value: ColorSource.wallpaper,
                          label: Text(l10n.colorSourceWallpaper),
                        ),
                        ButtonSegment(
                          value: ColorSource.fixed,
                          label: Text(l10n.colorSourceFixed),
                        ),
                      ],
                      selected: {settings.source},
                      onSelectionChanged: (s) => controller.setSource(s.first),
                    ),
                  ),
                  if (settings.source == ColorSource.fixed)
                    _Labeled(
                      label: l10n.settingsSeedColor,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final c in seedColorChoices)
                            _SeedSwatch(
                              color: c,
                              selected: settings.seed == c,
                              onTap: () => controller.setSeed(c),
                            ),
                        ],
                      ),
                    ),
                  _Labeled(
                    label: l10n.fontStyle,
                    child: SegmentedButton<AppFont>(
                      segments: [
                        ButtonSegment(
                          value: AppFont.serif,
                          label: Text(l10n.fontSerif),
                        ),
                        ButtonSegment(
                          value: AppFont.sans,
                          label: Text(l10n.fontSans),
                        ),
                      ],
                      selected: {settings.font},
                      onSelectionChanged: (s) => controller.setFont(s.first),
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.text_fields),
                    title: Text(l10n.useBundledFonts),
                    subtitle: Text(l10n.useBundledFontsHint),
                    value: settings.useBundledFonts,
                    onChanged: controller.setUseBundledFonts,
                  ),
                  _Labeled(
                    label: l10n.surfaceMaterial,
                    hint: l10n.surfaceMaterialHint,
                    child: SegmentedButton<SurfaceMaterial>(
                      segments: [
                        ButtonSegment(
                          value: SurfaceMaterial.standard,
                          icon: const Icon(Icons.crop_square),
                          label: Text(l10n.materialStandard),
                        ),
                        ButtonSegment(
                          value: SurfaceMaterial.glass,
                          icon: const Icon(Icons.blur_on),
                          label: Text(l10n.materialGlass),
                        ),
                      ],
                      selected: {settings.material},
                      onSelectionChanged: (s) =>
                          controller.setMaterial(s.first),
                    ),
                  ),
                  const LanguageTile(),
                ],
              ),
              _SectionTitle(l10n.settingsPlayback),
              _Group(
                children: [
                  _Labeled(
                    label: l10n.progressStyle,
                    child: DropdownButton<ProgressStyle>(
                      value: settings.progressStyle,
                      isExpanded: true,
                      items: [
                        for (final style in ProgressStyle.values)
                          DropdownMenuItem(
                            value: style,
                            child: Text(progressStyleLabel(style, l10n)),
                          ),
                      ],
                      onChanged: (style) {
                        if (style != null) controller.setProgressStyle(style);
                      },
                    ),
                  ),
                  _Labeled(
                    label: l10n.playerBackground,
                    hint: l10n.playerBackgroundHint,
                    child: SegmentedButton<PlayerBackgroundStyle>(
                      segments: [
                        ButtonSegment(
                          value: PlayerBackgroundStyle.gradient,
                          label: Text(l10n.backgroundGradient),
                        ),
                        ButtonSegment(
                          value: PlayerBackgroundStyle.blurredCover,
                          label: Text(l10n.backgroundBlurredCover),
                        ),
                      ],
                      selected: {settings.playerBackground},
                      onSelectionChanged: (s) =>
                          controller.setPlayerBackground(s.first),
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.auto_awesome),
                    title: Text(l10n.flowingLight),
                    subtitle: Text(l10n.flowingLightHint),
                    value: settings.flowingLight,
                    onChanged: controller.setFlowingLight,
                  ),
                  _Labeled(
                    label: l10n.coverShape,
                    child: SegmentedButton<CoverShape>(
                      segments: [
                        ButtonSegment(
                          value: CoverShape.square,
                          label: Text(l10n.coverShapeSquare),
                        ),
                        ButtonSegment(
                          value: CoverShape.disc,
                          label: Text(l10n.coverShapeDisc),
                        ),
                        ButtonSegment(
                          value: CoverShape.turntable,
                          label: Text(l10n.coverShapeTurntable),
                        ),
                      ],
                      selected: {ref.watch(coverShapeProvider)},
                      onSelectionChanged: (s) =>
                          ref.read(coverShapeProvider.notifier).set(s.first),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.equalizer),
                    title: Text(l10n.eqTitle),
                    subtitle: Text(l10n.settingsEqualizerSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/equalizer'),
                  ),
                ],
              ),
              if (isMacOS) ...[
                _SectionTitle(l10n.settingsShortcuts),
                _Group(
                  children: [
                    ListTile(
                      title: Text(l10n.navSettings),
                      trailing: const Text('⌘ ,'),
                    ),
                    ListTile(
                      title: Text(l10n.search),
                      trailing: const Text('⌘ F'),
                    ),
                    ListTile(
                      title: Text(l10n.shortcutPlayback),
                      trailing: Text(l10n.shortcutSpace),
                    ),
                    ListTile(
                      title: Text(l10n.shortcutTracks),
                      trailing: const Text('⌘ ← / →'),
                    ),
                    ListTile(
                      title: Text(l10n.shortcutWindow),
                      trailing: const Text('⌃ ⌘ F'),
                    ),
                  ],
                ),
              ],
              _SectionTitle(l10n.settingsAbout),
              _Group(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.aboutVersion),
                    trailing: Text(
                      _appVersion,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.font_download_outlined),
                    title: Text(l10n.aboutFonts),
                    subtitle: Text(l10n.aboutFontsCredit),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(l10n.aboutLicenses),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: l10n.appName,
                      applicationVersion: _appVersion,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.waving_hand_outlined),
                    title: Text(l10n.aboutRerunOnboarding),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/onboarding'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return standalone
        ? CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  context.pop(),
            },
            child: Focus(autofocus: true, child: page),
          )
        : page;
  }
}

String startPageLabel(AppLocalizations l10n, StartPage page) => switch (page) {
  StartPage.songs => l10n.navSongs,
  StartPage.favorites => l10n.navFavorites,
  StartPage.albums => l10n.navAlbums,
  StartPage.artists => l10n.navArtists,
  StartPage.folders => l10n.navFolders,
  StartPage.playlists => l10n.navPlaylists,
};

/// Picks the library page the app opens on.
class _StartPageTile extends ConsumerWidget {
  const _StartPageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(startPageProvider);
    return MenuAnchor(
      alignmentOffset: const Offset(16, 0),
      menuChildren: [
        for (final page in StartPage.values)
          MenuItemButton(
            trailingIcon: page == current ? const Icon(Icons.check) : null,
            onPressed: () => ref.read(startPageProvider.notifier).set(page),
            child: Text(startPageLabel(l10n, page)),
          ),
      ],
      builder: (context, controller, _) => ListTile(
        leading: const Icon(Icons.home_outlined),
        title: Text(l10n.settingsStartPage),
        subtitle: Text(l10n.settingsStartPageHint),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              startPageLabel(l10n, current),
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// Chooses the playback core on Android and macOS (TECH_SPEC §4.7). Takes effect after a
/// restart because the engine is created at startup.
class _PlaybackCoreTile extends ConsumerWidget {
  const _PlaybackCoreTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(playbackCoreProvider);
    String label(PlaybackCore core) => switch (core) {
      PlaybackCore.system => l10n.playbackCoreSystem,
      PlaybackCore.rust => l10n.playbackCoreRust,
    };
    return MenuAnchor(
      alignmentOffset: const Offset(16, 0),
      menuChildren: [
        for (final core in PlaybackCore.values)
          MenuItemButton(
            trailingIcon: core == current ? const Icon(Icons.check) : null,
            onPressed: () => ref.read(playbackCoreProvider.notifier).set(core),
            child: Text(label(core)),
          ),
      ],
      builder: (context, controller, _) => ListTile(
        leading: const Icon(Icons.memory_outlined),
        title: Text(l10n.settingsPlaybackCore),
        subtitle: Text(l10n.settingsPlaybackCoreHint),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label(current),
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Rounded group of settings rows, each row on its own tile separated by a
/// small gap (current Android settings style).
class _Group extends ConsumerWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    // On glass the rows let the light behind the page show through (no blur
    // of their own: the page card already frosts it).
    final glass = ref.watch(glassMaterialProvider);
    return Column(
      children: [
        for (var i = 0; i < children.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
            child: Material(
              color: glass
                  ? scheme.surfaceContainer.withValues(alpha: 0.5)
                  : scheme.surfaceContainer,
              clipBehavior: Clip.antiAlias,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(i == 0 ? 24 : 4),
                bottom: Radius.circular(i == children.length - 1 ? 24 : 4),
              ),
              child: children[i],
            ),
          ),
      ],
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child, this.hint});

  final String label;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}

class _SeedSwatch extends StatelessWidget {
  const _SeedSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final swatch = schemeFromSeed(color.toARGB32(), theme.brightness);
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: AnimatedContainer(
        duration: Durations.short4,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: swatch.primary,
          borderRadius: BorderRadius.circular(selected ? 16 : 24),
          border: Border.all(
            color: selected ? theme.colorScheme.onSurface : swatch.primary,
            width: 2,
          ),
        ),
        child: selected ? Icon(Icons.check, color: swatch.onPrimary) : null,
      ),
    );
  }
}
