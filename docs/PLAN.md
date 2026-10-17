# 施工方案（Implementation Plan）

> 项目代号：**Lyra** · 文档版本：v0.1 · 2026-10-17
> 配套文档：[`REQUIREMENTS.md`](./REQUIREMENTS.md)、[`TECH_SPEC.md`](./TECH_SPEC.md)
> 本文档写给"在 Claude Code 中逐步施工的人和 Claude"看。

---

## 0. 施工总原则

1. **按里程碑顺序推进**，一个里程碑完成并通过验收后再开始下一个。每个里程碑一个 git 分支，完成后合并到 `main`。
2. **先验证、后建造**：M0 技术验证没通过的假设（`TECH_SPEC.md` 中的 🔍），不得在后续里程碑中当作事实使用。
3. **文档是契约**：实现与 `TECH_SPEC.md` 冲突时，先停下来说明原因、提出修改，经开发者同意后**先改文档再改代码**。
4. **每个任务完成的定义**：代码写完 + `dart format .` + `flutter analyze` 零警告 + 相关单元测试通过 + 勾掉本文档中对应的复选框。
5. **真机优先**：播放、后台、权限相关的功能，以 Android 真机和 macOS 实际运行结果为准，模拟器只作参考；每个里程碑结束时至少用 Release 模式跑一次。
6. **小步提交**：每完成一个可独立验证的小功能就 commit，提交信息用中文或英文均可，格式 `type(scope): 描述`，如 `feat(lyrics): 解析多时间戳`。

## 1. 里程碑总览

| 里程碑 | 内容 | 规模 | 产出 |
|---|---|---|---|
| **M0** | 技术验证（Spike） | S | `SPIKE_REPORT.md`，回填 TECH_SPEC |
| **M1** | 工程骨架 | S | 可运行的空壳应用：主题、路由、自适应布局、数据库 |
| **M2** | 曲库 | M | 授权、扫描、标签、封面缓存、浏览与搜索 |
| **M3** | 播放核心 | M | 引擎、队列、迷你播放条、播放页、状态恢复 |
| **M4** | 后台与系统集成 | M | Android 通知/焦点/耳机；macOS 媒体键/关窗继续播 |
| **M5** | 歌词 | M | 解析、编码识别、歌词视图 |
| **M6** | 调音 | S | EQ 页面、预设、持久化 |
| **— MVP 完成 —** | 全部 P0 | | 按 `REQUIREMENTS.md` §8 验收 |
| **M7** | P1 功能 | M | 播放列表、双语歌词、多艺术家、日文界面、快捷键等 |
| **M8** | 打磨与 P2 | L | Expressive 动效、ReplayGain、睡眠定时等 |

规模：S ≈ 1–3 个晚上，M ≈ 1–2 周的业余时间，L ≈ 不设上限、按兴趣挑着做。

---

## M0 技术验证

**目标**：用最少的代码确认所有 🔍 假设，避免在错误的地基上盖楼。在独立目录 `spike/` 中进行，代码可以写得很粗糙，验证完不并入主工程。

**准备**：开发者提供测试素材（见附录 B）。

**任务清单**

