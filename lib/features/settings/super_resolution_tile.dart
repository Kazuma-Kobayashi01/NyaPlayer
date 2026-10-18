import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/sr/super_resolution.dart';
import 'package:path/path.dart' as p;

/// Settings: turn MP3s into SQ-AI FLACs with the on-device AI model.
class SuperResolutionTile extends ConsumerWidget {
  const SuperResolutionTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(superResolutionProvider);
    final controller = ref.read(superResolutionProvider.notifier);
    // Desktop only: on a phone or tablet the row stays but is switched off.
    final mobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final available = !mobile && state.available == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          enabled: !mobile,
          leading: const Icon(Icons.auto_awesome_outlined),
          title: Text(l10n.settingsSuperRes),
          subtitle: Text(
            mobile
                ? l10n.srDesktopOnly
                : state.available == false
                ? l10n.srModelMissing
                : l10n.settingsSuperResHint,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: available ? () => context.push('/sr-picker') : null,
                icon: const Icon(Icons.library_music_outlined),
                label: Text(l10n.srChooseFiles),
              ),
              const SizedBox(width: 8),
              if (state.jobs.isNotEmpty && !state.busy)
                TextButton(
                  onPressed: controller.clearFinished,
                  child: Text(l10n.srClearFinished),
                ),
            ],
          ),
        ),
        if (!mobile)
          for (final job in state.jobs)
            _JobRow(
              key: ValueKey('sr-job-${job.id}'),
              job: job,
              onCancel: () => controller.cancel(job.id),
              theme: theme,
            ),
      ],
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({
    super.key,
    required this.job,
    required this.onCancel,
    required this.theme,
  });

  final SrJob job;
  final VoidCallback onCancel;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = switch (job.status) {
      SrStatus.waiting => l10n.srWaiting,
      SrStatus.running => '${(job.fraction * 100).round()}%',
      SrStatus.done => l10n.srDone,
      SrStatus.failed => l10n.srFailed(job.message ?? ''),
      SrStatus.cancelled => l10n.srCancelled,
      SrStatus.exists => l10n.srExists,
    };
    final failed = job.status == SrStatus.failed;
    return ListTile(
      dense: true,
      title: Text(
        p.basename(job.source),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (job.active)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: LinearProgressIndicator(
                value: job.status == SrStatus.running ? job.fraction : null,
              ),
            ),
          Text(
            status,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: failed ? theme.colorScheme.error : null),
          ),
        ],
      ),
      trailing: job.active
          ? IconButton(
              tooltip: l10n.cancel,
              icon: const Icon(Icons.close),
              onPressed: onCancel,
            )
          : null,
    );
  }
}
