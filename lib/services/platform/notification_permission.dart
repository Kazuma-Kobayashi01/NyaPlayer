import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum NotificationAccess {
  granted,

  /// Not granted, but the system will still ask.
  denied,

  /// The system will not ask again; only the app's settings page can fix it.
  permanentlyDenied,
}

/// Permission to show the playback notification and lock-screen controls
/// (SYS-02, M4-3). Only Android 13+ has a runtime permission for it.
abstract class NotificationPermission {
  Future<NotificationAccess> status();

  /// Shows the system prompt if it can still be shown.
  Future<NotificationAccess> request();
}

/// Everything but Android: nothing to ask for.
class NoNotificationPermissionNeeded implements NotificationPermission {
  const NoNotificationPermissionNeeded();

  @override
  Future<NotificationAccess> status() async => NotificationAccess.granted;

  @override
  Future<NotificationAccess> request() async => NotificationAccess.granted;
}

/// permission_handler reports the permission as granted below Android 13,
/// where notifications need no runtime permission.
class AndroidNotificationPermission implements NotificationPermission {
  AndroidNotificationPermission({
    Future<PermissionStatus> Function()? check,
    Future<PermissionStatus> Function()? ask,
  }) : _check = check ?? (() => Permission.notification.status),
       _ask = ask ?? (() => Permission.notification.request());

  final Future<PermissionStatus> Function() _check;
  final Future<PermissionStatus> Function() _ask;

  static NotificationAccess _map(PermissionStatus s) => switch (s) {
    PermissionStatus.granted ||
    PermissionStatus.limited ||
    PermissionStatus.provisional => NotificationAccess.granted,
    PermissionStatus.permanentlyDenied => NotificationAccess.permanentlyDenied,
    _ => NotificationAccess.denied,
  };

  @override
  Future<NotificationAccess> status() async => _map(await _check());

  @override
  Future<NotificationAccess> request() async => _map(await _ask());
}

final notificationPermissionProvider = Provider<NotificationPermission>(
  (ref) => Platform.isAndroid
      ? AndroidNotificationPermission()
      : const NoNotificationPermissionNeeded(),
);
