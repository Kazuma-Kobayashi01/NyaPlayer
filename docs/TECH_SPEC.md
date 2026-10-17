# 技术要求（Technical Spec）

> 项目代号：**Lyra** · 文档版本：v0.1 · 2026-10-17
> 配套文档：[`REQUIREMENTS.md`](./REQUIREMENTS.md)、[`PLAN.md`](./PLAN.md)
> 需求编号（如 `EQ-06`）引用自 `REQUIREMENTS.md`。

本文档定义**必须遵守的技术决定**和**推荐做法**。标注 🔍 的条目是"尚未实测、需要在 M0 技术验证中确认"的假设，验证结果写入 `docs/SPIKE_REPORT.md` 并回填本文档。

---

## 1. 技术栈与依赖

### 1.1 基础环境

- Flutter：开工时的最新 **stable** 版本，Dart 3。
- Android：`minSdk 24`，`targetSdk` / `compileSdk` 跟随 Flutter 模板默认值（不得低于 34）。
- macOS：部署目标跟随 Flutter 模板（≥ 10.15）。
- 不支持的平台目录（ios / web / windows / linux）在创建工程时不生成：
  `flutter create --platforms=android,macos --org <your.org> lyra`

### 1.2 核心依赖（版本为 2026-10-17 在 pub.dev 核实的最新版）

| 用途 | 包 | 版本 | 备注 |
|---|---|---|---|
| 播放内核 | `media_kit` | ^1.2.6 | libmpv + FFmpeg，Dart FFI 实现 |
| 内核原生库 | `media_kit_libs_audio` | ^1.0.7 | **只用 audio 版**，不能和 `media_kit_libs_video` 混用 |
| 后台/系统媒体控制 | `audio_service` | ^0.18.19 | Android 通知、锁屏、耳机键；macOS 控制中心、媒体键 |
| 音频焦点/中断 | `audio_session` | 跟随 audio_service 约束 | 处理来电、拔耳机 |
| 标签/封面/歌词读取 | `audio_metadata_reader` | ^1.8.0 | 纯 Dart，支持 MP3/MP4/FLAC/OGG/Opus/WAV/AIFF/APE |

### 1.3 其他依赖（用 `flutter pub add` 取当时最新稳定版）

| 用途 | 包 |
|---|---|
| 状态管理 | `flutter_riverpod`（3.x，可不使用代码生成） |
| 路由 | `go_router` |
| 数据库 | `drift` + `drift_flutter` + `sqlite3_flutter_libs`；dev: `drift_dev`、`build_runner` |
| 壁纸动态取色 | `dynamic_color` |
| 权限 | `permission_handler` |
| 文件夹选择 | `file_picker`（macOS 选目录；Android 可选） |
| 路径 | `path_provider`、`path` |
| macOS 窗口控制 | `window_manager`（关闭窗口改为隐藏） |
| 图片缩放 | `image`（生成封面缩略图，在 isolate 中执行） |
| 国际化 | `flutter_localizations` + `intl`（ARB 文件） |
| 列表拖拽排序 | Flutter 自带 `ReorderableListView` 即可 |
| 测试 | `flutter_test`、`mocktail` |
| Lint | `flutter_lints`（在此基础上开启第 10 节的额外规则） |

**新增依赖规则**：引入上表以外的包之前，必须在本文档"附录 A 依赖变更记录"中写明理由。优先选择 pub points 高、近 12 个月有发布、发布者已验证的包。

### 1.4 明确不用的东西

- `just_audio`：EQ 只在 Android 有，不满足 `EQ-08`。
- `ffmpeg_kit_flutter` 系列：已停止维护且用途是转码，不是播放。
- `on_audio_query`：依赖 MediaStore，拿不到 `.lrc`，且跨平台不一致，统一改为自己扫描文件系统。

## 2. 总体架构

