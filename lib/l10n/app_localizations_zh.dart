// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'NyaPlayer';

  @override
  String get showAppWindow => '显示 NyaPlayer 窗口';

  @override
  String get quitApp => '退出 NyaPlayer';

  @override
  String get navSongs => '歌曲';

  @override
  String get navAlbums => '专辑';

  @override
  String get navArtists => '艺术家';

  @override
  String get navFolders => '文件夹';

  @override
  String get navPlaylists => '播放列表';

  @override
  String get search => '搜索';

  @override
  String get searchHint => '搜索歌曲、专辑、艺术家';

  @override
  String get searchNoResults => '没有找到结果';

  @override
  String get sectionSongs => '歌曲';

  @override
  String get sectionAlbums => '专辑';

  @override
  String get sectionArtists => '艺术家';

  @override
  String get moreOptions => '更多选项';

  @override
  String get sortTitle => '标题';

  @override
  String get sortArtist => '艺术家';

  @override
  String get sortAlbum => '专辑';

  @override
  String get sortAdded => '添加时间';

  @override
  String get sortDuration => '时长';

  @override
  String get sortAscending => '升序';

  @override
  String get sortDescending => '降序';

  @override
  String songCount(int count) {
    return '$count 首歌曲';
  }

  @override
  String albumCount(int count) {
    return '$count 张专辑';
  }

  @override
  String get playAll => '播放全部';

  @override
  String get shufflePlay => '随机播放';

  @override
  String get playNext => '下一首播放';

  @override
  String get addToQueue => '加入队列';

  @override
  String get songInfo => '歌曲信息';

  @override
  String get addedToQueue => '已加入队列';

  @override
  String get willPlayNext => '将在下一首播放';

  @override
  String get nowPlaying => '正在播放';

  @override
  String get notPlaying => '未在播放';

  @override
  String get notPlayingHint => '从曲库中选择一首歌开始播放';

  @override
  String get queue => '播放队列';

  @override
  String get queueEmpty => '队列是空的';

  @override
  String get lyrics => '歌词';

  @override
  String get cover => '封面';

  @override
  String get noLyrics => '暂无歌词';

  @override
  String get close => '关闭';

  @override
  String get back => '返回';

  @override
  String get play => '播放';

  @override
  String get pause => '暂停';

  @override
  String get previous => '上一首';

  @override
  String get next => '下一首';

  @override
  String get repeatOff => '循环：关';

  @override
  String get repeatAll => '循环：列表';

  @override
  String get repeatOne => '循环：单曲';

  @override
  String get shuffleOn => '随机：开';

  @override
  String get shuffleOff => '随机：关';

  @override
  String discLabel(int number) {
    return '碟 $number';
  }

  @override
  String get infoPath => '路径';

  @override
  String get infoFormat => '格式';

  @override
  String get infoSampleRate => '采样率';

  @override
  String get infoBitDepth => '位深';

  @override
  String get infoBitrate => '码率';

  @override
  String get infoChannels => '声道';

  @override
  String get infoDuration => '时长';

  @override
  String get infoYear => '年份';

  @override
  String get infoGenre => '流派';

  @override
  String get infoTrackNo => '音轨';

  @override
  String get infoAlbum => '专辑';

  @override
  String get infoArtist => '艺术家';

  @override
  String bitDepthValue(int bits) {
    return '$bits bit';
  }

  @override
  String bitrateValue(int kbps) {
    return '$kbps kbps';
  }

  @override
  String get channelsStereo => '立体声';

  @override
  String get channelsMono => '单声道';

  @override
  String get eqTitle => '均衡器';

  @override
  String get eqEnabled => '启用均衡器';

  @override
  String get eqPresets => '预设';

  @override
  String get eqPreamp => '前级增益';

  @override
  String get eqAutoClip => '自动防削波';

  @override
  String get eqReset => '重置';

  @override
  String get eqPresetFlat => '平坦';

  @override
  String get eqPresetPop => '流行';

  @override
  String get eqPresetRock => '摇滚';

  @override
  String get eqPresetJazz => '爵士';

  @override
  String get eqPresetClassical => '古典';

  @override
  String get eqPresetVocal => '人声';

  @override
  String get eqPresetBassBoost => '低音增强';

  @override
  String get eqPresetTrebleBoost => '高音增强';

  @override
  String get eqPresetCustom => '自定义';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsThemeMode => '主题模式';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get settingsColorSource => '配色来源';

  @override
  String get colorSourceWallpaper => '系统配色';

  @override
  String get colorSourceFixed => '固定主题色';

  @override
  String get settingsSeedColor => '主题色';

  @override
  String get settingsLanguage => '语言';

  @override
  String get langSystem => '跟随系统';

  @override
  String get settingsLibrary => '音乐库';

  @override
  String get settingsAbout => '关于';

  @override
  String get aboutVersion => '版本';

  @override
  String get aboutLicenses => '开放源代码许可';

  @override
  String get aboutRerunOnboarding => '重新查看引导页';

  @override
  String get onboardingTitle => '欢迎使用 NyaPlayer';

  @override
  String get onboardingBody => '一个纯本地、无广告、不联网的音乐播放器。选择你的音乐文件夹，开始聆听。';

  @override
  String get onboardingChoose => '选择音乐文件夹';

  @override
  String get onboardingSkip => '稍后再说';

  @override
  String get playlistsEmptyTitle => '还没有播放列表';

  @override
  String get playlistsEmptyBody => '点右下角的按钮新建一个，再从歌曲菜单把歌加进去。';

  @override
  String get loadFailed => '加载失败';

  @override
  String get emptyLibrary => '曲库是空的';

  @override
  String get variousArtists => '多位艺术家';

  @override
  String get navFavorites => '收藏';

  @override
  String get navSettings => '设置';

  @override
  String get openNavigation => '打开导航菜单';

  @override
  String get favorite => '收藏';

  @override
  String get unfavorite => '取消收藏';

  @override
  String get favoritesEmptyTitle => '还没有收藏的歌曲';

  @override
  String get favoritesEmptyBody => '在歌曲菜单或播放页点按 ♡ 即可收藏。';

  @override
  String get settingsPlayback => '播放';

  @override
  String get colorSourceHint => '选择系统配色或固定主题色，播放器背景可单独设置。';

  @override
  String get settingsEqualizerSubtitle => '10 段均衡器与预设';

  @override
  String get coverShape => '封面样式';

  @override
  String get coverShapeSquare => '方形';

  @override
  String get coverShapeDisc => '圆形（旋转）';

  @override
  String get coverShapeTurntable => '唱片机';

  @override
  String get expandPlayer => '放大播放页';

  @override
  String get collapsePlayer => '收起';

  @override
  String get playerMenu => '播放菜单';

  @override
  String get fontStyle => '字体';

  @override
  String get fontSerif => '衬线体';

  @override
  String get fontSans => '非衬线体';

  @override
  String get lyricsSettings => '歌词设置';

  @override
  String get lyricsFontSize => '字体大小';

  @override
  String get lyricsCentered => '居中显示';

  @override
  String get lyricsTranslation => '显示翻译';

  @override
  String lyricsFontSizeRange(int min, int max) {
    return '范围 $min–$max';
  }

  @override
  String get lyricsFontSizeInvalid => '请输入有效字号';

  @override
  String get settingsGeneral => '通用';

  @override
  String get settingsStartPage => '默认启动页';

  @override
  String get settingsStartPageHint => '打开应用时显示的页面';

  @override
  String get playerBackground => '播放页背景';

  @override
  String get progressStyle => '播放进度条样式';

  @override
  String get progressMaterial => 'Material';

  @override
  String get progressClassic => '经典圆点';

  @override
  String get progressSlim => '细线';

  @override
  String get progressWave => '波浪';

  @override
  String get backgroundGradient => '主题渐变';

  @override
  String get backgroundBlurredCover => '封面模糊';

  @override
  String get playerBackgroundHint => '放大并高度模糊专辑封面，营造沉浸背景。';

  @override
  String get settingsShortcuts => '键盘快捷键';

  @override
  String get shortcutPlayback => '播放 / 暂停';

  @override
  String get shortcutSpace => '空格';

  @override
  String get shortcutTracks => '上一首 / 下一首';

  @override
  String get shortcutWindow => '进入 / 退出全屏';

  @override
  String get lyricsLineHeight => '行距';

  @override
  String get lyricsLineHeightInvalid => '请输入 1–2 之间的行距倍数';

  @override
  String get newPlaylist => '新建播放列表';

  @override
  String get playlistName => '播放列表名称';

  @override
  String get playlistNameHint => '例如：通勤路上';

  @override
  String get create => '新建';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get rename => '重命名';

  @override
  String get delete => '删除';

  @override
  String get remove => '移除';

  @override
  String get removeFromPlaylist => '从此播放列表移除';

  @override
  String get addToPlaylist => '加入播放列表';

  @override
  String addedToPlaylist(String name) {
    return '已加入“$name”';
  }

  @override
  String get deletePlaylistTitle => '删除播放列表？';

  @override
  String deletePlaylistBody(String name) {
    return '将删除“$name”，歌曲文件不受影响。';
  }

  @override
  String get playlistEmpty => '这个播放列表还是空的';

  @override
  String get playlistEmptyBody => '在任意歌曲的菜单里选择“加入播放列表”。';

  @override
  String playlistTracks(int count) {
    return '$count 首';
  }

  @override
  String get reorder => '拖动排序';

  @override
  String get libraryFolders => '音乐文件夹';

  @override
  String get libraryFoldersHint => '应用会递归扫描这些文件夹里的 FLAC 和 MP3。';

  @override
  String get libraryNoFolders => '还没有添加音乐文件夹';

  @override
  String get addFolder => '添加文件夹';

  @override
  String get excludeFolder => '排除文件夹';

  @override
  String get excludedTag => '已排除';

  @override
  String get removeFolder => '移除此文件夹';

  @override
  String get folderAlreadyAdded => '这个文件夹已经在列表里了';

  @override
  String get rescan => '重新扫描';

  @override
  String get scanWalking => '正在查找音乐文件…';

  @override
  String scanReading(int done, int total) {
    return '正在读取标签 $done / $total';
  }

  @override
  String get scanFinishing => '正在整理曲库…';

  @override
  String get scanDone => '扫描完成';

  @override
  String scanDoneWithErrors(int count) {
    return '扫描完成，$count 个文件无法读取标签';
  }

  @override
  String get scanFailed => '扫描失败';

  @override
  String get emptyLibraryBody => '添加一个音乐文件夹，歌曲会出现在这里。';

  @override
  String get useBundledFonts => '使用内置字体';

  @override
  String get useBundledFontsHint =>
      '无衬线用 HarmonyOS Sans，衬线用 EB Garamond 与思源宋体。关闭后使用系统字体。';

  @override
  String get aboutFonts => '字体';

  @override
  String get aboutFontsCredit =>
      'HarmonyOS Sans（© 华为终端有限公司）、EB Garamond、Noto Serif SC（思源宋体，SIL OFL）';

  @override
  String get pickFolderMessage => '选择包含音乐（FLAC、MP3）的文件夹，可多选。';

  @override
  String get pickExcludeMessage => '选择扫描时要跳过的文件夹。';

  @override
  String get folderNotUsable => '无法读取这个文件夹，请换一个位置';

  @override
  String get folderPickFailed => '无法打开文件夹选择窗口';

  @override
  String get musicPermissionTitle => '需要读取音乐的权限';

  @override
  String get musicPermissionBody =>
      'NyaPlayer 只在本机读取你选择的文件夹里的音频文件，不会联网。请允许访问音乐和音频，否则无法扫描曲库。';

  @override
  String get musicPermissionSettings => '打开系统设置';

  @override
  String get settingsMinLength => '最短时长';

  @override
  String get minLengthOff => '不过滤，显示全部';

  @override
  String minLengthSummary(String duration) {
    return '隐藏短于 $duration 的音频';
  }

  @override
  String lengthSeconds(int count) {
    return '$count 秒';
  }

  @override
  String lengthMinutes(int count) {
    return '$count 分钟';
  }

  @override
  String get eqSavePreset => '保存为预设';

  @override
  String get eqPresetName => '预设名称';

  @override
  String eqDeletePresetBody(String name) {
    return '将删除预设“$name”。';
  }

  @override
  String get notificationPermissionTitle => '显示播放控制？';

  @override
  String get notificationPermissionBody => '允许通知后，可以在通知栏和锁屏上控制播放。不允许也能正常播放。';

  @override
  String get allow => '允许';

  @override
  String get flowingLight => '流光背景';

  @override
  String get flowingLightHint =>
      '播放界面背景上有彩色光斑，颜色取自封面，每次换歌会换一个位置；Hi-Res 歌曲会多一抹金色。';

  @override
  String get surfaceMaterial => '材质';

  @override
  String get materialStandard => '标准';

  @override
  String get materialGlass => '高级玻璃';

  @override
  String get surfaceMaterialHint =>
      '高级玻璃会让侧栏、卡片、播放条和抽屉变成半透明的磨砂玻璃，背后透出柔和的彩色光。更耗电。';

  @override
  String get settingsPlaybackCore => '播放内核';

  @override
  String get settingsPlaybackCoreHint => '系统解码（Media3）或 Rust 内核。切换后需重启应用生效。';

  @override
  String get playbackCoreSystem => '系统（Media3）';

  @override
  String get playbackCoreRust => 'Rust 内核';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appName => 'NyaPlayer';

  @override
  String get showAppWindow => '顯示 NyaPlayer 視窗';

  @override
  String get quitApp => '結束 NyaPlayer';

  @override
  String get navSongs => '歌曲';

  @override
  String get navAlbums => '專輯';

  @override
  String get navArtists => '藝人';

  @override
  String get navFolders => '資料夾';

  @override
  String get navPlaylists => '播放清單';

  @override
  String get search => '搜尋';

  @override
  String get searchHint => '搜尋歌曲、專輯、藝人';

  @override
  String get searchNoResults => '找不到結果';

  @override
  String get sectionSongs => '歌曲';

  @override
  String get sectionAlbums => '專輯';

  @override
  String get sectionArtists => '藝人';

  @override
  String get moreOptions => '更多選項';

  @override
  String get sortTitle => '標題';

  @override
  String get sortArtist => '藝人';

  @override
  String get sortAlbum => '專輯';

  @override
  String get sortAdded => '加入時間';

  @override
  String get sortDuration => '時間長度';

  @override
  String get sortAscending => '遞增';

  @override
  String get sortDescending => '遞減';

  @override
  String songCount(int count) {
    return '$count 首歌曲';
  }

  @override
  String albumCount(int count) {
    return '$count 張專輯';
  }

  @override
  String get playAll => '播放全部';

  @override
  String get shufflePlay => '隨機播放';

  @override
  String get playNext => '下一首播放';

  @override
  String get addToQueue => '加入佇列';

  @override
  String get songInfo => '歌曲資訊';

  @override
  String get addedToQueue => '已加入佇列';

  @override
  String get willPlayNext => '將在下一首播放';

  @override
  String get nowPlaying => '正在播放';

  @override
  String get notPlaying => '未在播放';

  @override
  String get notPlayingHint => '從音樂庫中選擇一首歌開始播放';

  @override
  String get queue => '播放佇列';

  @override
  String get queueEmpty => '佇列是空的';

  @override
  String get lyrics => '歌詞';

  @override
  String get cover => '封面';

  @override
  String get noLyrics => '暫無歌詞';

  @override
  String get close => '關閉';

  @override
  String get back => '返回';

  @override
  String get play => '播放';

  @override
  String get pause => '暫停';

  @override
  String get previous => '上一首';

  @override
  String get next => '下一首';

  @override
  String get repeatOff => '重複：關';

  @override
  String get repeatAll => '重複：清單';

  @override
  String get repeatOne => '重複：單曲';

  @override
  String get shuffleOn => '隨機：開';

  @override
  String get shuffleOff => '隨機：關';

  @override
  String discLabel(int number) {
    return '碟 $number';
  }

  @override
  String get infoPath => '路徑';

  @override
  String get infoFormat => '格式';

  @override
  String get infoSampleRate => '取樣率';

  @override
  String get infoBitDepth => '位元深度';

  @override
  String get infoBitrate => '位元率';

  @override
  String get infoChannels => '聲道';

  @override
  String get infoDuration => '時間長度';

  @override
  String get infoYear => '年份';

  @override
  String get infoGenre => '曲風';

  @override
  String get infoTrackNo => '音軌';

  @override
  String get infoAlbum => '專輯';

  @override
  String get infoArtist => '藝人';

  @override
  String bitDepthValue(int bits) {
    return '$bits 位元';
  }

  @override
  String bitrateValue(int kbps) {
    return '$kbps kbps';
  }

  @override
  String get channelsStereo => '立體聲';

  @override
  String get channelsMono => '單聲道';

  @override
  String get eqTitle => '等化器';

  @override
  String get eqEnabled => '啟用等化器';

  @override
  String get eqPresets => '預設';

  @override
  String get eqPreamp => '前級增益';

  @override
  String get eqAutoClip => '自動防止削波';

  @override
  String get eqReset => '重設';

  @override
  String get eqPresetFlat => '平坦';

  @override
  String get eqPresetPop => '流行';

  @override
  String get eqPresetRock => '搖滾';

  @override
  String get eqPresetJazz => '爵士';

  @override
  String get eqPresetClassical => '古典';

  @override
  String get eqPresetVocal => '人聲';

  @override
  String get eqPresetBassBoost => '低音增強';

  @override
  String get eqPresetTrebleBoost => '高音增強';

  @override
  String get eqPresetCustom => '自訂';

  @override
  String get settingsAppearance => '外觀';

  @override
  String get settingsThemeMode => '主題模式';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get settingsColorSource => '色彩來源';

  @override
  String get colorSourceWallpaper => '系統色彩';

  @override
  String get colorSourceFixed => '固定主題色';

  @override
  String get settingsSeedColor => '主題色';

  @override
  String get settingsLanguage => '語言';

  @override
  String get langSystem => '跟隨系統';

  @override
  String get settingsLibrary => '音樂庫';

  @override
  String get settingsAbout => '關於';

  @override
  String get aboutVersion => '版本';

  @override
  String get aboutLicenses => '開放原始碼授權';

  @override
  String get aboutRerunOnboarding => '重新檢視引導頁';

  @override
  String get onboardingTitle => '歡迎使用 NyaPlayer';

  @override
  String get onboardingBody => '純本機、無廣告、不連網的音樂播放器。選擇你的音樂資料夾，開始聆聽。';

  @override
  String get onboardingChoose => '選擇音樂資料夾';

  @override
  String get onboardingSkip => '稍後再說';

  @override
  String get playlistsEmptyTitle => '還沒有播放清單';

  @override
  String get playlistsEmptyBody => '點按按鈕新增一個，再從歌曲選單把歌加進去。';

  @override
  String get loadFailed => '載入失敗';

  @override
  String get emptyLibrary => '音樂庫是空的';

  @override
  String get variousArtists => '多位藝人';

  @override
  String get navFavorites => '收藏';

  @override
  String get navSettings => '設定';

  @override
  String get openNavigation => '開啟導覽選單';

  @override
  String get favorite => '加入收藏';

  @override
  String get unfavorite => '取消收藏';

  @override
  String get favoritesEmptyTitle => '還沒有收藏的歌曲';

  @override
  String get favoritesEmptyBody => '在歌曲選單或播放頁點按 ♡ 即可收藏。';

  @override
  String get settingsPlayback => '播放';

  @override
  String get colorSourceHint => '選擇系統色彩或固定主題色，播放器背景可另外設定。';

  @override
  String get settingsEqualizerSubtitle => '10 段等化器與預設';

  @override
  String get coverShape => '封面樣式';

  @override
  String get coverShapeSquare => '方形';

  @override
  String get coverShapeDisc => '圓形（旋轉）';

  @override
  String get coverShapeTurntable => '唱片機';

  @override
  String get expandPlayer => '放大播放頁';

  @override
  String get collapsePlayer => '收合';

  @override
  String get playerMenu => '播放選單';

  @override
  String get fontStyle => '字體';

  @override
  String get fontSerif => '襯線體';

  @override
  String get fontSans => '無襯線體';

  @override
  String get lyricsSettings => '歌詞設定';

  @override
  String get lyricsFontSize => '字體大小';

  @override
  String get lyricsCentered => '置中顯示';

  @override
  String get lyricsTranslation => '顯示翻譯';

  @override
  String lyricsFontSizeRange(int min, int max) {
    return '範圍 $min–$max';
  }

  @override
  String get lyricsFontSizeInvalid => '請輸入有效字級';

  @override
  String get settingsGeneral => '一般';

  @override
  String get settingsStartPage => '預設啟動頁';

  @override
  String get settingsStartPageHint => '開啟應用程式時顯示的頁面';

  @override
  String get playerBackground => '播放頁背景';

  @override
  String get progressStyle => '播放進度條樣式';

  @override
  String get progressMaterial => 'Material';

  @override
  String get progressClassic => '經典圓點';

  @override
  String get progressSlim => '細線';

  @override
  String get progressWave => '波浪';

  @override
  String get backgroundGradient => '主題漸層';

  @override
  String get backgroundBlurredCover => '封面模糊';

  @override
  String get playerBackgroundHint => '放大並高度模糊專輯封面，營造沉浸背景。';

  @override
  String get settingsShortcuts => '鍵盤快速鍵';

  @override
  String get shortcutPlayback => '播放 / 暫停';

  @override
  String get shortcutSpace => '空白鍵';

  @override
  String get shortcutTracks => '上一首 / 下一首';

  @override
  String get shortcutWindow => '進入 / 離開全螢幕';

  @override
  String get lyricsLineHeight => '行距';

  @override
  String get lyricsLineHeightInvalid => '請輸入 1–2 之間的行距倍數';

  @override
  String get newPlaylist => '新增播放清單';

  @override
  String get playlistName => '播放清單名稱';

  @override
  String get playlistNameHint => '例如：通勤路上';

  @override
  String get create => '新增';

  @override
  String get save => '儲存';

  @override
  String get cancel => '取消';

  @override
  String get rename => '重新命名';

  @override
  String get delete => '刪除';

  @override
  String get remove => '移除';

  @override
  String get removeFromPlaylist => '從此播放清單移除';

  @override
  String get addToPlaylist => '加入播放清單';

  @override
  String addedToPlaylist(String name) {
    return '已加入「$name」';
  }

  @override
  String get deletePlaylistTitle => '刪除播放清單？';

  @override
  String deletePlaylistBody(String name) {
    return '將刪除「$name」，歌曲檔案不受影響。';
  }

  @override
  String get playlistEmpty => '這個播放清單還是空的';

  @override
  String get playlistEmptyBody => '在任一歌曲的選單中選擇「加入播放清單」。';

  @override
  String playlistTracks(int count) {
    return '$count 首';
  }

  @override
  String get reorder => '拖曳排序';

  @override
  String get libraryFolders => '音樂資料夾';

  @override
  String get libraryFoldersHint => '應用程式會遞迴掃描這些資料夾裡的 FLAC 和 MP3。';

  @override
  String get libraryNoFolders => '還沒有加入音樂資料夾';

  @override
  String get addFolder => '加入資料夾';

  @override
  String get excludeFolder => '排除資料夾';

  @override
  String get excludedTag => '已排除';

  @override
  String get removeFolder => '移除此資料夾';

  @override
  String get folderAlreadyAdded => '這個資料夾已經在清單裡了';

  @override
  String get rescan => '重新掃描';

  @override
  String get scanWalking => '正在尋找音樂檔案…';

  @override
  String scanReading(int done, int total) {
    return '正在讀取標籤 $done / $total';
  }

  @override
  String get scanFinishing => '正在整理音樂庫…';

  @override
  String get scanDone => '掃描完成';

  @override
  String scanDoneWithErrors(int count) {
    return '掃描完成，$count 個檔案無法讀取標籤';
  }

  @override
  String get scanFailed => '掃描失敗';

  @override
  String get emptyLibraryBody => '加入一個音樂資料夾，歌曲就會出現在這裡。';

  @override
  String get useBundledFonts => '使用內建字體';

  @override
  String get useBundledFontsHint =>
      '無襯線用 HarmonyOS Sans，襯線用 EB Garamond 與思源宋體。關閉後使用系統字體。';

  @override
  String get aboutFonts => '字體';

  @override
  String get aboutFontsCredit =>
      'HarmonyOS Sans（© 華為終端有限公司）、EB Garamond、Noto Serif SC（思源宋體，SIL OFL）';

  @override
  String get pickFolderMessage => '選擇包含音樂（FLAC、MP3）的資料夾，可複選。';

  @override
  String get pickExcludeMessage => '選擇掃描時要略過的資料夾。';

  @override
  String get folderNotUsable => '無法讀取這個資料夾，請換一個位置';

  @override
  String get folderPickFailed => '無法開啟資料夾選擇視窗';

  @override
  String get musicPermissionTitle => '需要讀取音樂的權限';

  @override
  String get musicPermissionBody =>
      'NyaPlayer 只在本機讀取你所選資料夾裡的音訊檔案，不會連網。請允許存取音樂和音訊，否則無法掃描音樂庫。';

  @override
  String get musicPermissionSettings => '開啟系統設定';

  @override
  String get settingsMinLength => '最短時長';

  @override
  String get minLengthOff => '不過濾，顯示全部';

  @override
  String minLengthSummary(String duration) {
    return '隱藏短於 $duration 的音訊';
  }

  @override
  String lengthSeconds(int count) {
    return '$count 秒';
  }

  @override
  String lengthMinutes(int count) {
    return '$count 分鐘';
  }

  @override
  String get eqSavePreset => '儲存為預設';

  @override
  String get eqPresetName => '預設名稱';

  @override
  String eqDeletePresetBody(String name) {
    return '將刪除預設「$name」。';
  }

  @override
  String get notificationPermissionTitle => '顯示播放控制？';

  @override
  String get notificationPermissionBody => '允許通知後，可在通知列與鎖定畫面控制播放。不允許也能正常播放。';

  @override
  String get allow => '允許';

  @override
  String get flowingLight => '流光背景';

  @override
  String get flowingLightHint =>
      '播放介面背景上有彩色光斑，顏色取自封面，每次換歌會換一個位置；Hi-Res 歌曲會多一抹金色。';

  @override
  String get surfaceMaterial => '材質';

  @override
  String get materialStandard => '標準';

  @override
  String get materialGlass => '高級玻璃';

  @override
  String get surfaceMaterialHint =>
      '高級玻璃會讓側邊欄、卡片、播放列和抽屜變成半透明的霧面玻璃，背後透出柔和的彩色光。較耗電。';

  @override
  String get settingsPlaybackCore => '播放核心';

  @override
  String get settingsPlaybackCoreHint =>
      '系統解碼（Media3）或 Rust 核心。切換後需重新啟動應用程式才會生效。';

  @override
  String get playbackCoreSystem => '系統（Media3）';

  @override
  String get playbackCoreRust => 'Rust 核心';
}

