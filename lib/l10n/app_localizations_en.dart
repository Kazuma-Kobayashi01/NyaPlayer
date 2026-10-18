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
  String get showAppWindow => 'Show NyaPlayer';

  @override
  String get quitApp => 'Quit NyaPlayer';

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
  String get nowPlaying => 'Playing';

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
  String get eqPresetClub => 'Club';

  @override
  String get eqPresetDance => 'Dance';

  @override
  String get eqPresetFullBass => 'Full bass';

  @override
  String get eqPresetFullBassTreble => 'Full bass & treble';

  @override
  String get eqPresetFullTreble => 'Full treble';

  @override
  String get eqPresetHeadphones => 'Headphones';

  @override
  String get eqPresetLargeHall => 'Large hall';

  @override
  String get eqPresetLive => 'Live';

  @override
  String get eqPresetParty => 'Party';

  @override
  String get eqPresetReggae => 'Reggae';

  @override
  String get eqPresetSka => 'Ska';

  @override
  String get eqPresetSoft => 'Soft';

  @override
  String get eqPresetSoftRock => 'Soft rock';

  @override
  String get eqPresetTechno => 'Techno';

  @override
  String get eqPresetLoudness => 'Loudness';

  @override
  String get eqPresetCustom => 'Custom';

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
  String get settingsColorSource => 'Color source';

  @override
  String get colorSourceWallpaper => 'System';

  @override
  String get colorSourceFixed => 'Fixed color';

  @override
  String get settingsSeedColor => 'Theme color';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get langSystem => 'System';

  @override
  String get settingsLibrary => 'Library';

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
  String get playlistsEmptyBody =>
      'Tap the button to create one, then add songs from any song\'s menu.';

  @override
  String get loadFailed => 'Failed to load';

  @override
  String get emptyLibrary => 'Your library is empty';

  @override
  String get variousArtists => 'Various artists';

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
      'Use system colors or a fixed theme color. Player backgrounds are configured separately.';

  @override
  String get settingsEqualizerSubtitle => '10-band equalizer and presets';

  @override
  String get coverShape => 'Cover style';

  @override
  String get coverShapeSquare => 'Square';

  @override
  String get coverShapeDisc => 'Round (spinning)';

  @override
  String get coverShapeTurntable => 'Turntable';

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

  @override
  String get playerBackground => 'Player background';

  @override
  String get progressStyle => 'Progress bar style';

  @override
  String get progressMaterial => 'Material';

  @override
  String get progressClassic => 'Classic dot';

  @override
  String get progressSlim => 'Slim line';

  @override
  String get progressWave => 'Wave';

  @override
  String get backgroundGradient => 'Theme gradient';

  @override
  String get backgroundBlurredCover => 'Blurred cover';

  @override
  String get playerBackgroundHint =>
      'Enlarge and blur the album cover for an immersive backdrop.';

  @override
  String get settingsShortcuts => 'Keyboard shortcuts';

  @override
  String get shortcutPlayback => 'Play / pause';

  @override
  String get shortcutSpace => 'Space';

  @override
  String get shortcutTracks => 'Previous / next track';

  @override
  String get shortcutWindow => 'Enter / exit full screen';

  @override
  String get lyricsLineHeight => 'Line spacing';

  @override
  String get lyricsLineHeightInvalid => 'Enter a value between 1 and 2';

  @override
  String get newPlaylist => 'New playlist';

  @override
  String get playlistName => 'Playlist name';

  @override
  String get playlistNameHint => 'e.g. Commute';

  @override
  String get create => 'Create';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get removeFromPlaylist => 'Remove from this playlist';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String addedToPlaylist(String name) {
    return 'Added to “$name”';
  }

  @override
  String get deletePlaylistTitle => 'Delete playlist?';

  @override
  String deletePlaylistBody(String name) {
    return '“$name” will be deleted. Your song files are not touched.';
  }

  @override
  String get playlistEmpty => 'This playlist is empty';

  @override
  String get playlistEmptyBody =>
      'Choose “Add to playlist” in any song\'s menu.';

  @override
  String playlistTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String get reorder => 'Drag to reorder';

  @override
  String get libraryFolders => 'Music folders';

  @override
  String get libraryFoldersHint =>
      'FLAC and MP3 files in these folders are scanned recursively.';

  @override
  String get libraryNoFolders => 'No music folders yet';

  @override
  String get addFolder => 'Add folder';

  @override
  String get excludeFolder => 'Exclude folder';

  @override
  String get excludedTag => 'Excluded';

  @override
  String get removeFolder => 'Remove this folder';

  @override
  String get folderAlreadyAdded => 'That folder is already in the list';

  @override
  String get rescan => 'Rescan';

  @override
  String get scanWalking => 'Looking for music files…';

  @override
  String scanReading(int done, int total) {
    return 'Reading tags $done / $total';
  }

  @override
  String get scanFinishing => 'Tidying up the library…';

  @override
  String get scanDone => 'Scan finished';

  @override
  String scanDoneWithErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return 'Scan finished; tags of $_temp0 could not be read';
  }

  @override
  String get scanFailed => 'Scan failed';

  @override
  String get emptyLibraryBody =>
      'Add a music folder and your songs will show up here.';

  @override
  String get useBundledFonts => 'Use built-in fonts';

  @override
  String get useBundledFontsHint =>
      'Sans uses HarmonyOS Sans; serif uses EB Garamond and Noto Serif SC. Turn off to use the system fonts.';

  @override
  String get aboutFonts => 'Fonts';

  @override
  String get aboutFontsCredit =>
      'HarmonyOS Sans (© Huawei Device Co., Ltd.), EB Garamond and Noto Serif SC (SIL OFL)';

  @override
  String get pickFolderMessage =>
      'Choose folders that contain music (FLAC, MP3). You can pick several.';

  @override
  String get pickExcludeMessage => 'Choose folders to skip when scanning.';

  @override
  String get folderNotUsable =>
      'That folder cannot be read. Please choose another location.';

  @override
  String get folderPickFailed => 'Could not open the folder chooser';

  @override
  String get musicPermissionTitle => 'Permission to read music';

  @override
  String get musicPermissionBody =>
      'NyaPlayer only reads audio files in the folders you choose, on this device, and never goes online. Allow access to music and audio, or the library cannot be scanned.';

  @override
  String get musicPermissionSettings => 'Open system settings';

  @override
  String get settingsMinLength => 'Minimum track length';

  @override
  String get minLengthOff => 'Show all tracks';

  @override
  String minLengthSummary(String duration) {
    return 'Hide tracks shorter than $duration';
  }

  @override
  String lengthSeconds(int count) {
    return '$count sec';
  }

  @override
  String lengthMinutes(int count) {
    return '$count min';
  }

  @override
  String get eqSavePreset => 'Save as preset';

  @override
  String get eqPresetName => 'Preset name';

  @override
  String eqDeletePresetBody(String name) {
    return 'Delete preset “$name”?';
  }

  @override
  String get notificationPermissionTitle => 'Show playback controls?';

  @override
  String get notificationPermissionBody =>
      'Allow notifications to control playback from the notification shade and lock screen. Playback works either way.';

  @override
  String get allow => 'Allow';

  @override
  String get flowingLight => 'Flowing light background';

  @override
  String get flowingLightHint =>
      'Soft coloured light sits on the player background, taking its colours from the cover and moving to a new spot with each song. Hi-Res songs get a touch of gold.';

  @override
  String get surfaceMaterial => 'Material';

  @override
  String get materialStandard => 'Standard';

  @override
  String get materialGlass => 'Premium glass';

  @override
  String get surfaceMaterialHint =>
      'Premium glass turns the sidebar, cards, player bar and drawer into translucent frosted glass over a soft coloured light. Uses more power.';

  @override
  String get settingsPlaybackCore => 'Playback core';

  @override
  String get settingsPlaybackCoreHint =>
      'System decoding (Media3) or the Rust core. Restart the app to apply.';

  @override
  String get playbackCoreSystem => 'System (Media3)';

  @override
  String get playbackCoreRust => 'Rust core';

  @override
  String get settingsSuperRes => 'AI super-resolution (SQ-AI)';

  @override
  String get settingsSuperResHint =>
      'Turns lossy MP3 files into FLAC with an AI model on this Mac’s GPU. The MP3 stays; the new file is saved beside it as “name.SQ-AI.flac”. It is generated sound, not the original recording. Takes roughly half the song’s length.';

  @override
  String get srModelMissing => 'The AI model is not installed in this build.';

  @override
  String get srChooseFiles => 'Choose songs…';

  @override
  String get srClearFinished => 'Clear finished';

  @override
  String get srWaiting => 'Waiting';

  @override
  String get srDone => 'Done';

  @override
  String get srCancelled => 'Cancelled';

  @override
  String get srExists => 'Already converted';

  @override
  String srFailed(String message) {
    return 'Failed: $message';
  }

  @override
  String get srPickerTitle => 'MP3 songs to convert';

  @override
  String get srPickerEmpty => 'No MP3 songs to convert in your library.';

  @override
  String srConvertSelected(int count) {
    return 'Convert $count';
  }

  @override
  String get srSelectAll => 'Select all';

  @override
  String get srSelectNone => 'Clear';

  @override
  String get srDesktopOnly =>
      'Desktop only. Not available on phones and tablets.';
}

