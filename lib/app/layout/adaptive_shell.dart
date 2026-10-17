import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/app/layout/phone_drawer.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/features/now_playing/now_playing_panel.dart';
import 'package:nyaplayer/features/shared/player_bar.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';

/// Below this width navigation lives in a modal drawer; at or above it in a
/// permanent sidebar.
const sidebarBreakpoint = 840.0;

/// At or above this width the player moves from the bottom bar into a
/// persistent right-hand panel (UI-05).
const sidePanelBreakpoint = 1200.0;

class _Destination {
  const _Destination(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations l10n) label;
}

/// Order matches the shell branches in the router.
final _destinations = <_Destination>[
  _Destination(Icons.music_note_outlined, Icons.music_note, (l) => l.navSongs),
  _Destination(Icons.favorite_outline, Icons.favorite, (l) => l.navFavorites),
  _Destination(Icons.album_outlined, Icons.album, (l) => l.navAlbums),
  _Destination(Icons.person_outline, Icons.person, (l) => l.navArtists),
  _Destination(Icons.folder_outlined, Icons.folder, (l) => l.navFolders),
  _Destination(
    Icons.queue_music_outlined,
    Icons.queue_music,
    (l) => l.navPlaylists,
  ),
  _Destination(Icons.settings_outlined, Icons.settings, (l) => l.navSettings),
];

/// Lets top-level pages show a menu button that opens the navigation drawer.
/// [openNavigation] is null when the sidebar is permanently visible.
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.openNavigation,
    required super.child,
  });

  final VoidCallback? openNavigation;

  static VoidCallback? openNavigationOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>()?.openNavigation;

  @override
  bool updateShouldNotify(ShellScope oldWidget) =>
      (openNavigation == null) != (oldWidget.openNavigation == null);
}

/// Debug-only (set by the preview hook): open the phone drawer once the
/// shell is first shown, for screenshots.
bool debugOpenDrawerOnLaunch = false;

class AdaptiveShell extends StatefulWidget {
  const AdaptiveShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    if (debugOpenDrawerOnLaunch) {
      debugOpenDrawerOnLaunch = false;
      Future<void>.delayed(
        const Duration(milliseconds: 1500),
        () => _scaffoldKey.currentState?.openDrawer(),
      );
    }
  }

  void _select(int index) {
    _scaffoldKey.currentState?.closeDrawer();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  /// Phone drawer; counts come from the library snapshot.
  Widget _phoneDrawer() {
    return Consumer(
      builder: (context, ref, _) {
        final l10n = AppLocalizations.of(context);
        final library = ref.watch(libraryProvider).value;
        final favorites = ref.watch(favoritesProvider).length;
        final counts = <int?>[
          library?.tracks.length,
          favorites,
          library?.albums.length,
          library?.artists.length,
          library?.folders.length,
          null,
        ];
        DrawerDestination dest(_Destination d, [int? count]) =>
            DrawerDestination(
              icon: d.icon,
              selectedIcon: d.selectedIcon,
              label: d.label(l10n),
              count: count,
            );
        final settingsIndex = _destinations.length - 1;
        return PhoneDrawer(
          destinations: [
            for (var i = 0; i < settingsIndex; i++)
              dest(_destinations[i], counts[i]),
          ],
          settings: dest(_destinations[settingsIndex]),
          selectedIndex: widget.navigationShell.currentIndex,
          onSelect: _select,
        );
      },
    );
  }

  /// Permanent sidebar of the desktop layouts.
  Widget _sidebar() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settingsIndex = _destinations.length - 1;
    NavigationDrawerDestination dest(_Destination d) =>
        NavigationDrawerDestination(
          icon: Icon(d.icon),
          selectedIcon: Icon(d.selectedIcon),
          label: Text(d.label(l10n)),
        );
    return NavigationDrawer(
      selectedIndex: widget.navigationShell.currentIndex,
      onDestinationSelected: _select,
      backgroundColor: theme.colorScheme.surfaceContainer,
      elevation: 0,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 16, 16),
          child: Row(
            children: [
              Icon(Icons.graphic_eq, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  l10n.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
        for (final d in _destinations.take(settingsIndex)) dest(d),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Divider(),
        ),
        dest(_destinations[settingsIndex]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final scheme = Theme.of(context).colorScheme;

    if (width < sidebarBreakpoint) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: _phoneDrawer(),
        body: ShellScope(
          openNavigation: () => _scaffoldKey.currentState?.openDrawer(),
          child: Stack(
            children: [
              // Pages pad their scrollables by the floating card's height.
              MediaQuery(
                data: media.copyWith(
                  padding: media.padding.copyWith(
                    bottom: media.padding.bottom + PlayerBar.floatingInset,
                  ),
                ),
                child: widget.navigationShell,
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: PlayerBar(floating: true),
              ),
            ],
          ),
        ),
      );
    }

    final showPanel = width >= sidePanelBreakpoint;
    // Desktop layout: the sidebar sits on the container colour and the page
    // floats on top of it as a rounded surface, like Google's desktop apps.
    return Scaffold(
      backgroundColor: scheme.surfaceContainer,
      body: ShellScope(
        openNavigation: null,
        child: Row(
          children: [
            SizedBox(width: 220, child: _sidebar()),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 8, showPanel ? 8 : 12, 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: widget.navigationShell,
                      ),
                    ),
                  ),
                  if (!showPanel) const PlayerBar(),
                ],
              ),
            ),
            if (showPanel) const Expanded(flex: 8, child: NowPlayingPanel()),
          ],
        ),
      ),
    );
  }
}
