# 技术要求（Technical Spec）

> 项目代号：**Lyra** · 文档版本：v0.2 · 2026-10-17（v0.2：播放内核由 media_kit 改为 Rust，见附录 B 第 3 条）
> 配套文档：[`REQUIREMENTS.md`](./REQUIREMENTS.md)、[`PLAN.md`](./PLAN.md)
> 需求编号（如 `EQ-06`）引用自 `REQUIREMENTS.md`。

本文档定义**必须遵守的技术决定**和**推荐做法**。标注 🔍 的条目是"尚未实测、需要在 M0 技术验证中确认"的假设，验证结果写入 `docs/SPIKE_REPORT.md` 并回填本文档。

---

## 1. 技术栈与依赖

### 1.1 基础环境

- Flutter：开工时的最新 **stable** 版本，Dart 3。
- Android：**`minSdk 31`（Android 12 起，开发者 2026-10-17 决定）**，`targetSdk` / `compileSdk` 跟随 Flutter 模板默认值（不得低于 34）。Rust 输出库 cpal 直接使用 AAudio（需 API 26+），Android 12 基线同时保证壁纸取色（`UI-03`）全员可用。
- macOS：部署目标 **15.0（Sequoia）**，Intel + arm64。
- iOS：部署目标 **18.0**，arm64。
- 平台优先级（2026-10-18 开发者决定，详见 [`PLATFORM_SUPPORT.md`](./PLATFORM_SUPPORT.md)）：**优先适配 macOS、Android、iOS；次级适配 Windows（10+，x64/arm64）、Linux（Ubuntu 22.04，x64/aarch64）；明确拒绝适配 HarmonyOS**，Web 同样不做。
- 平台目录按优先级逐步生成：当前已有 android、macos；iOS 适配开始时执行 `flutter create --platforms=ios .`；windows / linux 在次级适配开始时再生成。不生成 web 与 ohos 目录。

### 1.2 核心依赖（版本为 2026-10-17 在 pub.dev / crates.io 核实的最新版）

**播放内核与元数据读取用 Rust 实现**（`rust/` 目录的 `nya_core` crate），通过 `flutter_rust_bridge` 暴露给 Dart。理由见附录 B 第 3 条。

Dart 侧：

| 用途 | 包 | 版本 | 备注 |
|---|---|---|---|
| Dart ↔ Rust 桥 | `flutter_rust_bridge` | 2.13.0（**与 Rust 侧版本必须完全一致**） | 代码生成 + Cargokit 在 `flutter build` 时自动编译各平台 Rust 库 |
| 后台/系统媒体控制 | `audio_service` | ^0.18.19 | Android 通知、锁屏、耳机键；macOS 控制中心、媒体键 |
| 音频焦点/中断 | `audio_session` | 跟随 audio_service 约束 | 处理来电、拔耳机 |

Rust 侧（`rust/Cargo.toml`）：

| 用途 | crate | 版本 | 备注 |
|---|---|---|---|
| 解码 | `symphonia` | 0.6 | 只启用 FLAC、MP3；开启 gapless（去除编码器延迟/填充） |
| 输出、队列、跳转、重采样 | `rodio` | 0.23 | 底层 `cpal` 0.18：Android 走 AAudio/OpenSL ES（Oboe），macOS 走 CoreAudio；只启用需要的解码特性 |
| 均衡器滤波器 | `biquad` | 0.6 | 10 段峰值滤波（RBJ cookbook），见 §5 |
| 标签/封面/歌词/音频参数 | `lofty` | 0.25 | FLAC Vorbis Comment / PICTURE，MP3 ID3v2（USLT/SYLT/APIC） |
| 桥 | `flutter_rust_bridge` | 2.13.0 | 同上 |
| 通用 | `anyhow`、`log`（+ 平台日志后端） | 最新 | 错误与日志 |

开发环境：Rust stable（rustup，含 `clippy`、`rustfmt`），target：`aarch64-apple-darwin`、`x86_64-apple-darwin`、`aarch64-linux-android`、`armv7-linux-androideabi`、`x86_64-linux-android`；Android NDK 使用 SDK 中已安装的版本（Cargokit 读取 Gradle 配置的 `ndkVersion`）。

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
| 缓存键 SHA-1 | `crypto` 3.0.7（2026-10-18 开发者授权，从已有间接依赖声明为直接依赖） |
| 国际化 | `flutter_localizations` + `intl`（ARB 文件） |
| 列表拖拽排序 | Flutter 自带 `ReorderableListView` 即可 |
| 测试 | `flutter_test`、`mocktail` |
| Lint | `flutter_lints`（在此基础上开启第 10 节的额外规则） |

**新增依赖规则**：引入上表以外的包（含 Rust crate）之前，必须在本文档"附录 A 依赖变更记录"中写明理由。优先选择 pub points 高 / crates.io 下载量高、近 12 个月有发布的包；Rust crate 一律关闭默认特性、只开需要的特性，控制包体。

### 1.4 明确不用的东西

- `just_audio`：EQ 只在 Android 有，不满足 `EQ-08`。
- `media_kit`（libmpv）：原定内核，2026-10-17 改为 Rust 内核（附录 B 第 3 条）。**保留为退路**：若 M0 证明 Rust 内核在无缝播放、Android 输出稳定性上有阻断问题，经开发者同意后回退，`PlayerEngine` 接口不变。
- `audio_metadata_reader`：由 Rust `lofty` 取代（同一次调用拿到标签、歌词、封面和音频参数，无需 Dart isolate）。
- `ffmpeg_kit_flutter` 系列：已停止维护且用途是转码，不是播放。
- `on_audio_query`：依赖 MediaStore，拿不到 `.lrc`，且跨平台不一致，统一改为自己扫描文件系统。