/// The translations for Chinese, as used in Hong Kong, using the Han script (`zh_Hant_HK`).
class AppLocalizationsZhHantHk extends AppLocalizationsZh {
  AppLocalizationsZhHantHk() : super('zh_Hant_HK');

  @override
  String get appName => 'NyaPlayer';

  @override
  String get showAppWindow => '顯示 NyaPlayer 視窗';

  @override
  String get quitApp => '結束 NyaPlayer';

  @override
  String get navSongs => '歌曲';

  @override
  String get navAlbums => '專輯';

  @override
  String get navArtists => '歌手';

  @override
  String get navFolders => '檔案夾';

  @override
  String get navPlaylists => '播放列表';

  @override
  String get search => '搜尋';

  @override
  String get searchHint => '搜尋歌曲、專輯、歌手';

  @override
  String get searchNoResults => '找不到結果';

  @override
  String get sectionSongs => '歌曲';

  @override
  String get sectionAlbums => '專輯';

  @override
  String get sectionArtists => '歌手';

  @override
  String get moreOptions => '更多選項';

  @override
  String get sortTitle => '標題';

  @override
  String get sortArtist => '歌手';

  @override
  String get sortAlbum => '專輯';

  @override
  String get sortAdded => '加入時間';

  @override
  String get sortDuration => '時間長度';

