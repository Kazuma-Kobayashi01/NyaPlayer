import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/app/layout/adaptive_shell.dart';
import 'package:nyaplayer/app/start_page.dart';
import 'package:nyaplayer/features/album/album_detail_page.dart';
import 'package:nyaplayer/features/album/albums_page.dart';
import 'package:nyaplayer/features/artist/artists_page.dart';
import 'package:nyaplayer/features/equalizer/equalizer_page.dart';
import 'package:nyaplayer/features/folder/folders_page.dart';
import 'package:nyaplayer/features/library/favorites_page.dart';
import 'package:nyaplayer/features/library/playlists_page.dart';
import 'package:nyaplayer/features/library/playlist_detail_page.dart';
import 'package:nyaplayer/features/library/songs_page.dart';
import 'package:nyaplayer/features/now_playing/now_playing_page.dart';
import 'package:nyaplayer/features/queue/queue_list.dart';
import 'package:nyaplayer/features/settings/onboarding_page.dart';
import 'package:nyaplayer/features/settings/settings_page.dart';
import 'package:nyaplayer/features/settings/sr_picker_page.dart';

/// Full-screen routes slide up over the shell on phones and fade/zoom in on
/// wide windows.
CustomTransitionPage<void> _slideUp(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Durations.long2,
    reverseTransitionDuration: Durations.medium3,
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Easing.emphasizedDecelerate,
        reverseCurve: Easing.emphasizedAccelerate,
      );
      if (useDesktopLayout(MediaQuery.sizeOf(context))) {
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      }
      return SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(),
);

/// True on first launch, before any scan location exists (LIB-01).
final needsOnboardingProvider = Provider<bool>((ref) => false);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: ref.watch(rootNavigatorKeyProvider),
    // Read once: changing the setting applies from the next launch.
    initialLocation: ref.read(needsOnboardingProvider)
        ? '/onboarding'
        : ref.read(startPageProvider).path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            AdaptiveShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/songs', builder: (_, _) => const SongsPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (_, _) => const FavoritesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/albums',
                builder: (_, _) => const AlbumsPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => AlbumDetailPage(
                      albumId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/artists',
                builder: (_, _) => const ArtistsPage(),
                routes: [
                  GoRoute(
                    path: ':name',
                    builder: (_, state) =>
                        ArtistDetailPage(name: state.pathParameters['name']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/folders',
                builder: (_, _) => const FoldersPage(),
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (_, state) => FolderDetailPage(
                      path: state.uri.queryParameters['path'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/playlists',
                builder: (_, _) => const PlaylistsPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => PlaylistDetailPage(
                      playlistId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/now-playing',
        pageBuilder: (_, state) => _slideUp(state, const NowPlayingPage()),
      ),
      GoRoute(
        path: '/queue',
        pageBuilder: (_, state) => _slideUp(state, const QueuePage()),
      ),
      GoRoute(
        path: '/preferences',
        builder: (_, _) => const SettingsPage(standalone: true),
      ),
      GoRoute(path: '/equalizer', builder: (_, _) => const EqualizerPage()),
      GoRoute(path: '/sr-picker', builder: (_, _) => const SrPickerPage()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
    ],
  );
});
