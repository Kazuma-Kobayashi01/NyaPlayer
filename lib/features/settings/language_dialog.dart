import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/l10n/language_options.dart';

/// The settings row: shows the current language and opens the chooser.
class LanguageTile extends ConsumerWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = languageOptionOfLocale(ref.watch(localeProvider));
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.settingsLanguage),
      subtitle: Text(current?.label ?? l10n.langSystem),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showLanguageDialog(context, ref),
    );
  }
}

/// Pop-up language chooser: "follow the system" on top, then every language
/// by its own name, sorted by English name. Picking one applies it at once.
Future<void> showLanguageDialog(BuildContext context, WidgetRef ref) async {
  final picked = await showDialog<String>(
    context: context,
    builder: (context) => const _LanguageDialog(),
  );
  if (picked == null) return;
  ref.read(localeProvider.notifier).set(localeOfId(picked));
}

class _LanguageDialog extends ConsumerWidget {
  const _LanguageDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentId = idOfLocale(ref.watch(localeProvider));

    Widget row(String id, String label) => ListTile(
      key: ValueKey('language-$id'),
      selected: id == currentId,
      title: Text(label),
      trailing: id == currentId ? const Icon(Icons.check) : null,
      onTap: () => Navigator.of(context).pop(id),
    );

    return AlertDialog(
      title: Text(l10n.settingsLanguage),
      contentPadding: const EdgeInsets.only(top: 12, bottom: 8),
      content: SizedBox(
        width: 360,
        child: ListView(
          shrinkWrap: true,
          children: [
            row(systemLanguageId, l10n.langSystem),
            const Divider(height: 1),
            for (final option in languageOptions) row(option.id, option.label),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