## 2. 总体架构

```
┌───────────────────────────── UI 层（features/*）──────────────────────────────┐
│  Widgets + Riverpod providers（只读状态、发出意图，不直接碰播放内核）            │
└──────────────────────────────────────┬───────────────────────────────────────┘
                                       │ 调用 / 订阅
┌──────────────────────────── 应用服务层（services/*）──────────────────────────┐
│ LyraAudioHandler（audio_service）──► QueueController ──► PlayerEngine 接口       │
│        ▲ 系统通知/媒体键/控制中心          │                    │               │
│        │                                │                 RustPlayerEngine   │
│ AudioFocusCoordinator（audio_session）    │                 （FRB 调用 Rust）   │
│ EqController ──► setEqualizer ───────────┘                                     │
│ LibraryScanner ─► MetadataExtractor ─► CoverCache    LyricsLoader ─► LrcParser │
└──────────────────────────────────────┬───────────────────────────────────────┘
                                       │ flutter_rust_bridge（FFI）
┌──────────────────────────── Rust 内核（rust/ nya_core）───────────────────────┐
│ player：命令通道 + 独立音频线程（rodio/cpal）；队列预读实现无缝播放；事件流回 Dart │
│ dsp：10 段 biquad EQ + 前级增益 + 防削波，参数无锁更新、带平滑，不爆音            │
│ decode：symphonia（FLAC/MP3，gapless）     meta：lofty（标签/歌词/封面/参数）    │
└──────────────────────────────────────┬───────────────────────────────────────┘
                                       │
┌────────────────────────────── 数据层（data/*）────────────────────────────────┐
│ Drift 数据库（tracks / albums / artists / playlists / eq_presets / settings）  │
│ Repository 封装查询；文件系统访问封装在 platform/ 下                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

**硬性约束：**

1. 全应用只有**一个** Rust 播放器实例（Rust 侧单例），由 `RustPlayerEngine` 访问。
2. UI 永远通过 `AudioHandler`（或其上的 provider）控制播放，**不得**直接调用 Rust API（`lib/src/rust/` 生成代码只允许 `services/` 引用），否则通知栏/媒体键状态会和 UI 不一致。
3. `PlayerEngine` 是抽象接口，`RustPlayerEngine` 是其实现（测试用 `FakePlayerEngine`）。这样以后换内核只改一个类。
4. 耗时操作不阻塞 UI 线程：读标签、提取封面、生成缩略图在 Rust 中执行（FRB 的 async 调用跑在 Rust 线程池上，天然不占 Dart UI 线程）；纯 Dart 的耗时计算（如大批量 ScanDiff）仍放 isolate。
5. Rust 音频线程**不能**分配内存、加锁等待或做 I/O：解码和预读在单独的解码线程完成，音频回调只读取环形缓冲/rodio 源，参数通过原子量传递。

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
├── src/rust/                      # flutter_rust_bridge 生成代码（不手改，不提交以外的修改）
├── services/
│   ├── player/
│   │   ├── player_engine.dart     # 抽象接口
│   │   ├── rust_player_engine.dart
│   │   ├── queue_controller.dart
│   │   ├── lyra_audio_handler.dart
│   │   └── audio_focus.dart
│   ├── eq/                        # EqController, 内置预设, EqParams 计算（preamp/防削波）
│   ├── library/                   # LibraryScanner, ScanDiff, MetadataExtractor, CoverCache
│   ├── lyrics/                    # LyricsLoader, LrcParser, TextEncodingDetector
│   └── platform/                  # Android 存储权限、macOS 窗口行为
├── features/
│   ├── onboarding/  library/  album/  artist/  folder/  search/
│   ├── now_playing/  lyrics/  queue/  equalizer/  settings/  playlists/
│   └── shared/                    # 共享 widget：封面图、歌曲列表项、迷你播放条
└── l10n/                          # app_zh.arb, app_ja.arb, app_en.arb
test/                              # 与 lib/ 镜像的目录结构
rust/                              # Rust crate nya_core（Cargo 工程）
├── Cargo.toml
└── src/
    ├── api/                       # 暴露给 Dart 的函数（FRB 扫描此目录）：player.rs, meta.rs, eq.rs
    ├── player/                    # 引擎线程、命令/事件、队列与预读、输出设备管理
    ├── dsp/                       # Equalizer（biquad）、参数平滑
    └── meta/                      # lofty 读取、歌词/封面提取
rust_builder/                      # FRB 生成的 Flutter 插件壳（Cargokit），把 Rust 库编进各平台产物
docs/                              # 三份文档 + SPIKE_REPORT.md
```

## 4. 播放引擎

