// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'NyaPlayer';

  @override
  String get showAppWindow => 'Показать NyaPlayer';

  @override
  String get quitApp => 'Выйти из NyaPlayer';

  @override
  String get navSongs => 'Песни';

  @override
  String get navAlbums => 'Альбомы';

  @override
  String get navArtists => 'Исполнители';

  @override
  String get navFolders => 'Папки';

  @override
  String get navPlaylists => 'Плейлисты';

  @override
  String get search => 'Поиск';

  @override
  String get searchHint => 'Поиск песен, альбомов, исполнителей';

  @override
  String get searchNoResults => 'Ничего не найдено';

  @override
  String get sectionSongs => 'Песни';

  @override
  String get sectionAlbums => 'Альбомы';

  @override
  String get sectionArtists => 'Исполнители';

  @override
  String get moreOptions => 'Ещё';

  @override
  String get sortTitle => 'Название';

  @override
  String get sortArtist => 'Исполнитель';

  @override
  String get sortAlbum => 'Альбом';

  @override
  String get sortAdded => 'Дата добавления';

  @override
  String get sortDuration => 'Длительность';

  @override
  String get sortAscending => 'По возрастанию';

  @override
  String get sortDescending => 'По убыванию';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песни',
      many: '$count песен',
      few: '$count песни',
      one: '$count песня',
    );
    return '$_temp0';
  }

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count альбома',
      many: '$count альбомов',
      few: '$count альбома',
      one: '$count альбом',
    );
    return '$_temp0';
  }

  @override
  String get playAll => 'Играть все';

  @override
  String get shufflePlay => 'Вперемешку';

  @override
  String get playNext => 'Играть следующей';

  @override
  String get addToQueue => 'Добавить в очередь';

  @override
  String get songInfo => 'О песне';

  @override
  String get addedToQueue => 'Добавлено в очередь';

  @override
  String get willPlayNext => 'Будет играть следующей';

  @override
  String get nowPlaying => 'Сейчас играет';

  @override
  String get notPlaying => 'Ничего не играет';

  @override
  String get notPlayingHint => 'Выберите песню из медиатеки, чтобы начать';

  @override
  String get queue => 'Очередь';

  @override
  String get queueEmpty => 'Очередь пуста';

  @override
  String get lyrics => 'Текст';

  @override
  String get cover => 'Обложка';

  @override
  String get noLyrics => 'Нет текста';

  @override
  String get close => 'Закрыть';

  @override
  String get back => 'Назад';

  @override
  String get play => 'Воспроизвести';

  @override
  String get pause => 'Пауза';

  @override
  String get previous => 'Назад';

  @override
  String get next => 'Далее';

  @override
  String get repeatOff => 'Повтор: выкл.';

  @override
  String get repeatAll => 'Повтор: все';

  @override
  String get repeatOne => 'Повтор: одна песня';

  @override
  String get shuffleOn => 'Вперемешку: вкл.';

  @override
  String get shuffleOff => 'Вперемешку: выкл.';

  @override
  String discLabel(int number) {
    return 'Диск $number';
  }

  @override
  String get infoPath => 'Путь';

  @override
  String get infoFormat => 'Формат';

  @override
  String get infoSampleRate => 'Частота дискретизации';

  @override
  String get infoBitDepth => 'Разрядность';

  @override
  String get infoBitrate => 'Битрейт';

  @override
  String get infoChannels => 'Каналы';

  @override
  String get infoDuration => 'Длительность';

  @override
  String get infoYear => 'Год';

  @override
  String get infoGenre => 'Жанр';

  @override
  String get infoTrackNo => 'Трек';

  @override
  String get infoAlbum => 'Альбом';

  @override
  String get infoArtist => 'Исполнитель';

  @override
  String bitDepthValue(int bits) {
    return '$bits бит';
  }

  @override
  String bitrateValue(int kbps) {
    return '$kbps кбит/с';
  }

  @override
  String get channelsStereo => 'Стерео';

  @override
  String get channelsMono => 'Моно';

  @override
  String get eqTitle => 'Эквалайзер';

  @override
  String get eqEnabled => 'Включить эквалайзер';

  @override
  String get eqPresets => 'Пресеты';

  @override
  String get eqPreamp => 'Предусиление';

  @override
  String get eqAutoClip => 'Защита от клиппинга';

  @override
  String get eqReset => 'Сбросить';

  @override
  String get eqPresetFlat => 'Ровный';

  @override
  String get eqPresetPop => 'Поп';

  @override
  String get eqPresetRock => 'Рок';

  @override
  String get eqPresetJazz => 'Джаз';

  @override
  String get eqPresetClassical => 'Классика';

  @override
  String get eqPresetVocal => 'Вокал';

  @override
  String get eqPresetBassBoost => 'Усиление басов';

  @override
  String get eqPresetTrebleBoost => 'Усиление высоких';

  @override
  String get eqPresetClub => 'Клуб';

  @override
  String get eqPresetDance => 'Танцевальная';

  @override
  String get eqPresetFullBass => 'Мощный бас';

  @override
  String get eqPresetFullBassTreble => 'Бас и высокие';

  @override
  String get eqPresetFullTreble => 'Мощные высокие';

  @override
  String get eqPresetHeadphones => 'Наушники';

  @override
  String get eqPresetLargeHall => 'Большой зал';

  @override
  String get eqPresetLive => 'Живой звук';

  @override
  String get eqPresetParty => 'Вечеринка';

  @override
  String get eqPresetReggae => 'Регги';

  @override
  String get eqPresetSka => 'Ска';

  @override
  String get eqPresetSoft => 'Мягкий';

  @override
  String get eqPresetSoftRock => 'Софт-рок';

  @override
  String get eqPresetTechno => 'Техно';

  @override
  String get eqPresetLoudness => 'Тонкомпенсация';

  @override
  String get eqPresetCustom => 'Свой';

  @override
  String get settingsAppearance => 'Оформление';

  @override
  String get settingsThemeMode => 'Тема';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeSystem => 'Системная';

  @override
  String get settingsColorSource => 'Источник цвета';

  @override
  String get colorSourceWallpaper => 'Системный';

  @override
  String get colorSourceFixed => 'Фиксированный цвет';

  @override
  String get settingsSeedColor => 'Цвет темы';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get langSystem => 'Системный';

  @override
  String get settingsLibrary => 'Медиатека';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String get aboutVersion => 'Версия';

  @override
  String get aboutLicenses => 'Лицензии открытого ПО';

  @override
  String get aboutRerunOnboarding => 'Показать приветствие снова';

  @override
  String get onboardingTitle => 'Добро пожаловать в NyaPlayer';

  @override
  String get onboardingBody =>
      'Локальный музыкальный плеер без рекламы и без интернета. Выберите папки с музыкой, чтобы начать слушать.';

  @override
  String get onboardingChoose => 'Выбрать папки с музыкой';

  @override
  String get onboardingSkip => 'Не сейчас';

  @override
  String get playlistsEmptyTitle => 'Плейлистов пока нет';

  @override
  String get playlistsEmptyBody =>
      'Нажмите кнопку, чтобы создать плейлист, а затем добавляйте песни через их меню.';

  @override
  String get loadFailed => 'Не удалось загрузить';

  @override
  String get emptyLibrary => 'Медиатека пуста';

  @override
  String get variousArtists => 'Разные исполнители';

  @override
  String get navFavorites => 'Избранное';

  @override
  String get navSettings => 'Настройки';

  @override
  String get openNavigation => 'Открыть меню навигации';

  @override
  String get favorite => 'В избранное';

  @override
  String get unfavorite => 'Убрать из избранного';

  @override
  String get favoritesEmptyTitle => 'В избранном пока ничего нет';

  @override
  String get favoritesEmptyBody =>
      'Нажмите ♡ в меню песни или в плеере, чтобы добавить её сюда.';

  @override
  String get settingsPlayback => 'Воспроизведение';

  @override
  String get colorSourceHint =>
      'Использовать системные цвета или фиксированный цвет темы. Фон плеера настраивается отдельно.';

  @override
  String get settingsEqualizerSubtitle => '10-полосный эквалайзер и пресеты';

  @override
  String get coverShape => 'Стиль обложки';

  @override
  String get coverShapeSquare => 'Квадратная';

  @override
  String get coverShapeDisc => 'Круглая (вращается)';

  @override
  String get coverShapeTurntable => 'Проигрыватель';

  @override
  String get expandPlayer => 'Развернуть плеер';

  @override
  String get collapsePlayer => 'Свернуть';

  @override
  String get playerMenu => 'Меню плеера';

  @override
  String get fontStyle => 'Шрифт';

  @override
  String get fontSerif => 'С засечками';

  @override
  String get fontSans => 'Без засечек';

  @override
  String get lyricsSettings => 'Настройки текста';

  @override
  String get lyricsFontSize => 'Размер шрифта';

  @override
  String get lyricsCentered => 'Выравнивать по центру';

  @override
  String get lyricsTranslation => 'Показывать перевод';

  @override
  String lyricsFontSizeRange(int min, int max) {
    return '$min–$max';
  }

  @override
  String get lyricsFontSizeInvalid => 'Введите допустимый размер';

  @override
  String get settingsGeneral => 'Основные';

  @override
  String get settingsStartPage => 'Стартовая страница';

  @override
  String get settingsStartPageHint =>
      'Страница, которая открывается при запуске приложения';

  @override
  String get playerBackground => 'Фон плеера';

  @override
  String get progressStyle => 'Стиль индикатора прогресса';

  @override
  String get progressMaterial => 'Material';

  @override
  String get progressClassic => 'Классическая точка';

  @override
  String get progressSlim => 'Тонкая линия';

  @override
  String get progressWave => 'Волна';

  @override
  String get backgroundGradient => 'Градиент темы';

  @override
  String get backgroundBlurredCover => 'Размытая обложка';

  @override
  String get playerBackgroundHint =>
      'Увеличивает и сильно размывает обложку альбома для эффекта погружения.';

  @override
  String get settingsShortcuts => 'Горячие клавиши';

  @override
  String get shortcutPlayback => 'Воспроизведение / пауза';

  @override
  String get shortcutSpace => 'Пробел';

  @override
  String get shortcutTracks => 'Предыдущая / следующая песня';

  @override
  String get shortcutWindow => 'Войти в полноэкранный режим / выйти';

  @override
  String get lyricsLineHeight => 'Межстрочный интервал';

  @override
  String get lyricsLineHeightInvalid => 'Введите значение от 1 до 2';

  @override
  String get newPlaylist => 'Новый плейлист';

  @override
  String get playlistName => 'Название плейлиста';

  @override
  String get playlistNameHint => 'например, По дороге на работу';

  @override
  String get create => 'Создать';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get rename => 'Переименовать';

  @override
  String get delete => 'Удалить';

  @override
  String get remove => 'Убрать';

  @override
  String get removeFromPlaylist => 'Убрать из этого плейлиста';

  @override
  String get addToPlaylist => 'Добавить в плейлист';

  @override
  String addedToPlaylist(String name) {
    return 'Добавлено в «$name»';
  }

  @override
  String get deletePlaylistTitle => 'Удалить плейлист?';

  @override
  String deletePlaylistBody(String name) {
    return 'Плейлист «$name» будет удалён. Файлы с музыкой не затрагиваются.';
  }

  @override
  String get playlistEmpty => 'Этот плейлист пуст';

  @override
  String get playlistEmptyBody =>
      'Выберите «Добавить в плейлист» в меню любой песни.';

  @override
  String playlistTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песни',
      many: '$count песен',
      few: '$count песни',
      one: '$count песня',
    );
    return '$_temp0';
  }

  @override
  String get reorder => 'Перетащите, чтобы изменить порядок';

  @override
  String get libraryFolders => 'Папки с музыкой';

  @override
  String get libraryFoldersHint =>
      'Файлы FLAC и MP3 в этих папках сканируются рекурсивно.';

  @override
  String get libraryNoFolders => 'Папок с музыкой пока нет';

  @override
  String get addFolder => 'Добавить папку';

  @override
  String get excludeFolder => 'Исключить папку';

  @override
  String get excludedTag => 'Исключена';

  @override
  String get removeFolder => 'Убрать эту папку';

  @override
  String get folderAlreadyAdded => 'Эта папка уже есть в списке';

  @override
  String get rescan => 'Сканировать снова';

  @override
  String get scanWalking => 'Поиск музыкальных файлов…';

  @override
  String scanReading(int done, int total) {
    return 'Чтение тегов $done / $total';
  }

  @override
  String get scanFinishing => 'Наведение порядка в медиатеке…';

  @override
  String get scanDone => 'Сканирование завершено';

  @override
  String scanDoneWithErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла',
      many: '$count файлов',
      few: '$count файла',
      one: '$count файл',
    );
    return 'Сканирование завершено; не удалось прочитать теги: $_temp0';
  }

  @override
  String get scanFailed => 'Не удалось выполнить сканирование';

  @override
  String get emptyLibraryBody =>
      'Добавьте папку с музыкой, и песни появятся здесь.';

  @override
  String get useBundledFonts => 'Использовать встроенные шрифты';

  @override
  String get useBundledFontsHint =>
      'Без засечек — HarmonyOS Sans; с засечками — EB Garamond и Noto Serif SC. Выключите, чтобы использовать системные шрифты.';

  @override
  String get aboutFonts => 'Шрифты';

  @override
  String get aboutFontsCredit =>
      'HarmonyOS Sans (© Huawei Device Co., Ltd.), EB Garamond и Noto Serif SC (SIL OFL)';

  @override
  String get pickFolderMessage =>
      'Выберите папки с музыкой (FLAC, MP3). Можно выбрать несколько.';

  @override
  String get pickExcludeMessage =>
      'Выберите папки, которые нужно пропускать при сканировании.';

  @override
  String get folderNotUsable =>
      'Не удаётся прочитать эту папку. Выберите другое место.';

  @override
  String get folderPickFailed => 'Не удалось открыть окно выбора папки';

  @override
  String get musicPermissionTitle => 'Разрешение на чтение музыки';

  @override
  String get musicPermissionBody =>
      'NyaPlayer читает только аудиофайлы в выбранных вами папках, на этом устройстве, и никогда не выходит в интернет. Разрешите доступ к музыке и аудио, иначе медиатеку нельзя просканировать.';

  @override
  String get musicPermissionSettings => 'Открыть настройки системы';

  @override
  String get settingsMinLength => 'Минимальная длительность';

  @override
  String get minLengthOff => 'Показывать все треки';

  @override
  String minLengthSummary(String duration) {
    return 'Скрывать треки короче $duration';
  }

  @override
  String lengthSeconds(int count) {
    return '$count с';
  }

  @override
  String lengthMinutes(int count) {
    return '$count мин';
  }

  @override
  String get eqSavePreset => 'Сохранить как пресет';

  @override
  String get eqPresetName => 'Название пресета';

  @override
  String eqDeletePresetBody(String name) {
    return 'Удалить пресет «$name»?';
  }

  @override
  String get notificationPermissionTitle =>
      'Показывать элементы управления воспроизведением?';

  @override
  String get notificationPermissionBody =>
      'Разрешите уведомления, чтобы управлять воспроизведением из шторки и с экрана блокировки. Воспроизведение работает и без них.';

  @override
  String get allow => 'Разрешить';

  @override
  String get flowingLight => 'Текучий световой фон';

  @override
  String get flowingLightHint =>
      'Мягкий цветной свет медленно перемещается по фону плеера, повторяя цвета обложки. У Hi-Res-треков добавляется золотой оттенок.';

  @override
  String get surfaceMaterial => 'Материал';

  @override
  String get materialStandard => 'Стандартный';

  @override
  String get materialGlass => 'Премиум-стекло';

  @override
  String get surfaceMaterialHint =>
      'Премиум-стекло превращает боковую панель, карточки, панель плеера и меню в полупрозрачное матовое стекло поверх плавно движущегося света. Расходует больше энергии.';

  @override
  String get settingsPlaybackCore => 'Движок воспроизведения';

  @override
  String get settingsPlaybackCoreHint =>
      'Системное декодирование (Media3) или ядро Rust. Чтобы применить, перезапустите приложение.';

  @override
  String get playbackCoreSystem => 'Система (Media3)';

  @override
  String get playbackCoreRust => 'Ядро Rust';

  @override
  String get settingsSuperRes => 'ИИ-апскейл (SQ-AI)';

  @override
  String get settingsSuperResHint =>
      'Преобразует MP3 во FLAC с помощью ИИ-модели на GPU этого Mac. MP3 остаётся; новый файл сохраняется рядом как «имя.SQ-AI.flac». Это сгенерированный звук, а не оригинальная запись. Занимает примерно половину длительности трека.';

  @override
  String get srModelMissing => 'В этой сборке не установлена ИИ-модель.';

  @override
  String get srChooseFiles => 'Выбрать треки…';

  @override
  String get srClearFinished => 'Убрать завершённые';

  @override
  String get srWaiting => 'Ожидание';

  @override
  String get srDone => 'Готово';

  @override
  String get srCancelled => 'Отменено';

  @override
  String get srExists => 'Уже преобразовано';

  @override
  String srFailed(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get srPickerTitle => 'MP3-треки для преобразования';

  @override
  String get srPickerEmpty => 'В медиатеке нет MP3 для преобразования.';

  @override
  String srConvertSelected(int count) {
    return 'Преобразовать: $count';
  }

  @override
  String get srSelectAll => 'Выбрать все';

  @override
  String get srSelectNone => 'Снять выбор';

  @override
  String get srDesktopOnly =>
      'Только для компьютера. На телефонах и планшетах недоступно.';
}
