import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/data/library_filter.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';

/// "30 sec" / "2 min" for the minimum-length setting.
String minLengthLabel(AppLocalizations l10n, int seconds) => seconds < 60
    ? l10n.lengthSeconds(seconds)
    : l10n.lengthMinutes(seconds ~/ 60);

/// Settings row for the shortest track the library shows (LIB-11).
class MinLengthTile extends ConsumerWidget {
  const MinLengthTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final seconds = ref.watch(minTrackDurationProvider).inSeconds;
    return ListTile(
      leading: const Icon(Icons.timer_outlined),
      title: Text(l10n.settingsMinLength),
      subtitle: Text(
        seconds == 0
            ? l10n.minLengthOff
            : l10n.minLengthSummary(minLengthLabel(l10n, seconds)),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final picked = await showDialog<int>(
          context: context,
          builder: (context) => _MinLengthDialog(current: seconds),
        );
        if (picked == null) return;
        ref
            .read(minTrackDurationProvider.notifier)
            .set(Duration(seconds: picked));
      },
    );
  }
}

class _MinLengthDialog extends StatelessWidget {
  const _MinLengthDialog({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final choices = {...minTrackDurationChoices, current}.toList()..sort();
    return AlertDialog(
      title: Text(l10n.settingsMinLength),
      contentPadding: const EdgeInsets.only(top: 12, bottom: 8),
      content: SizedBox(
        width: 320,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final seconds in choices)
              ListTile(
                key: ValueKey('min-length-$seconds'),
                selected: seconds == current,
                title: Text(
                  seconds == 0
                      ? l10n.minLengthOff
                      : minLengthLabel(l10n, seconds),
                ),
                trailing: seconds == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(seconds),
              ),
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
