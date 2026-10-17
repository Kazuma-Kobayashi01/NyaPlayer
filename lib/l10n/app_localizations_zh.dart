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
  String get sortBy => '排序方式';

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
  String get eqNotWired => '当前为界面预览，音频效果将在接入播放引擎后生效。';

  @override
  String get settingsTitle => '设置';

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
  String get langZh => '简体中文';

  @override
  String get langEn => 'English';

  @override
  String get settingsLibrary => '曲库';

  @override
  String get settingsFolders => '音乐文件夹';

  @override
  String get settingsAddFolder => '添加文件夹';

  @override
  String get settingsRescan => '重新扫描全部';

  @override
  String get rescanStarted => '已开始扫描曲库';

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
  String get playlistsEmptyBody => '播放列表功能即将推出。';

  @override
  String get loadFailed => '加载失败';

  @override
  String get emptyLibrary => '曲库是空的';

  @override
  String get unknownArtist => '未知艺术家';

  @override
  String get variousArtists => '群星';

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
  String get toggleSidebar => '显示或隐藏侧边栏';
}
