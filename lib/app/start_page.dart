import 'package:nyaplayer/data/repositories/settings_repository.dart';
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
  StartPage build() {
    final store = ref.read(settingsStoreProvider);
    listenSelf(
      skipInitial<StartPage>((_, next) => store.put('ui.startPage', next.name)),
    );
    return enumByName(
      StartPage.values,
      store.get('ui.startPage'),
      StartPage.songs,
    );
  }

  void set(StartPage page) => state = page;
}
