import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/lyrics/lyrics_settings.dart';
import 'package:nyaplayer/features/now_playing/playback_controls.dart';
import 'package:nyaplayer/features/shared/song_info_sheet.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';

class PlayerMenuItem {
  const PlayerMenuItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  /// Shows a check mark; used for the view that is currently open.
  final bool selected;
}

/// The hamburger button in the top-right corner of every player layout. All
/// secondary actions live in its menu, each with an icon and a text label;
/// the lyrics display options sit in a submenu at the end.
class PlayerMenuButton extends ConsumerWidget {
  const PlayerMenuButton({super.key, required this.items});

  final List<PlayerMenuItem> items;

  /// Equalizer entry, identical on every layout.
  static PlayerMenuItem equalizer(BuildContext context) => PlayerMenuItem(
    icon: Icons.equalizer,
    label: AppLocalizations.of(context).eqTitle,
    onPressed: () => context.push('/equalizer'),
  );

  /// Song info entry, identical on every layout.
  static PlayerMenuItem songInfo(BuildContext context, Track track) =>
      PlayerMenuItem(
        icon: Icons.info_outline,
        label: AppLocalizations.of(context).songInfo,
        onPressed: () => showSongInfo(context, track),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return MenuAnchor(
      menuChildren: [
        for (final item in items)
          MenuItemButton(
            leadingIcon: Icon(item.icon),
            trailingIcon: item.selected ? const Icon(Icons.check) : null,
            onPressed: item.onPressed,
            child: Text(item.label),
          ),
        // The menu is gone by the time an item's onPressed runs, so the
        // dialog is opened from this (still mounted) button's context.
        _LyricsSettingsMenu(
          onEditFontSize: () => showLyricsFontSizeDialog(context, ref),
        ),
      ],
      builder: (context, controller, _) => IconButton(
        tooltip: l10n.playerMenu,
        icon: const Icon(Icons.menu),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// Font size, alignment and translation toggle of the lyrics view.
class _LyricsSettingsMenu extends ConsumerWidget {
  const _LyricsSettingsMenu({required this.onEditFontSize});

  final VoidCallback onEditFontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(lyricsSettingsProvider);
    final controller = ref.read(lyricsSettingsProvider.notifier);
    return SubmenuButton(
      leadingIcon: const Icon(Icons.text_fields),
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.format_size),
          onPressed: onEditFontSize,
          child: Text(
            '${l10n.lyricsFontSize} · ${formatFontSize(settings.fontSize)} pt',
          ),
        ),
        const Divider(height: 1),
        MenuItemButton(
          closeOnActivate: false,
          leadingIcon: Icon(
            settings.centered
                ? Icons.format_align_center
                : Icons.format_align_left,
          ),
          trailingIcon: settings.centered ? const Icon(Icons.check) : null,
          onPressed: () => controller.setCentered(!settings.centered),
          child: Text(l10n.lyricsCentered),
        ),
        MenuItemButton(
          closeOnActivate: false,
          leadingIcon: const Icon(Icons.translate),
          trailingIcon: settings.showTranslation
              ? const Icon(Icons.check)
              : null,
          onPressed: () =>
              controller.setShowTranslation(!settings.showTranslation),
          child: Text(l10n.lyricsTranslation),
        ),
      ],
      child: Text(l10n.lyricsSettings),
    );
  }
}

String formatFontSize(double size) =>
    size == size.roundToDouble() ? '${size.round()}' : size.toStringAsFixed(1);

/// Number input for the lyrics font size, with -/+ steppers.
Future<void> showLyricsFontSizeDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (context) => _LyricsFontSizeDialog(
      initial: ref.read(lyricsSettingsProvider).fontSize,
      onApply: ref.read(lyricsSettingsProvider.notifier).setFontSize,
    ),
  );
}

class _LyricsFontSizeDialog extends StatefulWidget {
  const _LyricsFontSizeDialog({required this.initial, required this.onApply});

  final double initial;
  final ValueChanged<double> onApply;

  @override
  State<_LyricsFontSizeDialog> createState() => _LyricsFontSizeDialogState();
}

class _LyricsFontSizeDialogState extends State<_LyricsFontSizeDialog> {
  late final _text = TextEditingController(
    text: formatFontSize(widget.initial),
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  double? get _value {
    final v = double.tryParse(_text.text.trim());
    if (v == null ||
        v < LyricsSettings.minFontSize ||
        v > LyricsSettings.maxFontSize) {
      return null;
    }
    return v;
  }

  void _step(double delta) {
    final next = ((_value ?? widget.initial) + delta).clamp(
      LyricsSettings.minFontSize,
      LyricsSettings.maxFontSize,
    );
    setState(() => _text.text = formatFontSize(next));
  }

  void _apply() {
    final v = _value;
    if (v == null) return;
    widget.onApply(v);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final valid = _value != null;
    return AlertDialog(
      icon: const Icon(Icons.format_size),
      title: Text(l10n.lyricsFontSize),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: IconButton.filledTonal(
              tooltip: '-1',
              icon: const Icon(Icons.remove),
              onPressed: () => _step(-1),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 112,
            child: TextField(
              controller: _text,
              autofocus: true,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixText: 'pt',
                helperText: l10n.lyricsFontSizeRange(
                  LyricsSettings.minFontSize.round(),
                  LyricsSettings.maxFontSize.round(),
                ),
                errorText: valid ? null : l10n.lyricsFontSizeInvalid,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _apply(),
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: IconButton.filledTonal(
              tooltip: '+1',
              icon: const Icon(Icons.add),
              onPressed: () => _step(1),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: valid ? _apply : null,
          child: Text(material.okButtonLabel),
        ),
      ],
    );
  }
}

enum PlayerView { lyrics, queue }

/// Connected lyrics / queue toggle shown next to the menu button on desktop
/// layouts. With [allowNone], tapping the selected segment again clears it
/// (the side panel then goes back to the cover).
class LyricsQueueToggle extends StatelessWidget {
  const LyricsQueueToggle({
    super.key,
    required this.selected,
    required this.onChanged,
    this.allowNone = false,
  });

  final PlayerView? selected;
  final ValueChanged<PlayerView?> onChanged;
  final bool allowNone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<PlayerView>(
      segments: [
        ButtonSegment(
          value: PlayerView.lyrics,
          icon: const Icon(Icons.lyrics_outlined),
          tooltip: l10n.lyrics,
        ),
        ButtonSegment(
          value: PlayerView.queue,
          icon: const Icon(Icons.queue_music),
          tooltip: l10n.queue,
        ),
      ],
      selected: {?selected},
      emptySelectionAllowed: allowNone,
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onSelectionChanged: (s) => onChanged(s.isEmpty ? null : s.first),
    );
  }
}

/// Transport row of the desktop players: favourite at the far left, the
/// menu (and, in the immersive player, the lyrics / queue toggle) at the far
/// right.
class PlayerControlsRow extends StatelessWidget {
  const PlayerControlsRow({
    super.key,
    required this.track,
    required this.transport,
    required this.menuItems,
    this.toggle,
  });

  final Track track;
  final Widget transport;
  final Widget? toggle;
  final List<PlayerMenuItem> menuItems;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FavoriteButton(track: track),
        const SizedBox(width: 8),
        // Scales down in narrow panels instead of overflowing.
        Expanded(
          child: FittedBox(fit: BoxFit.scaleDown, child: transport),
        ),
        const SizedBox(width: 8),
        if (toggle case final toggle?) ...[toggle, const SizedBox(width: 4)],
        PlayerMenuButton(items: menuItems),
      ],
    );
  }
}