### 4.1 初始化顺序（`main.dart`）

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();                         // 加载 Rust 库，必须最先
  final db = AppDatabase();                     // drift
  final engine = await RustPlayerEngine.create(); // 启动 Rust 引擎线程、订阅事件流
  final handler = await AudioService.init(
    builder: () => LyraAudioHandler(engine, ...),
    config: const AudioServiceConfig(
      androidNotificationChannelId: '<org>.lyra.playback',
      androidNotificationChannelName: '播放',
      androidStopForegroundOnPause: true,       // 暂停后交还系统调度（§6.1）
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
  Future<void> reorder(List<int> order); // 原索引的完整排列；保留当前音源和进度
  Future<void> setLoopMode(LoopMode mode);           // none / all / one
  Future<void> setEqualizer(EqParams params);        // EQ，见 §5；开关、10 段增益、前级增益
  Future<void> setVolume(double linear);             // 0..1，用于音频焦点 duck
  Future<void> dispose();
}
```

### 4.3 Rust 引擎要点（`rust/src/player`，Dart 侧 `RustPlayerEngine`）

- **线程模型**：Dart 调用 → FRB → 往命令通道（`crossbeam`/`std::sync::mpsc`）发命令，立即返回；引擎线程处理命令、驱动 rodio；状态变化通过 FRB `StreamSink` 推回 Dart（`playing`、`currentIndex`、`completed`、`error`、`audioParams`）。**位置不推流**：Dart 侧用 `positionOf()` 在需要时拉取 / 以 200ms 定时拉取，播放页按 §8.3 外推。
- **队列在 Rust 侧只保留"路径列表 + 当前下标 + 循环模式"**，真相仍在 Dart `QueueController`；Dart 每次变更用增量命令（add/insert/remove/move）同步。
- **无缝播放（`PLAY-07`）**：当前曲目剩余约 5 秒（或解码完成时）预先打开并解码下一首，追加到 rodio 队列；symphonia 打开 `enable_gapless`，按编码器延迟/填充裁剪首尾样本；两首在同一输出流里首尾相接，不重建设备。下一首的身份由包装 Source 在其第一个样本被取用时发出 `currentIndex` 事件。🔍 M0 验证。
- **采样率**：输出流按设备默认配置打开；音源采样率不同时由 rodio 的高质量重采样转换（如 192k → 48k）。切到采样率不同的下一首时只换重采样器，不重开设备。
- **EQ 位置**：在重采样之后、输出之前（按设备采样率计算系数），见 §5。2026-10-18 已修正实现：每首歌先通过 rodio `UniformSourceIterator` 转换为已打开设备的声道数/采样率，再包 `EqSource`、`Tracked`，最后追加给 `Player`；离线回归与 macOS 基础实听结果见 `SPIKE_REPORT.md` §3，Android 仍待验证。
- **循环模式**：none / all / one 由引擎决定"下一首是谁"（one 时预读同一首）。
- **随机播放**：由 `QueueController` 决定排列，通过 `reorder` 原子地重排 Rust 队列；Rust 不实现随机算法。
- **解码失败**：发出 `error` 事件并自动跳到下一首；连续失败超过 5 首则停止，避免死循环（`FMT-07`）。
- **输出设备变化**（拔耳机、蓝牙断开/切换）：cpal 报错或默认设备改变时，引擎重建输出流并从当前位置继续（是否继续播放由 Dart 侧"拔耳机即暂停"规则决定）。🔍 M0 验证 Android。
- 不读取视频轨/封面流：解码只取第一条音频轨。

### 4.4 QueueController

- 是播放队列的**唯一真相来源**：持有 `originalOrder`、`shuffledOrder`、`currentIndex`、`loopMode`、`shuffleEnabled`。
- 开启随机：保留当前曲目实例在第 0 位，其余 Fisher–Yates 打乱；关闭随机恢复原顺序。2026-10-18 严重 bug 修复：两者均发送完整索引排列 `reorder`，校验后一次替换队列顺序，保留条目的稳定 ID、当前解码器、输出流、进度与暂停/播放状态，只刷新下一曲预载。不得重新 openQueue、seek 或暂停/恢复当前曲目。重复歌曲按出现次数匹配，保持当前实例而非仅按文件名匹配；非法排列不改变队列。
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
- 2026-10-18 实现：`LyraAudioHandler` 观察同一个 QueueController / PlayerEngine，不创建第二个播放器。系统指令走 QueueController；小幅度 seek 通过独立 seekEvents 同步，正常位置轮询只更新本地锚点，循环回到开头时更新系统。封面先发布文字，再异步发布本地文件 URI，使用歌曲代次防止旧封面串图。macOS 的 MPNowPlayingInfoCenter / MPRemoteCommandCenter 及 Android MediaSession 由 audio_service 的官方平台桥接提供。
- 循环、随机、EQ 预设切换等通过 `customAction` 暴露给 UI。

### 4.6 音频焦点与中断（AudioFocusCoordinator）

Rust 内核（cpal）不负责系统音频会话，必须自己用 `audio_session` 处理（`SYS-04`、`SYS-05`）：

- `session.configure(AudioSessionConfiguration.music())`。
- 每次开始播放前 `session.setActive(true)`；返回 false 则不播放。
- `interruptionEventStream`：
  - `begin + pause/unknown` → 暂停并记录 `resumeAfterInterruption = wasPlaying`；
  - `begin + duck` → `setVolume(0.3)`；`end + duck` → 恢复音量；
  - `end + pause` 且 `resumeAfterInterruption` → 继续播放。
- `becomingNoisyEventStream` → 暂停（拔耳机/蓝牙断开）。
- 🔍 M0 需确认 cpal/Oboe 在 Android 上**没有**自行申请音频焦点（预期没有），并确认 AAudio 流的 usage 为 media。

## 5. 均衡器（EQ）

### 5.1 实现方式

在 Rust 内核中实现（`rust/src/dsp`），两个平台共用同一实现（`EQ-08`），不依赖任何系统 EQ 或 FFmpeg 滤镜。

- 10 个频点：31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000 Hz。
- 每段为二阶峰值滤波（RBJ Audio EQ Cookbook，`biquad` crate），带宽 1 倍频程（Q ≈ 1.414），每声道独立状态，`f32` 处理。
- 前级增益：线性乘法，放在滤波器之前。
- 自动防削波（`EQ-05`）：开启时 `preamp = -max(0, 所有频段中的最大正增益)`，由 Dart 侧 `EqParams` 计算后下发（与 UI 显示一致）。
- 直通：EQ 关闭，或全部增益为 0 且 preamp 为 0 时完全跳过处理（零开销）。
- 系数按**输出采样率**计算；输出采样率变化时重算。频点 ≥ 采样率/2 时该段跳过。
- **参数更新不爆音**：新参数通过无锁方式（原子交换）交给音频线程；增益在约 20ms 内线性插值过渡（逐块重算系数），不直接跳变。
- 输出前做硬限幅到 [-1, 1]（兜底，正常情况下防削波已避免）。

单元测试（`cargo test`）：系数与参考值一致；1 kHz 正弦经 1 kHz +6 dB 后幅度增益在 ±0.2 dB 内；全 0 时输出与输入逐样本相同；参数切换过程中无超过阈值的跳变。

### 5.2 交互规则

- 滑块拖动时**节流 30ms** 调用 `setEqualizer`（Rust 侧开销极小，实时可听），松手时立即应用一次最终值（`EQ-06`）。
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
- `INTERNET` 权限：Rust 内核只读本地文件，**不声明** `INTERNET`（`NFR-06`）。
- Rust 库由 Cargokit 在 Gradle 构建时编译为 `arm64-v8a`、`armeabi-v7a`、`x86_64` 三个 ABI 的 `.so`；cpal 0.18 在 Android 上直接调用 AAudio（链接 `libaaudio`），不再需要 OpenSL ES 回退。
- 构建：Release 使用 `--split-per-abi` 或 App Bundle，控制包体。
- 边到边显示：`SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)`，所有页面正确处理 `MediaQuery.padding`（`UI-15`）。

**文件访问策略（重要）**

> **2026-10-17 范围调整**：曲库只有 FLAC/MP3 且歌词、封面全部内嵌（见 REQUIREMENTS §4.1），不再需要读 `.lrc` / `cover.jpg`。因此**默认改为方案 C：只申请 `READ_MEDIA_AUDIO`**（Android 12 用 `READ_EXTERNAL_STORAGE`）。M0-8 须验证：仅此权限下 `dart:io` 能递归列目录，Rust 能按路径打开并播放音频。验证失败再回退到下面的方案 A，届时再把 `MANAGE_EXTERNAL_STORAGE` 加回 Manifest。方案 A/B 的描述保留，供以后恢复外挂歌词（P2）时参考。

Android 11+ 的分区存储下，`READ_MEDIA_AUDIO` 只能读音频文件，**读不到 `.lrc`**（不是媒体文件），而外挂歌词是 P0 需求。

- **方案 A（默认）**：Android 11+ 申请"所有文件访问权限"（`MANAGE_EXTERNAL_STORAGE`，跳转系统设置页让用户开启），之后直接用文件路径扫描、读取 `.lrc` 和 `cover.jpg`，路径可直接交给 Rust 内核。代价：Google Play 上架受限，本项目不上架，可接受。
- **方案 B（备选）**：存储访问框架（SAF）让用户授权文件夹树，通过 `content://` URI 访问。代价：需要写 platform channel 遍历目录、需把 `content://` 打开为文件描述符再交给 Rust，工作量明显更大。
- 用户拒绝"所有文件访问"时降级：只申请 `READ_MEDIA_AUDIO`，正常播放，但外挂歌词和文件夹封面不可用，设置页提示原因。
- Android 12（API 31–32）：`READ_EXTERNAL_STORAGE`；Android 13+：`READ_MEDIA_AUDIO`。（minSdk 31，不再考虑 Android 10 及以下。）
- 🔍 M0 验证方案 A 在一台 Android 13+ 真机上能读到 `.lrc`。

