# macOS / Android 桌面卡片方案

## 范围

- 目标是系统原生小组件：macOS 桌面上的 WidgetKit 卡片，以及 Android 启动器主屏幕上的 App Widget。
- 不制作 Windows 版本，也不做应用内悬浮迷你播放器。
- macOS 首版按开发者指定提供三种尺寸：小号显示专辑封面与基本控制，中号增加进度和播放模式，大号增加当前播放队列。
- 使用各平台原生 UI。Flutter 继续负责播放器与业务状态，不尝试将 Flutter 页面嵌进系统 widget。

## 平台实现

### macOS

- 已加入 `NyaPlayerWidget` extension target，并嵌入 Runner 的 `Contents/PlugIns`。组件要求 macOS 14+，主应用的 macOS 12 部署目标保留。
- 小号（`systemSmall`）：左上角圆角方形封面、专辑名、上一首/播放暂停/下一首。
- 中号（`systemMedium`，2×1）：增加歌曲/艺术家、系统计时进度条、随机开关和循环模式按钮（关闭 → 列表循环 → 单曲循环）。进度条用于显示，WidgetKit 不提供应用内 Slider 式拖动。
- 大号（`systemLarge`，2×2）：在中号功能之下增加当前播放队列，每页 5 首；当前曲目高亮，可点击歌曲播放、翻页；切歌后自动定位当前页。
- 主 App 与 extension 通过 App Group 共享 `player.json` 和 256px JPEG；默认标识为 `group.com.kazuma.nyaplayer.widgets`，在 `Runner/Configs/AppInfo.xcconfig` 的 `NYA_WIDGET_APP_GROUP` 中统一配置。extension 不打开 Drift 数据库，也不启动 Rust 音频引擎。
- 共享的 `AudioPlaybackIntent` 同时加入 app 与 extension target，系统把控制动作放在 app 进程执行；`PlayerWidgetBridge` 等待 Flutter 恢复队列并报告 ready 后，经 `nyaplayer/widget` 通道调用 `QueueController`。控制请求串行处理，旧队列按钮用 revision 校验，避免同一位置已变成另一首歌时误播。
- 位置用快照时间 + 最近位置表示，播放中的进度由系统 `ProgressView(timerInterval:)` 更新。切歌、播放/暂停、明确 seek 和播放模式变化请求 timeline reload；普通位置更新最多每 30 秒补写磁盘，不高频刷新 widget。
- 点击卡片空白/封面，通过 `nyaplayer://player` 恢复主窗口。正常退出时写入暂停快照，保留队列以便下次启动恢复。

#### 在桌面添加

1. 构建并重新启动带扩展的应用：`LANG=en_US.UTF-8 flutter build macos --debug`。Runner scheme 会自动构建并嵌入 extension。
2. macOS 桌面右键选择“编辑小组件”，搜索 NyaPlayer，选择小/中/大尺寸。应用需至少启动一次，以发布当前队列和封面。
3. 如果重新打包时更改签名团队或 App Group，同时修改 Runner 与 NyaPlayerWidget，确保两者拥有相同的组权限。

#### 当前验证

- macOS Debug 应用与 extension 构建通过，签名完整性检查通过；PlugInKit 已识别 extension。
- 以相同 App Group 权限运行的沙盒应用完成共享目录 JSON 写入/读取检查。本机可用 ad-hoc 签名进行这一步检查，不要求预先配置开发者证书。
- Flutter 339 项测试通过（包含 7 项 widget 桥接测试：控制、队列版本、播放位置、封面竞态、退出、快速连续操作和旧系统降级）。
- 已离屏渲染检查浅色/深色三种尺寸、空状态；`tool/render_macos_widgets.swift` 可重复生成 `build/widget_previews/`。
- 尚未在系统桌面宿主中实点卡片：需要重新启动新版应用后添加卡片，核对实际点击、冷启动和多组件实例。

### Android

- 首选 Jetpack Glance + `GlanceAppWidgetReceiver`；Glance 最终仍受 Android `RemoteViews` 的系统限制。
- Receiver/ActionCallback 保持轻量。卡片动作经 Android MediaSession / `LyraAudioHandler` 控制播放，不另起 Flutter UI，也不新建音频引擎。
- 复用 app 私有目录中的 256px 封面，并写入小型快照（曲目元数据、播放状态、更新时间）；widget 在独立生命周期中读取快照，不能依赖 Dart/Riverpod 内存状态。
- 按平台刷新策略更新：曲目变化、播放/暂停、用户 seek 时主动更新；播放过程中的进度用快照时间推算，不定时高频重绘。
- 先支持当前已配置的 Android 基线（minSdk 31、arm64-v8a），不扩展 ABI。

## 跨端状态约定

macOS 已用字段：`schemaVersion`、`title`、`artist`、`album`、`artworkName`、`currentIndex`、`isPlaying`、`appRunning`、`positionMs`、`durationMs`、`updatedAtMs`、`shuffle`、`repeatMode`、`queueRevision`、`queue` 和 `labels`。原始缓存路径只交给主应用的原生桥复制，不直接暴露给沙盒 extension。每个平台独立实现存储和 UI，业务字段尽量一致。

初次实现顺序：

1. 核对 macOS 桌面实际操作和冷启动行为。
2. 开始 Android Glance 卡片与 MediaSession 命令链路。
3. 检查应用被系统回收、无封面、长曲名、多 widget 实例及用户移除/重加卡片时的表现。

## 官方平台参考

- Apple： [WidgetKit widgets](https://developer.apple.com/documentation/widgetkit/widgets-and-complications-collection)、[交互式 widgets 与 App Intents](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities)、[timeline 更新](https://developer.apple.com/documentation/widgetkit/timeline)。
- Android： [App Widgets 概览](https://developer.android.com/develop/ui/views/appwidgets/overview)、[Jetpack Glance](https://developer.android.com/develop/ui/compose/glance)、[Glance 交互](https://developer.android.com/develop/ui/compose/glance/user-interaction)。

## 待决定

- macOS 应用退出后，系统通过 `AudioPlaybackIntent` 启动 app 并等待播放器 ready 的完整链路仍需在桌面宿主实测。
- Android 首版应验证 MediaSession action 在服务存活和被系统回收两种情况下的行为，再决定 widget 是否仅控制已启动的播放会话。
