# 施工记录（PROGRESS）

> 最后更新：2026-10-18 · 写给接手开发的人（或 AI）。先读本文，再读 `.claude/CLAUDE.md`、`docs/TECH_SPEC.md`、`docs/PLAN.md`、`docs/REQUIREMENTS.md`。
> 本文只记录**当前状态、决定、坑和下一步**；需求和技术规范以另外三份文档为准，冲突时以 TECH_SPEC 为准。

## 0. 一眼看完

- **项目**：NyaPlayer（文档代号 Lyra）——本地离线、无广告的 Material 3 音乐播放器，Flutter，Android + macOS。曲库只有 **FLAC + MP3**，歌词和封面**全部内嵌**，双语歌词是 P0。
- **当前分支**：`1.0.0.universal`（通用功能开发）；`main` 停在"前端 UI 完成"的提交 `11125fa`。以后各平台特化从 `1.0.0.universal` 再拉分支。
- **阶段**：前端 UI 基本完成（假数据 + 假引擎）；**播放内核已决定改用 Rust**，Rust 内核代码已写好并通过单元测试，**但还没在真机上放出过声音**。
- **紧急事项（接手后第一件事）**：
  1. **工作区有大量未提交改动**（见 §2），先 `git status` 确认，再提交。
  2. `.claude/worktrees/` 下有两个已合并完的子代理临时工作区和两个同名分支 `worktree-agent-*`，确认无用后删除（`git worktree remove` + `git branch -D`），不要提交 `.claude/worktrees/`。
  3. **macOS 沙盒仍是开启的**，调试版读不了任意目录（`Operation not permitted`）。TECH_SPEC §6.2 本来就规定要关；**开发者尚未授权本次关闭**（见 §6）。
- **用户**：回复一律用**中文**；代码注释中英文均可，标识符用英文。喜欢用截图迭代界面。

## 1. 必须遵守的工作规则（摘自 CLAUDE.md，再强调）

- 一次只做一个里程碑里的任务；开始前先说明做哪几个任务编号。
- **实现与 TECH_SPEC 冲突时先停下来说明**，不要自行改方案；不要新增 TECH_SPEC §1 之外的依赖，除非先在附录 A 记录理由并征得同意。
- UI 不得直接调用 Rust 内核 API（`lib/src/rust/`），必须经过 AudioHandler / QueueController。
- 颜色一律从 `ColorScheme` 取，不得硬编码。耗时操作不阻塞 UI 线程。
- 完成任务后：`dart format . && flutter analyze && flutter test`；改了 `rust/` 再加 `cargo fmt && cargo clippy --all-targets -- -D warnings && cargo test`；然后勾选 `PLAN.md`。
- **改系统权限类设置（如 macOS 沙盒）必须先征得开发者明确同意**；只有开发者说"提交"才 `git commit`。

## 2. 仓库与提交状态

分支 `1.0.0.universal` 上的提交（新→旧）：

| 提交 | 内容 |
|---|---|
| `88d6724` | 集成 flutter_rust_bridge 2.13.0，Rust crate `nya_core`（M0-R2 的骨架） |
| `6dfb09c` | 文档：播放内核改 Rust（TECH_SPEC v0.2、PLAN M0、CLAUDE.md） |
| `11125fa` | 桌面侧栏 244dp、"Playing" 文案（前端最后一个提交，`main` 同此） |
| 更早 | 横屏桌面布局、macOS 融合标题栏、悬浮播放条、专辑网格溢出、歌词渐隐、窗口最小尺寸、初始提交 |

**未提交的改动（截至本文写作时）**，都在工作区，需要整理后提交：