```
┌───────────────────────────── UI 层（features/*）──────────────────────────────┐
│  Widgets + Riverpod providers（只读状态、发出意图，不直接碰 media_kit）           │
└──────────────────────────────────────┬───────────────────────────────────────┘
                                       │ 调用 / 订阅
┌──────────────────────────── 应用服务层（services/*）──────────────────────────┐
│ LyraAudioHandler（audio_service）──► QueueController ──► PlayerEngine 接口       │
│        ▲ 系统通知/媒体键/控制中心          │                    │               │
│        │                                │                 MediaKitEngine     │
│ AudioFocusCoordinator（audio_session）    │                 （唯一持有 Player） │
│ EqController ──► EqFilterBuilder ────────┘                                     │
│ LibraryScanner ─► MetadataExtractor ─► CoverCache    LyricsLoader ─► LrcParser │
└──────────────────────────────────────┬───────────────────────────────────────┘
                                       │
┌────────────────────────────── 数据层（data/*）────────────────────────────────┐
│ Drift 数据库（tracks / albums / artists / playlists / eq_presets / settings）  │
│ Repository 封装查询；文件系统访问封装在 platform/ 下                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

**硬性约束：**

1. 全应用只有**一个** `media_kit` `Player` 实例，由 `MediaKitEngine` 持有。
2. UI 永远通过 `AudioHandler`（或其上的 provider）控制播放，**不得**直接调用 `Player`，否则通知栏/媒体键状态会和 UI 不一致。
3. `PlayerEngine` 是抽象接口，`MediaKitEngine` 是其实现。这样以后换内核只改一个类。
4. 耗时操作（扫描、读标签、解码封面、生成缩略图、读 `.lrc` 并识别编码）一律在 **isolate** 中执行，不阻塞 UI 线程。

## 3. 目录结构

```
lib/
├── main.dart                      # 初始化顺序见 §4.1
├── app/
│   ├── app.dart                   # MaterialApp.router、主题注入
│   ├── router.dart
│   ├── theme/                     # ColorScheme 生成、封面取色、文字主题
│   └── layout/                    # 自适应外壳：NavigationBar / Rail / 侧边面板
├── core/                          # 通用工具：日志、Result、扩展方法、常量
├── domain/                        # 纯 Dart 模型：Track, Album, Artist, LyricLine, EqPreset, QueueState
├── data/
│   ├── db/                        # drift 表定义、DAO、迁移
│   └── repositories/              # LibraryRepository, PlaylistRepository, SettingsRepository
├── services/
│   ├── player/
│   │   ├── player_engine.dart     # 抽象接口
│   │   ├── media_kit_engine.dart
│   │   ├── queue_controller.dart
│   │   ├── lyra_audio_handler.dart
│   │   └── audio_focus.dart
│   ├── eq/                        # EqController, EqFilterBuilder, 内置预设
│   ├── library/                   # LibraryScanner, ScanDiff, MetadataExtractor, CoverCache
│   ├── lyrics/                    # LyricsLoader, LrcParser, TextEncodingDetector
│   └── platform/                  # Android 存储权限、macOS 窗口行为
├── features/
│   ├── onboarding/  library/  album/  artist/  folder/  search/
│   ├── now_playing/  lyrics/  queue/  equalizer/  settings/  playlists/
│   └── shared/                    # 共享 widget：封面图、歌曲列表项、迷你播放条
└── l10n/                          # app_zh.arb, app_ja.arb, app_en.arb
test/                              # 与 lib/ 镜像的目录结构
docs/                              # 三份文档 + SPIKE_REPORT.md
```

## 4. 播放引擎

### 4.1 初始化顺序（`main.dart`）

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();                 // 必须最先
  final db = AppDatabase();                     // drift
  final engine = MediaKitEngine();              // 创建唯一 Player
  final handler = await AudioService.init(
    builder: () => LyraAudioHandler(engine, ...),
    config: const AudioServiceConfig(
      androidNotificationChannelId: '<org>.lyra.playback',
      androidNotificationChannelName: '播放',
      androidStopForegroundOnPause: false,      // 见 §6.1 风险说明，M4 再评估
    ),
  );
  await AudioFocusCoordinator.configure(handler); // audio_session
  runApp(ProviderScope(overrides: [...], child: const LyraApp()));
}
```

### 4.2 `PlayerEngine` 接口（草案）

```dart
abstract interface class PlayerEngine {
  Stream<bool> get playing;
  Stream<Duration> get position;
  Stream<Duration> get duration;
  Stream<int?> get currentIndex;
  Stream<bool> get completed;
  Stream<String> get errors;
  Stream<AudioParams> get audioParams;   // 用于"歌曲信息"页

  Future<void> openQueue(List<String> filePaths, {int startIndex = 0, bool autoplay = true});
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> jumpTo(int index);
  Future<void> add(String filePath);
  Future<void> insert(int index, String filePath);  // 通过 add + move 实现
  Future<void> remove(int index);
  Future<void> move(int from, int to);
  Future<void> setLoopMode(LoopMode mode);           // none / all / one
  Future<void> setAudioFilter(String afChain);       // EQ，见 §5
  Future<void> setMpvProperty(String key, String value);
  Future<void> dispose();
}
```

### 4.3 MediaKitEngine 要点

- 使用 `Playlist` 交给 mpv 管理队列，从而获得**无缝播放**（`PLAY-07`）。
- 启动时设置 mpv 属性（通过 `(player.platform as NativePlayer).setProperty`）：
  - `gapless-audio` = `weak`（默认）或 `yes`（设置项开启时）🔍
  - `vid` = `no`、`audio-display` = `no`（不解码内嵌封面为视频轨，避免浪费）🔍
  - 需要时 `replaygain` = `track` / `album`（P2）
- 循环模式映射：`none → PlaylistMode.none`，`all → PlaylistMode.loop`，`one → PlaylistMode.single`。
- **不使用** media_kit 自带的 `setShuffle`（它会在下一次 `open` 时被重置），随机播放由 `QueueController` 自己实现。
- 解码失败：监听 `stream.error`，记录日志、提示用户、自动 `next()`；连续失败超过 5 首则停止播放，避免死循环（`FMT-07`）。

