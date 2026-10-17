import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/app/start_page.dart';
import 'package:nyaplayer/app/theme/app_theme.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';
import 'package:nyaplayer/features/now_playing/player_artwork.dart';
import 'package:nyaplayer/features/search/library_app_bar.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';

const _appVersion = '0.1.0';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(themeSettingsProvider);
    final controller = ref.read(themeSettingsProvider.notifier);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: LibraryAppBar(title: l10n.navSettings, showSearch: false),
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
              const _Group(children: [_StartPageTile()]),
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
                          value: ColorSource.cover,
                          label: Text(l10n.colorSourceCover),
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
                  _Labeled(
                    label: l10n.settingsLanguage,
                    child: SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'system',
                          label: Text(l10n.langSystem),
                        ),
                        ButtonSegment(value: 'zh', label: Text(l10n.langZh)),
                        ButtonSegment(value: 'en', label: Text(l10n.langEn)),
                      ],
                      selected: {locale?.languageCode ?? 'system'},
                      onSelectionChanged: (s) => ref
                          .read(localeProvider.notifier)
                          .set(s.first == 'system' ? null : Locale(s.first)),
                    ),
                  ),
                ],
              ),
              _SectionTitle(l10n.settingsPlayback),
              _Group(
                children: [
                  _Labeled(
                    label: l10n.coverShape,
                    child: SegmentedButton<CoverShape>(
                      segments: [
                        ButtonSegment(
                          value: CoverShape.square,
                          icon: const Icon(Icons.crop_square),
                          label: Text(l10n.coverShapeSquare),
                        ),
                        ButtonSegment(
                          value: CoverShape.disc,
                          icon: const Icon(Icons.album),
                          label: Text(l10n.coverShapeDisc),
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
              _SectionTitle(l10n.settingsLibrary),
              _Group(
                children: [
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(l10n.settingsFolders),
                    subtitle: const Text('/Music'),
                    trailing: IconButton(
                      tooltip: l10n.settingsAddFolder,
                      icon: const Icon(Icons.add),
                      onPressed: () {},
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: Text(l10n.settingsRescan),
                    onTap: () => ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(l10n.rescanStarted)),
                      ),
                  ),
                ],
              ),
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
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var i = 0; i < children.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
            child: Material(
              color: scheme.surfaceContainer,
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
