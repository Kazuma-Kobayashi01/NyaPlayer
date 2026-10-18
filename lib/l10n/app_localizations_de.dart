// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'NyaPlayer';

  @override
  String get showAppWindow => 'NyaPlayer anzeigen';

  @override
  String get quitApp => 'NyaPlayer beenden';

  @override
  String get navSongs => 'Titel';

  @override
  String get navAlbums => 'Alben';

  @override
  String get navArtists => 'Interpreten';

  @override
  String get navFolders => 'Ordner';

  @override
  String get navPlaylists => 'Wiedergabelisten';

  @override
  String get search => 'Suchen';

  @override
  String get searchHint => 'Titel, Alben, Interpreten suchen';

  @override
  String get searchNoResults => 'Keine Ergebnisse';

  @override
  String get sectionSongs => 'Titel';

  @override
  String get sectionAlbums => 'Alben';

  @override
  String get sectionArtists => 'Interpreten';

  @override
  String get moreOptions => 'Weitere Optionen';

  @override
  String get sortTitle => 'Titel';

  @override
  String get sortArtist => 'Interpret';

  @override
  String get sortAlbum => 'Album';

  @override
  String get sortAdded => 'Hinzugefügt am';

  @override
  String get sortDuration => 'Dauer';

  @override
  String get sortAscending => 'Aufsteigend';

  @override
  String get sortDescending => 'Absteigend';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel',
      one: '1 Titel',
    );
    return '$_temp0';
  }

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Alben',
      one: '1 Album',
    );
    return '$_temp0';
  }

  @override
  String get playAll => 'Alle abspielen';

  @override
  String get shufflePlay => 'Zufällig';

  @override
  String get playNext => 'Als Nächstes abspielen';

  @override
  String get addToQueue => 'Zur Warteschlange hinzufügen';

  @override
  String get songInfo => 'Titelinfo';

  @override
  String get addedToQueue => 'Zur Warteschlange hinzugefügt';

  @override
  String get willPlayNext => 'Wird als Nächstes abgespielt';

  @override
  String get nowPlaying => 'Wiedergabe';

  @override
  String get notPlaying => 'Keine Wiedergabe';

  @override
  String get notPlayingHint =>
      'Wähle einen Titel aus deiner Bibliothek, um zu starten';

  @override
  String get queue => 'Warteschlange';

  @override
  String get queueEmpty => 'Die Warteschlange ist leer';

  @override
  String get lyrics => 'Songtext';

  @override
  String get cover => 'Cover';

  @override
  String get noLyrics => 'Kein Songtext';

  @override
  String get close => 'Schließen';

  @override
  String get back => 'Zurück';

  @override
  String get play => 'Wiedergabe';

  @override
  String get pause => 'Pause';

  @override
  String get previous => 'Zurück';

  @override
  String get next => 'Weiter';

  @override
  String get repeatOff => 'Wiederholen: aus';

  @override
  String get repeatAll => 'Wiederholen: alle';

  @override
  String get repeatOne => 'Wiederholen: ein Titel';

  @override
  String get shuffleOn => 'Zufall: an';

  @override
  String get shuffleOff => 'Zufall: aus';

  @override
  String discLabel(int number) {
    return 'Disc $number';
  }

  @override
  String get infoPath => 'Pfad';

  @override
  String get infoFormat => 'Format';

  @override
  String get infoSampleRate => 'Abtastrate';

  @override
  String get infoBitDepth => 'Bittiefe';

  @override
  String get infoBitrate => 'Bitrate';

  @override
  String get infoChannels => 'Kanäle';

  @override
  String get infoDuration => 'Dauer';

  @override
  String get infoYear => 'Jahr';

  @override
  String get infoGenre => 'Genre';

  @override
  String get infoTrackNo => 'Titelnummer';

  @override
  String get infoAlbum => 'Album';

  @override
  String get infoArtist => 'Interpret';

  @override
  String bitDepthValue(int bits) {
    return '$bits Bit';
  }

  @override
  String bitrateValue(int kbps) {
    return '$kbps kbit/s';
  }

  @override
  String get channelsStereo => 'Stereo';

  @override
  String get channelsMono => 'Mono';

  @override
  String get eqTitle => 'Equalizer';

  @override
  String get eqEnabled => 'Equalizer aktivieren';

  @override
  String get eqPresets => 'Voreinstellungen';

  @override
  String get eqPreamp => 'Vorverstärkung';

  @override
  String get eqAutoClip => 'Übersteuerung vermeiden';

  @override
  String get eqReset => 'Zurücksetzen';

  @override
  String get eqPresetFlat => 'Linear';

  @override
  String get eqPresetPop => 'Pop';

  @override
  String get eqPresetRock => 'Rock';

  @override
  String get eqPresetJazz => 'Jazz';

  @override
  String get eqPresetClassical => 'Klassik';

  @override
  String get eqPresetVocal => 'Gesang';

  @override
  String get eqPresetBassBoost => 'Bassverstärkung';

  @override
  String get eqPresetTrebleBoost => 'Höhenverstärkung';

  @override
  String get eqPresetCustom => 'Benutzerdefiniert';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsThemeMode => 'Designmodus';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeSystem => 'System';

  @override
  String get settingsColorSource => 'Farbquelle';

  @override
  String get colorSourceWallpaper => 'System';

  @override
  String get colorSourceFixed => 'Feste Farbe';

  @override
  String get settingsSeedColor => 'Designfarbe';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get langSystem => 'System';

  @override
  String get settingsLibrary => 'Bibliothek';

  @override
  String get settingsAbout => 'Über';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutLicenses => 'Open-Source-Lizenzen';

  @override
  String get aboutRerunOnboarding => 'Willkommensbildschirm erneut anzeigen';

  @override
  String get onboardingTitle => 'Willkommen bei NyaPlayer';

  @override
  String get onboardingBody =>
      'Ein lokaler, werbefreier Offline-Musikplayer. Wähle deine Musikordner, um loszulegen.';

  @override
  String get onboardingChoose => 'Musikordner auswählen';

  @override
  String get onboardingSkip => 'Später';

  @override
  String get playlistsEmptyTitle => 'Noch keine Wiedergabelisten';

  @override
  String get playlistsEmptyBody =>
      'Tippe auf die Schaltfläche, um eine zu erstellen, und füge dann Titel über deren Menü hinzu.';

  @override
  String get loadFailed => 'Laden fehlgeschlagen';

  @override
  String get emptyLibrary => 'Deine Bibliothek ist leer';

  @override
  String get variousArtists => 'Verschiedene Interpreten';

  @override
  String get navFavorites => 'Favoriten';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get openNavigation => 'Navigationsmenü öffnen';

  @override
  String get favorite => 'Zu Favoriten hinzufügen';

  @override
  String get unfavorite => 'Aus Favoriten entfernen';

  @override
  String get favoritesEmptyTitle => 'Noch keine Favoriten';

  @override
  String get favoritesEmptyBody =>
      'Tippe im Menü eines Titels oder im Player auf ♡, um ihn hier hinzuzufügen.';

  @override
  String get settingsPlayback => 'Wiedergabe';

  @override
  String get colorSourceHint =>
      'Systemfarben oder eine feste Designfarbe verwenden. Der Player-Hintergrund wird separat eingestellt.';

  @override
  String get settingsEqualizerSubtitle =>
      '10-Band-Equalizer und Voreinstellungen';

  @override
  String get coverShape => 'Cover-Stil';

  @override
  String get coverShapeSquare => 'Quadratisch';

  @override
  String get coverShapeDisc => 'Rund (rotierend)';

  @override
  String get coverShapeTurntable => 'Plattenspieler';

  @override
  String get expandPlayer => 'Player vergrößern';

  @override
  String get collapsePlayer => 'Einklappen';

  @override
  String get playerMenu => 'Player-Menü';

  @override
  String get fontStyle => 'Schrift';

  @override
  String get fontSerif => 'Serif';

  @override
  String get fontSans => 'Sans';

  @override
  String get lyricsSettings => 'Songtext-Einstellungen';

  @override
  String get lyricsFontSize => 'Schriftgröße';

  @override
  String get lyricsCentered => 'Zeilen zentrieren';

  @override
  String get lyricsTranslation => 'Übersetzung anzeigen';

  @override
  String lyricsFontSizeRange(int min, int max) {
    return '$min–$max';
  }

  @override
  String get lyricsFontSizeInvalid => 'Gib eine gültige Größe ein';

  @override
  String get settingsGeneral => 'Allgemein';

  @override
  String get settingsStartPage => 'Startseite';

  @override
  String get settingsStartPageHint =>
      'Die Seite, die beim Öffnen der App angezeigt wird';

  @override
  String get playerBackground => 'Player-Hintergrund';

  @override
  String get progressStyle => 'Stil der Fortschrittsleiste';

  @override
  String get progressMaterial => 'Material';

  @override
  String get progressClassic => 'Klassischer Punkt';

  @override
  String get progressSlim => 'Dünne Linie';

  @override
  String get progressWave => 'Welle';

  @override
  String get backgroundGradient => 'Designverlauf';

  @override
  String get backgroundBlurredCover => 'Unscharfes Cover';

  @override
  String get playerBackgroundHint =>
      'Vergrößert das Albumcover und macht es stark unscharf – für einen immersiven Hintergrund.';

  @override
  String get settingsShortcuts => 'Tastenkürzel';

  @override
  String get shortcutPlayback => 'Wiedergabe / Pause';

  @override
  String get shortcutSpace => 'Leertaste';

  @override
  String get shortcutTracks => 'Vorheriger / nächster Titel';

  @override
  String get shortcutWindow => 'Vollbild ein / aus';

  @override
  String get lyricsLineHeight => 'Zeilenabstand';

  @override
  String get lyricsLineHeightInvalid => 'Gib einen Wert zwischen 1 und 2 ein';

  @override
  String get newPlaylist => 'Neue Wiedergabeliste';

  @override
  String get playlistName => 'Name der Wiedergabeliste';

  @override
  String get playlistNameHint => 'z. B. Arbeitsweg';

  @override
  String get create => 'Erstellen';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get delete => 'Löschen';

  @override
  String get remove => 'Entfernen';

  @override
  String get removeFromPlaylist => 'Aus dieser Wiedergabeliste entfernen';

  @override
  String get addToPlaylist => 'Zur Wiedergabeliste hinzufügen';

  @override
  String addedToPlaylist(String name) {
    return 'Zu „$name“ hinzugefügt';
  }

  @override
  String get deletePlaylistTitle => 'Wiedergabeliste löschen?';

  @override
  String deletePlaylistBody(String name) {
    return '„$name“ wird gelöscht. Deine Musikdateien bleiben unberührt.';
  }

  @override
  String get playlistEmpty => 'Diese Wiedergabeliste ist leer';

  @override
  String get playlistEmptyBody =>
      'Wähle im Menü eines Titels „Zur Wiedergabeliste hinzufügen“.';

  @override
  String playlistTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel',
      one: '1 Titel',
    );
    return '$_temp0';
  }

  @override
  String get reorder => 'Zum Umsortieren ziehen';

  @override
  String get libraryFolders => 'Musikordner';

  @override
  String get libraryFoldersHint =>
      'FLAC- und MP3-Dateien in diesen Ordnern werden rekursiv durchsucht.';

  @override
  String get libraryNoFolders => 'Noch keine Musikordner';

  @override
  String get addFolder => 'Ordner hinzufügen';

  @override
  String get excludeFolder => 'Ordner ausschließen';

  @override
  String get excludedTag => 'Ausgeschlossen';

  @override
  String get removeFolder => 'Diesen Ordner entfernen';

  @override
  String get folderAlreadyAdded => 'Dieser Ordner ist bereits in der Liste';

  @override
  String get rescan => 'Erneut durchsuchen';

  @override
  String get scanWalking => 'Musikdateien werden gesucht …';

  @override
  String scanReading(int done, int total) {
    return 'Tags werden gelesen $done / $total';
  }

  @override
  String get scanFinishing => 'Bibliothek wird aufgeräumt …';

  @override
  String get scanDone => 'Suche abgeschlossen';

  @override
  String scanDoneWithErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien',
      one: '1 Datei',
    );
    return 'Suche abgeschlossen; die Tags von $_temp0 konnten nicht gelesen werden';
  }

  @override
  String get scanFailed => 'Suche fehlgeschlagen';

  @override
  String get emptyLibraryBody =>
      'Füge einen Musikordner hinzu, dann erscheinen deine Titel hier.';

  @override
  String get useBundledFonts => 'Integrierte Schriften verwenden';

  @override
  String get useBundledFontsHint =>
      'Sans verwendet HarmonyOS Sans, Serif verwendet EB Garamond und Noto Serif SC. Ausschalten, um die Systemschriften zu verwenden.';

  @override
  String get aboutFonts => 'Schriften';

  @override
  String get aboutFontsCredit =>
      'HarmonyOS Sans (© Huawei Device Co., Ltd.), EB Garamond und Noto Serif SC (SIL OFL)';

  @override
  String get pickFolderMessage =>
      'Wähle Ordner mit Musik (FLAC, MP3). Du kannst mehrere auswählen.';

  @override
  String get pickExcludeMessage =>
      'Wähle Ordner, die beim Durchsuchen übersprungen werden.';

  @override
  String get folderNotUsable =>
      'Dieser Ordner kann nicht gelesen werden. Bitte wähle einen anderen Ort.';

  @override
  String get folderPickFailed =>
      'Die Ordnerauswahl konnte nicht geöffnet werden';

  @override
  String get musicPermissionTitle => 'Berechtigung zum Lesen von Musik';

  @override
  String get musicPermissionBody =>
      'NyaPlayer liest nur Audiodateien in den von dir gewählten Ordnern, auf diesem Gerät, und geht nie online. Erlaube den Zugriff auf Musik und Audio, sonst kann die Bibliothek nicht durchsucht werden.';

  @override
  String get musicPermissionSettings => 'Systemeinstellungen öffnen';

  @override
  String get settingsMinLength => 'Mindestlänge';

  @override
  String get minLengthOff => 'Alle Titel anzeigen';

  @override
  String minLengthSummary(String duration) {
    return 'Titel unter $duration ausblenden';
  }

  @override
  String lengthSeconds(int count) {
    return '$count Sek.';
  }

  @override
  String lengthMinutes(int count) {
    return '$count Min.';
  }

  @override
  String get eqSavePreset => 'Als Preset speichern';

  @override
  String get eqPresetName => 'Preset-Name';

  @override
  String eqDeletePresetBody(String name) {
    return 'Preset „$name“ löschen?';
  }

  @override
  String get notificationPermissionTitle => 'Wiedergabesteuerung anzeigen?';

  @override
  String get notificationPermissionBody =>
      'Erlaube Benachrichtigungen, um die Wiedergabe über die Benachrichtigungsleiste und den Sperrbildschirm zu steuern. Die Wiedergabe funktioniert auch ohne.';

  @override
  String get allow => 'Erlauben';

  @override
  String get flowingLight => 'Fließender Lichthintergrund';

  @override
  String get flowingLightHint =>
      'Weiches farbiges Licht wandert über den Player-Hintergrund und übernimmt die Farben des Covers. Hi-Res-Titel bekommen einen Hauch Gold.';

  @override
  String get surfaceMaterial => 'Material';

  @override
  String get materialStandard => 'Standard';

  @override
  String get materialGlass => 'Premium-Glas';

  @override
  String get surfaceMaterialHint =>
      'Premium-Glas macht Seitenleiste, Karten, Player-Leiste und Menü zu durchscheinendem Milchglas über einem sanft bewegten Licht. Verbraucht mehr Strom.';
}