### 4.4 QueueController

- 是播放队列的**唯一真相来源**：持有 `originalOrder`、`shuffledOrder`、`currentIndex`、`loopMode`、`shuffleEnabled`。
- 开启随机：保留当前曲目在第 0 位，其余 Fisher–Yates 打乱，重新 `openQueue(..., autoplay: 当前状态)` 并 seek 回原位置。关闭随机：恢复原顺序，定位到当前曲目。
- 每次队列变化后：
  1. 同步给 `PlayerEngine`（尽量用 add/remove/move 增量操作，避免整体重开打断播放）；
  2. 推送 `queue` 和 `mediaItem` 给 `AudioHandler`；
  3. 防抖（1 秒）持久化到数据库（`PLAY-05`）。
- 恢复播放状态时：`openQueue(autoplay: false)` 后 seek 到上次位置。
- "上一首"规则（`PLAY-06`）：位置 > 3 秒 → seek(0)；否则上一首。

### 4.5 LyraAudioHandler

- `extends BaseAudioHandler with QueueHandler, SeekHandler`。
- 把 `PlayerEngine` 的流合成 `PlaybackState` 推送，规则：**只在状态变化或 seek 时更新 `updatePosition`**，不要每帧推送位置（audio_service 会自己外推）。
- 通知栏控件：上一首 / 播放或暂停 / 下一首；`androidCompactActionIndices: [0, 1, 2]`；`systemActions` 包含 `seek`。
- `MediaItem.artUri` 必须是 `file://` URI，指向 `CoverCache` 中写好的 1024px 封面文件（见 §7.3）。
- 循环、随机、EQ 预设切换等通过 `customAction` 暴露给 UI。

### 4.6 音频焦点与中断（AudioFocusCoordinator）

media_kit 不负责系统音频会话，必须自己用 `audio_session` 处理（`SYS-04`、`SYS-05`）：

- `session.configure(AudioSessionConfiguration.music())`。
- 每次开始播放前 `session.setActive(true)`；返回 false 则不播放。
- `interruptionEventStream`：
  - `begin + pause/unknown` → 暂停并记录 `resumeAfterInterruption = wasPlaying`；
  - `begin + duck` → 音量降到 30%；`end + duck` → 恢复音量；
  - `end + pause` 且 `resumeAfterInterruption` → 继续播放。
- `becomingNoisyEventStream` → 暂停（拔耳机/蓝牙断开）。
- 🔍 M0 需确认 media_kit 在 Android 上**没有**自行申请音频焦点，避免两边重复处理。

## 5. 均衡器（EQ）

### 5.1 实现方式

通过 mpv 的音频滤镜属性 `af` 调用 FFmpeg libavfilter 的 `equalizer` 滤镜，两个平台共用同一实现（`EQ-08`）。

- 10 个频点：31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000 Hz。
- 每段：`equalizer=f=<Hz>:t=o:w=1:g=<dB>`（峰值滤波，带宽 1 倍频程）。
- 增益为 0 的频段**不生成**滤镜，全部为 0 且 preamp 为 0 时 `af` 设为空字符串（直通，零开销）。
- 前级增益：`volume=volume=<dB>dB`，放在链首。
- 自动防削波（`EQ-05`）：开启时 `preamp = -max(0, 所有频段中的最大正增益)`。

`EqFilterBuilder` 输出示例（31Hz +4dB，1kHz -2dB，自动防削波）：

```
lavfi=[volume=volume=-4dB,equalizer=f=31:t=o:w=1:g=4,equalizer=f=1000:t=o:w=1:g=-2]
```

🔍 M0 必须验证：
1. `media_kit_libs_audio` 在 Android 和 macOS 上打包的 libmpv 是否包含 libavfilter 的 `equalizer`、`volume` 滤镜；
2. 上述字符串的转义写法是否被 mpv 正确解析；
3. 播放中修改 `af` 是否会产生爆音或短暂静音。

如果第 1 点失败，备选方案依次为：`firequalizer` / `superequalizer` 滤镜 → mpv 内置滤镜 → 各平台原生实现（Android `android.media.audiofx.Equalizer` 挂到 mpv 的 audio session、macOS 暂不支持）。备选方案启用前必须先告诉开发者。

### 5.2 交互规则

- 滑块拖动时 **防抖 120ms** 后调用 `setAudioFilter`，松手时立即应用一次最终值（`EQ-06`）。
- 若 M0 发现修改 `af` 有明显爆音：改为松手时才应用，拖动中只更新 UI。
- EQ 状态（开关、当前预设 ID、10 个增益、preamp、防削波）保存在 `settings` 表，启动时在 `openQueue` 之前应用。

### 5.3 内置预设（单位 dB，频点顺序同上）

