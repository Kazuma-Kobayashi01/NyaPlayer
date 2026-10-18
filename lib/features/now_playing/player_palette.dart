import 'package:flutter/material.dart';

/// Grey-white colours for the player's buttons and progress bar.
///
/// They are not tinted by the theme colour: this is [ColorScheme.onSurface]
/// with its hue removed, so it stays a neutral near-white on dark themes and
/// a neutral dark grey on light ones, and still comes from the ColorScheme.
@immutable
class PlayerPalette {
  const PlayerPalette._(this.strong, this.soft, this.track);

  factory PlayerPalette.of(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final grey = HSLColor.fromColor(onSurface).withSaturation(0).toColor();
    return PlayerPalette._(
      grey,
      grey.withValues(alpha: 0.6),
      grey.withValues(alpha: 0.22),
    );
  }

  /// Transport buttons, filled progress, buttons that are switched on.
  final Color strong;

  /// Secondary buttons, and toggles that are off.
  final Color soft;

  /// The unfilled part of the progress bar.
  final Color track;

  /// Icon-button colours. A selected button is [strong]; otherwise [strong]
  /// or [soft] depending on [dimWhenOff].
  ButtonStyle iconStyle({bool dimWhenOff = false}) => ButtonStyle(
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.selected) || !dimWhenOff ? strong : soft,
    ),
  );
}