- `rust/`：`src/player/{engine,queue,tracked,mod}.rs`、`src/dsp/{eq,mod}.rs`、`src/meta/{mod,tests}.rs`、`src/api/{player,meta,mod}.rs`、`src/lib.rs`、`examples/{engine_smoke,devices}.rs`、`tests/fixtures/`、`Cargo.toml`（`crate-type` 加了 `rlib`）、`Cargo.lock`。
- `lib/`：`services/player/rust_player_engine.dart`、`services/player/player_engine.dart`（接口新增 `setEqualizer`、`setVolume`）、`services/player/fake_player_engine.dart`、`services/eq/eq_state.dart`（新增 `EqParams`）、`dev/folder_library.dart`、`dev/preview_hook.dart`、`main.dart`、`src/rust/**`（FRB 生成代码）。
- `rust_builder/macos/nya_core.podspec`（链接 CoreAudio 等系统框架）、`macos/Podfile.lock`、`android/app/build.gradle.kts`（`minSdk = 31`）。
- `docs/`：`TECH_SPEC.md`、`PLAN.md`（Android 12 基线），以及本文件。
- 不要提交：`.claude/worktrees/`、`rust/target/`、`build/`、`test_music/`（`.gitignore` 已处理前三者之外的音乐文件）。

## 3. 已完成

### 3.1 前端（UI-first 阶段，全部用 `FakePlayerEngine` + `data/sample_library.dart` 假数据）

- 响应式外壳（`lib/app/layout/adaptive_shell.dart`）：
  - 竖屏且 < 840dp：左滑抽屉（`PhoneDrawer`）+ 悬浮播放条；
  - 横屏（宽 > 高）或 ≥ 840dp：244dp 常驻侧栏（与抽屉共用 `NavigationPanel`）+ 悬浮播放条；
  - 横屏且宽 ≥ 1100dp、高 ≥ 480dp：再加右侧"正在播放"面板。
- 播放页：手机左右滑切封面/歌词、上滑拉出队列（`QueueSheet`）；桌面沉浸式（放大）布局；歌词显示设置（字号 22pt 默认、居中、翻译）；Hi-Res 金标（≥24bit 且 ≥96kHz 的无损）；歌词/队列边缘渐隐（`FadedEdges`，固定 32px）。
- 主题：系统调色板逐角色复制（`adoptSystemScheme`，因 `dynamic_color` 返回 `material_ui` 的 `ColorScheme`，见 TECH_SPEC 附录 B-1）、跟随封面/固定色、衬线/非衬线字体。
- 曲库页：歌曲/收藏/专辑/艺术家/文件夹/播放列表/设置；**按名称排序：中文按拼音、英文按字母**（无第三方依赖，拼音表由 `tool/gen_pinyin.swift` + `tool/build_pinyin_table.py` 生成到 `lib/core/pinyin_table.dart`）。
- macOS：去掉系统标题栏，红绿灯向内偏移（`macos/Runner/MainFlutterWindow.swift`），`TitlebarInset`（`lib/app/window_chrome.dart`）留 34dp 顶部安全区，全屏时取消；最小窗口 400×700，无最大限制。
- 设置：默认启动页、字体、封面形状（方/圆唱片）、语言等——**全部只在内存里，重启丢失**（等 drift，见 M1-5/6）。
- 测试：Flutter 75 个（`test/`）。

### 3.2 Rust 内核（`rust/`，crate `nya_core`）