| 预设 | 31 | 62 | 125 | 250 | 500 | 1k | 2k | 4k | 8k | 16k |
|---|---|---|---|---|---|---|---|---|---|---|
| 平坦 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 流行 | -1 | 1 | 3 | 4 | 3 | 0 | -1 | -1 | 1 | 2 |
| 摇滚 | 4 | 3 | 2 | 0 | -1 | -1 | 1 | 3 | 4 | 4 |
| 爵士 | 3 | 2 | 1 | 2 | -1 | -1 | 0 | 1 | 2 | 3 |
| 古典 | 3 | 2 | 1 | 0 | 0 | 0 | 0 | 1 | 2 | 3 |
| 人声 | -2 | -2 | -1 | 1 | 3 | 4 | 3 | 1 | 0 | -1 |
| 低音增强 | 6 | 5 | 4 | 2 | 0 | 0 | 0 | 0 | 0 | 0 |
| 高音增强 | 0 | 0 | 0 | 0 | 0 | 1 | 2 | 4 | 5 | 6 |

（数值为起点，可在实际听感测试后微调，修改时同步更新本表。）

## 6. 平台相关

### 6.1 Android

**Manifest（在 Flutter 模板基础上增加）：**

```xml
<manifest xmlns:tools="http://schemas.android.com/tools" ...>
  <uses-permission android:name="android.permission.WAKE_LOCK"/>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  <!-- 存储：见下方"文件访问策略" -->
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
  <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
  <!-- 仅当 M0-8 证明方案 C 不可行时才加入（见下方文件访问策略） -->
  <!-- <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" tools:ignore="ScopedStorage"/> -->

  <application ...>
    <activity android:name="com.ryanheise.audioservice.AudioServiceActivity" ...> ... </activity>
    <service android:name="com.ryanheise.audioservice.AudioService"
        android:foregroundServiceType="mediaPlayback"
        android:exported="true" tools:ignore="Instantiatable">
      <intent-filter><action android:name="android.media.browse.MediaBrowserService"/></intent-filter>
    </service>
    <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
        android:exported="true" tools:ignore="Instantiatable">
      <intent-filter><action android:name="android.intent.action.MEDIA_BUTTON"/></intent-filter>
    </receiver>
  </application>
</manifest>
```

- `MainActivity` 继承 `AudioServiceActivity`（或直接用它作为 activity）。
- `INTERNET` 权限：media_kit 文档要求网络播放时声明。本项目只播本地文件，🔍 M0 验证不声明 `INTERNET` 是否能正常工作；能则不声明（`NFR-06`）。
- 构建：Release 使用 `--split-per-abi` 或 App Bundle，控制包体。
- 边到边显示：`SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)`，所有页面正确处理 `MediaQuery.padding`（`UI-15`）。

**文件访问策略（重要）**

> **2026-10-17 范围调整**：曲库只有 FLAC/MP3 且歌词、封面全部内嵌（见 REQUIREMENTS §4.1），不再需要读 `.lrc` / `cover.jpg`。因此**默认改为方案 C：只申请 `READ_MEDIA_AUDIO`**（Android 10 及以下用 `READ_EXTERNAL_STORAGE`）。M0-8 须验证：仅此权限下 `dart:io` 能递归列目录、按路径读取音频并交给 libmpv 播放。验证失败再回退到下面的方案 A，届时再把 `MANAGE_EXTERNAL_STORAGE` 加回 Manifest。方案 A/B 的描述保留，供以后恢复外挂歌词（P2）时参考。

Android 11+ 的分区存储下，`READ_MEDIA_AUDIO` 只能读音频文件，**读不到 `.lrc`**（不是媒体文件），而外挂歌词是 P0 需求。

- **方案 A（默认）**：Android 11+ 申请"所有文件访问权限"（`MANAGE_EXTERNAL_STORAGE`，跳转系统设置页让用户开启），之后直接用文件路径扫描、读取 `.lrc` 和 `cover.jpg`，路径可直接交给 media_kit。代价：Google Play 上架受限，本项目不上架，可接受。
- **方案 B（备选）**：存储访问框架（SAF）让用户授权文件夹树，通过 `content://` URI 访问。代价：需要写 platform channel 遍历目录、需验证 media_kit 能否播放 `content://` URI，工作量明显更大。
- 用户拒绝"所有文件访问"时降级：只申请 `READ_MEDIA_AUDIO`，正常播放，但外挂歌词和文件夹封面不可用，设置页提示原因。
- Android 10 及以下：`READ_EXTERNAL_STORAGE` 即可（Android 10 需在 application 上加 `android:requestLegacyExternalStorage="true"`）。
- 🔍 M0 验证方案 A 在一台 Android 13+ 真机上能读到 `.lrc`。

**`androidStopForegroundOnPause`**：设为 `true` 时，暂停后服务退出前台，之后从后台（如蓝牙耳机按键）恢复播放可能触发 `ForegroundServiceStartNotAllowedException`。先设 `false` 保证稳定，代价是暂停时通知不能被划掉；M4 实测后再决定。

