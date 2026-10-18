import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/data/repositories/settings_repository.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/platform/notification_permission.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// Asks once, the first time something plays, whether the playback
/// notification may be shown (M4-3). A short explanation comes first, since
/// the system prompt alone does not say why; the answer is never asked for
/// again, and playback works without it either way.
class NotificationPrompt extends ConsumerStatefulWidget {
  const NotificationPrompt({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationPrompt> createState() => _NotificationPromptState();
}

class _NotificationPromptState extends ConsumerState<NotificationPrompt> {
  static const _askedKey = 'android.notificationPromptShown';
  bool _asking = false;

  Future<void> _maybeAsk() async {
    final store = ref.read(settingsStoreProvider);
    if (_asking || store.get(_askedKey) == 'true') return;
    _asking = true;
    try {
      final permission = ref.read(notificationPermissionProvider);
      if (await permission.status() != NotificationAccess.denied) return;
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final allow = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.notificationPermissionTitle),
          content: Text(l10n.notificationPermissionBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.onboardingSkip),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.allow),
            ),
          ],
        ),
      );
      store.put(_askedKey, 'true');
      if (allow ?? false) await permission.request();
    } finally {
      _asking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(queueProvider.select((s) => s.playing), (_, playing) {
      if (playing) _maybeAsk();
    });
    return widget.child;
  }
}