**`androidStopForegroundOnPause`**：2026-10-18 开发者指定服从系统电源调度，改为 `true`。播放期间使用 mediaPlayback 前台服务，暂停后退出前台并释放插件的播放唤醒锁；划掉最近任务不主动停止正在播放的队列，由系统电池设置、系统版本及厂商策略决定服务存活时间，不保证“无限制”绝不被回收。保持插件 START_NOT_STICKY，不请求电池优化豁免、不使用守护进程/定时拉起/重启保活、不实现自定义生存时限。后台恢复仍须满足系统前台服务启动限制，蓝牙恢复/系统停止等行为待 Android 真机实测；不得绕过系统限制强行恢复。

### 6.2 macOS

- **关闭 App Sandbox**：`macos/Runner/DebugProfile.entitlements` 与 `Release.entitlements` 中 `com.apple.security.app-sandbox` 设为 `false`。理由：需要自由读取用户选择的任意目录及其中的 `.lrc`、封面；本项目不上架 Mac App Store。若将来要上架，改用 security-scoped bookmarks。
- `audio_service` 的 macOS 要求：`macos/Podfile` 平台版本不低于 `10.12.2`（模板默认值已满足即可）。
- **关闭窗口继续播放（`SYS-08`）**：
  - 用 `window_manager`：`setPreventClose(true)`，在 `onWindowClose` 中 `hide()`；
  - `AppDelegate.swift`：`applicationShouldTerminateAfterLastWindowClosed` 返回 `false`，`applicationShouldHandleReopen` 中重新显示窗口；
  - ⌘Q 和菜单"退出"走正常退出流程，退出前 `dispose` 播放器、保存播放状态。
  - 2026-10-18 开发者指定：补齐原生“关闭窗口 / ⌘W”菜单，红色关闭按钮采用同样的隐藏行为，保留窗口、Flutter 引擎与现有控制中心会话。Dock 或常驻菜单栏图标可显示原窗口，不重新建播放器。菜单栏图标使用 AppKit NSStatusItem（无额外依赖），包含显示窗口、播放/暂停、上下首、退出，标签跟随应用语言。
  - 退出请求通过独立生命周期通道先停止媒体会话、释放 Dart 播放器和 provider，再批准 AppKit 终止；并发退出只清理一次，3 秒未回应时允许系统退出。播放状态持久化仍待 M3-9/数据库，不能把本次进程退出误记为恢复功能完成。
