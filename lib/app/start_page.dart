import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Library page shown when the app starts (SET-07).
enum StartPage {
  songs('/songs'),
  favorites('/favorites'),
  albums('/albums'),
  artists('/artists'),
  folders('/folders'),
  playlists('/playlists');

  const StartPage(this.path);

  final String path;
}

final startPageProvider = NotifierProvider<StartPageController, StartPage>(
  StartPageController.new,
);

class StartPageController extends Notifier<StartPage> {
  @override
  StartPage build() => StartPage.songs;

  void set(StartPage page) => state = page;
}
