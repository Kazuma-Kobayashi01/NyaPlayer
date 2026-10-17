import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';

/// One entry of the phone navigation drawer.
class DrawerDestination {
  const DrawerDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.count,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Optional number shown at the end of the row (e.g. song count).
  final int? count;
}

/// Colour pair of a destination's round icon badge. Taken from the scheme's
/// container roles so the drawer is colourful but always on-palette.
typedef _Tone = (Color background, Color foreground);

/// Modal navigation drawer of the phone layout.
class PhoneDrawer extends StatelessWidget {
  const PhoneDrawer({
    super.key,
    required this.destinations,
    required this.settings,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<DrawerDestination> destinations;
  final DrawerDestination settings;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 304,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        child: NavigationPanel(
          destinations: destinations,
          settings: settings,
          selectedIndex: selectedIndex,
          onSelect: onSelect,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

/// Navigation content shared by the phone drawer and the permanent desktop
/// sidebar: a header card with quick actions, the library pages in one
/// rounded card and settings in another. Colours come from the scheme.
class NavigationPanel extends ConsumerWidget {
  const NavigationPanel({
    super.key,
    required this.destinations,
    required this.settings,
    required this.selectedIndex,
    required this.onSelect,
    this.onClose,
  });

  /// Library pages, in shell branch order.
  final List<DrawerDestination> destinations;

  /// Settings entry; its branch index is `destinations.length`.
  final DrawerDestination settings;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  /// Called before a quick action navigates away; closes the drawer. Null for
  /// the permanent sidebar.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = dark
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainerLowest;
    final tones = <_Tone>[
      (scheme.primaryContainer, scheme.onPrimaryContainer),
      (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      (scheme.secondaryContainer, scheme.onSecondaryContainer),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      children: [
        _Card(
          color: card,
          child: _Header(onClose: onClose),
        ),
        const SizedBox(height: 12),
        _Card(
          color: card,
          child: Column(
            children: [
              for (var i = 0; i < destinations.length; i++)
                _Tile(
                  destination: destinations[i],
                  tone: tones[i % tones.length],
                  selected: i == selectedIndex,
                  onTap: () => onSelect(i),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          color: card,
          child: _Tile(
            destination: settings,
            tone: (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
            selected: selectedIndex == destinations.length,
            onTap: () => onSelect(destinations.length),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(6), child: child),
    );
  }
}

/// App name, library size and three quick actions.
class _Header extends ConsumerWidget {
  const _Header({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = ref.watch(libraryProvider).value?.tracks.length;
    final dark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.graphic_eq, color: scheme.onPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (count != null)
                      Text(
                        l10n.songCount(count),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _QuickAction(
                icon: dark ? Icons.light_mode : Icons.dark_mode,
                label: dark ? l10n.themeLight : l10n.themeDark,
                tone: (scheme.tertiaryContainer, scheme.onTertiaryContainer),
                onTap: () => ref
                    .read(themeSettingsProvider.notifier)
                    .setMode(dark ? ThemeMode.light : ThemeMode.dark),
              ),
              _QuickAction(
                icon: Icons.play_circle,
                label: l10n.nowPlaying,
                tone: (scheme.primaryContainer, scheme.onPrimaryContainer),
                onTap: () {
                  onClose?.call();
                  context.push('/now-playing');
                },
              ),
              _QuickAction(
                icon: Icons.equalizer,
                label: l10n.eqTitle,
                tone: (scheme.secondaryContainer, scheme.onSecondaryContainer),
                onTap: () {
                  onClose?.call();
                  context.push('/equalizer');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final _Tone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 40,
                decoration: BoxDecoration(
                  color: tone.$1,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 22, color: tone.$2),
              ),
              const SizedBox(height: 6),
              // Shrinks a little instead of truncating ("Now playing").
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.destination,
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final DrawerDestination destination;
  final _Tone tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = destination.count;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 10),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected ? scheme.primary : tone.$1,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 20,
                    color: selected ? scheme.onPrimary : tone.$2,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? scheme.onSecondaryContainer
                          : scheme.onSurface,
                    ),
                  ),
                ),
                if (count != null)
                  Text(
                    '$count',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: selected
                          ? scheme.onSecondaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