- **架构**（TECH_SPEC §2、§4.3、§5）：Dart → flutter_rust_bridge（FRB）同步命令（只往通道发消息，立即返回）→ 引擎线程（`rust/src/player/engine.rs`）独占输出设备和 rodio `Player`；状态通过 FRB `StreamSink` 回 Dart；**位置不推流**，Dart 每 200ms 拉 `playerPositionMs()`。
- **队列模型**（`player/queue.rs`，纯逻辑，7 个测试）：与 `FakePlayerEngine` 语义一致；每个条目有稳定 id，用来判断预读的"下一首"是否被编辑作废。
- **无缝播放**：当前曲 + 预读的下一首都追加进 rodio 的顺序队列，同一输出流首尾相接；解码器 `with_gapless(true)`。`Tracked` 包装器（`player/tracked.rs`）在下一首的第一个样本被取用时通过原子量报告"换曲"，并支持取消尚未开始的预读。
- **EQ**（`dsp/eq.rs`，7 个测试）：10 段 RBJ 峰值滤波（biquad，Q≈1.414，f32）、前级增益、无锁更新、20ms 增益平滑、旁路时逐位相同、输出硬限幅。
- **元数据**（`meta/`，lofty 0.25，11 个测试 + 2 个 `#[ignore]` 真实文件测试）：标签、FLAC `LYRICS`/`UNSYNCEDLYRICS`、MP3 `USLT`（优先含时间戳的）、`SYLT` 转 LRC、封面（Front Cover 优先）、批量并行读取（保序）。**已用 `test_music/` 里两首真实文件验证**：十年 FLAC = 192kHz/24bit，带 LRC 歌词和 181KB PNG 封面；缭花绚烂 MP3 = 320kbps，USLT 为 LRC，有封面。
- **Dart 侧**：`RustPlayerEngine`（`lib/services/player/rust_player_engine.dart`）实现 `PlayerEngine`；`main.dart` 在 debug 下设置环境变量 `NYA_MUSIC_DIR=<文件夹>` 即用 Rust 引擎 + `lib/dev/folder_library.dart`（临时调试用的扫描器，**不是 M2 的 LibraryScanner**）；EQ 通过 `container.listen(eqProvider)` 实时转发。
- **已验证（静音）**：Rust 库在 macOS 加载（日志 `nya_core 0.1.0`）；`engine_smoke` 例子播放真实 FLAC→MP3，位置计数正常，换曲事件正确，坏文件被跳过且只报一次错；macOS debug 与 Android debug APK 都能编过；`cargo test` 28 通过（2 ignored）。
- 测试：**Rust 28 个**（`cd rust && cargo test`）。

## 4. 关键决定与原因（均已写入 TECH_SPEC，此处是速查）

1. **播放内核改 Rust**（附录 B-3）：原 media_kit 的最大风险是打包的 libmpv 不含 EQ 所需的 libavfilter 滤镜、且维护放缓。现用 symphonia(rodio 内部) 解码、rodio/cpal 输出与重采样、自写 biquad EQ、lofty 读标签。**media_kit 保留为退路**（若 M0 证明无缝/设备切换有阻断问题，经开发者同意后回退，`PlayerEngine` 接口不变）。参考了 Rune（Flutter+Rust 播放器，MPL-2.0），**只参考思路，没有拷贝代码**。
2. **Android 基线 = Android 12（minSdk 31）**（开发者决定）：cpal 在 Android 上直接用 AAudio（需 API 26+）；同时壁纸取色（UI-03）全员可用。不再考虑 Android 11 及以下，相关兼容代码可省。
3. **范围**：只支持 FLAC + MP3；歌词、封面只读内嵌；不引入外挂 `.lrc`（P2）。
4. **不新增 FRB 之外的 Dart 依赖**：Rust 事件用扁平结构 `PlayerEvent { kind, playing, index, message }`，而不是带数据的 Rust enum（会让 FRB 生成 `freezed` 类）。注意 FRB 生成的 Dart 枚举成员**不能叫 `index`**（与 `Enum.index` 冲突），所以是 `PlayerEventKind::CurrentIndex`。
5. **顺序**：先前端（假数据），再验证内核（M0），再接真实播放（M3）。当前正处于 M0 中段。

## 5. PLAN 进度（以 `docs/PLAN.md` 复选框为准，下面是补充）

- **M0**：M0-1（旧 media_kit spike，已删）、M0-R1（Rust 工具链）已勾选。**M0-R2（桥接）实际已完成但 PLAN 里还没勾**（macOS 与 Android 都编过、Dart 调 Rust 成功）——接手后请勾选。
  - 待做：M0-2 格式（需**听**）、M0-3 EQ（`cargo test` 已验频响，**实听拖动无爆音**未做）、M0-4 无缝（静音下换曲事件正确，**实听无缝**未做）、M0-5 后台/通知栏/耳机键、M0-6 音频焦点、M0-7 输出设备切换（含 Android 真机）、M0-8 Android 文件权限（只给 `READ_MEDIA_AUDIO`）、M0-9 标签（lofty 已验证两首真实文件；还要用开发者更多真实曲库样本、粗测 1000 文件耗时）、M0-11 FTS5、M0-12 M3 Expressive 调研、M0-14 Release 包体与 192k 在 Android 的 CPU、M0-13 写 `docs/SPIKE_REPORT.md`。
