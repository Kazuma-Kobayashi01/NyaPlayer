import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/services/platform/folder_picker.dart';
import 'package:nyaplayer/services/platform/music_permission.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AndroidMusicPermission', () {
    late List<Permission> asked;
    late List<Permission> checked;
    var settingsOpened = 0;

    AndroidMusicPermission make({
      required int sdk,
      PermissionStatus status = PermissionStatus.denied,
      PermissionStatus answer = PermissionStatus.granted,
    }) {
      asked = [];
      checked = [];
      settingsOpened = 0;
      return AndroidMusicPermission(
        sdkInt: () async => sdk,
        check: (p) async {
          checked.add(p);
          return status;
        },
        ask: (p) async {
          asked.add(p);
          return answer;
        },
        openAppSettings_: () async {
          settingsOpened++;
          return true;
        },
      );
    }

    test('Android 13+ uses the audio permission', () async {
      final permission = make(sdk: 33);
      await permission.status();
      await permission.request();
      expect(checked, [Permission.audio]);
      expect(asked, [Permission.audio]);
      expect(await make(sdk: 35).request(), MusicAccess.granted);
    });

    test('Android 12 (API 31, 32) uses the storage permission', () async {
      for (final sdk in [31, 32]) {
        final permission = make(sdk: sdk);
        await permission.status();
        await permission.request();
        expect(checked, [Permission.storage], reason: 'API $sdk');
        expect(asked, [Permission.storage], reason: 'API $sdk');
      }
    });

    test('statuses are mapped', () async {
      Future<MusicAccess> status(PermissionStatus s) =>
          make(sdk: 34, status: s).status();
      expect(await status(PermissionStatus.granted), MusicAccess.granted);
      expect(await status(PermissionStatus.limited), MusicAccess.granted);
      expect(await status(PermissionStatus.denied), MusicAccess.denied);
      expect(await status(PermissionStatus.restricted), MusicAccess.denied);
      expect(
        await status(PermissionStatus.permanentlyDenied),
        MusicAccess.permanentlyDenied,
      );
      expect(
        await make(
          sdk: 34,
          answer: PermissionStatus.permanentlyDenied,
        ).request(),
        MusicAccess.permanentlyDenied,
      );
    });

    test('settings can be opened', () async {
      final permission = make(sdk: 34);
      await permission.openSettings();
      expect(settingsOpened, 1);
    });
  });

  test('platforms without a permission are always granted', () async {
    const permission = NoPermissionNeeded();
    expect(await permission.status(), MusicAccess.granted);
    expect(await permission.request(), MusicAccess.granted);
  });

  group('MacosFolderPicker', () {
    const channel = MethodChannel('nyaplayer/folders');
    late List<MethodCall> calls;

    void answer(Future<Object?> Function(MethodCall) handler) {
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) {
            calls.add(call);
            return handler(call);
          });
    }

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test(
      'passes the texts and start folder; returns every chosen folder',
      () async {
        answer((_) async => ['/Users/me/Music/A', '/Volumes/Disk/B']);
        final picker = MacosFolderPicker(startIn: '/Users/me/Music');

        final paths = await picker.pickDirectories(
          title: 'Add folder',
          message: 'Choose music',
          prompt: 'Add',
        );

        expect(paths, ['/Users/me/Music/A', '/Volumes/Disk/B']);
        expect(calls.single.method, 'pickDirectories');
        expect(calls.single.arguments, {
          'title': 'Add folder',
          'message': 'Choose music',
          'prompt': 'Add',
          'initialDirectory': '/Users/me/Music',
        });
      },
    );

    test('cancelling gives an empty list', () async {
      answer((_) async => <String>[]);
      expect(await MacosFolderPicker(startIn: '/x').pickDirectories(), isEmpty);
      answer((_) async => null);
      expect(await MacosFolderPicker(startIn: '/x').pickDirectories(), isEmpty);
    });

    test('a native error becomes a FolderPickException', () async {
      answer((_) async => throw PlatformException(code: 'boom', message: 'no'));
      expect(
        MacosFolderPicker(startIn: '/x').pickDirectories(),
        throwsA(isA<FolderPickException>()),
      );
    });
  });
}
