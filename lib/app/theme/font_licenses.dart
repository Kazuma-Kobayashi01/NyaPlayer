import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the licences of the bundled fonts to the app's licence page, and is
/// the single place that names them. HarmonyOS Sans' licence requires a
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
}