### 6.2 macOS

- **关闭 App Sandbox**：`macos/Runner/DebugProfile.entitlements` 与 `Release.entitlements` 中 `com.apple.security.app-sandbox` 设为 `false`。理由：需要自由读取用户选择的任意目录及其中的 `.lrc`、封面；本项目不上架 Mac App Store。若将来要上架，改用 security-scoped bookmarks。
- `audio_service` 的 macOS 要求：`macos/Podfile` 平台版本不低于 `10.12.2`（模板默认值已满足即可）。
- **关闭窗口继续播放（`SYS-08`）**：
  - 用 `window_manager`：`setPreventClose(true)`，在 `onWindowClose` 中 `hide()`；
  - `AppDelegate.swift`：`applicationShouldTerminateAfterLastWindowClosed` 返回 `false`，`applicationShouldHandleReopen` 中重新显示窗口；
  - ⌘Q 和菜单"退出"走正常退出流程，退出前 `dispose` 播放器、保存播放状态。
- 媒体键与控制中心由 `audio_service` 提供；🔍 M0 验证 media_kit 播放时 macOS"正在播放"显示的是我们推送的 `MediaItem`，且不会出现第二个重复条目。
- 键盘快捷键（`SYS-10`）：用 `Shortcuts` + `Actions` 实现，只在 macOS 注册。
- 分发：本地 `flutter build macos --release`，ad-hoc 签名即可，首次运行右键"打开"。

## 7. 曲库、元数据、封面

### 7.1 扫描（LibraryScanner）

1. 递归遍历用户配置的根目录，跳过排除目录和以 `.` 开头的隐藏目录；按扩展名过滤：
   `flac mp3 m4a aac ogg oga opus wav aif aiff alac ape wv dsf dff`（大小写不敏感）。
2. 收集每个文件的 `(path, size, mtime)`，与数据库对比得到 **新增 / 修改 / 删除** 三个集合（`ScanDiff`，纯函数，需单元测试）。
3. 新增和修改的文件分批（每批 50 个）送入 isolate，调用 `readMetadata(file, getImage: false)` 读标签，**扫描阶段不读封面**。
4. 同时记录：同目录是否存在同名 `.lrc`、同目录是否存在 `cover/folder/front.(jpg|jpeg|png)`。
5. 批量写入数据库（drift 事务）；通过 `Stream<ScanProgress>` 报告进度。
6. 删除的文件从库中移除，并清理孤立的专辑/艺术家记录和封面缓存。

读取失败的文件不中断扫描：记录到 `scan_errors`，仍以文件名入库，标记 `metadataError = true`。

### 7.2 归类规则

- **专辑键**：`normalize(albumArtist ?? artist) + '\u0000' + normalize(album)`；`album` 为空时，用"所在目录路径"作为专辑键（让无标签的文件夹也能当专辑浏览）。
- `normalize`：去首尾空白、Unicode NFKC、转小写。显示时用原始文本。
- **艺术家**：P0 只按整个 artist 字符串归类；P1 支持按 `; / 、 feat.` 拆分多艺术家（拆分规则做成可配置）。
- 排序键（`core/sort_key.dart`）：去掉开头的 "The "、全角转半角、英文小写；汉字（U+4E00–U+9FFF）换成无声调拼音并逐音节比较，与英文字母混排（"CATHY" < "曾经" < "CheerS"）；首字符为数字的排最前，其他符号与假名排最后。多音字取最常见读音。拼音数据由 `tool/gen_pinyin.swift`（macOS 的 Mandarin-Latin 转换）生成、`tool/build_pinyin_table.py` 编译为 `lib/core/pinyin_table.dart`，**不引入第三方依赖**，纯 Dart，可在 isolate 内使用。日文假名按码点排序（P2 再考虑读音）。

### 7.3 封面缓存（CoverCache）

- 按需提取：第一次需要显示某专辑封面时，在 isolate 中读取该专辑第一首歌的内嵌图片（`getImage: true`），无内嵌则读文件夹封面。
- 生成两个尺寸写入 `getApplicationSupportDirectory()/covers/`：
  - `<albumKeyHash>_256.jpg`（列表、网格用）
  - `<albumKeyHash>_1024.jpg`（播放页、通知栏 `artUri` 用）
- 文件名用专辑键的 SHA-1；数据库 `albums.coverState` 记录：`unknown / none / cached`，避免重复尝试。
- 列表中用 `Image.file(..., cacheWidth: 实际像素宽度)` 解码，严格控制内存（`NFR-04`）。
- 专辑内歌曲封面不同的情况（少见）：P2 再考虑按曲目缓存。

### 7.4 文本编码

`audio_metadata_reader` 负责解析标签结构。对于 ID3 中声明为 ISO-8859-1 但实际是 GBK/Shift-JIS 的旧文件（`META-06`），以及 `.lrc` 文件（`LRC-09`），由 `TextEncodingDetector` 处理：

