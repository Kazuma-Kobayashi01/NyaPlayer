import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  _ => l10n.eqPresetCustom,
};

String _bandLabel(int hz) => hz >= 1000 ? '${hz ~/ 1000}k' : '$hz';

class EqualizerPage extends ConsumerWidget {
  const EqualizerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final eq = ref.watch(eqProvider);
    final controller = ref.read(eqProvider.notifier);

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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(l10n.eqPresets, style: theme.textTheme.titleSmall),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
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
                if (eq.presetId == customPresetId)
                  ChoiceChip(
                    label: Text(l10n.eqPresetCustom),
                    selected: true,
                    onSelected: null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (var i = 0; i < eqBandFrequencies.length; i++)
                  Expanded(
                    child: _BandSlider(
                      label: _bandLabel(eqBandFrequencies[i]),
                      gain: eq.gains[i],
                      enabled: eq.enabled,
                      onChanged: (v) => controller.setGain(i, v),
                    ),
                  ),
              ],
            ),
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
        Text(label, style: theme.textTheme.labelMedium),
      ],
    );
  }
}