- **M1**：外壳、路由、日志、主题大部分、i18n 骨架已做；未做：drift 数据库（M1-5）、设置/收藏持久化（M1-6）、Android 清单与 audio_service（M1-3）、macOS 关闭沙盒与 window_manager（M1-4）、ja 语言。
- **M2 曲库**（真实扫描 + drift + 封面缓存）、**M3 播放核心**（QueueController 接真引擎、解码失败跳过等）、M4 后台与系统集成、M5 歌词加载、M6 EQ 接 UI——都未开始；M3/M6 的 Rust 部分已超前完成。

## 6. 待开发者决定 / 授权

1. **关闭 macOS App Sandbox**：把 `macos/Runner/DebugProfile.entitlements` 和 `Release.entitlements` 里 `com.apple.security.app-sandbox` 设为 `false`。不改的话调试版读不了 `test_music/` 或外接硬盘。**这是系统权限设置，需开发者明确同意后才改。**
2. 测试音乐：开发者的曲库在外接硬盘，当前不在身边。`test_music/` 里只有两首（FLAC 十年、MP3 缭花绚烂），够做基础验证；要测 24bit/96k 等其他规格、无缝专辑，需要开发者再提供。
3. 是否提交当前所有改动、清理 worktree（见 §0）。

## 7. 下一步建议（按顺序）

1. 整理并提交（先与开发者确认），清理 `.claude/worktrees/`。
2. 获得沙盒授权后关闭沙盒；用 `NYA_MUSIC_DIR=$PWD/test_music flutter run -d macos`（不要加 `NYA_VOLUME=0`）**实听**：播放、暂停、拖进度条、切歌、EQ 滑块（重点听拖动是否爆音）、192k/24bit 重采样音质。
3. 做 M0-4 的真实验证：找两首连续的现场专辑曲目，听切换处是否有缝隙；必要时按 TECH_SPEC §13 的应对（绕过 rodio 队列自维护环形缓冲）。
4. 在 Android 12+ 真机跑一遍：`flutter run --release -d <设备id>`，验证 AAudio 输出、拔插耳机/蓝牙（M0-7）、`READ_MEDIA_AUDIO`（M0-8）。
5. 写 `docs/SPIKE_REPORT.md`，回填 TECH_SPEC 里的 🔍；勾选 PLAN。
6. 进入 M1 剩余（drift、持久化设置）→ M2（扫描器改成 Rust `read_metadata_batch` + drift）→ M3（`QueueController` 接 `RustPlayerEngine`，去掉 `NYA_MUSIC_DIR` 调试通道）。

## 8. 环境与常用命令

- Flutter 3.47.2（stable）、Dart 3.13；Rust stable 1.99.1（rustup，目标含 `aarch64/x86_64-apple-darwin`、`aarch64/armv7/x86_64-linux-android`）；`flutter_rust_bridge_codegen 2.13.0`（`cargo install` 装在 `~/.cargo/bin`，已加入 shell PATH：`. "$HOME/.cargo/env"`）。Android NDK 在 `~/Library/Android/sdk/ndk/`（28.2、30.0）。机器是 Apple Silicon，Xcode 已装。
- **改了 `rust/src/api/` 之后必须重新生成桥接**：`flutter_rust_bridge_codegen generate`（生成 `lib/src/rust/` 与 `rust/src/frb_generated.rs`，要一并提交）。
- 运行：`flutter run -d macos`；Android：`flutter run --release -d <id>`；macOS 构建/`pod install` 时请带 `LANG=en_US.UTF-8`，否则 CocoaPods 会因编码报错。
- 测试：`flutter test`；`cd rust && cargo test`；真实文件测试：`NYA_TEST_MUSIC=$PWD/../test_music cargo test real_test_music -- --ignored --nocapture`。
- 不接 Flutter 直接驱动引擎：`cd rust && NYA_VOLUME=0 cargo run --example engine_smoke -- 文件1 文件2 …`（`NYA_SEEK=秒` 可跳到曲末附近测换曲；`NYA_TIMEOUT=秒`）；`cargo run --example devices` 列出输出设备。
- 调试环境变量（仅 debug，`lib/dev/preview_hook.dart`）：`NYA_PREVIEW=player|panel`、`NYA_TRACK=序号`、`NYA_PAUSE=1`、`NYA_THEME=light|dark`、`NYA_FONT=serif`、`NYA_SHAPE=disc`、`NYA_LYRICS=center,large,notrans`、`NYA_QUEUE=1`、`NYA_DRAWER=1`、`NYA_VOLUME=0..1`、`NYA_MUSIC_DIR=文件夹`；`NYA_WINDOW_SIZE=宽x高` 由 `MainFlutterWindow.swift` 读取。
- 截图验证用的脚本（`shot.sh`、`winid`）放在会话临时目录，**不在仓库里**，需要时自己重写：`screencapture -x -l <窗口id>`，窗口 id 用 CoreGraphics 的 `CGWindowListCopyWindowInfo` 取。