1. 有 BOM → 按 BOM（UTF-8 / UTF-16LE / UTF-16BE）。
2. 能通过严格 UTF-8 校验 → UTF-8。
3. 否则分别尝试 Shift-JIS 和 GBK 解码，选"非法字节更少、且出现假名则偏向 Shift-JIS"的那个。
4. 设置中可指定"遇到不确定时优先 Shift-JIS / GBK"。

GBK / Shift-JIS 解码实现 🔍 M0 选型：优先找纯 Dart 包（候选 `charset`）；没有可靠的包时，走 platform channel（Android 用 `java.nio.charset.Charset`，macOS 用 `NSString` 的编码转换），两端各十几行代码。

## 8. 歌词

### 8.1 加载（LyricsLoader）

按 `LRC-03` 的优先级依次尝试，结果缓存在内存（LRU，最多 50 首）：

1. 同目录同名 `.lrc`（文件名与音频文件名相同，仅扩展名不同，大小写不敏感）；
2. 内嵌歌词中**含时间戳**的（内容能被 LrcParser 解析出 ≥ 1 个时间行）；
3. 内嵌纯文本歌词。

内嵌歌词来自 `readMetadata` 返回的 `lyrics` 字段；🔍 M0 用测试文件确认 FLAC 的 `LYRICS` / `UNSYNCEDLYRICS`、MP3 的 `USLT`、M4A 的 `©lyr` 都能读到，读不到的字段用 `readAllMetadata` 取格式专属对象补齐。

### 8.2 LrcParser（纯 Dart，必须有完整单元测试）

- 时间标签：`[mm:ss]`、`[mm:ss.x]`、`[mm:ss.xx]`、`[mm:ss.xxx]`、`[mm:ss:xx]`；分钟可超过 99。
- 一行多个时间标签 → 展开成多行。
- 元信息：`[ti:] [ar:] [al:] [by:] [offset:]`；`offset` 单位毫秒，正值表示歌词提前。
- 同一时间戳出现两行 → 视为 原文 + 翻译（`LRC-08`），按出现顺序第一行为原文。
- 空行保留为"间奏"占位（显示为 •••）。
- 增强型 `<mm:ss.xx>` 逐字时间（`LRC-11`，P2）：P0 阶段解析时**剥离**这些标签，不能显示在文本中。
- 输出按时间升序排列的 `List<LyricLine>`，每行含 `start`、`text`、`translation?`、`words?`。
- 当前行查找用二分查找。

### 8.3 歌词视图

- 使用 `ScrollablePositionedList` 风格的定位方式或自己计算偏移，保证当前行垂直居中，`Curves.easeOutCubic` 300ms 滚动。
- 当前行：`titleLarge` + `colorScheme.onSurface`；其他行：`bodyLarge` + `onSurfaceVariant` 降低透明度。
- 用户拖动后停止自动跟随 3 秒（`LRC-07`）。
- 位置更新：播放中用 `Ticker` 根据"最后一次位置 + 经过时间 × 速率"推算，避免依赖高频 position 流；不可见时停止 Ticker（`NFR-07`）。

## 9. 数据库（drift）

```
tracks(
  id INTEGER PK, path TEXT UNIQUE, size INT, mtime INT,
  title TEXT, artist TEXT, album_artist TEXT, album TEXT,
  album_id INT FK, track_no INT, disc_no INT, year INT, genre TEXT,
  duration_ms INT, sample_rate INT, bit_depth INT, bitrate INT, channels INT, codec TEXT,
  has_embedded_lyrics BOOL, sidecar_lrc_path TEXT, folder_cover_path TEXT,
  metadata_error BOOL, added_at INT, play_count INT, last_played_at INT
)
albums(id PK, album_key TEXT UNIQUE, title, album_artist, year, cover_state INT, cover_track_id INT)
artists(id PK, name_key TEXT UNIQUE, name)
track_artists(track_id, artist_id)                 -- P1 多艺术家
library_roots(id PK, path TEXT UNIQUE, excluded BOOL)
playlists(id PK, name, created_at, updated_at)
playlist_items(playlist_id, position, track_id)
eq_presets(id PK, name, builtin BOOL, gains_json TEXT, preamp REAL)
playback_state(id = 1, queue_json, shuffled_json, current_index, position_ms, loop_mode, shuffle)
settings(key TEXT PK, value TEXT)                  -- 简单 KV
scan_errors(path PK, message, at)
```

- 索引：`tracks(album_id)`、`tracks(title)`、`tracks(artist)`、`tracks(added_at)`。
- 搜索（`LIB-09`）：建立 FTS5 虚表索引 title/artist/album，分词器使用 `trigram`，以支持中日文子串搜索。🔍 M0 确认 `sqlite3_flutter_libs` 自带的 SQLite 版本支持 FTS5 trigram（需 ≥ 3.34）。
- 数据库在后台 isolate 运行（`drift_flutter` 默认即可）。
- Schema 变更必须写迁移，不允许直接删库重建（会丢播放列表）。

