import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/features/settings/library_folders.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';

/// First-launch guide (LIB-01): pick the first music folder.
class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.library_music,
                    size: 96,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.onboardingTitle,
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.onboardingBody,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () async {
                      final router = GoRouter.of(context);
                      if (await addLibraryFolder(context, ref)) {
                        router.go('/songs');
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: Text(l10n.onboardingChoose),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/songs'),
                    child: Text(l10n.onboardingSkip),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