  @override
  String get sortAscending => '遞增';

  @override
  String get sortDescending => '遞減';

  @override
  String songCount(int count) {
    return '$count 首歌曲';
  }

  @override
  String albumCount(int count) {
    return '$count 張專輯';
  }

  @override
  String get playAll => '播放全部';

  @override
  String get shufflePlay => '隨機播放';

  @override
  String get playNext => '下一首播放';

  @override
  String get addToQueue => '加入隊列';

  @override
  String get songInfo => '歌曲資訊';

  @override
  String get addedToQueue => '已加入隊列';

  @override
  String get willPlayNext => '將在下一首播放';

  @override
  String get nowPlaying => '正在播放';

  @override
  String get notPlaying => '未在播放';

  @override
  String get notPlayingHint => '從音樂庫中選擇一首歌開始播放';

  @override
  String get queue => '播放隊列';

  @override
  String get queueEmpty => '隊列是空的';

  @override
  String get lyrics => '歌詞';

  @override
  String get cover => '封面';

  @override
  String get noLyrics => '暫無歌詞';

  @override
  String get close => '關閉';

  @override
  String get back => '返回';

  @override
  String get play => '播放';

  @override
  String get pause => '暫停';

  @override
  String get previous => '上一首';

  @override
  String get next => '下一首';

