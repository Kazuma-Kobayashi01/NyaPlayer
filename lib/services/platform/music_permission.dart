import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum MusicAccess {
  granted,

  /// Not granted, but the system will still ask.
  denied,

  /// The system will not ask again; only the app's settings page can fix it.
  permanentlyDenied,
}

/// Read access to the audio files in shared storage (TECH_SPEC §6.1, plan C:
/// only the audio permission). Only Android has such a permission.
abstract class MusicPermission {
  Future<MusicAccess> status();

  /// Shows the system prompt if it can still be shown.
  Future<MusicAccess> request();

  /// Opens the system settings page of this app.
  Future<void> openSettings();
}

/// macOS and everything else: no permission to ask for here. (macOS asks for
/// protected folders such as Documents when the first file is read.)
class NoPermissionNeeded implements MusicPermission {
  const NoPermissionNeeded();

  @override
  Future<MusicAccess> status() async => MusicAccess.granted;

  @override
  Future<MusicAccess> request() async => MusicAccess.granted;

  @override
  Future<void> openSettings() async {}
}

/// Android 13+ (API 33) has `READ_MEDIA_AUDIO`; Android 12 (API 31–32, our
/// minimum) only has `READ_EXTERNAL_STORAGE`. permission_handler treats the
/// audio permission as granted on 12 and refuses the storage one on 13+, so
/// the right one has to be chosen from the system version.
class AndroidMusicPermission implements MusicPermission {
  AndroidMusicPermission({
    Future<int> Function()? sdkInt,
    Future<PermissionStatus> Function(Permission)? check,
    Future<PermissionStatus> Function(Permission)? ask,
    Future<bool> Function()? openAppSettings_,
  }) : _sdkInt = sdkInt ?? _platformSdkInt,
       _check = check ?? ((p) => p.status),
       _ask = ask ?? ((p) => p.request()),
       _openSettings = openAppSettings_ ?? openAppSettings;

  static const _channel = MethodChannel('nyaplayer/platform');
  static Future<int> _platformSdkInt() async =>
      (await _channel.invokeMethod<int>('sdkInt')) ?? 0;

  final Future<int> Function() _sdkInt;
  final Future<PermissionStatus> Function(Permission) _check;
  final Future<PermissionStatus> Function(Permission) _ask;
  final Future<bool> Function() _openSettings;

  static const _firstWithAudioPermission = 33;

  Future<Permission> _permission() async =>
      await _sdkInt() >= _firstWithAudioPermission
      ? Permission.audio
      : Permission.storage;

  static MusicAccess _map(PermissionStatus s) => switch (s) {
    PermissionStatus.granted || PermissionStatus.limited => MusicAccess.granted,
    PermissionStatus.permanentlyDenied => MusicAccess.permanentlyDenied,
    _ => MusicAccess.denied,
  };

  @override
  Future<MusicAccess> status() async => _map(await _check(await _permission()));

  @override
  Future<MusicAccess> request() async => _map(await _ask(await _permission()));

  @override
  Future<void> openSettings() async {
    await _openSettings();
  }
}

final musicPermissionProvider = Provider<MusicPermission>(
  (ref) => Platform.isAndroid
      ? AndroidMusicPermission()
      : const NoPermissionNeeded(),
);
