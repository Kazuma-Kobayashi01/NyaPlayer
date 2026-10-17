import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/app/layout/phone_drawer.dart';
import 'package:nyaplayer/app/window_chrome.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/features/now_playing/now_playing_panel.dart';
import 'package:nyaplayer/features/shared/player_bar.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';

/// At or above this width navigation lives in a permanent sidebar, whatever
/// the orientation.
const sidebarBreakpoint = 840.0;

/// Width of the permanent sidebar.
const sidebarWidth = 280.0;

/// At or above this width (and tall enough) the player moves from the bottom
/// bar into a persistent right-hand panel (UI-05).
const sidePanelBreakpoint = 1100.0;

/// Panels need some height for cover, lyrics lines and controls.
const sidePanelMinHeight = 480.0;

/// Desktop layout (sidebar + docked player) for any landscape window and for
/// any window wide enough; portrait phones keep the drawer layout.
bool useDesktopLayout(Size size) =>
    size.width >= sidebarBreakpoint || size.width > size.height;

/// Right-hand now-playing panel next to the library.
bool useSidePanel(Size size) =>
    size.width > size.height &&
    size.width >= sidePanelBreakpoint &&
    size.height >= sidePanelMinHeight;

/// Corner radius of the rounded content cards of the desktop layout. On macOS
/// it follows the window's own (smaller) corner radius so the cards sit
/// concentrically inside the window.
BorderRadius get desktopCardRadius => BorderRadius.circular(isMacOS ? 12 : 24);

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

  /// Navigation content for the phone drawer ([modal]) or the desktop
  /// sidebar; counts come from the library snapshot.
  Widget _navigation({required bool modal}) {
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
        final destinations = [
          for (var i = 0; i < settingsIndex; i++)
            dest(_destinations[i], counts[i]),
        ];
        final settings = dest(_destinations[settingsIndex]);
        final selected = widget.navigationShell.currentIndex;
        if (modal) {
          return PhoneDrawer(
            destinations: destinations,
            settings: settings,
            selectedIndex: selected,
            onSelect: _select,
          );
        }
        return NavigationPanel(
          destinations: destinations,
          settings: settings,
          selectedIndex: selected,
          onSelect: _select,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (!useDesktopLayout(media.size)) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: _navigation(modal: true),
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

    final showPanel = useSidePanel(media.size);
    // Desktop layout: the sidebar sits on the container colour and the page
    // floats on top of it as a rounded surface, like Google's desktop apps.
    return Scaffold(
      backgroundColor: scheme.surfaceContainer,
      body: ShellScope(
        openNavigation: null,
        child: Row(
          children: [
            // The sidebar starts below the traffic lights (macOS); the cards
            // on the right sit beside them and need no top inset.
            SizedBox(
              width: sidebarWidth,
              child: Padding(
                padding: EdgeInsets.only(top: media.padding.top),
                child: _navigation(modal: false),
              ),
            ),
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        0,
                        8,
                        showPanel ? 8 : 12,
                        // With the panel the page ends above the window edge;
                        // otherwise the floating player bar sits on top of it.
                        8,
                      ),
                      child: ClipRRect(
                        borderRadius: desktopCardRadius,
                        // Pages pad their scrollables by the floating card.
                        child: MediaQuery(
                          data: media.copyWith(
                            padding: media.padding.copyWith(
                              top: 0,
                              bottom: showPanel
                                  ? media.padding.bottom
                                  : PlayerBar.floatingInset - 8,
                            ),
                          ),
                          child: widget.navigationShell,
                        ),
                      ),
                    ),
                  ),
                  if (!showPanel)
                    const Positioned(
                      left: 0,
                      right: 12,
                      bottom: 0,
                      child: PlayerBar(floating: true),
                    ),
                ],
              ),
            ),
            if (showPanel)
              Expanded(
                flex: 8,
                child: MediaQuery(
                  data: media.copyWith(padding: media.padding.copyWith(top: 0)),
                  child: const NowPlayingPanel(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