## 9. 已踩的坑（避免重复）

- **cpal/rodio 在 macOS 上打不开蓝牙耳机**：rodio 默认要 2048 帧缓冲，而 FreeBuds 5i 只允许最多 1024 帧（`Buffer size 2048 is not in the supported range 14..=1024`）。`engine.rs::output_buffer_size()` 现按设备报告的范围取值。切换输出设备后应检查类似问题。
- **macOS 链接失败 `_AudioComponentFindNext` 等未定义**：Rust 静态库用到 CoreAudio，需要在 `rust_builder/macos/nya_core.podspec` 里 `s.frameworks = 'CoreAudio','AudioToolbox','AudioUnit','CoreFoundation'`，改后要 `pod install`（带 UTF-8 locale）。
- **Android 链接 `-laaudio` 找不到**：`minSdk 24` 下 NDK 没有 AAudio；已改 `minSdk 31`。
- **FRB 自动覆盖 `lib/main.dart`**：`flutter_rust_bridge_codegen integrate` 会用示例覆盖 `main.dart`，已恢复并手加 `RustLib.init()`。以后重跑 integrate 要注意。
- **`rust/` 的 crate 类型**：`cdylib` + `staticlib` + `rlib`；`rlib` 是为了让 `examples/` 能链接 `nya_core`。
- `.gitignore` 里有 `*.flac`、`*.mp3`，所以测试用的 FLAC 夹具以 `rust/tests/fixtures/sine_44k_16bit_mono.flac.bin` 提交，测试里复制到临时目录再用。
- Riverpod 3：`Override` 类型要从 `package:flutter_riverpod/misc.dart` 导入。
- BSD `sed -i` 需要 `sed -i ''`；多行替换用 Python 更稳。
- macOS 上 `screencapture -o`、系统事件脚本（需要辅助功能权限）都用不了，只能截窗口并读图。

## 10. 已知限制 / 风险（尚未验证）

- 无缝播放（rodio 顺序队列 + symphonia gapless）在**实听**层面未验证；MP3 的 gapless 依赖 LAME/Xing 头。
- `meta`：`lofty` 读 MP3 一定会把整个 ID3v2 标签（含封面）读进内存；FLAC 里仅靠 Vorbis 注释内嵌的封面（`METADATA_BLOCK_PICTURE`）在 `has_cover` 上会被判为 false（`read_cover` 仍可取到）。
- Android 输出设备切换（拔耳机/蓝牙）后的流重建逻辑已写（`recover_device`），**未在真机验证**；音频焦点和系统媒体控制完全未做（计划用 `audio_service` + `audio_session`，M4）。
- Rust 引擎目前没有 `audioParams` 事件（TECH_SPEC §4.2 草案里有，实现时未包含），"歌曲信息"页的采样率/位深来自元数据而非实时输出参数。
- 设置、收藏、播放队列全在内存里，重启丢失（drift 未做）。
- 播放位置在 macOS 上用 Dart 每 200ms 拉取；播放页歌词用 `positionProvider`，后台时是否节流未处理（NFR-07）。