## 10. UI 与主题

### 10.1 主题

- `ThemeData(useMaterial3: true, colorScheme: ...)`，全部颜色从 `ColorScheme` 取，**禁止硬编码颜色值**（占位封面的生成色除外）。
- 配色来源（`UI-04`、`SET-02`）：
  - **跟随封面**：用 `ColorScheme.fromImageProvider(provider: FileImage(256px 封面), brightness: ...)` 生成，结果按专辑缓存在内存；
  - **系统配色（默认）**：`dynamic_color` 的 `DynamicColorBuilder`（Android 12+ 壁纸色板，macOS 强调色；不可用时回退到固定色）。整套色板逐个角色复制到 Flutter 的 `ColorScheme`（见附录 B 第 1 条）；
  - **固定主题色**：`ColorScheme.fromSeed`。
- "跟随封面"只作用于播放页、播放条和专辑详情页，其余界面仍用系统配色，切歌时用 `ColorScheme.lerp` + `AnimationController`（400ms）过渡。
- 字体：默认系统字体；中日文混排时设置 `fontFamilyFallback`，Android 上避免日文汉字被渲染成中文字形——根据界面语言设置 `Locale`，必要时为日文文本单独指定 `locale: Locale('ja')`。

### 10.2 自适应布局（按 Material 3 窗口尺寸类）

| 宽度 | 导航 | 播放器 |
|---|---|---|
| 竖屏且 < 840dp | 左侧滑出 `NavigationDrawer`（顶栏左侧菜单按钮打开） | 底部常驻播放条（替代底部导航栏），点击展开为全屏播放页（横屏或宽 ≥ 720dp 时封面与歌词并排） |
| 横屏（宽 > 高）或 ≥ 840dp，且不满足下一行 | 左侧常驻侧边栏（280dp，与手机抽屉共用 `NavigationPanel`），内容区为圆角 surface | 悬浮圆角播放条（与手机一致，浮在内容区底部） |
| 横屏且宽 ≥ 1100dp、高 ≥ 480dp | 同上 | 右侧常驻"正在播放"面板（封面/歌词/队列切换），与目录区按 8:5 分配宽度（重心在播放面板）；"放大"按钮推入沉浸式播放页（横屏或宽 ≥ 720dp 时的播放页布局，矮窗口自动精简标题区：左封面、右歌词/队列且歌词区高度与封面等高对齐、底部控制） |

- 一级导航：歌曲、收藏、专辑、艺术家、文件夹、播放列表、设置（设置与前六项之间用分隔线隔开）；顶栏标题居中，右侧只有搜索（`SearchAnchor`），不设溢出菜单；均衡器从设置页和播放页进入。
- macOS 标题栏：去掉系统标题栏（`titlebarAppearsTransparent` + `fullSizeContentView`，标题隐藏），红绿灯直接浮在应用界面上；红绿灯向内偏移（右 8pt、下 6pt，类似 VS Code，在 `MainFlutterWindow.swift` 里重设按钮位置）；Flutter 侧用 `TitlebarInset`（`lib/app/window_chrome.dart`）在顶部留出 34dp 安全区，桌面布局由侧边栏避让；全屏时通过 MethodChannel `nyaplayer/window` 收到通知并取消该留白。
- macOS 窗口：最小 400×700（手机版的正常大小，在 `MainFlutterWindow.swift` 用 `contentMinSize` 设置），不设最大尺寸，可拉伸至全屏。

### 10.3 组件约定

- 列表项：`ListTile` 系列；专辑网格：`Card`（filled）+ 封面 + 两行文字。
- 播放页的次要功能（歌词、队列、均衡器、歌曲信息、放大/收起）统一放进右上角三横线的 `PlayerMenuButton` 菜单，每项带图标和文字；随机/循环放在播放控制行两侧。
- 进度条：P0 用 `Slider`（2024 M3 样式），P2 再替换为 Expressive 波浪进度条。沉浸式播放页采用"控制按钮在上、时间—进度条—时间同一行在下"的布局。
- 手机播放条悬浮：`PlayerBar(floating: true)` 叠在页面之上，外壳通过 `MediaQuery` 把 `PlayerBar.floatingInset` 加进底部 padding，列表自动留白。
- 字体：设置中切换 `AppFont.serif / sans`；衬线体不打包字体，macOS 用 Times New Roman + 宋体/明朝，Android 用系统 serif + Noto Serif CJK。
- 封面样式：`PlayerArtwork` 统一渲染方形/唱片两种样式；唱片的旋转 `AnimationController` 只在播放时运行（`NFR-07`）。
- 播放/暂停主按钮：`FilledButton` 大尺寸或 `FloatingActionButton.large`。
- 弹出操作：`MenuAnchor` / `showModalBottomSheet`（M3 样式）。
- 动效：使用 Material 动效时长与曲线（`Durations.medium2`、`Easing.emphasizedDecelerate` 等），共享元素过渡用 `Hero`（`UI-11`）。
- **Material 3 Expressive（P2）**：pub.dev 上已有第三方 M3E 组件包（如 `m3e_core`、`m3_expressive`），但普及度低、稳定性未知。使用时必须包在项目自己的 widget 中（如 `LyraSeekBar`），以便随时替换；🔍 开工时再确认 Flutter 官方对 M3 Expressive 的支持进度（Flutter 正在推进 Material 库与框架分离，部分 M3E 包已依赖新的独立 Material 包）。

