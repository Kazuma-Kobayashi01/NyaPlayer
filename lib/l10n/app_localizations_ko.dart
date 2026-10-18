// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'NyaPlayer';

  @override
  String get showAppWindow => 'NyaPlayer 보기';

  @override
  String get quitApp => 'NyaPlayer 종료';

  @override
  String get navSongs => '노래';

  @override
  String get navAlbums => '앨범';

  @override
  String get navArtists => '아티스트';

  @override
  String get navFolders => '폴더';

  @override
  String get navPlaylists => '재생목록';

  @override
  String get search => '검색';

  @override
  String get searchHint => '노래, 앨범, 아티스트 검색';

  @override
  String get searchNoResults => '검색 결과가 없습니다';

  @override
  String get sectionSongs => '노래';

  @override
  String get sectionAlbums => '앨범';

  @override
  String get sectionArtists => '아티스트';

  @override
  String get moreOptions => '옵션 더 보기';

  @override
  String get sortTitle => '제목';

  @override
  String get sortArtist => '아티스트';

  @override
  String get sortAlbum => '앨범';

  @override
  String get sortAdded => '추가한 날짜';

  @override
  String get sortDuration => '재생 시간';

  @override
  String get sortAscending => '오름차순';

  @override
  String get sortDescending => '내림차순';

  @override
  String songCount(int count) {
    return '노래 $count곡';
  }

  @override
  String albumCount(int count) {
    return '앨범 $count장';
  }

  @override
  String get playAll => '모두 재생';

  @override
  String get shufflePlay => '셔플 재생';

  @override
  String get playNext => '다음에 재생';

  @override
  String get addToQueue => '대기열에 추가';

  @override
  String get songInfo => '노래 정보';

  @override
  String get addedToQueue => '대기열에 추가했습니다';

  @override
  String get willPlayNext => '다음에 재생됩니다';

  @override
  String get nowPlaying => '재생 중';

  @override
  String get notPlaying => '재생 중인 노래 없음';

  @override
  String get notPlayingHint => '보관함에서 노래를 골라 재생을 시작하세요';

  @override
  String get queue => '재생 대기열';

  @override
  String get queueEmpty => '대기열이 비어 있습니다';

  @override
  String get lyrics => '가사';

  @override
  String get cover => '커버';

  @override
  String get noLyrics => '가사 없음';

  @override
  String get close => '닫기';

  @override
  String get back => '뒤로';

  @override
  String get play => '재생';

  @override
  String get pause => '일시정지';

  @override
  String get previous => '이전';

  @override
  String get next => '다음';

  @override
  String get repeatOff => '반복: 끔';

  @override
  String get repeatAll => '반복: 전체';

  @override
  String get repeatOne => '반복: 한 곡';

  @override
  String get shuffleOn => '셔플: 켬';

  @override
  String get shuffleOff => '셔플: 끔';

  @override
  String discLabel(int number) {
    return '디스크 $number';
  }

  @override
  String get infoPath => '경로';

  @override
  String get infoFormat => '형식';

  @override
  String get infoSampleRate => '샘플 레이트';

  @override
  String get infoBitDepth => '비트 심도';

  @override
  String get infoBitrate => '비트레이트';

  @override
  String get infoChannels => '채널';

  @override
  String get infoDuration => '재생 시간';

  @override
  String get infoYear => '연도';

  @override
  String get infoGenre => '장르';

  @override
  String get infoTrackNo => '트랙';

  @override
  String get infoAlbum => '앨범';

  @override
  String get infoArtist => '아티스트';

  @override
  String bitDepthValue(int bits) {
    return '$bits비트';
  }

  @override
  String bitrateValue(int kbps) {
    return '${kbps}kbps';
  }

  @override
  String get channelsStereo => '스테레오';

  @override
  String get channelsMono => '모노';

  @override
  String get eqTitle => '이퀄라이저';

  @override
  String get eqEnabled => '이퀄라이저 사용';

  @override
  String get eqPresets => '프리셋';

  @override
  String get eqPreamp => '프리앰프';

  @override
  String get eqAutoClip => '클리핑 방지';

  @override
  String get eqReset => '초기화';

  @override
  String get eqPresetFlat => '플랫';

  @override
  String get eqPresetPop => '팝';

  @override
  String get eqPresetRock => '록';

  @override
  String get eqPresetJazz => '재즈';

  @override
  String get eqPresetClassical => '클래식';

  @override
  String get eqPresetVocal => '보컬';

  @override
  String get eqPresetBassBoost => '저음 강화';

  @override
  String get eqPresetTrebleBoost => '고음 강화';

  @override
  String get eqPresetCustom => '사용자 설정';

  @override
  String get settingsAppearance => '화면 스타일';

  @override
  String get settingsThemeMode => '테마 모드';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get themeSystem => '시스템';

  @override
  String get settingsColorSource => '색상 출처';

  @override
  String get colorSourceWallpaper => '시스템';

  @override
  String get colorSourceFixed => '고정 색상';

  @override
  String get settingsSeedColor => '테마 색상';

  @override
  String get settingsLanguage => '언어';

  @override
  String get langSystem => '시스템';

  @override
  String get settingsLibrary => '보관함';

  @override
  String get settingsAbout => '정보';

  @override
  String get aboutVersion => '버전';

  @override
  String get aboutLicenses => '오픈 소스 라이선스';

  @override
  String get aboutRerunOnboarding => '시작 화면 다시 보기';

  @override
  String get onboardingTitle => 'NyaPlayer에 오신 것을 환영합니다';

  @override
  String get onboardingBody =>
      '광고 없이 오프라인으로 로컬 음악을 재생하는 플레이어입니다. 음악 폴더를 선택해 듣기 시작하세요.';

  @override
  String get onboardingChoose => '음악 폴더 선택';

  @override
  String get onboardingSkip => '나중에';

  @override
  String get playlistsEmptyTitle => '아직 재생목록이 없습니다';

  @override
  String get playlistsEmptyBody => '버튼을 눌러 만든 다음, 노래 메뉴에서 노래를 추가하세요.';

  @override
  String get loadFailed => '불러오지 못했습니다';

  @override
  String get emptyLibrary => '보관함이 비어 있습니다';

  @override
  String get variousArtists => '여러 아티스트';

  @override
  String get navFavorites => '즐겨찾기';

  @override
  String get navSettings => '설정';

  @override
  String get openNavigation => '탐색 메뉴 열기';

  @override
  String get favorite => '즐겨찾기에 추가';

  @override
  String get unfavorite => '즐겨찾기에서 삭제';

  @override
  String get favoritesEmptyTitle => '아직 즐겨찾는 노래가 없습니다';

  @override
  String get favoritesEmptyBody => '노래 메뉴나 플레이어에서 ♡를 누르면 여기에 추가됩니다.';

  @override
  String get settingsPlayback => '재생';

  @override
  String get colorSourceHint =>
      '시스템 색상 또는 고정 테마 색상을 사용합니다. 플레이어 배경은 따로 설정할 수 있습니다.';

  @override
  String get settingsEqualizerSubtitle => '10밴드 이퀄라이저 및 프리셋';

  @override
  String get coverShape => '커버 스타일';

  @override
  String get coverShapeSquare => '사각형';

  @override
  String get coverShapeDisc => '원형(회전)';

  @override
  String get coverShapeTurntable => '턴테이블';

  @override
  String get expandPlayer => '플레이어 확대';

  @override
  String get collapsePlayer => '접기';

  @override
  String get playerMenu => '플레이어 메뉴';

  @override
  String get fontStyle => '글꼴';

  @override
  String get fontSerif => '세리프';

  @override
  String get fontSans => '산세리프';

  @override
  String get lyricsSettings => '가사 설정';

  @override
  String get lyricsFontSize => '글꼴 크기';

  @override
  String get lyricsCentered => '가운데 정렬';

  @override
  String get lyricsTranslation => '번역 표시';

  @override
  String lyricsFontSizeRange(int min, int max) {
    return '$min~$max';
  }

  @override
  String get lyricsFontSizeInvalid => '올바른 크기를 입력하세요';

  @override
  String get settingsGeneral => '일반';

  @override
  String get settingsStartPage => '시작 페이지';

  @override
  String get settingsStartPageHint => '앱을 열 때 표시되는 페이지';

  @override
  String get playerBackground => '플레이어 배경';

  @override
  String get progressStyle => '재생 막대 스타일';

  @override
  String get progressMaterial => 'Material';

  @override
  String get progressClassic => '클래식 점';

  @override
  String get progressSlim => '가는 선';

  @override
  String get progressWave => '물결';

  @override
  String get backgroundGradient => '테마 그라데이션';

  @override
  String get backgroundBlurredCover => '흐린 커버';

  @override
  String get playerBackgroundHint => '앨범 커버를 확대하고 강하게 흐려 몰입감 있는 배경을 만듭니다.';

  @override
  String get settingsShortcuts => '키보드 단축키';

  @override
  String get shortcutPlayback => '재생 / 일시정지';

  @override
  String get shortcutSpace => '스페이스바';

  @override
  String get shortcutTracks => '이전 / 다음 곡';

  @override
  String get shortcutWindow => '전체 화면 시작 / 종료';

  @override
  String get lyricsLineHeight => '줄 간격';

  @override
  String get lyricsLineHeightInvalid => '1~2 사이의 값을 입력하세요';

  @override
  String get newPlaylist => '새 재생목록';

  @override
  String get playlistName => '재생목록 이름';

  @override
  String get playlistNameHint => '예: 출퇴근길';

  @override
  String get create => '만들기';

  @override
  String get save => '저장';

  @override
  String get cancel => '취소';

  @override
  String get rename => '이름 바꾸기';

  @override
  String get delete => '삭제';

  @override
  String get remove => '제거';

  @override
  String get removeFromPlaylist => '이 재생목록에서 제거';

  @override
  String get addToPlaylist => '재생목록에 추가';

  @override
  String addedToPlaylist(String name) {
    return '“$name”에 추가했습니다';
  }

  @override
  String get deletePlaylistTitle => '재생목록을 삭제할까요?';

  @override
  String deletePlaylistBody(String name) {
    return '“$name”을(를) 삭제합니다. 음악 파일은 그대로 유지됩니다.';
  }

  @override
  String get playlistEmpty => '이 재생목록은 비어 있습니다';

  @override
  String get playlistEmptyBody => '노래 메뉴에서 ‘재생목록에 추가’를 선택하세요.';

  @override
  String playlistTracks(int count) {
    return '$count곡';
  }

  @override
  String get reorder => '끌어서 순서 변경';

  @override
  String get libraryFolders => '음악 폴더';

  @override
  String get libraryFoldersHint => '이 폴더 안의 FLAC 및 MP3 파일을 하위 폴더까지 검색합니다.';

  @override
  String get libraryNoFolders => '아직 음악 폴더가 없습니다';

  @override
  String get addFolder => '폴더 추가';

  @override
  String get excludeFolder => '폴더 제외';

  @override
  String get excludedTag => '제외됨';

  @override
  String get removeFolder => '이 폴더 제거';

  @override
  String get folderAlreadyAdded => '이미 목록에 있는 폴더입니다';

  @override
  String get rescan => '다시 검색';

  @override
  String get scanWalking => '음악 파일을 찾는 중…';

  @override
  String scanReading(int done, int total) {
    return '태그 읽는 중 $done / $total';
  }

  @override
  String get scanFinishing => '보관함을 정리하는 중…';

  @override
  String get scanDone => '검색을 완료했습니다';

  @override
  String scanDoneWithErrors(int count) {
    return '검색을 완료했습니다. 파일 $count개의 태그를 읽지 못했습니다';
  }

  @override
  String get scanFailed => '검색하지 못했습니다';

  @override
  String get emptyLibraryBody => '음악 폴더를 추가하면 노래가 여기에 표시됩니다.';

  @override
  String get useBundledFonts => '내장 글꼴 사용';

  @override
  String get useBundledFontsHint =>
      '산세리프는 HarmonyOS Sans, 세리프는 EB Garamond와 Noto Serif SC를 사용합니다. 끄면 시스템 글꼴을 사용합니다.';

  @override
  String get aboutFonts => '글꼴';

  @override
  String get aboutFontsCredit =>
      'HarmonyOS Sans (© Huawei Device Co., Ltd.), EB Garamond, Noto Serif SC (SIL OFL)';

  @override
  String get pickFolderMessage =>
      '음악(FLAC, MP3)이 들어 있는 폴더를 선택하세요. 여러 개를 선택할 수 있습니다.';

  @override
  String get pickExcludeMessage => '검색할 때 건너뛸 폴더를 선택하세요.';

  @override
  String get folderNotUsable => '이 폴더를 읽을 수 없습니다. 다른 위치를 선택하세요.';

  @override
  String get folderPickFailed => '폴더 선택 창을 열 수 없습니다';

  @override
  String get musicPermissionTitle => '음악 읽기 권한';

  @override
  String get musicPermissionBody =>
      'NyaPlayer는 선택한 폴더의 오디오 파일만 이 기기에서 읽으며 인터넷에 연결하지 않습니다. 음악 및 오디오 접근을 허용해 주세요. 허용하지 않으면 보관함을 검색할 수 없습니다.';

  @override
  String get musicPermissionSettings => '시스템 설정 열기';

  @override
  String get settingsMinLength => '최소 재생 시간';

  @override
  String get minLengthOff => '모두 표시';

  @override
  String minLengthSummary(String duration) {
    return '$duration보다 짧은 곡 숨기기';
  }

  @override
  String lengthSeconds(int count) {
    return '$count초';
  }

  @override
  String lengthMinutes(int count) {
    return '$count분';
  }

  @override
  String get eqSavePreset => '프리셋으로 저장';

  @override
  String get eqPresetName => '프리셋 이름';

  @override
  String eqDeletePresetBody(String name) {
    return '프리셋 “$name”을(를) 삭제할까요?';
  }

  @override
  String get notificationPermissionTitle => '재생 컨트롤을 표시할까요?';

  @override
  String get notificationPermissionBody =>
      '알림을 허용하면 알림 창과 잠금 화면에서 재생을 제어할 수 있습니다. 허용하지 않아도 재생은 됩니다.';

  @override
  String get allow => '허용';

  @override
  String get flowingLight => '흐르는 빛 배경';

  @override
  String get flowingLightHint =>
      '재생 화면 배경에 앨범 커버 색을 따른 부드러운 빛이 천천히 흐릅니다. Hi-Res 곡에는 금빛이 살짝 더해집니다.';

  @override
  String get surfaceMaterial => '재질';

  @override
  String get materialStandard => '표준';

  @override
  String get materialGlass => '프리미엄 유리';

  @override
  String get surfaceMaterialHint =>
      '사이드바, 카드, 재생 바, 서랍이 반투명 젖빛 유리로 바뀌고 그 뒤로 천천히 움직이는 빛이 비칩니다. 전력을 더 사용합니다.';

  @override
  String get settingsPlaybackCore => '재생 엔진';

  @override
  String get settingsPlaybackCoreHint =>
      '시스템 디코딩(Media3) 또는 Rust 엔진. 적용하려면 앱을 다시 시작하세요.';

  @override
  String get playbackCoreSystem => '시스템 (Media3)';

  @override
  String get playbackCoreRust => 'Rust 엔진';
}