  @override
  String get repeatOff => '重複：關';

  @override
  String get repeatAll => '重複：清單';

  @override
  String get repeatOne => '重複：單曲';

  @override
  String get shuffleOn => '隨機：開';

  @override
  String get shuffleOff => '隨機：關';

  @override
  String discLabel(int number) {
    return '碟 $number';
  }

  @override
  String get infoPath => '路徑';

  @override
  String get infoFormat => '格式';

  @override
  String get infoSampleRate => '取樣率';

  @override
  String get infoBitDepth => '位元深度';

  @override
  String get infoBitrate => '位元率';

  @override
  String get infoChannels => '聲道';

  @override
  String get infoDuration => '時間長度';

  @override
  String get infoYear => '年份';

  @override
  String get infoGenre => '曲風';

  @override
  String get infoTrackNo => '音軌';

  @override
  String get infoAlbum => '專輯';

  @override
  String get infoArtist => '歌手';

  @override
  String bitDepthValue(int bits) {
    return '$bits 位元';
  }

  @override
  String bitrateValue(int kbps) {
    return '$kbps kbps';
  }

  @override
  String get channelsStereo => '立體聲';

  @override
  String get channelsMono => '單聲道';

  @override
  String get eqTitle => '均衡器';

  @override
  String get eqEnabled => '啟用均衡器';