- [x] M0-1 新建 `spike/` Flutter 工程验证 media_kit 方案。（2026-10-17：`spike/` 已删除；同日决定改用 Rust 内核，M0 改在主工程 `1.0.0.universal` 分支上验证 Rust 方案，见 TECH_SPEC 附录 B 第 3 条。）
- [x] M0-R1 安装 Rust 工具链（rustup stable 1.99.1，clippy、rustfmt；macOS 双架构与 Android 三个 ABI 的 target）。
- [ ] M0-R2 **桥接**：在主工程集成 `flutter_rust_bridge` 2.13.0（`rust/` crate `nya_core` + `rust_builder/` Cargokit 插件），Dart 调用一个 Rust 函数成功；macOS debug 与 Android `flutter build apk` 都能编过。
- [ ] M0-2 **格式**：Rust 引擎在 macOS 和 Android 真机上播放 FLAC（16/24bit，44.1k～192k）、MP3（CBR/VBR），记录结果；确认 192k 被正确重采样到设备采样率。
- [ ] M0-3 **EQ**：Rust 10 段 biquad EQ（TECH_SPEC §5.1）。`cargo test` 验证频响；实听确认各预设生效、拖动滑块时无爆音/静音。
- [ ] M0-4 **无缝播放**：连续两轨（现场专辑或自制的切开的正弦波）首尾无缝；`cargo test` 用自制音频验证裁剪后样本连续。
- [ ] M0-5 **后台**：最小 `AudioHandler` 包住 `RustPlayerEngine`，验证 Android 通知栏控制、锁屏后持续播放 10 分钟、蓝牙耳机按键；macOS 媒体键和控制中心显示（检查是否出现重复条目）。
- [ ] M0-6 **音频焦点**：Android 上播放时打一个电话 / 打开另一个音乐 App，确认 cpal/Oboe 不自行处理焦点，`audio_session` 处理生效。
- [ ] M0-7 **输出设备切换**：播放中拔插有线耳机、连接/断开蓝牙耳机，Android 与 macOS 上输出流能重建且不崩溃。
- [ ] M0-8 **Android 文件访问**：Android 13+ 真机上**只授予 `READ_MEDIA_AUDIO`**（方案 C），确认 `dart:io` 能递归列出音乐目录，Rust 能按路径打开播放；失败再测方案 A（"所有文件访问权限"）。
- [ ] M0-9 **标签**（歌词是唯一来源，最关键）：用**开发者真实曲库中的样本**检查 Rust `lofty` 能否读出：中日英标签、内嵌封面、FLAC `LYRICS`/`UNSYNCEDLYRICS`、MP3 `USLT`（并确认有无 `SYLT` 同步歌词）、采样率/位深/码率；归纳出开发者歌词的实际形态；粗测 1000 个文件的读取耗时。
- [ ] M0-10 **编码**（降为 P2，仅在 M0-9 发现内嵌歌词/标签有乱码时才做）：选定 GBK / Shift-JIS 解码方案（Rust `encoding_rs`）。
- [ ] M0-11 **FTS5**：在 `sqlite3_flutter_libs` 上创建 `trigram` 分词的 FTS5 表并查询中日文子串。
- [ ] M0-12 **M3 Expressive 现状**：查 Flutter 当前 stable 对 M3 Expressive 的支持情况，写一段结论。
- [ ] M0-14 **Release 与性能**：Release 包体（各 ABI）、192k/24-bit 播放时的 CPU 占用（Android 中低端机）。
- [ ] M0-13 写 `docs/SPIKE_REPORT.md`：每项的结论、遇到的坑、需要修改的 TECH_SPEC 条目；更新 `TECH_SPEC.md`，把已验证的 🔍 去掉或改写。

**验收**：开发者阅读 SPIKE_REPORT，确认没有阻断性问题（尤其 M0-3、M0-4、M0-5、M0-7、M0-8），或对阻断问题选定了替代方案（退路：media_kit）。

---

## M1 工程骨架

> **2026-10-17 前端先行**：开发者决定在 M0 完成前先做界面。已用假数据（`data/sample_library.dart`）和假引擎（`FakePlayerEngine`）把 M1 骨架与 M2/M3/M5/M6 的界面部分跑通；播放、扫描、数据库、EQ 滤镜仍待各自里程碑。M0 中未验证的假设仍不得当作事实使用。

- [x] M1-1 `flutter create --platforms=android,macos --org <org> lyra`，删除示例代码，按 `TECH_SPEC.md` §3 建目录。
- [ ] M1-2 加入 §1.2、§1.3 全部依赖；配置 `analysis_options.yaml`（§11）。（部分完成：已加 riverpod / go_router / dynamic_color / path / intl / mocktail 与额外 lint；drift、permission_handler、file_picker、window_manager、image 等待用到时再加）
- [ ] M1-3 Android：Manifest 权限与 audio_service 组件（§6.1）、`minSdk 24`、边到边显示。
- [ ] M1-4 macOS：关闭 sandbox、`window_manager` 初始化、最小窗口尺寸（§6.2）。（部分完成：最小窗口 400×700 已用原生 `contentMinSize` 实现，无最大限制可全屏；已去掉系统标题栏、红绿灯融入界面；sandbox 与 window_manager 未做）
- [ ] M1-5 drift 数据库：建好 §9 全部表（先不实现 FTS），生成代码，写一个迁移测试。
- [ ] M1-6 主题系统：`LyraTheme`，支持明/暗/跟随系统、壁纸动态取色、固定种子色；设置项存 `settings` 表。（封面取色在 M3 接入）（部分完成：明/暗/系统、固定种子色、封面取色已做，设置暂存内存未入 `settings` 表；壁纸取色因 dynamic_color 2.1.0 使用 `material_ui` 的 `ColorScheme`，暂以壁纸主色作种子，见 TECH_SPEC 附录 A）
- [x] M1-7 自适应外壳 `AdaptiveScaffold`：三种宽度下切换 NavigationBar / Rail / Rail + 侧边面板占位（§10.2）；五个一级页面为空白占位。
- [x] M1-8 `go_router` 路由表：一级页面、专辑详情、艺术家详情、文件夹、搜索、播放页、均衡器、设置。
- [ ] M1-9 i18n 骨架：`app_zh.arb`、`app_en.arb`、`app_ja.arb`（ja 可先空）。（部分完成：zh / en 已有，ja 待 M7）
- [x] M1-10 日志工具 `core/log.dart`。