- 媒体键与控制中心由 `audio_service` 提供（cpal 不注册"正在播放"，不会出现重复条目）；🔍 M0 验证。
- Rust 库：Cargokit 构建通用二进制（arm64 + x86_64），随 App 打包，无需额外签名步骤。
- 键盘快捷键（`SYS-10`）：用 `Shortcuts` + `Actions` 实现，只在 macOS 注册。2026-10-18 开发者指定：⌘, 打开可返回原页面的设置，空格播放/暂停、⌘←/→ 上下首、⌘F 全局搜索；文本编辑期间不抢占空格与方向键。原生应用菜单的 Settings… / ⌘, 同步通过 MethodChannel 打开相同设置入口，保留系统自带的退出、隐藏、最小化与全屏快捷键。
  - 设置中的快捷键说明按实际支持的平台显示：当前仅 macOS 展示；Android 不展示，Windows 待后续适配后再提供自己的按键说明，不显示 macOS 的 ⌘ 文案。
- 分发：本地 `flutter build macos --release`，ad-hoc 签名即可，首次运行右键"打开"。

## 7. 曲库、元数据、封面

### 7.1 扫描（LibraryScanner）

1. 递归遍历用户配置的根目录，跳过排除目录和以 `.` 开头的隐藏目录；按扩展名过滤：
   `flac mp3 m4a aac ogg oga opus wav aif aiff alac ape wv dsf dff`（大小写不敏感）。
2. 收集每个文件的 `(path, size, mtime)`，与数据库对比得到 **新增 / 修改 / 删除** 三个集合（`ScanDiff`，纯函数，需单元测试）。
3. 新增和修改的文件分批（每批 50 个）交给 Rust `read_metadata_batch(paths)`（lofty，Rust 线程池并行），返回标签、歌词、音频参数，**扫描阶段不读封面图片数据**（只记录是否有内嵌封面）。
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

- 按需提取：第一次需要显示某专辑封面时，调用 Rust `read_cover(path)` 读取该专辑第一首歌的内嵌图片字节（优先 Front Cover 类型），无内嵌则读文件夹封面。缩放在 Dart isolate 中用 `image` 包完成（或 M2 评估改用 Rust `image` crate）。
- 生成两个尺寸写入 `getApplicationSupportDirectory()/covers/`：
  - `<albumKeyHash>_256.jpg`（列表、网格用）
  - `<albumKeyHash>_1024.jpg`（播放页、通知栏 `artUri` 用）
- 文件名用专辑键的 SHA-1；数据库 `albums.coverState` 记录：`unknown / none / cached`，避免重复尝试。
- **2026-10-18 接入进度（M2-6）**：`CoverCache` 已复用 Rust `read_cover`，在 Dart isolate 中完成 EXIF 方向校正、等比缩放和 JPEG 编码；尺寸是长边上限，不放大低分辨率封面。文件放在 `covers/<源文件版本哈希>/<albumKeyHash>_256.jpg` 与 `_1024.jpg`，版本由文件路径、size、mtime 和缓存格式版本决定，避免标签更新后命中 Flutter 的旧图片内存缓存。完成标记最后写入；同一源并发请求去重，提取/解码串行执行，限制大图内存峰值。
- Drift 尚未落地，**数据库 `coverState` 与孤立缓存清理待 M1-5 / M2 扫描器接入**；当前缺图结果按源版本在内存记忆，正向磁盘缓存可跨启动复用。按范围调整，本轮只读内嵌封面，文件夹封面仍为 P2。通过 `CoverSource` 给模型传递代表曲目的信息，UI 仅通过服务 provider 获取缓存文件，不直接调用 Rust API。
- 列表中用 `Image.file(..., cacheWidth: 实际像素宽度)` 解码，严格控制内存（`NFR-04`）。
- 专辑内歌曲封面不同的情况（少见）：P2 再考虑按曲目缓存。

### 7.4 文本编码

`lofty` 负责解析标签结构。对于 ID3 中声明为 ISO-8859-1 但实际是 GBK/Shift-JIS 的旧文件（`META-06`），以及 `.lrc` 文件（`LRC-09`），由 `TextEncodingDetector` 处理：

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

内嵌歌词由 Rust `meta` 模块读取：FLAC 的 `LYRICS` / `UNSYNCEDLYRICS`（Vorbis Comment），MP3 的 `USLT`（以及 `SYLT` 同步歌词，转换成 LRC 文本返回）；🔍 M0 用开发者真实样本确认。

### 8.2 LrcParser（纯 Dart，必须有完整单元测试）