  @override
  String get eqPresets => '預設';

  @override
  String get eqPreamp => '前級增益';

  @override
  String get eqAutoClip => '自動防止削波';

  @override
  String get eqReset => '重設';

  @override
  String get eqPresetFlat => '平坦';

  @override
  String get eqPresetPop => '流行';

  @override
  String get eqPresetRock => '搖滾';

  @override
  String get eqPresetJazz => '爵士';

  @override
  String get eqPresetClassical => '古典';

  @override
  String get eqPresetVocal => '人聲';

  @override
  String get eqPresetBassBoost => '低音增強';

  @override
  String get eqPresetTrebleBoost => '高音增強';

  @override
  String get eqPresetCustom => '自訂';

  @override
  String get settingsAppearance => '外觀';

  @override
  String get settingsThemeMode => '主題模式';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get settingsColorSource => '色彩來源';

  @override
  String get colorSourceWallpaper => '系統色彩';

  @override
  String get colorSourceFixed => '固定主題色';

  @override
  String get settingsSeedColor => '主題色';

  @override
  String get settingsLanguage => '語言';

  @override
  String get langSystem => '跟隨系統';

  @override
  String get settingsLibrary => '音樂庫';

  @override
  String get settingsAbout => '關於';

  @override
  String get aboutVersion => '版本';

