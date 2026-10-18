import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// The picker could not give back a usable folder (as opposed to the user
/// cancelling, which is an empty result).
class FolderPickException implements Exception {
  const FolderPickException(this.message);

  final String message;

  @override
  String toString() => 'FolderPickException: $message';
}

/// Asks the user for music folders through the system's own dialog. Behind
/// an interface so tests can answer without a native dialog.
abstract class FolderPicker {
  /// The chosen folders; empty when the user cancels.
  Future<List<String>> pickDirectories({
    String? title,
    String? message,
    String? prompt,
  });
}

/// macOS: a native `NSOpenPanel` (see `MainFlutterWindow.swift`), attached to
/// the window as a sheet, several folders at once, starting in ~/Music.
class MacosFolderPicker implements FolderPicker {
  MacosFolderPicker({String? startIn}) : _startIn = startIn ?? _musicFolder();

  static const _channel = MethodChannel('nyaplayer/folders');
  final String? _startIn;

  static String? _musicFolder() {
    final home = Platform.environment['HOME'];
    if (home == null) return null;
    final dir = p.join(home, 'Music');
    return Directory(dir).existsSync() ? dir : null;
  }

  @override
  Future<List<String>> pickDirectories({
    String? title,
    String? message,
    String? prompt,
  }) async {
    try {
      final paths = await _channel.invokeListMethod<String>('pickDirectories', {
        'title': title,
        'message': message,
        'prompt': prompt,
        'initialDirectory': _startIn,
      });
      return paths ?? const [];
    } on PlatformException catch (e) {
      throw FolderPickException(e.message ?? e.code);
    }
  }
}

/// Android: the system folder chooser (Storage Access Framework) through
/// file_picker. The scanner and the Rust core need real file paths, so a
/// choice that cannot be turned into one is refused.
class AndroidFolderPicker implements FolderPicker {
  const AndroidFolderPicker();

  @override
  Future<List<String>> pickDirectories({
    String? title,
    String? message,
    String? prompt,
  }) async {
    final String? path;
    try {
      path = await FilePicker.getDirectoryPath(dialogTitle: title);
    } on PlatformException catch (e) {
      throw FolderPickException(e.message ?? e.code);
    }
    if (path == null) return const [];
    if (!p.isAbsolute(path) || !Directory(path).existsSync()) {
      throw FolderPickException('not a readable folder path: $path');
    }
    return [path];
  }
}

/// Any other platform: file_picker's dialog.
class GenericFolderPicker implements FolderPicker {
  const GenericFolderPicker();

  @override
  Future<List<String>> pickDirectories({
    String? title,
    String? message,
    String? prompt,
  }) async {
    final path = await FilePicker.getDirectoryPath(dialogTitle: title);
    return path == null ? const [] : [path];
  }
}

final folderPickerProvider = Provider<FolderPicker>(
  (ref) => Platform.isMacOS
      ? MacosFolderPicker()
      : Platform.isAndroid
      ? const AndroidFolderPicker()
      : const GenericFolderPicker(),
);
