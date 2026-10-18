// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'NyaPlayer';

  @override
  String get showAppWindow => 'Mostrar NyaPlayer';

  @override
  String get quitApp => 'Salir de NyaPlayer';

  @override
  String get navSongs => 'Canciones';

  @override
  String get navAlbums => 'Álbumes';

  @override
  String get navArtists => 'Artistas';

  @override
  String get navFolders => 'Carpetas';

  @override
  String get navPlaylists => 'Listas de reproducción';

  @override
  String get search => 'Buscar';

  @override
  String get searchHint => 'Buscar canciones, álbumes, artistas';

  @override
  String get searchNoResults => 'No se encontraron resultados';

  @override
  String get sectionSongs => 'Canciones';

  @override
  String get sectionAlbums => 'Álbumes';

  @override
  String get sectionArtists => 'Artistas';

  @override
  String get moreOptions => 'Más opciones';

  @override
  String get sortTitle => 'Título';

  @override
  String get sortArtist => 'Artista';

  @override
  String get sortAlbum => 'Álbum';

  @override
  String get sortAdded => 'Fecha de incorporación';

  @override
  String get sortDuration => 'Duración';

  @override
  String get sortAscending => 'Ascendente';

  @override
  String get sortDescending => 'Descendente';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones',
      one: '1 canción',
    );
    return '$_temp0';
  }

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count álbumes',
      one: '1 álbum',
    );
    return '$_temp0';
  }

  @override
  String get playAll => 'Reproducir todo';

  @override
  String get shufflePlay => 'Aleatorio';

  @override
  String get playNext => 'Reproducir a continuación';

  @override
  String get addToQueue => 'Añadir a la cola';

  @override
  String get songInfo => 'Información de la canción';

  @override
  String get addedToQueue => 'Añadida a la cola';

  @override
  String get willPlayNext => 'Se reproducirá a continuación';

  @override
  String get nowPlaying => 'Reproduciendo';

  @override
  String get notPlaying => 'Nada en reproducción';

  @override
  String get notPlayingHint =>
      'Elige una canción de tu biblioteca para empezar';

  @override
  String get queue => 'Cola de reproducción';

  @override
  String get queueEmpty => 'La cola está vacía';

  @override
  String get lyrics => 'Letra';

  @override
  String get cover => 'Carátula';

  @override
  String get noLyrics => 'Sin letra';

  @override
  String get close => 'Cerrar';

  @override
  String get back => 'Atrás';

  @override
  String get play => 'Reproducir';

  @override
  String get pause => 'Pausa';

  @override
  String get previous => 'Anterior';

  @override
  String get next => 'Siguiente';

  @override
  String get repeatOff => 'Repetir: desactivado';

  @override
  String get repeatAll => 'Repetir: todo';

  @override
  String get repeatOne => 'Repetir: una canción';

  @override
  String get shuffleOn => 'Aleatorio: activado';

  @override
  String get shuffleOff => 'Aleatorio: desactivado';

  @override
  String discLabel(int number) {
    return 'Disco $number';
  }

  @override
  String get infoPath => 'Ruta';

  @override
  String get infoFormat => 'Formato';

  @override
  String get infoSampleRate => 'Frecuencia de muestreo';

  @override
  String get infoBitDepth => 'Profundidad de bits';

  @override
  String get infoBitrate => 'Tasa de bits';

  @override
  String get infoChannels => 'Canales';

  @override
  String get infoDuration => 'Duración';

  @override
  String get infoYear => 'Año';

  @override
  String get infoGenre => 'Género';

  @override
  String get infoTrackNo => 'Pista';

  @override
  String get infoAlbum => 'Álbum';

  @override
  String get infoArtist => 'Artista';

  @override
  String bitDepthValue(int bits) {
    return '$bits bits';
  }

  @override
  String bitrateValue(int kbps) {
    return '$kbps kbps';
  }

  @override
  String get channelsStereo => 'Estéreo';

  @override
  String get channelsMono => 'Mono';

  @override
  String get eqTitle => 'Ecualizador';

  @override
  String get eqEnabled => 'Activar el ecualizador';

  @override
  String get eqPresets => 'Ajustes preestablecidos';

  @override
  String get eqPreamp => 'Preamplificación';

  @override
  String get eqAutoClip => 'Evitar saturación';

  @override
  String get eqReset => 'Restablecer';

  @override
  String get eqPresetFlat => 'Plano';

  @override
  String get eqPresetPop => 'Pop';

  @override
  String get eqPresetRock => 'Rock';

  @override
  String get eqPresetJazz => 'Jazz';

  @override
  String get eqPresetClassical => 'Clásica';

  @override
  String get eqPresetVocal => 'Voz';

  @override
  String get eqPresetBassBoost => 'Refuerzo de graves';

  @override
  String get eqPresetTrebleBoost => 'Refuerzo de agudos';

  @override
  String get eqPresetCustom => 'Personalizado';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsThemeMode => 'Modo del tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get settingsColorSource => 'Origen del color';

  @override
  String get colorSourceWallpaper => 'Sistema';

  @override
  String get colorSourceFixed => 'Color fijo';

  @override
  String get settingsSeedColor => 'Color del tema';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get langSystem => 'Sistema';

  @override
  String get settingsLibrary => 'Biblioteca';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get aboutVersion => 'Versión';

  @override
  String get aboutLicenses => 'Licencias de código abierto';

  @override
  String get aboutRerunOnboarding =>
      'Volver a mostrar la pantalla de bienvenida';

  @override
  String get onboardingTitle => 'Te damos la bienvenida a NyaPlayer';

  @override
  String get onboardingBody =>
      'Un reproductor de música local, sin anuncios y sin conexión. Elige tus carpetas de música para empezar a escuchar.';

  @override
  String get onboardingChoose => 'Elegir carpetas de música';

  @override
  String get onboardingSkip => 'Ahora no';

  @override
  String get playlistsEmptyTitle => 'Aún no hay listas de reproducción';

  @override
  String get playlistsEmptyBody =>
      'Toca el botón para crear una y luego añade canciones desde el menú de cualquier canción.';

  @override
  String get loadFailed => 'Error al cargar';

  @override
  String get emptyLibrary => 'Tu biblioteca está vacía';

  @override
  String get variousArtists => 'Varios artistas';

  @override
  String get navFavorites => 'Favoritos';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get openNavigation => 'Abrir el menú de navegación';

  @override
  String get favorite => 'Añadir a favoritos';

  @override
  String get unfavorite => 'Quitar de favoritos';

  @override
  String get favoritesEmptyTitle => 'Aún no hay favoritos';

  @override
  String get favoritesEmptyBody =>
      'Toca ♡ en el menú de una canción o en el reproductor para añadirla aquí.';

  @override
  String get settingsPlayback => 'Reproducción';

  @override
  String get colorSourceHint =>
      'Usa los colores del sistema o un color de tema fijo. El fondo del reproductor se ajusta aparte.';

  @override
  String get settingsEqualizerSubtitle =>
      'Ecualizador de 10 bandas y ajustes preestablecidos';

  @override
  String get coverShape => 'Estilo de la carátula';

  @override
  String get coverShapeSquare => 'Cuadrada';

  @override
  String get coverShapeDisc => 'Redonda (giratoria)';

  @override
  String get coverShapeTurntable => 'Tocadiscos';

  @override
  String get expandPlayer => 'Ampliar el reproductor';

  @override
  String get collapsePlayer => 'Contraer';

  @override
  String get playerMenu => 'Menú del reproductor';

  @override
  String get fontStyle => 'Fuente';

  @override
  String get fontSerif => 'Serif';

  @override
  String get fontSans => 'Sans';

  @override
  String get lyricsSettings => 'Ajustes de la letra';

  @override
  String get lyricsFontSize => 'Tamaño de fuente';

  @override
  String get lyricsCentered => 'Centrar las líneas';

  @override
  String get lyricsTranslation => 'Mostrar la traducción';

  @override
  String lyricsFontSizeRange(int min, int max) {
    return '$min–$max';
  }

  @override
  String get lyricsFontSizeInvalid => 'Introduce un tamaño válido';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsStartPage => 'Página de inicio';

  @override
  String get settingsStartPageHint =>
      'La página que se muestra al abrir la app';

  @override
  String get playerBackground => 'Fondo del reproductor';

  @override
  String get progressStyle => 'Estilo de la barra de progreso';

  @override
  String get progressMaterial => 'Material';

  @override
  String get progressClassic => 'Punto clásico';

  @override
  String get progressSlim => 'Línea fina';

  @override
  String get progressWave => 'Onda';

  @override
  String get backgroundGradient => 'Degradado del tema';

  @override
  String get backgroundBlurredCover => 'Carátula desenfocada';

  @override
  String get playerBackgroundHint =>
      'Amplía y desenfoca mucho la carátula del álbum para crear un fondo envolvente.';

  @override
  String get settingsShortcuts => 'Atajos de teclado';

  @override
  String get shortcutPlayback => 'Reproducir / pausa';

  @override
  String get shortcutSpace => 'Espacio';

  @override
  String get shortcutTracks => 'Canción anterior / siguiente';

  @override
  String get shortcutWindow => 'Entrar / salir de pantalla completa';

  @override
  String get lyricsLineHeight => 'Interlineado';

  @override
  String get lyricsLineHeightInvalid => 'Introduce un valor entre 1 y 2';

  @override
  String get newPlaylist => 'Nueva lista de reproducción';

  @override
  String get playlistName => 'Nombre de la lista';

  @override
  String get playlistNameHint => 'p. ej., De camino al trabajo';

  @override
  String get create => 'Crear';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get rename => 'Cambiar nombre';

  @override
  String get delete => 'Eliminar';

  @override
  String get remove => 'Quitar';

  @override
  String get removeFromPlaylist => 'Quitar de esta lista';

  @override
  String get addToPlaylist => 'Añadir a una lista de reproducción';

  @override
  String addedToPlaylist(String name) {
    return 'Añadida a «$name»';
  }

  @override
  String get deletePlaylistTitle => '¿Eliminar la lista de reproducción?';

  @override
  String deletePlaylistBody(String name) {
    return 'Se eliminará «$name». Tus archivos de música no se tocan.';
  }

  @override
  String get playlistEmpty => 'Esta lista está vacía';

  @override
  String get playlistEmptyBody =>
      'Elige «Añadir a una lista de reproducción» en el menú de cualquier canción.';

  @override
  String playlistTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones',
      one: '1 canción',
    );
    return '$_temp0';
  }

  @override
  String get reorder => 'Arrastra para reordenar';

  @override
  String get libraryFolders => 'Carpetas de música';

  @override
  String get libraryFoldersHint =>
      'Los archivos FLAC y MP3 de estas carpetas se analizan de forma recursiva.';

  @override
  String get libraryNoFolders => 'Aún no hay carpetas de música';

  @override
  String get addFolder => 'Añadir carpeta';

  @override
  String get excludeFolder => 'Excluir carpeta';

  @override
  String get excludedTag => 'Excluida';

  @override
  String get removeFolder => 'Quitar esta carpeta';

  @override
  String get folderAlreadyAdded => 'Esa carpeta ya está en la lista';

  @override
  String get rescan => 'Volver a analizar';

  @override
  String get scanWalking => 'Buscando archivos de música…';

  @override
  String scanReading(int done, int total) {
    return 'Leyendo etiquetas $done / $total';
  }

  @override
  String get scanFinishing => 'Ordenando la biblioteca…';

  @override
  String get scanDone => 'Análisis terminado';

  @override
  String scanDoneWithErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos',
      one: '1 archivo',
    );
    return 'Análisis terminado; no se pudieron leer las etiquetas de $_temp0';
  }

  @override
  String get scanFailed => 'Error en el análisis';

  @override
  String get emptyLibraryBody =>
      'Añade una carpeta de música y tus canciones aparecerán aquí.';

  @override
  String get useBundledFonts => 'Usar las fuentes integradas';

  @override
  String get useBundledFontsHint =>
      'Sans usa HarmonyOS Sans; serif usa EB Garamond y Noto Serif SC. Desactívalo para usar las fuentes del sistema.';

  @override
  String get aboutFonts => 'Fuentes';

  @override
  String get aboutFontsCredit =>
      'HarmonyOS Sans (© Huawei Device Co., Ltd.), EB Garamond y Noto Serif SC (SIL OFL)';

  @override
  String get pickFolderMessage =>
      'Elige las carpetas que contienen música (FLAC, MP3). Puedes elegir varias.';

  @override
  String get pickExcludeMessage =>
      'Elige las carpetas que se omitirán al analizar.';

  @override
  String get folderNotUsable =>
      'No se puede leer esa carpeta. Elige otra ubicación.';

  @override
  String get folderPickFailed => 'No se pudo abrir el selector de carpetas';

  @override
  String get musicPermissionTitle => 'Permiso para leer música';

  @override
  String get musicPermissionBody =>
      'NyaPlayer solo lee los archivos de audio de las carpetas que elijas, en este dispositivo, y nunca se conecta a internet. Permite el acceso a la música y al audio; de lo contrario, no se puede analizar la biblioteca.';

  @override
  String get musicPermissionSettings => 'Abrir los ajustes del sistema';

  @override
  String get settingsMinLength => 'Duración mínima';

  @override
  String get minLengthOff => 'Mostrar todas las canciones';

  @override
  String minLengthSummary(String duration) {
    return 'Ocultar canciones de menos de $duration';
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
  String get eqSavePreset => 'Guardar como preajuste';

  @override
  String get eqPresetName => 'Nombre del preajuste';

  @override
  String eqDeletePresetBody(String name) {
    return '¿Eliminar el preajuste «$name»?';
  }

  @override
  String get notificationPermissionTitle =>
      '¿Mostrar los controles de reproducción?';

  @override
  String get notificationPermissionBody =>
      'Permite las notificaciones para controlar la reproducción desde el panel de notificaciones y la pantalla de bloqueo. La reproducción funciona igualmente sin ellas.';

  @override
  String get allow => 'Permitir';

  @override
  String get flowingLight => 'Fondo de luz fluida';

  @override
  String get flowingLightHint =>
      'Una luz suave de colores se desplaza por el fondo del reproductor, con los colores de la carátula. Las canciones Hi-Res reciben un toque dorado.';

  @override
  String get surfaceMaterial => 'Material';

  @override
  String get materialStandard => 'Estándar';

  @override
  String get materialGlass => 'Cristal premium';

  @override
  String get surfaceMaterialHint =>
      'El cristal premium convierte la barra lateral, las tarjetas, la barra del reproductor y el panel en cristal esmerilado translúcido sobre una luz en movimiento. Consume más energía.';

  @override
  String get settingsPlaybackCore => 'Motor de reproducción';

  @override
  String get settingsPlaybackCoreHint =>
      'Decodificación del sistema (Media3) o motor Rust. Reinicia la app para aplicarlo.';

  @override
  String get playbackCoreSystem => 'Sistema (Media3)';

  @override
  String get playbackCoreRust => 'Motor Rust';
}
