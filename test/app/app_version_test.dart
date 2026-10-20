import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/app/app_version.dart';

void main() {
  test('appVersion matches pubspec.yaml and the Rust crate', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final declared = RegExp(
      r'^version:\s*([^\s+]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(declared, appVersion);

    final cargo = File('rust/Cargo.toml').readAsStringSync();
    final crate = RegExp(
      r'^version\s*=\s*"([^"]+)"',
      multiLine: true,
    ).firstMatch(cargo)!.group(1);
    expect(crate, appVersion);
  });

  test('platform label comes from the VM target', () {
    expect(
      platformLabel('3.11 (stable) on "android_arm64"'),
      'Android(armv8a)',
    );
    expect(platformLabel('3.11 (stable) on "android_arm"'), 'Android(armv7a)');
    expect(platformLabel('3.11 (stable) on "macos_arm64"'), 'macOS(arm64)');
    expect(platformLabel('3.11 (stable) on "macos_x64"'), 'macOS(x86_64)');
    expect(platformLabel('3.11 (stable) on "windows_x64"'), 'Windows(x86_64)');
    expect(platformLabel('3.11 (stable) on "linux_arm64"'), 'Linux(arm64)');
  });

  test('version label joins version and platform', () {
    expect(
      appVersionLabel('3.11 (stable) on "android_arm64"'),
      '2.0.0-Android(armv8a)',
    );
    expect(appVersionLabel(), startsWith('$appVersion-'));
  });
}