- 时间标签：`[mm:ss]`、`[mm:ss.x]`、`[mm:ss.xx]`、`[mm:ss.xxx]`、`[mm:ss:xx]`；分钟可超过 99。
- 一行多个时间标签 → 展开成多行。
- 元信息：`[ti:] [ar:] [al:] [by:] [offset:]`；`offset` 单位毫秒，正值表示歌词提前。
- 同一时间戳出现两行 → 视为 原文 + 翻译（`LRC-08`），按出现顺序第一行为原文。
- 2026-10-18 实际内嵌样本：《小小奇迹》42 组、《打上花火》44 组，均为同一时间标签内用 U+2009 细空格分隔原文和中文。新增同行双语识别：细空格/其他 Unicode 宽空格、制表符、至少两个普通空格、`//`、`|` / `｜`、两侧带空格的 `/`、字面 `\n` 与 `<br>`。仅在两侧语言文字特征符合英/日/中译文关系时拆分，普通句子词间空格、同语言片段、含冒号的制作信息和歌手名裸斜杠保持原样；同时间戳分行仍优先保留，不猜测原译倒序。
- 带时间戳原文紧接一行无时间戳译文时，通过同样的语言判定附到前一时间标签（多时间标签全部复制）；纯文本只识别显式同行分隔，不把任意相邻段落配对。同时间戳下重复译文去重。显示开关通过 `LyricLine.translation` 生效，关闭后不应残留同行中译。
- 空行保留为"间奏"占位（显示为 •••）。
- 增强型 `<mm:ss.xx>` 逐字时间（`LRC-11`，P2）：P0 阶段解析时**剥离**这些标签，不能显示在文本中。
- 输出按时间升序排列的 `List<LyricLine>`，每行含 `start`、`text`、`translation?`、`words?`。
- 当前行查找用二分查找。

### 8.3 歌词视图

- 使用 `ScrollablePositionedList` 风格的定位方式或自己计算偏移，保证当前行垂直居中，`Curves.easeOutCubic` 300ms 滚动。
- 当前行：`colorScheme.onSurface` + 加粗，按歌词字号的 1.15 倍再加 1pt（默认 20 → 24pt）；其他行使用歌词字号 + `onSurfaceVariant` 降低透明度。封面下三行预览的高亮字比原先增加 1pt。
- 行距（2026-10-18 开发者指定）：默认行高 1.2 倍（原为 1.35），歌词条目上下留白从各 10pt 收紧到各 6pt。播放菜单 → 歌词设置可输入 1.0～2.0 倍行距，步进 0.1；同步作用于主歌词、翻译与三行预览。预览按行距和系统字体缩放计算占用高度，封面随剩余空间收缩；偏好暂存内存。
- 封面下三行预览：当前行含翻译且开关开启时，第三行显示当前译文（较小字号），否则显示下一行原文；不增加预览高度。完整歌词把译文独立放在原文下方，较小字号，关闭翻译后两处都隐藏译文。
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
  - **系统配色（默认）**：`dynamic_color` 的 `DynamicColorBuilder`（Android 12+ 壁纸色板，macOS 强调色；不可用时回退到固定色）。整套色板逐个角色复制到 Flutter 的 `ColorScheme`（见附录 B 第 1 条）；
  - **固定主题色**：`ColorScheme.fromSeed`。
- 2026-10-18 开发者调整：移除中间的“跟随封面”取色选项及播放器局部主题覆盖，配色仅保留系统 / 固定色；专辑封面模糊背景独立保留，不改变控件的主题色。
- 字体：默认系统字体；中日文混排时设置 `fontFamilyFallback`，Android 上避免日文汉字被渲染成中文字形——根据界面语言设置 `Locale`，必要时为日文文本单独指定 `locale: Locale('ja')`。

### 10.2 自适应布局（按 Material 3 窗口尺寸类）

| 宽度 | 导航 | 播放器 |
|---|---|---|
| 竖屏且 < 720dp | 左侧滑出 `NavigationDrawer`（顶栏左侧菜单按钮打开） | 底部常驻播放条，点击展开为全屏播放页（横屏或宽 ≥ 720dp 时封面与歌词并排） |
| 横屏（宽 > 高）或 ≥ 720dp，且不满足下一行 | 左侧常驻侧边栏（244dp，与手机抽屉共用 `NavigationPanel`），内容区为圆角 surface | 悬浮圆角播放条（与手机一致，浮在内容区底部） |
| 宽 ≥ 960dp、高 ≥ 480dp（含宽竖屏） | 同上 | 右侧常驻正在播放面板。中间目录栏分配剩余宽度约 42%，最小 300dp、最大 420dp 后停止增长，其余空间均给播放面板；放大按钮推入沉浸式播放页，矮窗口精简标题区。歌词容器保留与封面/音质信息的外边界对齐，文字留白另见 §10.3。 |

- 2026-10-18 开发者指定折叠屏与桌面调整：按可用逻辑宽度放宽判定，不依赖横竖屏方向。按开发者最新要求移除侧栏收起功能及 macOS 原生收起按钮；桌面侧栏固定 244dp 展开，双栏最低宽度统一为 960dp。手机继续使用抽屉导航。
- 桌面播放面板与沉浸式页面的放大/退出放大按钮使用 18dp 图标、34dp 点击区域，取消 Material 默认的额外触摸留白；按钮无常驻背景。

