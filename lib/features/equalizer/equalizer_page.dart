import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/data/db/database_providers.dart';
import 'package:nyaplayer/features/playlists/playlist_dialogs.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/eq/eq_state.dart';

String _presetName(AppLocalizations l10n, String id) => switch (id) {
  'flat' => l10n.eqPresetFlat,
  'pop' => l10n.eqPresetPop,
  'rock' => l10n.eqPresetRock,
  'jazz' => l10n.eqPresetJazz,
  'classical' => l10n.eqPresetClassical,
  'vocal' => l10n.eqPresetVocal,
  'bassBoost' => l10n.eqPresetBassBoost,
  'trebleBoost' => l10n.eqPresetTrebleBoost,
  'club' => l10n.eqPresetClub,
  'dance' => l10n.eqPresetDance,
  'fullBass' => l10n.eqPresetFullBass,
  'fullBassTreble' => l10n.eqPresetFullBassTreble,
  'fullTreble' => l10n.eqPresetFullTreble,
  'headphones' => l10n.eqPresetHeadphones,
  'largeHall' => l10n.eqPresetLargeHall,
  'live' => l10n.eqPresetLive,
  'party' => l10n.eqPresetParty,
  'reggae' => l10n.eqPresetReggae,
  'ska' => l10n.eqPresetSka,
  'soft' => l10n.eqPresetSoft,
  'softRock' => l10n.eqPresetSoftRock,
  'techno' => l10n.eqPresetTechno,
  'loudness' => l10n.eqPresetLoudness,
  _ => l10n.eqPresetCustom,
};

/// 1600 Hz -> "1.6k", 25 Hz -> "25".
String _bandLabel(int hz) {
  if (hz < 1000) return '$hz';
  final k = hz / 1000;
  return '${k == k.roundToDouble() ? k.round() : k}k';
}

/// Narrowest a band's column may get; on a phone in portrait the 15 bands
/// do not fit and the sliders scroll sideways.
const _minBandWidth = 30.0;

class EqualizerPage extends ConsumerWidget {
  const EqualizerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final eq = ref.watch(eqProvider);
    final controller = ref.read(eqProvider.notifier);
    final saved = ref.watch(savedEqPresetsProvider).value ?? const [];
    final selectedSaved = [
      for (final p in saved)
        if (p.presetId == eq.presetId) p,
    ].firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eqTitle),
        actions: [
          TextButton(onPressed: controller.reset, child: Text(l10n.eqReset)),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SwitchListTile(
            title: Text(l10n.eqEnabled),
            value: eq.enabled,
            onChanged: controller.setEnabled,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.eqPresets,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (selectedSaved != null)
                  PopupMenuButton<String>(
                    tooltip: l10n.moreOptions,
                    onSelected: (action) => _onSavedAction(
                      context,
                      controller,
                      selectedSaved,
                      action,
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
                      PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                    ],
                  ),
                TextButton.icon(
                  onPressed: () => _savePreset(context, controller),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(l10n.eqSavePreset),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // The curve being worked on and the user's own presets come
              // first, so they are in view without scrolling.
              children: [
                if (eq.presetId == customPresetId ||
                    (userPresetIdOf(eq.presetId) != null &&
                        selectedSaved == null))
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(l10n.eqPresetCustom),
                      selected: true,
                      onSelected: null,
                    ),
                  ),
                for (final p in saved)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      key: ValueKey('eq-preset-${p.id}'),
                      label: Text(p.name),
                      selected: eq.presetId == p.presetId,
                      onSelected: eq.enabled
                          ? (_) => controller.selectSaved(p)
                          : null,
                    ),
                  ),
                for (final p in builtinEqPresets)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_presetName(l10n, p.id)),
                      selected: eq.presetId == p.id,
                      onSelected: eq.enabled
                          ? (_) => controller.selectPreset(p.id)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final room = constraints.maxWidth - 16;
              final width = (room / eqBandFrequencies.length).clamp(
                _minBandWidth,
                double.infinity,
              );
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    for (var i = 0; i < eqBandFrequencies.length; i++)
                      SizedBox(
                        width: width,
                        child: _BandSlider(
                          label: _bandLabel(eqBandFrequencies[i]),
                          gain: eq.gains[i],
                          enabled: eq.enabled,
                          onChanged: (v) => controller.setGain(i, v),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            title: Text(l10n.eqPreamp),
            trailing: Text(
              '${eq.preamp.toStringAsFixed(1)} dB',
              style: theme.textTheme.labelLarge,
            ),
          ),
          Slider(
            value: eq.preamp,
            min: -eqMaxGain,
            max: eqMaxGain,
            divisions: 48,
            label: '${eq.preamp.toStringAsFixed(1)} dB',
            onChanged: eq.enabled ? controller.setPreamp : null,
          ),
          SwitchListTile(
            title: Text(l10n.eqAutoClip),
            value: eq.autoPreventClipping,
            onChanged: eq.enabled ? controller.setAutoPreventClipping : null,
          ),
        ],
      ),
    );
  }
}

Future<void> _savePreset(BuildContext context, EqController controller) async {
  final l10n = AppLocalizations.of(context);
  final name = await promptName(
    context,
    title: l10n.eqSavePreset,
    confirmLabel: l10n.save,
    label: l10n.eqPresetName,
  );
  if (name != null) await controller.saveCurrent(name);
}

Future<void> _onSavedAction(
  BuildContext context,
  EqController controller,
  SavedEqPreset preset,
  String action,
) async {
  final l10n = AppLocalizations.of(context);
  if (action == 'rename') {
    final name = await promptName(
      context,
      initial: preset.name,
      title: l10n.rename,
      confirmLabel: l10n.save,
      label: l10n.eqPresetName,
    );
    if (name != null) await controller.renameSaved(preset.id, name);
    return;
  }
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.delete),
      content: Text(l10n.eqDeletePresetBody(preset.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  if (ok ?? false) await controller.deleteSaved(preset.id);
}

class _BandSlider extends StatelessWidget {
  const _BandSlider({
    required this.label,
    required this.gain,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final double gain;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          gain > 0 ? '+${gain.round()}' : '${gain.round()}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(
          height: 220,
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: gain,
              min: -eqMaxGain,
              max: eqMaxGain,
              divisions: 24,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
