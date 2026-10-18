// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'NyaPlayer';

  @override
  String get showAppWindow => 'Afficher NyaPlayer';

  @override
  String get quitApp => 'Quitter NyaPlayer';

  @override
  String get navSongs => 'Titres';

  @override
  String get navAlbums => 'Albums';

  @override
  String get navArtists => 'Artistes';

  @override
  String get navFolders => 'Dossiers';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get search => 'Rechercher';

  @override
  String get searchHint => 'Rechercher des titres, albums, artistes';

  @override
  String get searchNoResults => 'Aucun résultat';

  @override
  String get sectionSongs => 'Titres';

  @override
  String get sectionAlbums => 'Albums';

  @override
  String get sectionArtists => 'Artistes';

  @override
  String get moreOptions => 'Plus d’options';

  @override
  String get sortTitle => 'Titre';

  @override
  String get sortArtist => 'Artiste';

  @override
  String get sortAlbum => 'Album';

  @override
  String get sortAdded => 'Date d’ajout';

  @override
  String get sortDuration => 'Durée';

  @override
  String get sortAscending => 'Croissant';

  @override
  String get sortDescending => 'Décroissant';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '$count titre',
    );
    return '$_temp0';
  }

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '$count album',
    );
    return '$_temp0';
  }

  @override
  String get playAll => 'Tout lire';

  @override
  String get shufflePlay => 'Aléatoire';

  @override
  String get playNext => 'Lire ensuite';

  @override
  String get addToQueue => 'Ajouter à la file d’attente';

  @override
  String get songInfo => 'Infos du titre';

  @override
  String get addedToQueue => 'Ajouté à la file d’attente';

  @override
  String get willPlayNext => 'Sera lu ensuite';

  @override
  String get nowPlaying => 'En lecture';

  @override
  String get notPlaying => 'Rien en lecture';

  @override
  String get notPlayingHint =>
      'Choisissez un titre dans votre bibliothèque pour commencer';

  @override
  String get queue => 'File d’attente';

  @override
  String get queueEmpty => 'La file d’attente est vide';

  @override
  String get lyrics => 'Paroles';

  @override
  String get cover => 'Pochette';

  @override
  String get noLyrics => 'Pas de paroles';

  @override
  String get close => 'Fermer';

  @override
  String get back => 'Retour';

  @override
  String get play => 'Lecture';

  @override
  String get pause => 'Pause';

  @override
  String get previous => 'Précédent';

  @override
  String get next => 'Suivant';

  @override
  String get repeatOff => 'Répétition : désactivée';

  @override
  String get repeatAll => 'Répétition : tout';

  @override
  String get repeatOne => 'Répétition : un titre';

  @override
  String get shuffleOn => 'Aléatoire : activé';

  @override
  String get shuffleOff => 'Aléatoire : désactivé';

  @override
  String discLabel(int number) {
    return 'Disque $number';
  }

  @override
  String get infoPath => 'Chemin';

  @override
  String get infoFormat => 'Format';

  @override
  String get infoSampleRate => 'Fréquence d’échantillonnage';

  @override
  String get infoBitDepth => 'Profondeur de bits';

  @override
  String get infoBitrate => 'Débit';

  @override
  String get infoChannels => 'Canaux';

  @override
  String get infoDuration => 'Durée';

  @override
  String get infoYear => 'Année';

  @override
  String get infoGenre => 'Genre';

  @override
  String get infoTrackNo => 'Piste';

  @override
  String get infoAlbum => 'Album';

  @override
  String get infoArtist => 'Artiste';

  @override
  String bitDepthValue(int bits) {
    return '$bits bits';
  }

  @override
  String bitrateValue(int kbps) {
    return '$kbps kbit/s';
  }

  @override
  String get channelsStereo => 'Stéréo';

  @override
  String get channelsMono => 'Mono';

  @override
  String get eqTitle => 'Égaliseur';

  @override
  String get eqEnabled => 'Activer l’égaliseur';

  @override
  String get eqPresets => 'Préréglages';

  @override
  String get eqPreamp => 'Préampli';

  @override
  String get eqAutoClip => 'Éviter l’écrêtage';

  @override
  String get eqReset => 'Réinitialiser';

  @override
  String get eqPresetFlat => 'Neutre';

  @override
  String get eqPresetPop => 'Pop';

  @override
  String get eqPresetRock => 'Rock';

  @override
  String get eqPresetJazz => 'Jazz';

  @override
  String get eqPresetClassical => 'Classique';

  @override
  String get eqPresetVocal => 'Voix';

  @override
  String get eqPresetBassBoost => 'Graves renforcés';

  @override
  String get eqPresetTrebleBoost => 'Aigus renforcés';

  @override
  String get eqPresetCustom => 'Personnalisé';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsThemeMode => 'Mode du thème';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Système';

  @override
  String get settingsColorSource => 'Source des couleurs';

  @override
  String get colorSourceWallpaper => 'Système';

  @override
  String get colorSourceFixed => 'Couleur fixe';

  @override
  String get settingsSeedColor => 'Couleur du thème';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get langSystem => 'Système';

  @override
  String get settingsLibrary => 'Bibliothèque';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutLicenses => 'Licences open source';

  @override
  String get aboutRerunOnboarding => 'Revoir l’écran d’accueil';

  @override
  String get onboardingTitle => 'Bienvenue dans NyaPlayer';

  @override
  String get onboardingBody =>
      'Un lecteur de musique local, sans publicité et hors ligne. Choisissez vos dossiers de musique pour commencer à écouter.';

  @override
  String get onboardingChoose => 'Choisir les dossiers de musique';

  @override
  String get onboardingSkip => 'Plus tard';

  @override
  String get playlistsEmptyTitle => 'Aucune playlist pour l’instant';

  @override
  String get playlistsEmptyBody =>
      'Touchez le bouton pour en créer une, puis ajoutez des titres depuis le menu d’un titre.';

  @override
  String get loadFailed => 'Échec du chargement';

  @override
  String get emptyLibrary => 'Votre bibliothèque est vide';

  @override
  String get variousArtists => 'Artistes divers';

  @override
  String get navFavorites => 'Favoris';

  @override
  String get navSettings => 'Réglages';

  @override
  String get openNavigation => 'Ouvrir le menu de navigation';

  @override
  String get favorite => 'Ajouter aux favoris';

  @override
  String get unfavorite => 'Retirer des favoris';

  @override
  String get favoritesEmptyTitle => 'Aucun favori pour l’instant';

  @override
  String get favoritesEmptyBody =>
      'Touchez ♡ dans le menu d’un titre ou dans le lecteur pour l’ajouter ici.';

  @override
  String get settingsPlayback => 'Lecture';

  @override
  String get colorSourceHint =>
      'Utilisez les couleurs du système ou une couleur de thème fixe. L’arrière-plan du lecteur se règle séparément.';

  @override
  String get settingsEqualizerSubtitle => 'Égaliseur 10 bandes et préréglages';

  @override
  String get coverShape => 'Style de la pochette';

  @override
  String get coverShapeSquare => 'Carrée';

  @override
  String get coverShapeDisc => 'Ronde (rotative)';

  @override
  String get coverShapeTurntable => 'Platine';

  @override
  String get expandPlayer => 'Agrandir le lecteur';

  @override
  String get collapsePlayer => 'Réduire';

  @override
  String get playerMenu => 'Menu du lecteur';

  @override
  String get fontStyle => 'Police';

  @override
  String get fontSerif => 'Serif';

  @override
  String get fontSans => 'Sans serif';

  @override
  String get lyricsSettings => 'Réglages des paroles';

  @override
  String get lyricsFontSize => 'Taille de police';

  @override
  String get lyricsCentered => 'Centrer les lignes';

  @override
  String get lyricsTranslation => 'Afficher la traduction';

  @override
  String lyricsFontSizeRange(int min, int max) {
    return '$min–$max';
  }

  @override
  String get lyricsFontSizeInvalid => 'Saisissez une taille valide';

  @override
  String get settingsGeneral => 'Général';

  @override
  String get settingsStartPage => 'Page de démarrage';

  @override
  String get settingsStartPageHint => 'La page affichée à l’ouverture de l’app';

  @override
  String get playerBackground => 'Arrière-plan du lecteur';

  @override
  String get progressStyle => 'Style de la barre de progression';

  @override
  String get progressMaterial => 'Material';

  @override
  String get progressClassic => 'Point classique';

  @override
  String get progressSlim => 'Ligne fine';

  @override
  String get progressWave => 'Onde';

  @override
  String get backgroundGradient => 'Dégradé du thème';

  @override
  String get backgroundBlurredCover => 'Pochette floutée';

  @override
  String get playerBackgroundHint =>
      'Agrandit et floute fortement la pochette de l’album pour une ambiance immersive.';

  @override
  String get settingsShortcuts => 'Raccourcis clavier';

  @override
  String get shortcutPlayback => 'Lecture / pause';

  @override
  String get shortcutSpace => 'Espace';

  @override
  String get shortcutTracks => 'Titre précédent / suivant';

  @override
  String get shortcutWindow => 'Entrer / quitter le plein écran';

  @override
  String get lyricsLineHeight => 'Interligne';

  @override
  String get lyricsLineHeightInvalid => 'Saisissez une valeur entre 1 et 2';

  @override
  String get newPlaylist => 'Nouvelle playlist';

  @override
  String get playlistName => 'Nom de la playlist';

  @override
  String get playlistNameHint => 'p. ex. Trajet';

  @override
  String get create => 'Créer';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get rename => 'Renommer';

  @override
  String get delete => 'Supprimer';

  @override
  String get remove => 'Retirer';

  @override
  String get removeFromPlaylist => 'Retirer de cette playlist';

  @override
  String get addToPlaylist => 'Ajouter à une playlist';

  @override
  String addedToPlaylist(String name) {
    return 'Ajouté à « $name »';
  }

  @override
  String get deletePlaylistTitle => 'Supprimer la playlist ?';

  @override
  String deletePlaylistBody(String name) {
    return '« $name » sera supprimée. Vos fichiers musicaux ne sont pas touchés.';
  }

  @override
  String get playlistEmpty => 'Cette playlist est vide';

  @override
  String get playlistEmptyBody =>
      'Choisissez « Ajouter à une playlist » dans le menu d’un titre.';

  @override
  String playlistTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '$count titre',
    );
    return '$_temp0';
  }

  @override
  String get reorder => 'Faire glisser pour réorganiser';

  @override
  String get libraryFolders => 'Dossiers de musique';

  @override
  String get libraryFoldersHint =>
      'Les fichiers FLAC et MP3 de ces dossiers sont analysés de façon récursive.';

  @override
  String get libraryNoFolders => 'Aucun dossier de musique pour l’instant';

  @override
  String get addFolder => 'Ajouter un dossier';

  @override
  String get excludeFolder => 'Exclure un dossier';

  @override
  String get excludedTag => 'Exclu';

  @override
  String get removeFolder => 'Retirer ce dossier';

  @override
  String get folderAlreadyAdded => 'Ce dossier figure déjà dans la liste';

  @override
  String get rescan => 'Réanalyser';

  @override
  String get scanWalking => 'Recherche des fichiers musicaux…';

  @override
  String scanReading(int done, int total) {
    return 'Lecture des tags $done / $total';
  }

  @override
  String get scanFinishing => 'Mise en ordre de la bibliothèque…';

  @override
  String get scanDone => 'Analyse terminée';

  @override
  String scanDoneWithErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers',
      one: '$count fichier',
    );
    return 'Analyse terminée ; les tags de $_temp0 n’ont pas pu être lus';
  }

  @override
  String get scanFailed => 'Échec de l’analyse';

  @override
  String get emptyLibraryBody =>
      'Ajoutez un dossier de musique et vos titres apparaîtront ici.';

  @override
  String get useBundledFonts => 'Utiliser les polices intégrées';

  @override
  String get useBundledFontsHint =>
      'Le sans serif utilise HarmonyOS Sans ; le serif utilise EB Garamond et Noto Serif SC. Désactivez pour utiliser les polices du système.';

  @override
  String get aboutFonts => 'Polices';

  @override
  String get aboutFontsCredit =>
      'HarmonyOS Sans (© Huawei Device Co., Ltd.), EB Garamond et Noto Serif SC (SIL OFL)';

  @override
  String get pickFolderMessage =>
      'Choisissez les dossiers qui contiennent de la musique (FLAC, MP3). Vous pouvez en sélectionner plusieurs.';

  @override
  String get pickExcludeMessage =>
      'Choisissez les dossiers à ignorer lors de l’analyse.';

  @override
  String get folderNotUsable =>
      'Ce dossier ne peut pas être lu. Choisissez un autre emplacement.';

  @override
  String get folderPickFailed => 'Impossible d’ouvrir le sélecteur de dossiers';

  @override
  String get musicPermissionTitle => 'Autorisation de lire la musique';

  @override
  String get musicPermissionBody =>
      'NyaPlayer ne lit que les fichiers audio des dossiers que vous choisissez, sur cet appareil, et ne se connecte jamais à Internet. Autorisez l’accès à la musique et à l’audio, sinon la bibliothèque ne peut pas être analysée.';

  @override
  String get musicPermissionSettings => 'Ouvrir les réglages du système';

  @override
  String get settingsMinLength => 'Durée minimale des titres';

  @override
  String get minLengthOff => 'Tout afficher';

  @override
  String minLengthSummary(String duration) {
    return 'Masquer les titres de moins de $duration';
  }

  @override
  String lengthSeconds(int count) {
    return '$count s';
  }

  @override
  String lengthMinutes(int count) {
    return '$count min';
  }

  @override
  String get eqSavePreset => 'Enregistrer comme préréglage';

  @override
  String get eqPresetName => 'Nom du préréglage';

  @override
  String eqDeletePresetBody(String name) {
    return 'Supprimer le préréglage « $name » ?';
  }

  @override
  String get notificationPermissionTitle =>
      'Afficher les commandes de lecture ?';

  @override
  String get notificationPermissionBody =>
      'Autorisez les notifications pour contrôler la lecture depuis le panneau de notifications et l\'écran de verrouillage. La lecture fonctionne dans les deux cas.';

  @override
  String get allow => 'Autoriser';

  @override
  String get flowingLight => 'Arrière-plan lumineux animé';

  @override
  String get flowingLightHint =>
      'Une lumière colorée et douce dérive sur l\'arrière-plan du lecteur, aux couleurs de la pochette. Les titres Hi-Res reçoivent une touche d\'or.';

  @override
  String get surfaceMaterial => 'Matière';

  @override
  String get materialStandard => 'Standard';

  @override
  String get materialGlass => 'Verre premium';

  @override
  String get surfaceMaterialHint =>
      'Le verre premium rend la barre latérale, les cartes, la barre de lecture et le tiroir translucides, comme du verre dépoli sur une lumière mouvante. Consomme plus d\'énergie.';
}