  @override
  String get aboutLicenses => '開放原始碼授權';

  @override
  String get aboutRerunOnboarding => '重新檢視引導頁';

  @override
  String get onboardingTitle => '歡迎使用 NyaPlayer';

  @override
  String get onboardingBody => '純本機、無廣告、不連網的音樂播放器。選擇你的音樂檔案夾，開始聆聽。';

  @override
  String get onboardingChoose => '選擇音樂檔案夾';

  @override
  String get onboardingSkip => '稍後再說';

  @override
  String get playlistsEmptyTitle => '還沒有播放列表';

  @override
  String get playlistsEmptyBody => '點按按鈕新增一個，再從歌曲選單把歌加進去。';

  @override
  String get loadFailed => '載入失敗';

  @override
  String get emptyLibrary => '音樂庫是空的';

  @override
  String get variousArtists => '多位歌手';

  @override
  String get navFavorites => '收藏';

  @override
  String get navSettings => '設定';

  @override
  String get openNavigation => '開啟導覽選單';

  @override
  String get favorite => '加入收藏';

  @override
  String get unfavorite => '取消收藏';

  @override
  String get favoritesEmptyTitle => '還沒有收藏的歌曲';

  @override
  String get favoritesEmptyBody => '在歌曲選單或播放頁點按 ♡ 即可收藏。';

