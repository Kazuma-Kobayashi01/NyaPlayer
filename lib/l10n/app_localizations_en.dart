// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'NyaPlayer';

  @override
  String get navSongs => 'Songs';

  @override
  String get navAlbums => 'Albums';

  @override
  String get navArtists => 'Artists';

  @override
  String get navFolders => 'Folders';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search songs, albums, artists';

  @override
  String get searchNoResults => 'No results found';

  @override
  String get sectionSongs => 'Songs';

  @override
  String get sectionAlbums => 'Albums';

  @override
  String get sectionArtists => 'Artists';

  @override
  String get moreOptions => 'More options';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortTitle => 'Title';

  @override
  String get sortArtist => 'Artist';

  @override
  String get sortAlbum => 'Album';

  @override
  String get sortAdded => 'Date added';

  @override
  String get sortDuration => 'Duration';

  @override
  String get sortAscending => 'Ascending';

  @override
  String get sortDescending => 'Descending';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
    );
    return '$_temp0';
  }

  @override
  String get playAll => 'Play all';

  @override
  String get shufflePlay => 'Shuffle';

  @override
  String get playNext => 'Play next';

  @override
  String get addToQueue => 'Add to queue';

  @override
  String get songInfo => 'Song info';

  @override
  String get addedToQueue => 'Added to queue';

  @override
  String get willPlayNext => 'Will play next';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get notPlaying => 'Nothing playing';

  @override
  String get notPlayingHint => 'Pick a song from your library to start';

  @override
  String get queue => 'Queue';

  @override
  String get queueEmpty => 'The queue is empty';

  @override
  String get lyrics => 'Lyrics';

  @override
  String get cover => 'Cover';

  @override
  String get noLyrics => 'No lyrics';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get repeatOff => 'Repeat: off';

  @override
  String get repeatAll => 'Repeat: all';

  @override
  String get repeatOne => 'Repeat: one';

  @override
  String get shuffleOn => 'Shuffle: on';

  @override
  String get shuffleOff => 'Shuffle: off';

  @override
  String discLabel(int number) {
    return 'Disc $number';
  }

  @override
  String get infoPath => 'Path';

  @override
  String get infoFormat => 'Format';

  @override
  String get infoSampleRate => 'Sample rate';

  @override
  String get infoBitDepth => 'Bit depth';

  @override
  String get infoBitrate => 'Bitrate';

  @override
  String get infoChannels => 'Channels';

  @override
  String get infoDuration => 'Duration';

  @override
  String get infoYear => 'Year';

  @override
  String get infoGenre => 'Genre';

  @override
  String get infoTrackNo => 'Track';

  @override
  String get infoAlbum => 'Album';

  @override
  String get infoArtist => 'Artist';

  @override
  String bitDepthValue(int bits) {
    return '$bits-bit';
  }

  @override
  String bitrateValue(int kbps) {
    return '$kbps kbps';
  }

  @override
  String get channelsStereo => 'Stereo';

  @override
  String get channelsMono => 'Mono';

  @override
  String get eqTitle => 'Equalizer';

  @override
  String get eqEnabled => 'Enable equalizer';

  @override
  String get eqPresets => 'Presets';

  @override
  String get eqPreamp => 'Preamp';

  @override
  String get eqAutoClip => 'Prevent clipping';

  @override
  String get eqReset => 'Reset';

  @override
  String get eqPresetFlat => 'Flat';

  @override
  String get eqPresetPop => 'Pop';

  @override
  String get eqPresetRock => 'Rock';

  @override
  String get eqPresetJazz => 'Jazz';

  @override
  String get eqPresetClassical => 'Classical';

  @override
  String get eqPresetVocal => 'Vocal';

  @override
  String get eqPresetBassBoost => 'Bass boost';

  @override
  String get eqPresetTrebleBoost => 'Treble boost';

  @override
  String get eqPresetCustom => 'Custom';

  @override
  String get eqNotWired =>
      'This is a UI preview. Audio effects take effect once the playback engine is connected.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeMode => 'Theme mode';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get settingsColorSource => 'Colour source';

  @override
  String get colorSourceCover => 'Album cover';

  @override
  String get colorSourceWallpaper => 'System';

  @override
  String get colorSourceFixed => 'Fixed colour';

  @override
  String get settingsSeedColor => 'Theme colour';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get langSystem => 'System';

  @override
  String get langZh => '简体中文';

  @override
  String get langEn => 'English';

  @override
  String get settingsLibrary => 'Library';

  @override
  String get settingsFolders => 'Music folders';

  @override
  String get settingsAddFolder => 'Add folder';

  @override
  String get settingsRescan => 'Rescan everything';

  @override
  String get rescanStarted => 'Library scan started';

  @override
  String get settingsAbout => 'About';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutLicenses => 'Open-source licenses';

  @override
  String get aboutRerunOnboarding => 'Show welcome screen again';

  @override
  String get onboardingTitle => 'Welcome to NyaPlayer';

  @override
  String get onboardingBody =>
      'A local, ad-free, offline music player. Choose your music folders to start listening.';

  @override
  String get onboardingChoose => 'Choose music folders';

  @override
  String get onboardingSkip => 'Not now';

  @override
  String get playlistsEmptyTitle => 'No playlists yet';

  @override
  String get playlistsEmptyBody => 'Playlists are coming soon.';

  @override
  String get loadFailed => 'Failed to load';

  @override
  String get emptyLibrary => 'Your library is empty';

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get variousArtists => 'Various Artists';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navSettings => 'Settings';

  @override
  String get openNavigation => 'Open navigation menu';

  @override
  String get favorite => 'Favorite';

  @override
  String get unfavorite => 'Remove from favorites';

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptyBody =>
      'Tap ♡ in a song\'s menu or in the player to add it here.';

  @override
  String get settingsPlayback => 'Playback';

  @override
  String get colorSourceHint =>
      '“Album cover” only tints the player; the rest of the app uses system colours.';

  @override
  String get settingsEqualizerSubtitle => '10-band equalizer and presets';

  @override
  String get coverShape => 'Cover style';

  @override
  String get coverShapeSquare => 'Square';

  @override
  String get coverShapeDisc => 'Round (spinning)';

  @override
  String get expandPlayer => 'Expand player';

  @override
  String get collapsePlayer => 'Collapse';

  @override
  String get playerMenu => 'Player menu';

  @override
  String get fontStyle => 'Font';

  @override
  String get fontSerif => 'Serif';

  @override
  String get fontSans => 'Sans';

  @override
  String get lyricsSettings => 'Lyrics settings';

  @override
  String get lyricsFontSize => 'Font size';

  @override
  String get lyricsCentered => 'Center lines';

  @override
  String get lyricsTranslation => 'Show translation';

  @override
  String lyricsFontSizeRange(int min, int max) {
    return '$min–$max';
  }

  @override
  String get lyricsFontSizeInvalid => 'Enter a valid size';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsStartPage => 'Start page';

  @override
  String get settingsStartPageHint => 'The page shown when the app opens';
}
