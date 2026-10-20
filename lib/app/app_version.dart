import 'dart:io';

/// Release version. Keep in step with `pubspec.yaml` (a test checks this).
const appVersion = '2.0.0';

/// Platform and CPU architecture of this build, e.g. `Android(armv8a)` or
/// `macOS(arm64)`. Read from the Dart VM's target triple so no plugin is
/// needed: `Platform.version` ends with `on "macos_arm64"`.
String platformLabel([String? vmVersion]) {
  final match = RegExp(r'on "([a-z]+)_([a-z0-9]+)"')
      .firstMatch(vmVersion ?? Platform.version);
  if (match == null) return Platform.operatingSystem;
  final os = switch (match.group(1)) {
    'android' => 'Android',
    'macos' => 'macOS',
    'ios' => 'iOS',
    'windows' => 'Windows',
    'linux' => 'Linux',
    final other => other!,
  };
  final arch = switch ((match.group(1), match.group(2))) {
    ('android', 'arm64') => 'armv8a',
    ('android', 'arm') => 'armv7a',
    (_, 'x64') => 'x86_64',
    (_, 'ia32') => 'x86',
    (_, final other) => other!,
  };
  return '$os($arch)';
}

/// What the About page shows: `2.0.0-Android(armv8a)`.
String appVersionLabel([String? vmVersion]) =>
    '$appVersion-${platformLabel(vmVersion)}';