  @override
  String get settingsPlayback => '播放';

  @override
  String get colorSourceHint => '選擇系統色彩或固定主題色，播放器背景可另外設定。';

  @override
  String get settingsEqualizerSubtitle => '10 段均衡器與預設';

  @override
  String get coverShape => '封面樣式';

  @override
  String get coverShapeSquare => '方形';

  @override
  String get coverShapeDisc => '圓形（旋轉）';

  @override
  String get coverShapeTurntable => '唱片機';

  @override
  String get expandPlayer => '放大播放頁';

  @override
  String get collapsePlayer => '收合';

  @override
  String get playerMenu => '播放選單';

  @override
  String get fontStyle => '字體';

  @override
  String get fontSerif => '襯線體';

  @override
  String get fontSans => '無襯線體';

  @override
  String get lyricsSettings => '歌詞設定';

  @override
  String get lyricsFontSize => '字體大小';

  @override
  String get lyricsCentered => '置中顯示';

  @override
  String get lyricsTranslation => '顯示翻譯';

  @override
  String lyricsFontSizeRange(int min, int max) {
    return '範圍 $min–$max';
  }

  @override
  String get lyricsFontSizeInvalid => '請輸入有效字級';

  @override
  String get settingsGeneral => '一般';

  @override
  String get settingsStartPage => '預設啟動頁';

  @override
  String get settingsStartPageHint => '開啟應用程式時顯示的頁面';

  @override
  String get playerBackground => '播放頁背景';

  @override
  String get progressStyle => '播放進度條樣式';

  @override
  String get progressMaterial => 'Material';

  @override
  String get progressClassic => '經典圓點';

  @override
  String get progressSlim => '細線';

  @override
  String get progressWave => '波浪';

  @override
  String get backgroundGradient => '主題漸層';

  @override
  String get backgroundBlurredCover => '封面模糊';

  @override
  String get playerBackgroundHint => '放大並高度模糊專輯封面，營造沉浸背景。';

  @override
  String get settingsShortcuts => '鍵盤快速鍵';

  @override
  String get shortcutPlayback => '播放 / 暫停';

  @override
  String get shortcutSpace => '空白鍵';

  @override
  String get shortcutTracks => '上一首 / 下一首';

  @override
  String get shortcutWindow => '進入 / 離開全螢幕';

  @override
  String get lyricsLineHeight => '行距';

  @override
  String get lyricsLineHeightInvalid => '請輸入 1–2 之間的行距倍數';

  @override
  String get newPlaylist => '新增播放列表';

  @override
  String get playlistName => '播放列表名稱';

  @override
  String get playlistNameHint => '例如：通勤路上';

