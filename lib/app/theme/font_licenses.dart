import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the licences of the bundled fonts, of the Rust crates linked into the
/// native library, of Media3 and of the Hi-Res mark to the app's licence page
/// (Flutter's own packages are listed by the framework). It is the single
/// place that names the fonts. HarmonyOS Sans' licence requires a
/// notice in the software and the licence text to travel with the fonts.
void registerFontLicenses() {
  const fonts = <(String, String)>[
    ('HarmonyOS Sans', 'assets/fonts/licenses/HarmonyOS-Sans.txt'),
    ('EB Garamond', 'assets/fonts/licenses/EB-Garamond-OFL.txt'),
    ('Noto Serif SC', 'assets/fonts/licenses/Noto-Serif-SC-OFL.txt'),
  ];
  LicenseRegistry.addLicense(() async* {
    for (final (name, asset) in fonts) {
      final text = await rootBundle.loadString(asset);
      yield LicenseEntryWithLineBreaks([name], text);
    }
  });
  LicenseRegistry.addLicense(rustCrateLicenses);
  LicenseRegistry.addLicense(nativeLicenses);
}

/// Licences of the Rust crates in `libnya_core`, written by
/// `tool/gen_rust_licenses.py`: entries are split by a `=====` line, each is a
/// comma-separated crate list, a blank line and the text.
@visibleForTesting
Stream<LicenseEntry> rustCrateLicenses({AssetBundle? bundle}) async* {
  final all = await (bundle ?? rootBundle).loadString(
    'assets/licenses/rust_crates.txt',
  );
  for (final entry in all.split('\n=====\n')) {
    final split = entry.indexOf('\n\n');
    if (split < 0) continue;
    final names = entry
        .substring(0, split)
        .split(', ')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty);
    yield LicenseEntryWithLineBreaks(
      names.toList(),
      entry.substring(split + 2).trim(),
    );
  }
}

/// Licences that do not come with a package: the Android playback stack and
/// the Hi-Res Audio mark.
@visibleForTesting
Stream<LicenseEntry> nativeLicenses({AssetBundle? bundle}) async* {
  final apache = await (bundle ?? rootBundle).loadString(
    'assets/licenses/Apache-2.0.txt',
  );
  yield LicenseEntryWithLineBreaks(const [
    'AndroidX Media3 (ExoPlayer)',
    'AndroidX libraries',
  ], 'Copyright The Android Open Source Project\n\n$apache');
  yield const LicenseEntryWithLineBreaks(
    ['Apollo (AI super-resolution model)'],
    'The SQ-AI model is Apollo by Kai Li and Yi Luo (Tsinghua University, '
    'Tencent AI Lab): https://github.com/JusperLee/Apollo\n\n'
    'Licensed under Creative Commons Attribution-ShareAlike 4.0 '
    'International (CC BY-SA 4.0): '
    'https://creativecommons.org/licenses/by-sa/4.0/\n\n'
    'It was converted to Core ML for this app; the converted model is '
    'shared under the same licence. What it produces is generated sound, '
    'not the original recording.',
  );
  yield const LicenseEntryWithLineBreaks(
    ['Hi-Res Audio logo'],
    'The Hi-Res Audio logo is a trademark of the Japan Audio Society (JAS). '
    'The image file comes from Wikimedia Commons and is used here only '
    'to mark tracks as high-resolution audio. It is not covered by this '
    "app's MIT licence.",
  );
}