- 一级导航：歌曲、收藏、专辑、艺术家、文件夹、播放列表、设置（设置与前六项之间用分隔线隔开）；顶栏标题居中，右侧只有搜索（`SearchAnchor`），不设溢出菜单；均衡器从设置页和播放页进入。
- macOS 标题栏：去掉系统标题栏（`titlebarAppearsTransparent` + `fullSizeContentView`，标题隐藏），红绿灯直接浮在应用界面上；红绿灯向内偏移（右 8pt、下 6pt，类似 VS Code，在 `MainFlutterWindow.swift` 里重设按钮位置）；Flutter 侧用 `TitlebarInset`（`lib/app/window_chrome.dart`）在顶部留出 34dp 安全区，桌面布局由侧边栏避让；全屏时通过 MethodChannel `nyaplayer/window` 收到通知并取消该留白。
- macOS 窗口：最小 400×700（手机版的正常大小，在 `MainFlutterWindow.swift` 用 `contentMinSize` 设置），不设最大尺寸，可拉伸至全屏。

### 10.3 组件约定

- 列表项：`ListTile` 系列；专辑网格：`Card`（filled）+ 封面 + 两行文字。
- 一级页面顶部标题（Songs 等）：在现有全局字号调整基础上再减小 1pt，列表正文与播放器标题字号保持各自设置。
- 播放页次要操作使用 `PlayerMenuButton`，每项带图标和文字。2026-10-18 开发者调整：手机紧凑播放页菜单去掉歌词/队列条目，保留左右滑切歌词和上滑队列入口；桌面歌词/队列通过顶部分段按钮切换。桌面展开页与右侧面板底部的收藏、播放控制、更多按钮作为一组居中排列，不再贴两边。
- 桌面展开歌词：外容器保持与封面顶部、音质标签底部对齐，面板向左扩展 48pt，右边界不变，队列位置不变。2026-10-18 开发者再次调整：容器内歌词上下各留约 7% 空白（8–48dp），左右各留约 5%（12–32dp），可滚动的歌词区最大宽度 560dp，基于居中位置再向左偏约 16dp（用不对称内边距实现，左边距不低于 0），避免全屏文字完全撑满。歌词淡出边缘跟随内层滚动区，手机紧凑页维持原布局。
- 进度条（2026-10-18 开发者指定）：设置提供 Material（默认）、经典圆点、细线、波浪四种样式，手机/侧栏/沉浸式播放器共用同一偏好；均基于 Slider 保留拖动、键盘及无障碍语义。波浪为静态装饰，不伪装成音频波形，不启动常驻动画。沉浸式采用“控制在上、时间—进度条—时间在下”布局，样式暂存内存，待设置表落地后统一持久化。
- 播放器的播放/暂停、上下首、随机、循环、收藏、菜单及歌词/队列切换均使用无常驻背景的图标按钮；选中项使用主题主色表示状态，保留悬停、聚焦与按下反馈及原触控面积。
- 手机播放条悬浮：`PlayerBar(floating: true)` 叠在页面之上，外壳通过 `MediaQuery` 把 `PlayerBar.floatingInset` 加进底部 padding，列表自动留白。
- 字号（2026-10-18 开发者调整）：全局 `textTheme` / `primaryTextTheme` 的各级字号在 Material 3 默认值上减 1 个逻辑像素，保留系统字体缩放；歌词单独使用设置值，默认 20pt，不再叠加全局减量。
- 字体：设置中切换 `AppFont.serif / sans`；衬线体不打包字体，macOS 用 Times New Roman + 宋体/明朝，Android 用系统 serif + Noto Serif CJK。
- 播放页背景（2026-10-18 开发者指定）：独立于主题配色来源，设置中可选主题渐变或封面模糊，默认封面模糊。手机完整播放页、桌面展开播放页和右侧播放器共用同一实现；使用缓存的 256px 封面放大并进行高度模糊，叠加 ColorScheme 表面色保证可读，切歌平滑过渡，无封面回退主题渐变。设置暂随现有 ThemeSettings 存内存，后续统一接 settings 表。
  - 封面背景微调（2026-10-18 开发者纠正）：仅深色模式在 48% surface 遮罩上再叠加 ColorScheme.scrim 的 10% 黑色遮罩；浅色模式不加黑色遮罩，surface 遮罩不透明度由 68% 降为 50%，减少泛白、保留封面色彩。播放条同样仅深色叠 10% 黑色遮罩，浅色的 surfaceContainerHigh 遮罩由 45% 降为 35%。只作用于封面背景，不修改主题渐变或前景封面。
  - 缩放窗口时使用固定的 256/1024px 解码缓存键，不随每个布局像素重新解码；图片替换期间保留上一帧。同源已解析的封面路径有最多 128 条的内存缓存（不持有图片字节），布局切换重建时可同步复用，后台仍验证磁盘缓存；源版本变化独立加载，避免旧封面串图。
- 手机封面：完整播放页封面在现有尺寸基础上缩小约 6%，保留原有进度、歌词及手势布局。
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
- 每个 PR / 里程碑结束前：`dart format .`、`flutter analyze` 零警告、`flutter test` 全通过；Rust 侧 `cargo fmt`、`cargo clippy -- -D warnings`、`cargo test` 全通过。
- Rust：`unsafe` 只允许出现在 FRB 生成代码中；音频回调路径禁止 `unwrap`/`panic`、内存分配和阻塞；错误用 `anyhow::Result` 返回给 Dart。
- FRB 生成代码（`lib/src/rust/`、`rust/src/frb_generated.rs`）提交进仓库，修改 `rust/src/api/` 后必须重新运行 `flutter_rust_bridge_codegen generate`。

