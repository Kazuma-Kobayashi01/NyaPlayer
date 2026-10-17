# NyaPlayer

一个**纯本地、无广告、无联网、完全遵循 Material Design 3** 的音乐播放器。使用 Flutter 开发，主平台 Android，次平台 macOS。

> 📌 **当前状态：规划阶段**，尚未开始写代码，下一步是 M0 技术验证。
> 文档中的项目代号为 **Lyra**（暂定），与 NyaPlayer 指同一个项目；正式定名后会统一替换。

## 特性（目标）

- 🎵 **常见格式稳定播放**：FLAC（含 24bit / 高采样率）、MP3、AAC/M4A、OGG、Opus、WAV；P1 支持 ALAC、AIFF、APE、WavPack
- 🖼️ **封面与歌词**：读取内嵌封面；内嵌歌词与同名外挂 `.lrc` 均可显示，支持滚动高亮、点击跳转、双语、GBK/Shift-JIS 自动识别
- 🎨 **Material 3 界面**：浅色/深色、壁纸动态取色、跟随封面配色；窄屏底部导航栏、中屏 Rail、宽屏 Rail + 右侧正在播放面板
- 📱 **后台与系统集成**：Android 前台服务、媒体通知、蓝牙/耳机按键、音频焦点；macOS 媒体键、控制中心、关窗继续播放
- 🎚️ **10 段均衡器**：31 Hz – 16 kHz，±12 dB，内置预设与自定义预设，两个平台效果一致
- 🔒 **隐私优先**：不发起任何网络请求，不收集任何数据

**非目标**：在线音乐/流媒体、在线刮削、标签编辑、视频、发烧级输出、账号与云同步。

## 平台

| 平台 | 状态 |
|---|---|
| Android（minSdk 24） | 主平台 |
| macOS（≥ 10.15） | 次平台 |
| iOS / Windows / Linux / Web | 不做 |

## 技术栈

| 用途 | 方案 |
|---|---|
| 框架 | Flutter（stable）/ Dart 3 |
| 播放内核 | `media_kit` + `media_kit_libs_audio`（libmpv + FFmpeg） |
| 后台/系统控制 | `audio_service`、`audio_session` |
| 标签读取 | `audio_metadata_reader` |
| 均衡器 | mpv `af` 属性 → FFmpeg `equalizer` 滤镜（双平台同一实现） |
| 状态管理 / 路由 | `flutter_riverpod` / `go_router` |
| 数据库 | `drift`（SQLite，FTS5 trigram 搜索） |
| 主题 | `dynamic_color` + `ColorScheme.fromImageProvider` |

架构分三层：UI（`features/*`）→ 应用服务（`services/*`）→ 数据（`data/*`）。UI 只通过 `AudioHandler` 控制播放，全应用仅一个 `media_kit` `Player` 实例，由 `PlayerEngine` 接口隔离。详见 [TECH_SPEC](docs/TECH_SPEC.md)。

## 文档

| 文档 | 内容 |
|---|---|
| [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) | 需求声明：功能需求（带编号与优先级）、非功能需求、MVP 与验收标准 |
| [docs/TECH_SPEC.md](docs/TECH_SPEC.md) | 技术要求：依赖、架构、播放引擎、EQ、平台配置、曲库/封面/歌词/数据库设计 |
| [docs/PLAN.md](docs/PLAN.md) | 施工方案：M0–M8 里程碑任务清单、`CLAUDE.md` 模板、测试素材清单 |

三份文档互相引用，需求编号（如 `EQ-06`）贯穿其中。**实现与 TECH_SPEC 冲突时，先改文档再改代码。**

## 路线图

| 里程碑 | 内容 | 状态 |
|---|---|---|
| M0 | 技术验证（格式、EQ 滤镜、后台、Android 文件访问、FTS5 等） | ⬜ 未开始 |
| M1 | 工程骨架（主题、路由、自适应布局、数据库） | ⬜ |
| M2 | 曲库（授权、扫描、封面缓存、浏览与搜索） | ⬜ |
| M3 | 播放核心（引擎、队列、播放页、状态恢复） | ⬜ |
| M4 | 后台与系统集成 | ⬜ |
| M5 | 歌词 | ⬜ |
| M6 | 均衡器 | ⬜ |
| **MVP** | 全部 P0 需求，按验收标准通过 | |
| M7 / M8 | P1 功能 / 打磨与 P2（Material 3 Expressive 等） | ⬜ |

详细任务与复选框见 [PLAN.md](docs/PLAN.md)。

## 开发

> 工程尚未创建，以下为 M1 完成后的常用命令。

```bash
# 创建工程（M1-1，仅 android 与 macos）
flutter create --platforms=android,macos --org <your.org> nyaplayer

# 运行
flutter run -d macos
flutter run --release -d <android-device-id>

# drift 代码生成
dart run build_runner build --delete-conflicting-outputs

# 提交前检查
dart format . && flutter analyze && flutter test

# 发布构建
flutter build apk --release --split-per-abi
flutter build macos --release
```

## 与 Claude Code 协作

开工时把 [PLAN.md 附录 A](docs/PLAN.md) 的模板放到项目根目录作为 `CLAUDE.md`，Claude Code 每次启动会自动读取三份文档并遵守其中的工作规则。

## License

待定。
