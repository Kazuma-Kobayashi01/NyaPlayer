import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/data/library.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';

/// Resolves [libraryProvider] and handles the loading / error states.
class LibraryBuilder extends ConsumerWidget {
  const LibraryBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, Library library) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    return library.when(
      data: (lib) => builder(context, lib),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text(AppLocalizations.of(context).loadFailed)),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? body;

  /// Optional call to action under the text (hidden in very short panes).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Shrinks in short panes (landscape phones) instead of overflowing.
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 220;
        return Center(
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: compact ? 36 : 64,
                  color: theme.colorScheme.outline,
                ),
                SizedBox(height: compact ? 8 : 16),
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                if (body != null && !compact) ...[
                  const SizedBox(height: 8),
                  Text(
                    body!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (action != null && !compact) ...[
                  const SizedBox(height: 20),
                  action!,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