**验收**：Android 和 macOS 都能启动；拖动 macOS 窗口宽度时导航形态正确切换；明暗主题、动态取色切换正常；`flutter analyze` 零警告。

---

## M2 曲库

- [ ] M2-1 首次启动引导页（`onboarding`）：说明用途 → 申请权限（Android 按 §6.1 方案 A，含拒绝后的降级）→ 选择音乐文件夹。
- [ ] M2-2 `library_roots` 管理：设置页可添加/移除/排除文件夹（`SET-01`）。
- [ ] M2-3 `ScanDiff`（纯函数）+ 单元测试。
- [ ] M2-4 `LibraryScanner`：遍历 → diff → isolate 分批读标签 → 事务写库 → 进度流（§7.1）。
- [ ] M2-5 专辑键 `normalize` 与归类（§7.2）+ 单元测试；孤立记录清理。
- [ ] M2-6 `CoverCache`：按需提取、两种尺寸、`cover_state` 状态（§7.3）；占位封面生成。
- [ ] M2-7 `LibraryRepository`：歌曲/专辑/艺术家/文件夹查询与排序（`LIB-06`、`LIB-08`），全部返回 `Stream`，数据库变化自动刷新 UI。
- [ ] M2-8 页面：歌曲列表、专辑网格、专辑详情、艺术家列表与详情、文件夹浏览。
- [ ] M2-9 FTS5 搜索表 + 搜索页（`LIB-09`）。
- [ ] M2-10 扫描进度显示（顶部 `LinearProgressIndicator` 或 SnackBar），设置页"重新扫描"（`LIB-12`）。
- [ ] M2-11 "歌曲信息"底部弹窗：显示路径、标签、技术参数（`META-07`，可在本阶段一并做）。

**验收**：用附录 B 素材和一个真实曲库扫描；标签、封面显示正确；新增/删除/修改文件后增量扫描结果正确；滚动大列表流畅；扫描中可以正常浏览。

---

## M3 播放核心

- [ ] M3-1 `PlayerEngine` 接口与 `RustPlayerEngine` 实现（§4.2、§4.3），含解码失败自动跳过。
- [ ] M3-2 `QueueController`（§4.4）+ 用 fake engine 的单元测试：随机开关、增删移动、上一首 3 秒规则、循环模式。
- [ ] M3-3 `LyraAudioHandler` 基础版：把队列和状态桥接给 audio_service（通知栏细节在 M4 完善）。
- [ ] M3-4 从任意列表"播放全部 / 点击某首播放 / 下一首播放 / 加入队列"。
- [ ] M3-5 迷你播放条：封面、标题、艺术家、播放/暂停、细进度条；点击或上滑展开。
- [ ] M3-6 完整播放页：大封面、标题、艺术家、`Slider` 进度、控制按钮、循环/随机、队列入口；宽屏时右侧面板版。
- [ ] M3-7 队列页：当前高亮、点击跳转、滑动移除、拖拽排序（`PLAY-02`）。
- [ ] M3-8 播放页**封面取色**与切歌颜色过渡（§10.1，`UI-04`）。
- [ ] M3-9 播放状态持久化与启动恢复（`PLAY-05`）。
- [ ] M3-10 列表封面 → 播放页的 `Hero` 过渡（可选，时间不够留到 M7）。

