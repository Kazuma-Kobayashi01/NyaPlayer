import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';

/// First-launch guide (LIB-01). Folder picking is wired up in M2.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () => context.go('/songs'),
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