## 12. 测试策略

| 层级 | 对象 | 要求 |
|---|---|---|
| 单元测试（必须） | `LrcParser`、`TextEncodingDetector`、`EqParams`（防削波计算）、`ScanDiff`、`QueueController`（用 fake `PlayerEngine`）、专辑键 `normalize` | 覆盖所有分支和边界情况 |
| Rust 单元测试（必须） | EQ 系数与频响、参数平滑、gapless 裁剪后首尾样本连续、队列预读与下标事件、lofty 歌词/封面提取 | `cargo test`，用生成的短音频或 `test/fixtures` |
| Widget 测试（推荐） | 歌词视图当前行定位、迷你播放条状态、自适应外壳在三种宽度下的布局 | 关键交互 |
| 数据库测试（推荐） | drift 内存数据库测迁移与查询 | 每次改 schema 必测 |
| 真机手测（必须） | 按 `REQUIREMENTS.md` §8 验收清单 | 每个里程碑结束时跑相关条目 |

`test/fixtures/` 中放极小的测试音频（几秒的 FLAC/MP3/M4A/OGG/Opus，带各种标签、内嵌封面和歌词）和各种编码的 `.lrc` 样例；生成方式记录在 `test/fixtures/README.md`。

## 13. 风险清单

| 风险 | 影响 | 应对 |
|---|---|---|
| 无缝播放在 rodio 队列中有缝隙（预读不及时 / 裁剪不准） | `PLAY-07` 不达标 | M0 用连续两轨验证；必要时绕过 rodio 队列，自己维护环形缓冲直接喂 cpal |
| Android 输出设备切换（拔耳机、蓝牙）后流失效 | 无声或崩溃 | 监听 cpal 错误回调重建流；M0 真机验证 |
| Rust 构建链复杂（NDK、多 ABI、通用二进制） | 构建失败、包体增大 | 用 FRB + Cargokit 自动化；crate 只开必要特性；Release 开 LTO 与 `strip` |
| FRB 版本不一致 | 运行时崩溃 | Dart 与 Rust 侧锁定同一版本，升级时同时改两处并重新生成 |
| 192k/24-bit 在低端 Android 上重采样 CPU 占用高 | 发热、耗电 | M0 测 CPU 占用；必要时降低重采样质量档位 |
| Android 分区存储读不到 `.lrc` | 外挂歌词不可用 | 默认方案 A（所有文件访问）；降级提示 |
| `lofty` 对某些文件解析失败 | 标签缺失 | 失败容错 + 记录 `scan_errors`；必要时为个别格式写补充解析 |
| 大曲库扫描慢 | 首次体验差 | isolate 分批 + 进度显示 + 扫描期间可用 |
| Release 下 FFI 相关代码被裁剪或符号丢失导致崩溃 | 发布版不能播放 | 每个里程碑都用 Release 模式在真机跑一遍 |

## 附录 A：依赖变更记录

| 日期 | 变更 | 理由 |
|---|---|---|
| 2026-10-18 | 开发者已授权：将锁文件已有的间接依赖 `crypto` 3.0.7 声明为直接依赖；加入 `image` ^4.12.0、`path_provider` ^2.1.6 | M2-6 按 §7.3 使用 SHA-1 专辑键命名、在 isolate 生成缩略图、存到应用支持目录。`crypto` 复用锁定版本；后两项原已在 §1.3 清单内。 |
| 2026-10-17 | 初始依赖列表 | 见 §1 |
| 2026-10-17 | 主工程已加入：`flutter_riverpod`、`go_router`、`dynamic_color`、`path`、`intl`、`flutter_localizations`、`mocktail`（dev） | 均在 §1.3 表内，M1 骨架使用 |
| 2026-10-17 | 移除计划中的 `media_kit`、`media_kit_libs_audio`、`audio_metadata_reader`；新增 Dart `flutter_rust_bridge` 2.13.0，Rust `symphonia`、`rodio`、`biquad`、`lofty`、`flutter_rust_bridge`、`anyhow`、`log` | 播放内核改为 Rust（附录 B 第 3 条），开发者已同意 |

## 附录 B：已决问题

1. **`dynamic_color` 与 `material_ui`**：Flutter 3.47 将 Material 拆为独立包 `material_ui`，`dynamic_color` 2.1.0 返回该包的 `ColorScheme`，与 `flutter/material.dart` 的不是同一类型。决定（2026-10-17）：使用完整系统色板，由 `adoptSystemScheme` 逐个角色复制，不新增依赖。
2. **双语歌词的排列（§8.2）**：开发者曲库中 4 首双语歌词的原文/翻译顺序是反的。决定（2026-10-17）：按惯例处理（同一时间戳第一行为原文），这些文件视为数据问题，不做特殊处理。
3. **播放内核改用 Rust（2026-10-17，开发者决定）**：原方案 media_kit 的最大风险是打包的 libmpv 是否含 EQ 所需的 libavfilter 滤镜，且其维护放缓。改为 Rust 内核：symphonia 解码（FLAC/MP3 gapless）、rodio/cpal 输出与重采样、biquad 自写 10 段 EQ、lofty 读标签；参考了开源 Flutter + Rust 播放器 Rune（MPL-2.0，只参考思路，不拷贝代码）。好处：EQ 两平台完全一致且可测试，标签读取更快；代价：无缝播放预读、设备切换需要自己实现。media_kit 保留为退路（§1.4）。