**验收**：所有 P0 格式能播放；队列操作与随机/循环行为符合预期；切歌颜色平滑变化；杀进程重启后队列和位置恢复。

---

## M4 后台与系统集成

- [ ] M4-1 Android 媒体通知完善：封面（`artUri` 用 1024px 缓存文件）、三个按钮、可拖动进度（`SYS-02`）。
- [ ] M4-2 `AudioFocusCoordinator`：中断暂停/恢复、ducking、拔耳机暂停（§4.6，`SYS-04`、`SYS-05`）。
- [ ] M4-3 Android 通知权限（Android 13+ `POST_NOTIFICATIONS`）请求流程。
- [ ] M4-4 实测 `androidStopForegroundOnPause` 两种取值，确定最终配置并记录到 TECH_SPEC。
- [ ] M4-5 macOS：关闭窗口隐藏、Dock 点击恢复、⌘Q 退出前保存状态（§6.2，`SYS-08`）。
- [ ] M4-6 macOS：媒体键与控制中心显示核对（`SYS-06`、`SYS-07`）。

**验收**：`REQUIREMENTS.md` §8 第 4、5 条全部通过（Android 锁屏 30 分钟、来电、拔耳机、蓝牙按键；macOS 关窗继续播、媒体键、控制中心）。

---

## M5 歌词

- [ ] M5-1 `LrcParser`（§8.2）+ 完整单元测试（各种时间格式、多时间戳、offset、空行、增强型标签剥离、双语同时间戳）。
- [ ] M5-2 `TextEncodingDetector`（§7.4）+ 单元测试（BOM、UTF-8、GBK、Shift-JIS 样例）。
- [ ] M5-3 `LyricsLoader`：来源优先级、LRU 缓存、isolate 读取（§8.1）。
- [ ] M5-4a 双语歌词（`LRC-08`，P0）：同时间戳两行显示为原文 + 翻译；仅含空白的行视为间奏。
- [ ] M5-4 歌词视图：居中高亮、平滑滚动、点击跳转、手动滚动暂停跟随、纯文本歌词静态显示（§8.3）。
- [ ] M5-5 播放页"封面 ↔ 歌词"切换；宽屏并排（`UI-08`）。
- [ ] M5-6 把 M0 验证中 GBK/Shift-JIS 的结论应用到 ID3 标签文本兜底（`META-06`，P1，可顺手做）。

**验收**：附录 B 中所有歌词样例显示正确；同步误差肉眼无感；点击跳转准确；后台时没有歌词相关的计时器在跑。

---

## M6 调音

- [ ] M6-1 `EqFilterBuilder`（§5.1）+ 单元测试（全零直通、防削波、负增益、字符串格式）。
- [ ] M6-2 `EqController`：开关、10 段增益、预设、preamp、防削波，防抖应用（§5.2），持久化。
- [ ] M6-3 内置预设（§5.3）写入 `eq_presets`（`builtin = true`）。
- [ ] M6-4 均衡器页面：10 个竖向 `Slider` + 频点标签 + dB 数值、预设选择（`DropdownMenu` 或 `ChoiceChip` 横向列表）、开关、preamp。
- [ ] M6-5 自定义预设保存/重命名/删除（`EQ-04`，P1，可顺手做）。

**验收**：两个平台调节效果一致且实时；无明显爆音；重启后设置保持。

---

## ✅ MVP 验收

按 `REQUIREMENTS.md` §8 完整跑一遍，问题记入 GitHub Issues 或 `docs/ISSUES.md`，修完再进 M7。打 tag `v0.1.0`，构建：

```bash
flutter build apk --release --split-per-abi
flutter build macos --release
```

---

## M7 P1 功能

按开发者兴趣排序，每项独立完成：

- [ ] 播放列表（`LIB-13`）
- [ ] 文件夹封面回退（`META-03`）、专辑艺术家归类（`LIB-10`）、多艺术家拆分
- [ ] 排除文件夹 / 最短时长过滤（`LIB-11`）
- [ ] 歌词来源优先级设置（`LRC-03`，P2）、手动滚动恢复（`LRC-07`）
- [ ] 无缝播放开关（`PLAY-07`）、上一首行为设置
- [ ] 共享元素过渡（`UI-11`）
- [ ] 日文界面（`UI-13`）、无障碍检查（`UI-14`）
- [ ] macOS 键盘快捷键（`SYS-10`）
- [ ] 关于页与开源许可（`SET-05`，`showLicensePage` 即可）
- [ ] APE / WavPack / ALAC / AIFF 回归测试（`FMT-05`）