/// The translations for English, as used in the United Kingdom (`en_GB`).
class AppLocalizationsEnGb extends AppLocalizationsEn {
  AppLocalizationsEnGb() : super('en_GB');

  @override
  String get eqTitle => 'Equaliser';

  @override
  String get eqEnabled => 'Enable equaliser';

  @override
  String get settingsColorSource => 'Colour source';

  @override
  String get colorSourceFixed => 'Fixed colour';

  @override
  String get settingsSeedColor => 'Theme colour';

  @override
  String get navFavorites => 'Favourites';

  @override
  String get favorite => 'Favourite';

  @override
  String get unfavorite => 'Remove from favourites';

  @override
  String get favoritesEmptyTitle => 'No favourites yet';

  @override
  String get colorSourceHint =>
      'Use system colours or a fixed theme colour. Player backgrounds are configured separately.';

  @override
  String get settingsEqualizerSubtitle => '10-band equaliser and presets';

  @override
  String get lyricsCentered => 'Centre lines';

  @override
  String get settingsPlaybackCore => 'Playback core';

  @override
  String get settingsPlaybackCoreHint =>
      'System decoding (Media3) or the Rust core. Restart the app to apply.';

  @override
  String get playbackCoreSystem => 'System (Media3)';

  @override
  String get playbackCoreRust => 'Rust core';
}
