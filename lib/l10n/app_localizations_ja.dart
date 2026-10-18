// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'NyaPlayer';

  @override
  String get showAppWindow => 'NyaPlayerを表示';

  @override
  String get quitApp => 'NyaPlayerを終了';

  @override
  String get navSongs => '曲';

  @override
  String get navAlbums => 'アルバム';

  @override
  String get navArtists => 'アーティスト';

  @override
  String get navFolders => 'フォルダ';

  @override
  String get navPlaylists => 'プレイリスト';

  @override
  String get search => '検索';

  @override
  String get searchHint => '曲、アルバム、アーティストを検索';

  @override
  String get searchNoResults => '見つかりませんでした';

  @override
  String get sectionSongs => '曲';

  @override
  String get sectionAlbums => 'アルバム';

  @override
  String get sectionArtists => 'アーティスト';

  @override
  String get moreOptions => 'その他のオプション';

  @override
  String get sortTitle => 'タイトル';

  @override
  String get sortArtist => 'アーティスト';

  @override
  String get sortAlbum => 'アルバム';

  @override
  String get sortAdded => '追加日';

  @override
  String get sortDuration => '長さ';

  @override
  String get sortAscending => '昇順';

  @override
  String get sortDescending => '降順';

  @override
  String songCount(int count) {
    return '$count曲';
  }

  @override
  String albumCount(int count) {
    return '$count枚のアルバム';
  }

  @override
  String get playAll => 'すべて再生';

  @override
  String get shufflePlay => 'シャッフル再生';

  @override
  String get playNext => '次に再生';

  @override
  String get addToQueue => 'キューに追加';

  @override
  String get songInfo => '曲の情報';

  @override
  String get addedToQueue => 'キューに追加しました';

  @override
  String get willPlayNext => '次に再生します';

  @override
  String get nowPlaying => '再生中';

  @override
  String get notPlaying => '再生していません';

  @override
  String get notPlayingHint => 'ライブラリから曲を選んで再生を始めましょう';

  @override
  String get queue => '再生キュー';

  @override
  String get queueEmpty => 'キューは空です';

  @override
  String get lyrics => '歌詞';

  @override
  String get cover => 'ジャケット';

  @override
  String get noLyrics => '歌詞がありません';

  @override
  String get close => '閉じる';

  @override
  String get back => '戻る';

  @override
  String get play => '再生';

  @override
  String get pause => '一時停止';

  @override
  String get previous => '前の曲';

  @override
  String get next => '次の曲';

  @override
  String get repeatOff => 'リピート：オフ';

  @override
  String get repeatAll => 'リピート：全曲';

  @override
  String get repeatOne => 'リピート：1曲';

  @override
  String get shuffleOn => 'シャッフル：オン';

  @override
  String get shuffleOff => 'シャッフル：オフ';

  @override
  String discLabel(int number) {
    return 'ディスク $number';
  }

  @override
  String get infoPath => 'パス';

  @override
  String get infoFormat => 'フォーマット';

  @override
  String get infoSampleRate => 'サンプルレート';

  @override
  String get infoBitDepth => 'ビット深度';

  @override
  String get infoBitrate => 'ビットレート';

  @override
  String get infoChannels => 'チャンネル';

  @override
  String get infoDuration => '長さ';

  @override
  String get infoYear => '年';

  @override
  String get infoGenre => 'ジャンル';

  @override
  String get infoTrackNo => 'トラック';

  @override
  String get infoAlbum => 'アルバム';

  @override
  String get infoArtist => 'アーティスト';

  @override
  String bitDepthValue(int bits) {
    return '$bits bit';
  }

  @override
  String bitrateValue(int kbps) {
    return '$kbps kbps';
  }

  @override
  String get channelsStereo => 'ステレオ';

  @override
  String get channelsMono => 'モノラル';

  @override
  String get eqTitle => 'イコライザー';

  @override
  String get eqEnabled => 'イコライザーを有効にする';

  @override
  String get eqPresets => 'プリセット';

  @override
  String get eqPreamp => 'プリアンプ';

  @override
  String get eqAutoClip => 'クリッピングを防止';

  @override
  String get eqReset => 'リセット';

  @override
  String get eqPresetFlat => 'フラット';

  @override
  String get eqPresetPop => 'ポップ';

  @override
  String get eqPresetRock => 'ロック';

  @override
  String get eqPresetJazz => 'ジャズ';

  @override
  String get eqPresetClassical => 'クラシック';

  @override
  String get eqPresetVocal => 'ボーカル';

  @override
  String get eqPresetBassBoost => '低音強調';

  @override
  String get eqPresetTrebleBoost => '高音強調';

  @override
  String get eqPresetCustom => 'カスタム';

  @override
  String get settingsAppearance => '外観';

  @override
  String get settingsThemeMode => 'テーマモード';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeSystem => 'システム';

  @override
  String get settingsColorSource => 'カラーの取得元';

  @override
  String get colorSourceWallpaper => 'システム';

  @override
  String get colorSourceFixed => '固定カラー';

  @override
  String get settingsSeedColor => 'テーマカラー';

  @override
  String get settingsLanguage => '言語';

  @override
  String get langSystem => 'システム';

  @override
  String get settingsLibrary => 'ライブラリ';

  @override
  String get settingsAbout => 'このアプリについて';

  @override
  String get aboutVersion => 'バージョン';

  @override
  String get aboutLicenses => 'オープンソースライセンス';

  @override
  String get aboutRerunOnboarding => 'ウェルカム画面をもう一度表示';

  @override
  String get onboardingTitle => 'NyaPlayerへようこそ';

  @override
  String get onboardingBody =>
      'ローカル再生専用、広告なし、オフラインの音楽プレーヤーです。音楽フォルダを選んで聴き始めましょう。';

  @override
  String get onboardingChoose => '音楽フォルダを選択';

  @override
  String get onboardingSkip => 'あとで';

  @override
  String get playlistsEmptyTitle => 'プレイリストはまだありません';

  @override
  String get playlistsEmptyBody => 'ボタンをタップして作成し、曲のメニューから曲を追加します。';

  @override
  String get loadFailed => '読み込めませんでした';

  @override
  String get emptyLibrary => 'ライブラリは空です';

  @override
  String get variousArtists => 'さまざまなアーティスト';

  @override
  String get navFavorites => 'お気に入り';

  @override
  String get navSettings => '設定';

  @override
  String get openNavigation => 'ナビゲーションメニューを開く';

  @override
  String get favorite => 'お気に入りに追加';

  @override
  String get unfavorite => 'お気に入りから削除';

  @override
  String get favoritesEmptyTitle => 'お気に入りはまだありません';

  @override
  String get favoritesEmptyBody => '曲のメニューまたはプレーヤーで ♡ をタップすると、ここに追加されます。';

  @override
  String get settingsPlayback => '再生';

  @override
  String get colorSourceHint => 'システムカラーまたは固定のテーマカラーを使います。プレーヤーの背景は別に設定できます。';

  @override
  String get settingsEqualizerSubtitle => '10バンドイコライザーとプリセット';

  @override
  String get coverShape => 'ジャケットのスタイル';

  @override
  String get coverShapeSquare => '四角';

  @override
  String get coverShapeDisc => '円形（回転）';

  @override
  String get coverShapeTurntable => 'ターンテーブル';

  @override
  String get expandPlayer => 'プレーヤーを拡大';

  @override
  String get collapsePlayer => '閉じる';

  @override
  String get playerMenu => 'プレーヤーメニュー';

  @override
  String get fontStyle => 'フォント';

  @override
  String get fontSerif => 'セリフ体';

  @override
  String get fontSans => 'サンセリフ体';

  @override
  String get lyricsSettings => '歌詞の設定';

  @override
  String get lyricsFontSize => '文字サイズ';

  @override
  String get lyricsCentered => '中央揃え';

  @override
  String get lyricsTranslation => '翻訳を表示';

  @override
  String lyricsFontSizeRange(int min, int max) {
    return '$min～$max';
  }

  @override
  String get lyricsFontSizeInvalid => '有効なサイズを入力してください';

  @override
  String get settingsGeneral => '一般';

  @override
  String get settingsStartPage => '起動時のページ';

  @override
  String get settingsStartPageHint => 'アプリを開いたときに表示するページ';

  @override
  String get playerBackground => 'プレーヤーの背景';

  @override
  String get progressStyle => 'プログレスバーのスタイル';

  @override
  String get progressMaterial => 'Material';

  @override
  String get progressClassic => 'クラシックなドット';

  @override
  String get progressSlim => '細い線';

  @override
  String get progressWave => '波';

  @override
  String get backgroundGradient => 'テーマのグラデーション';

  @override
  String get backgroundBlurredCover => 'ぼかしたジャケット';

  @override
  String get playerBackgroundHint => 'アルバムのジャケットを拡大して強くぼかし、没入感のある背景にします。';

  @override
  String get settingsShortcuts => 'キーボードショートカット';

  @override
  String get shortcutPlayback => '再生 / 一時停止';

  @override
  String get shortcutSpace => 'スペース';

  @override
  String get shortcutTracks => '前の曲 / 次の曲';

  @override
  String get shortcutWindow => '全画面表示の開始 / 終了';

  @override
  String get lyricsLineHeight => '行間';

  @override
  String get lyricsLineHeightInvalid => '1～2の間の値を入力してください';

  @override
  String get newPlaylist => '新規プレイリスト';

  @override
  String get playlistName => 'プレイリスト名';

  @override
  String get playlistNameHint => '例：通勤用';

  @override
  String get create => '作成';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get rename => '名前を変更';

  @override
  String get delete => '削除';

  @override
  String get remove => '削除';

  @override
  String get removeFromPlaylist => 'このプレイリストから削除';

  @override
  String get addToPlaylist => 'プレイリストに追加';

  @override
  String addedToPlaylist(String name) {
    return '「$name」に追加しました';
  }

  @override
  String get deletePlaylistTitle => 'プレイリストを削除しますか？';

  @override
  String deletePlaylistBody(String name) {
    return '「$name」を削除します。曲のファイルは変更されません。';
  }

  @override
  String get playlistEmpty => 'このプレイリストは空です';

  @override
  String get playlistEmptyBody => '曲のメニューで「プレイリストに追加」を選んでください。';

  @override
  String playlistTracks(int count) {
    return '$count曲';
  }

  @override
  String get reorder => 'ドラッグして並べ替え';

  @override
  String get libraryFolders => '音楽フォルダ';

  @override
  String get libraryFoldersHint => 'これらのフォルダ内のFLACとMP3ファイルを再帰的にスキャンします。';

  @override
  String get libraryNoFolders => '音楽フォルダはまだありません';

  @override
  String get addFolder => 'フォルダを追加';

  @override
  String get excludeFolder => 'フォルダを除外';

  @override
  String get excludedTag => '除外';

  @override
  String get removeFolder => 'このフォルダを削除';

  @override
  String get folderAlreadyAdded => 'このフォルダはすでにリストにあります';

  @override
  String get rescan => '再スキャン';

  @override
  String get scanWalking => '音楽ファイルを探しています…';

  @override
  String scanReading(int done, int total) {
    return 'タグを読み込み中 $done / $total';
  }

  @override
  String get scanFinishing => 'ライブラリを整理しています…';

  @override
  String get scanDone => 'スキャンが完了しました';

  @override
  String scanDoneWithErrors(int count) {
    return 'スキャンが完了しました。$count個のファイルのタグを読み込めませんでした';
  }

  @override
  String get scanFailed => 'スキャンに失敗しました';

  @override
  String get emptyLibraryBody => '音楽フォルダを追加すると、曲がここに表示されます。';

  @override
  String get useBundledFonts => '内蔵フォントを使用';

  @override
  String get useBundledFontsHint =>
      'サンセリフ体はHarmonyOS Sans、セリフ体はEB GaramondとNoto Serif SCを使います。オフにするとシステムフォントを使います。';

  @override
  String get aboutFonts => 'フォント';

  @override
  String get aboutFontsCredit =>
      'HarmonyOS Sans（© Huawei Device Co., Ltd.）、EB Garamond、Noto Serif SC（SIL OFL）';

  @override
  String get pickFolderMessage => '音楽（FLAC、MP3）が入っているフォルダを選んでください。複数選択できます。';

  @override
  String get pickExcludeMessage => 'スキャン時にスキップするフォルダを選んでください。';

  @override
  String get folderNotUsable => 'このフォルダは読み込めません。別の場所を選んでください。';

  @override
  String get folderPickFailed => 'フォルダ選択画面を開けませんでした';

  @override
  String get musicPermissionTitle => '音楽を読み取る権限';

  @override
  String get musicPermissionBody =>
      'NyaPlayerは、選択したフォルダ内の音声ファイルをこのデバイス上でのみ読み取り、インターネットには接続しません。音楽とオーディオへのアクセスを許可してください。許可しないとライブラリをスキャンできません。';

  @override
  String get musicPermissionSettings => 'システム設定を開く';

  @override
  String get settingsMinLength => '最短の長さ';

  @override
  String get minLengthOff => 'すべて表示';

  @override
  String minLengthSummary(String duration) {
    return '$duration未満の曲を非表示';
  }

  @override
  String lengthSeconds(int count) {
    return '$count秒';
  }

  @override
  String lengthMinutes(int count) {
    return '$count分';
  }

  @override
  String get eqSavePreset => 'プリセットとして保存';

  @override
  String get eqPresetName => 'プリセット名';

  @override
  String eqDeletePresetBody(String name) {
    return 'プリセット「$name」を削除しますか？';
  }

  @override
  String get notificationPermissionTitle => '再生コントロールを表示しますか？';

  @override
  String get notificationPermissionBody =>
      '通知を許可すると、通知パネルやロック画面から再生を操作できます。許可しなくても再生はできます。';

  @override
  String get allow => '許可';

  @override
  String get flowingLight => '流れる光の背景';

  @override
  String get flowingLightHint =>
      'プレーヤーの背景に、ジャケットの色をもとにした柔らかな光がゆっくり流れます。Hi-Res の曲には金色が少し加わります。';

  @override
  String get surfaceMaterial => 'マテリアル';

  @override
  String get materialStandard => '標準';

  @override
  String get materialGlass => 'プレミアムガラス';

  @override
  String get surfaceMaterialHint =>
      'サイドバー、カード、プレーヤーバー、ドロワーが半透明のすりガラスになり、背後でゆっくり動く光が透けて見えます。消費電力が増えます。';

  @override
  String get settingsPlaybackCore => '再生エンジン';

  @override
  String get settingsPlaybackCoreHint =>
      'システムデコード（Media3）またはRustエンジン。反映には再起動が必要です。';

  @override
  String get playbackCoreSystem => 'システム（Media3）';

  @override
  String get playbackCoreRust => 'Rustエンジン';
}