### 10.4 国际化

- 所有用户可见文本放入 ARB；P0 先只写简体中文和英文 key，日文在 P1 补全（`UI-13`）。
- 时长格式：`m:ss`，超过 1 小时 `h:mm:ss`。

## 11. 代码规范

- 开启 `analysis_options.yaml` 额外规则：`prefer_final_locals`、`always_declare_return_types`、`avoid_print`、`unawaited_futures`、`require_trailing_commas`、`prefer_const_constructors`。
- 不用 `print`，统一用 `core/log.dart`（Release 下只保留 warning 以上）。
- 模型类不可变（`final` 字段 + `copyWith`），不强制使用 freezed。
- 任何 `StreamSubscription`、`AnimationController`、`Ticker` 都必须在 `dispose` 中释放。
- 每个 PR / 里程碑结束前：`dart format .`、`flutter analyze` 零警告、`flutter test` 全通过。

## 12. 测试策略

| 层级 | 对象 | 要求 |
|---|---|---|
| 单元测试（必须） | `LrcParser`、`TextEncodingDetector`、`EqFilterBuilder`、`ScanDiff`、`QueueController`（用 fake `PlayerEngine`）、专辑键 `normalize` | 覆盖所有分支和边界情况 |
| Widget 测试（推荐） | 歌词视图当前行定位、迷你播放条状态、自适应外壳在三种宽度下的布局 | 关键交互 |
| 数据库测试（推荐） | drift 内存数据库测迁移与查询 | 每次改 schema 必测 |
| 真机手测（必须） | 按 `REQUIREMENTS.md` §8 验收清单 | 每个里程碑结束时跑相关条目 |

`test/fixtures/` 中放极小的测试音频（几秒的 FLAC/MP3/M4A/OGG/Opus，带各种标签、内嵌封面和歌词）和各种编码的 `.lrc` 样例；生成方式记录在 `test/fixtures/README.md`。

## 13. 风险清单

| 风险 | 影响 | 应对 |
|---|---|---|
| media_kit 内置 libmpv 不含所需 libavfilter 滤镜 | EQ 方案失效 | M0 第一优先验证；备选见 §5.1 |
| media_kit 最近一次发布在 2025-12，维护节奏放缓 | 新系统版本出兼容问题时修复慢 | `PlayerEngine` 接口隔离内核；关注 GitHub issues |
| media_kit 与 audio_service 在 macOS 上的"正在播放"冲突 | 控制中心显示错乱 | M0 验证；必要时通过 mpv 属性关闭其自带的媒体控制集成 |
| Android 分区存储读不到 `.lrc` | 外挂歌词不可用 | 默认方案 A（所有文件访问）；降级提示 |
| `audio_metadata_reader` 对某些文件解析失败 | 标签缺失 | 失败容错 + 记录 `scan_errors`；必要时为个别格式写补充解析 |
| 大曲库扫描慢 | 首次体验差 | isolate 分批 + 进度显示 + 扫描期间可用 |
| Release 下 FFI 相关代码被裁剪导致崩溃 | 发布版不能播放 | 每个里程碑都用 Release 模式在真机跑一遍 |

## 附录 A：依赖变更记录

| 日期 | 变更 | 理由 |
|---|---|---|
| 2026-10-17 | 初始依赖列表 | 见 §1 |
| 2026-10-17 | 主工程已加入：`flutter_riverpod`、`go_router`、`dynamic_color`、`path`、`intl`、`flutter_localizations`、`mocktail`（dev） | 均在 §1.3 表内，M1 骨架使用 |

## 附录 B：已决问题

1. **`dynamic_color` 与 `material_ui`**：Flutter 3.47 将 Material 拆为独立包 `material_ui`，`dynamic_color` 2.1.0 返回该包的 `ColorScheme`，与 `flutter/material.dart` 的不是同一类型。决定（2026-10-17）：使用完整系统色板，由 `adoptSystemScheme` 逐个角色复制，不新增依赖。
2. **双语歌词的排列（§8.2）**：开发者曲库中 4 首双语歌词的原文/翻译顺序是反的。决定（2026-10-17）：按惯例处理（同一时间戳第一行为原文），这些文件视为数据问题，不做特殊处理。