  @override
  String get create => '新增';

  @override
  String get save => '儲存';

  @override
  String get cancel => '取消';

  @override
  String get rename => '重新命名';

  @override
  String get delete => '刪除';

  @override
  String get remove => '移除';

  @override
  String get removeFromPlaylist => '從此播放列表移除';

  @override
  String get addToPlaylist => '加入播放列表';

  @override
  String addedToPlaylist(String name) {
    return '已加入「$name」';
  }

  @override
  String get deletePlaylistTitle => '刪除播放列表？';

  @override
  String deletePlaylistBody(String name) {
    return '將刪除「$name」，歌曲檔案不受影響。';
  }

  @override
  String get playlistEmpty => '這個播放列表還是空的';

  @override
  String get playlistEmptyBody => '在任一歌曲的選單中選擇「加入播放列表」。';

  @override
  String playlistTracks(int count) {
    return '$count 首';
  }

  @override
  String get reorder => '拖曳排序';

  @override
  String get libraryFolders => '音樂檔案夾';

  @override
  String get libraryFoldersHint => '應用程式會遞迴掃描這些檔案夾裡的 FLAC 和 MP3。';

  @override
  String get libraryNoFolders => '還沒有加入音樂檔案夾';

  @override
  String get addFolder => '加入檔案夾';

  @override
  String get excludeFolder => '排除檔案夾';

  @override
  String get excludedTag => '已排除';

  @override
  String get removeFolder => '移除此檔案夾';

  @override
  String get folderAlreadyAdded => '這個檔案夾已經在清單裡了';

  @override
  String get rescan => '重新掃描';

  @override
  String get scanWalking => '正在尋找音樂檔案…';

  @override
  String scanReading(int done, int total) {
    return '正在讀取標籤 $done / $total';
  }

  @override
  String get scanFinishing => '正在整理音樂庫…';

  @override
  String get scanDone => '掃描完成';

  @override
  String scanDoneWithErrors(int count) {
    return '掃描完成，$count 個檔案無法讀取標籤';
  }

  @override
  String get scanFailed => '掃描失敗';

  @override
  String get emptyLibraryBody => '加入一個音樂檔案夾，歌曲就會出現在這裡。';

  @override
  String get useBundledFonts => '使用內建字體';

  @override
  String get useBundledFontsHint =>
      '無襯線用 HarmonyOS Sans，襯線用 EB Garamond 與思源宋體。關閉後使用系統字體。';

  @override
  String get aboutFonts => '字體';

  @override
  String get aboutFontsCredit =>
      'HarmonyOS Sans（© 華為終端有限公司）、EB Garamond、Noto Serif SC（思源宋體，SIL OFL）';

  @override
  String get pickFolderMessage => '選擇包含音樂（FLAC、MP3）的檔案夾，可複選。';

  @override
  String get pickExcludeMessage => '選擇掃描時要略過的檔案夾。';

  @override
  String get folderNotUsable => '無法讀取這個檔案夾，請換一個位置';

  @override
  String get folderPickFailed => '無法開啟檔案夾選擇視窗';

  @override
  String get musicPermissionTitle => '需要讀取音樂的權限';

  @override
  String get musicPermissionBody =>
      'NyaPlayer 只在本機讀取你所選檔案夾裡的音頻檔案，不會連網。請允許存取音樂和音頻，否則無法掃描音樂庫。';

  @override
  String get musicPermissionSettings => '開啟系統設定';

  @override
  String get settingsMinLength => '最短時長';

  @override
  String get minLengthOff => '不過濾，顯示全部';

  @override
  String minLengthSummary(String duration) {
    return '隱藏短於 $duration 的音頻';
  }

  @override
  String lengthSeconds(int count) {
    return '$count 秒';
  }

  @override
  String lengthMinutes(int count) {
    return '$count 分鐘';
  }

  @override
  String get eqSavePreset => '儲存為預設';

  @override
  String get eqPresetName => '預設名稱';

  @override
  String eqDeletePresetBody(String name) {
    return '將刪除預設「$name」。';
  }

  @override
  String get notificationPermissionTitle => '顯示播放控制？';

  @override
  String get notificationPermissionBody => '允許通知後，可在通知欄與鎖定畫面控制播放。不允許也能正常播放。';

  @override
  String get allow => '允許';

  @override
  String get flowingLight => '流光背景';

  @override
  String get flowingLightHint =>
      '播放介面背景上有彩色光斑，顏色取自封面，每次換歌會換個位置；Hi-Res 歌曲會多一抹金色。';

  @override
  String get surfaceMaterial => '質感';

  @override
  String get materialStandard => '標準';

  @override
  String get materialGlass => '高級玻璃';

  @override
  String get surfaceMaterialHint =>
      '高級玻璃會令側邊欄、卡片、播放列同抽屜變成半透明嘅磨砂玻璃，背後透出柔和嘅彩色光。較耗電。';

  @override
  String get settingsPlaybackCore => '播放核心';

  @override
  String get settingsPlaybackCoreHint =>
      '系統解碼（Media3）或 Rust 核心。切換後需重新啟動應用程式才會生效。';

  @override
  String get playbackCoreSystem => '系統（Media3）';

  @override
  String get playbackCoreRust => 'Rust 核心';
}
