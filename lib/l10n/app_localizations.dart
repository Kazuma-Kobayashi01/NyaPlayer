import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'NyaPlayer'**
  String get appName;

  /// No description provided for @navSongs.
  ///
  /// In zh, this message translates to:
  /// **'歌曲'**
  String get navSongs;

  /// No description provided for @navAlbums.
  ///
  /// In zh, this message translates to:
  /// **'专辑'**
  String get navAlbums;

  /// No description provided for @navArtists.
  ///
  /// In zh, this message translates to:
  /// **'艺术家'**
  String get navArtists;

  /// No description provided for @navFolders.
  ///
  /// In zh, this message translates to:
  /// **'文件夹'**
  String get navFolders;

  /// No description provided for @navPlaylists.
  ///
  /// In zh, this message translates to:
  /// **'播放列表'**
  String get navPlaylists;

  /// No description provided for @search.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索歌曲、专辑、艺术家'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In zh, this message translates to:
  /// **'没有找到结果'**
  String get searchNoResults;

  /// No description provided for @sectionSongs.
  ///
  /// In zh, this message translates to:
  /// **'歌曲'**
  String get sectionSongs;

  /// No description provided for @sectionAlbums.
  ///
  /// In zh, this message translates to:
  /// **'专辑'**
  String get sectionAlbums;

  /// No description provided for @sectionArtists.
  ///
  /// In zh, this message translates to:
  /// **'艺术家'**
  String get sectionArtists;

  /// No description provided for @moreOptions.
  ///
  /// In zh, this message translates to:
  /// **'更多选项'**
  String get moreOptions;

  /// No description provided for @sortBy.
  ///
  /// In zh, this message translates to:
  /// **'排序方式'**
  String get sortBy;

  /// No description provided for @sortTitle.
  ///
  /// In zh, this message translates to:
  /// **'标题'**
  String get sortTitle;

  /// No description provided for @sortArtist.
  ///
  /// In zh, this message translates to:
  /// **'艺术家'**
  String get sortArtist;

  /// No description provided for @sortAlbum.
  ///
  /// In zh, this message translates to:
  /// **'专辑'**
  String get sortAlbum;

  /// No description provided for @sortAdded.
  ///
  /// In zh, this message translates to:
  /// **'添加时间'**
  String get sortAdded;

  /// No description provided for @sortDuration.
  ///
  /// In zh, this message translates to:
  /// **'时长'**
  String get sortDuration;

  /// No description provided for @sortAscending.
  ///
  /// In zh, this message translates to:
  /// **'升序'**
  String get sortAscending;

  /// No description provided for @sortDescending.
  ///
  /// In zh, this message translates to:
  /// **'降序'**
  String get sortDescending;

  /// No description provided for @songCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 首歌曲'**
  String songCount(int count);

  /// No description provided for @albumCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 张专辑'**
  String albumCount(int count);

  /// No description provided for @playAll.
  ///
  /// In zh, this message translates to:
  /// **'播放全部'**
  String get playAll;

  /// No description provided for @shufflePlay.
  ///
  /// In zh, this message translates to:
  /// **'随机播放'**
  String get shufflePlay;

  /// No description provided for @playNext.
  ///
  /// In zh, this message translates to:
  /// **'下一首播放'**
  String get playNext;

  /// No description provided for @addToQueue.
  ///
  /// In zh, this message translates to:
  /// **'加入队列'**
  String get addToQueue;

  /// No description provided for @songInfo.
  ///
  /// In zh, this message translates to:
  /// **'歌曲信息'**
  String get songInfo;

  /// No description provided for @addedToQueue.
  ///
  /// In zh, this message translates to:
  /// **'已加入队列'**
  String get addedToQueue;

  /// No description provided for @willPlayNext.
  ///
  /// In zh, this message translates to:
  /// **'将在下一首播放'**
  String get willPlayNext;

  /// No description provided for @nowPlaying.
  ///
  /// In zh, this message translates to:
  /// **'正在播放'**
  String get nowPlaying;

  /// No description provided for @notPlaying.
  ///
  /// In zh, this message translates to:
  /// **'未在播放'**
  String get notPlaying;

  /// No description provided for @notPlayingHint.
  ///
  /// In zh, this message translates to:
  /// **'从曲库中选择一首歌开始播放'**
  String get notPlayingHint;

  /// No description provided for @queue.
  ///
  /// In zh, this message translates to:
  /// **'播放队列'**
  String get queue;

  /// No description provided for @queueEmpty.
  ///
  /// In zh, this message translates to:
  /// **'队列是空的'**
  String get queueEmpty;

  /// No description provided for @lyrics.
  ///
  /// In zh, this message translates to:
  /// **'歌词'**
  String get lyrics;

  /// No description provided for @cover.
  ///
  /// In zh, this message translates to:
  /// **'封面'**
  String get cover;

  /// No description provided for @noLyrics.
  ///
  /// In zh, this message translates to:
  /// **'暂无歌词'**
  String get noLyrics;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get back;

  /// No description provided for @play.
  ///
  /// In zh, this message translates to:
  /// **'播放'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get pause;

  /// No description provided for @previous.
  ///
  /// In zh, this message translates to:
  /// **'上一首'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In zh, this message translates to:
  /// **'下一首'**
  String get next;

  /// No description provided for @repeatOff.
  ///
  /// In zh, this message translates to:
  /// **'循环：关'**
  String get repeatOff;

  /// No description provided for @repeatAll.
  ///
  /// In zh, this message translates to:
  /// **'循环：列表'**
  String get repeatAll;

  /// No description provided for @repeatOne.
  ///
  /// In zh, this message translates to:
  /// **'循环：单曲'**
  String get repeatOne;

  /// No description provided for @shuffleOn.
  ///
  /// In zh, this message translates to:
  /// **'随机：开'**
  String get shuffleOn;

  /// No description provided for @shuffleOff.
  ///
  /// In zh, this message translates to:
  /// **'随机：关'**
  String get shuffleOff;

  /// No description provided for @discLabel.
  ///
  /// In zh, this message translates to:
  /// **'碟 {number}'**
  String discLabel(int number);

  /// No description provided for @infoPath.
  ///
  /// In zh, this message translates to:
  /// **'路径'**
  String get infoPath;

  /// No description provided for @infoFormat.
  ///
  /// In zh, this message translates to:
  /// **'格式'**
  String get infoFormat;

  /// No description provided for @infoSampleRate.
  ///
  /// In zh, this message translates to:
  /// **'采样率'**
  String get infoSampleRate;

  /// No description provided for @infoBitDepth.
  ///
  /// In zh, this message translates to:
  /// **'位深'**
  String get infoBitDepth;

  /// No description provided for @infoBitrate.
  ///
  /// In zh, this message translates to:
  /// **'码率'**
  String get infoBitrate;

  /// No description provided for @infoChannels.
  ///
  /// In zh, this message translates to:
  /// **'声道'**
  String get infoChannels;

  /// No description provided for @infoDuration.
  ///
  /// In zh, this message translates to:
  /// **'时长'**
  String get infoDuration;

  /// No description provided for @infoYear.
  ///
  /// In zh, this message translates to:
  /// **'年份'**
  String get infoYear;

  /// No description provided for @infoGenre.
  ///
  /// In zh, this message translates to:
  /// **'流派'**
  String get infoGenre;

  /// No description provided for @infoTrackNo.
  ///
  /// In zh, this message translates to:
  /// **'音轨'**
  String get infoTrackNo;

  /// No description provided for @infoAlbum.
  ///
  /// In zh, this message translates to:
  /// **'专辑'**
  String get infoAlbum;

  /// No description provided for @infoArtist.
  ///
  /// In zh, this message translates to:
  /// **'艺术家'**
  String get infoArtist;

  /// No description provided for @bitDepthValue.
  ///
  /// In zh, this message translates to:
  /// **'{bits} bit'**
  String bitDepthValue(int bits);

  /// No description provided for @bitrateValue.
  ///
  /// In zh, this message translates to:
  /// **'{kbps} kbps'**
  String bitrateValue(int kbps);

  /// No description provided for @channelsStereo.
  ///
  /// In zh, this message translates to:
  /// **'立体声'**
  String get channelsStereo;

  /// No description provided for @channelsMono.
  ///
  /// In zh, this message translates to:
  /// **'单声道'**
  String get channelsMono;

  /// No description provided for @eqTitle.
  ///
  /// In zh, this message translates to:
  /// **'均衡器'**
  String get eqTitle;

  /// No description provided for @eqEnabled.
  ///
  /// In zh, this message translates to:
  /// **'启用均衡器'**
  String get eqEnabled;

  /// No description provided for @eqPresets.
  ///
  /// In zh, this message translates to:
  /// **'预设'**
  String get eqPresets;

  /// No description provided for @eqPreamp.
  ///
  /// In zh, this message translates to:
  /// **'前级增益'**
  String get eqPreamp;

  /// No description provided for @eqAutoClip.
  ///
  /// In zh, this message translates to:
  /// **'自动防削波'**
  String get eqAutoClip;

  /// No description provided for @eqReset.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get eqReset;

  /// No description provided for @eqPresetFlat.
  ///
  /// In zh, this message translates to:
  /// **'平坦'**
  String get eqPresetFlat;

  /// No description provided for @eqPresetPop.
  ///
  /// In zh, this message translates to:
  /// **'流行'**
  String get eqPresetPop;

  /// No description provided for @eqPresetRock.
  ///
  /// In zh, this message translates to:
  /// **'摇滚'**
  String get eqPresetRock;

  /// No description provided for @eqPresetJazz.
  ///
  /// In zh, this message translates to:
  /// **'爵士'**
  String get eqPresetJazz;

  /// No description provided for @eqPresetClassical.
  ///
  /// In zh, this message translates to:
  /// **'古典'**
  String get eqPresetClassical;

  /// No description provided for @eqPresetVocal.
  ///
  /// In zh, this message translates to:
  /// **'人声'**
  String get eqPresetVocal;

  /// No description provided for @eqPresetBassBoost.
  ///
  /// In zh, this message translates to:
  /// **'低音增强'**
  String get eqPresetBassBoost;

  /// No description provided for @eqPresetTrebleBoost.
  ///
  /// In zh, this message translates to:
  /// **'高音增强'**
  String get eqPresetTrebleBoost;

  /// No description provided for @eqPresetCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get eqPresetCustom;

  /// No description provided for @eqNotWired.
  ///
  /// In zh, this message translates to:
  /// **'当前为界面预览，音频效果将在接入播放引擎后生效。'**
  String get eqNotWired;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeMode.
  ///
  /// In zh, this message translates to:
  /// **'主题模式'**
  String get settingsThemeMode;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeSystem;

  /// No description provided for @settingsColorSource.
  ///
  /// In zh, this message translates to:
  /// **'配色来源'**
  String get settingsColorSource;

  /// No description provided for @colorSourceCover.
  ///
  /// In zh, this message translates to:
  /// **'跟随封面'**
  String get colorSourceCover;

  /// No description provided for @colorSourceWallpaper.
  ///
  /// In zh, this message translates to:
  /// **'系统配色'**
  String get colorSourceWallpaper;

  /// No description provided for @colorSourceFixed.
  ///
  /// In zh, this message translates to:
  /// **'固定主题色'**
  String get colorSourceFixed;

  /// No description provided for @settingsSeedColor.
  ///
  /// In zh, this message translates to:
  /// **'主题色'**
  String get settingsSeedColor;

  /// No description provided for @settingsLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get settingsLanguage;

  /// No description provided for @langSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get langSystem;

  /// No description provided for @langZh.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get langZh;

  /// No description provided for @langEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @settingsLibrary.
  ///
  /// In zh, this message translates to:
  /// **'曲库'**
  String get settingsLibrary;

  /// No description provided for @settingsFolders.
  ///
  /// In zh, this message translates to:
  /// **'音乐文件夹'**
  String get settingsFolders;

  /// No description provided for @settingsAddFolder.
  ///
  /// In zh, this message translates to:
  /// **'添加文件夹'**
  String get settingsAddFolder;

  /// No description provided for @settingsRescan.
  ///
  /// In zh, this message translates to:
  /// **'重新扫描全部'**
  String get settingsRescan;

  /// No description provided for @rescanStarted.
  ///
  /// In zh, this message translates to:
  /// **'已开始扫描曲库'**
  String get rescanStarted;

  /// No description provided for @settingsAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get settingsAbout;

  /// No description provided for @aboutVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get aboutVersion;

  /// No description provided for @aboutLicenses.
  ///
  /// In zh, this message translates to:
  /// **'开源许可'**
  String get aboutLicenses;

  /// No description provided for @aboutRerunOnboarding.
  ///
  /// In zh, this message translates to:
  /// **'重新查看引导页'**
  String get aboutRerunOnboarding;

  /// No description provided for @onboardingTitle.
  ///
  /// In zh, this message translates to:
  /// **'欢迎使用 NyaPlayer'**
  String get onboardingTitle;

  /// No description provided for @onboardingBody.
  ///
  /// In zh, this message translates to:
  /// **'一个纯本地、无广告、不联网的音乐播放器。选择你的音乐文件夹，开始聆听。'**
  String get onboardingBody;

  /// No description provided for @onboardingChoose.
  ///
  /// In zh, this message translates to:
  /// **'选择音乐文件夹'**
  String get onboardingChoose;

  /// No description provided for @onboardingSkip.
  ///
  /// In zh, this message translates to:
  /// **'稍后再说'**
  String get onboardingSkip;

  /// No description provided for @playlistsEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有播放列表'**
  String get playlistsEmptyTitle;

  /// No description provided for @playlistsEmptyBody.
  ///
  /// In zh, this message translates to:
  /// **'播放列表功能即将推出。'**
  String get playlistsEmptyBody;

  /// No description provided for @loadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get loadFailed;

  /// No description provided for @emptyLibrary.
  ///
  /// In zh, this message translates to:
  /// **'曲库是空的'**
  String get emptyLibrary;

  /// No description provided for @unknownArtist.
  ///
  /// In zh, this message translates to:
  /// **'未知艺术家'**
  String get unknownArtist;

  /// No description provided for @variousArtists.
  ///
  /// In zh, this message translates to:
  /// **'群星'**
  String get variousArtists;

  /// No description provided for @navFavorites.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get navFavorites;

  /// No description provided for @navSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get navSettings;

  /// No description provided for @openNavigation.
  ///
  /// In zh, this message translates to:
  /// **'打开导航菜单'**
  String get openNavigation;

  /// No description provided for @favorite.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get favorite;

  /// No description provided for @unfavorite.
  ///
  /// In zh, this message translates to:
  /// **'取消收藏'**
  String get unfavorite;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有收藏的歌曲'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyBody.
  ///
  /// In zh, this message translates to:
  /// **'在歌曲菜单或播放页点按 ♡ 即可收藏。'**
  String get favoritesEmptyBody;

  /// No description provided for @settingsPlayback.
  ///
  /// In zh, this message translates to:
  /// **'播放'**
  String get settingsPlayback;

  /// No description provided for @colorSourceHint.
  ///
  /// In zh, this message translates to:
  /// **'“跟随封面”只作用于播放器，其余界面使用系统配色。'**
  String get colorSourceHint;

  /// No description provided for @settingsEqualizerSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'10 段均衡器与预设'**
  String get settingsEqualizerSubtitle;

  /// No description provided for @coverShape.
  ///
  /// In zh, this message translates to:
  /// **'封面样式'**
  String get coverShape;

  /// No description provided for @coverShapeSquare.
  ///
  /// In zh, this message translates to:
  /// **'方形'**
  String get coverShapeSquare;

  /// No description provided for @coverShapeDisc.
  ///
  /// In zh, this message translates to:
  /// **'圆形（旋转）'**
  String get coverShapeDisc;

  /// No description provided for @expandPlayer.
  ///
  /// In zh, this message translates to:
  /// **'放大播放页'**
  String get expandPlayer;

  /// No description provided for @collapsePlayer.
  ///
  /// In zh, this message translates to:
  /// **'收起'**
  String get collapsePlayer;

  /// No description provided for @playerMenu.
  ///
  /// In zh, this message translates to:
  /// **'播放菜单'**
  String get playerMenu;

  /// No description provided for @fontStyle.
  ///
  /// In zh, this message translates to:
  /// **'字体'**
  String get fontStyle;

  /// No description provided for @fontSerif.
  ///
  /// In zh, this message translates to:
  /// **'衬线体'**
  String get fontSerif;

  /// No description provided for @fontSans.
  ///
  /// In zh, this message translates to:
  /// **'非衬线体'**
  String get fontSans;

  /// No description provided for @lyricsSettings.
  ///
  /// In zh, this message translates to:
  /// **'歌词设置'**
  String get lyricsSettings;

  /// No description provided for @lyricsFontSize.
  ///
  /// In zh, this message translates to:
  /// **'字体大小'**
  String get lyricsFontSize;

  /// No description provided for @lyricsCentered.
  ///
  /// In zh, this message translates to:
  /// **'居中显示'**
  String get lyricsCentered;

  /// No description provided for @lyricsTranslation.
  ///
  /// In zh, this message translates to:
  /// **'显示翻译'**
  String get lyricsTranslation;

  /// No description provided for @lyricsFontSizeRange.
  ///
  /// In zh, this message translates to:
  /// **'范围 {min}–{max}'**
  String lyricsFontSizeRange(int min, int max);

  /// No description provided for @lyricsFontSizeInvalid.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效字号'**
  String get lyricsFontSizeInvalid;

  /// No description provided for @settingsGeneral.
  ///
  /// In zh, this message translates to:
  /// **'通用'**
  String get settingsGeneral;

  /// No description provided for @settingsStartPage.
  ///
  /// In zh, this message translates to:
  /// **'默认启动页'**
  String get settingsStartPage;

  /// No description provided for @settingsStartPageHint.
  ///
  /// In zh, this message translates to:
  /// **'打开应用时显示的页面'**
  String get settingsStartPageHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