## M8 打磨与 P2

- [ ] Material 3 Expressive：波浪进度条、形状变形播放按钮、弹簧动效（先完成 M0-12 的调研结论）
- [ ] ReplayGain（`EQ-09`）、变调（`EQ-10`）、倍速（`PLAY-10`）
- [ ] 睡眠定时器（`PLAY-09`）
- [ ] 逐字歌词（`LRC-11`）、歌词偏移微调（`LRC-12`）
- [ ] 自动列表：最近播放 / 最常播放 / 最近添加（`LIB-14`）
- [ ] M3U 导入导出（`LIB-15`）
- [ ] macOS 菜单栏迷你控制（`SYS-09`）
- [ ] 流派/年份浏览（`LIB-07`）、DSD（`FMT-06`）

---

## 附录 A：`CLAUDE.md` 模板

在项目根目录创建 `CLAUDE.md`，Claude Code 每次启动会自动读取：

```markdown
# Lyra — 本地音乐播放器（Flutter，Android + macOS）

## 必读文档
- docs/REQUIREMENTS.md — 需求与编号（FMT/LIB/META/LRC/PLAY/SYS/EQ/UI/SET）
- docs/TECH_SPEC.md — 技术决定与约束（以此为准）
- docs/PLAN.md — 里程碑与任务清单（当前进度看这里的复选框）
- docs/SPIKE_REPORT.md — M0 实测结论（存在时优先于 TECH_SPEC 中的 🔍 假设）

## 工作规则
- 一次只做一个里程碑里的任务；开始前先说明要做哪几个任务编号。
- 实现与 TECH_SPEC 冲突时先停下来说明，不要自行改方案。
- 不要新增 TECH_SPEC §1 之外的依赖，除非先在附录 A 记录理由并征得同意。
- UI 不得直接调用 Rust 内核 API，必须经过 AudioHandler / QueueController。
- 耗时操作放 isolate；不要硬编码颜色，全部从 ColorScheme 取。
- 完成任务后：dart format . && flutter analyze && flutter test，然后勾选 PLAN.md 中的复选框。

## 常用命令
- flutter run -d macos
- flutter run --release -d <android-device-id>
- dart run build_runner build --delete-conflicting-outputs   # drift 代码生成
- flutter test

## 开发者偏好
- 回复用中文；代码注释中英文均可，标识符用英文。
```

## 附录 B：测试素材清单（开发者准备）

在电脑上建一个 `lyra-test-music/` 目录，手机上放一份同样的：

| 类别 | 内容 |
|---|---|
| 格式 | FLAC 16bit/44.1k、FLAC 24bit/96k、MP3 CBR 320、MP3 VBR、M4A(AAC)、M4A(ALAC)、OGG、Opus、WAV、APE、WV 各 1–2 首 |
| 标签语言 | 中文、日文、英文标签各若干；至少 1 个日文假名 + 汉字混合的专辑 |
| 封面 | 有内嵌封面、无内嵌但目录有 `cover.jpg`、两者都没有 |
| 内嵌歌词 | FLAC 带 `LYRICS`（带时间戳）、FLAC 带 `UNSYNCEDLYRICS`（纯文本）、MP3 带 `USLT`、M4A 带歌词 |
| 外挂歌词 | 同名 `.lrc`：UTF-8、UTF-8 BOM、GBK、Shift-JIS 各一个；含双语（同时间戳两行）的一个；含 `[offset:]` 的一个；含一行多个时间戳的一个 |
| 异常文件 | 一个改了扩展名的文本文件（假 .mp3）、一个截断的 FLAC、一个没有任何标签的 MP3 |
| 专辑结构 | 一张多碟专辑（碟号 1/2）、一张合辑（各曲 artist 不同、album artist 相同）、一张现场专辑（测无缝） |

另准备一个"大曲库"：把真实音乐目录复制到手机，或用脚本复制若干次凑到 5,000 首，用于性能验收。
