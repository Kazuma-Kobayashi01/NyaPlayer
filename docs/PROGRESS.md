# 施工记录（PROGRESS）

> 最后更新：2026-10-21 · 写给接手开发的人（或 AI）。先读本文，再读 `.claude/CLAUDE.md`、`docs/TECH_SPEC.md`、`docs/PLAN.md`、`docs/REQUIREMENTS.md`。
> 本文只记录**当前状态、决定、坑和下一步**；需求和技术规范以另外三份文档为准，冲突时以 TECH_SPEC 为准。

## 0. 一眼看完

- **2.0.0 收包（2026-10-21）**：版本号统一为 `2.0.0`（`pubspec.yaml` 的 `2.0.0+1`、`rust/Cargo.toml`；`rust/Cargo.lock` 同步）。应用内版本改由 `lib/app/app_version.dart` 提供，显示 `2.0.0-{平台}({架构})`（如 `2.0.0-Android(armv8a)`、`2.0.0-macOS(arm64)`），平台与架构取自 Dart VM 的 `Platform.version` 目标串，不加依赖；`test/app/app_version_test.dart` 校验它与 pubspec、Cargo 版本一致，以后改版本漏改会直接失败。验收：开发者确认 macOS 退出不慢、两端切歌正常、SQ-AI 真机验收完成、macOS 桌面卡片验收通过、Android 用了一段时间没问题。PLAN 里 M0–M6 一批早已完成的复选框已补勾，没做专项验证的几项（来电焦点、macOS 媒体键、500 次切歌压测）保留未勾并写明。README 中英文重写：图标、版本徽章、截图（用内置虚构演示曲库，`docs/screenshots/`）、技术栈徽章、架构图。
- **Intel Mac 编译修复（2026-10-21）**：`SRConverter.swift` 用了 `Float16`，Intel 上的 Swift 没有这个类型，`darwin-x86_64` 的 release 编译失败（SQ-AI 加入后才出现）。现在 arm64 仍用 `Float16`，其他架构走手写的半精度转单精度 `halfToFloat`，对全部 65536 个半精度值与 `Float16` 逐一对照，零差异。x86_64 包能编出，但 Intel 机器上没有实际运行过。
- **macOS 内存体检（2026-10-21）**：常驻约 404 MB（图形内存约 232 MB，堆约 108 MB），空闲不增长；空的 Flutter 应用约 45 MB，空曲库的 NyaPlayer 约 90–135 MB。封面不是主因（缓存里只有 256 px 和 500 px 两档，142 张全解码也就几十 MB），更可能是流光、预模糊封面、播放条模糊、玻璃面板这些整窗大小的离屏图层，**没做 profile，是推测**。开发者认为可以接受（特效本来就多），不再处理。SQ-AI 转换峰值约 2 GB、几秒后释放；`MacSuperResolution.swift` 改为任务队列清空后释放转换器，不让模型常驻。
- **截图方法（2026-10-21）**：`NYA_SAMPLE=1`（假引擎 + 虚构曲库，不碰真实数据库）配合 `NYA_PREVIEW` / `NYA_THEME` / `NYA_SHAPE` / `NYA_LYRICS`，新增 `NYA_ROUTE=/albums` 直接打开某个页面；运行 debug 包后用 `screencapture -l <窗口号>` 抓图。不要对真实曲库用 `NYA_MUSIC_DIR`（会改写真实数据库，2026-10-18 已吃过亏）。
- **后续第一计划（2026-10-19，M12，只是计划，没写代码）**：**主线继续不联网，承诺不变**，做①歌曲卡片分享（专辑图 + 歌手 + 歌词，纯本地，导出 PNG 再分享）和②播放历史与本地统计（含不带路径的聚合结构 `ListeningSummary`）。**联网的 AI 听歌分析与推荐做成独立版本**：git 分支 `ai`、独立 App ID、独立发布、不合进主线；网络库用 **Rust**；**只提供 OpenAI 兼容的接口，不内置任何服务商**（用户自己找提供商，填 Base URL、模型名、API Key），**全部是固定的系统提示词、不允许自定义**，界面只显示结果；独立版本里**所有联网服务**第一次使用前都要过**免责声明弹窗**（同意才能继续，Rust 层还要再拦一道）。待你确认的几条在 TECH_SPEC §4.9。
- **AI 超分设置“仅桌面端可用”（2026-10-19）**：手机和平板上这一项照样显示，但置灰禁用并写明“仅桌面端可用”，其余平台行为不变；有 android / iOS / macOS 三种平台的测试。
- **Android 版 SQ-AI 试过又移除了（2026-10-19）**：MNN（OpenCL / Vulkan + FP16）、自写 C++ DSP 和 FLAC 编码器、MediaStore 发布都做到了能打进 APK，但手机上 12 秒窗口的会话占 4.8 GB 物理 + 5.5 GB 交换（约 10 GB）被 lmkd 杀掉，开发者决定去掉。已删除相关代码、构建输入和 `python/` 里的 MNN 部分；手机上的残留（解包的 34 MB 模型）由新版启动时清掉。这一路踩过的坑：①先是 `assets.openFd()` 打不开被压缩的资源；②再是 release 的 R8 把只被 JNI 引用的方法删掉，`GetMethodID` 失败后继续调 JNI 直接 abort；③最后是内存。PyPI 的 `MNN` 包还带遥测（见 TECH_SPEC §4.8）。**Android 的均衡器（M10-4）不受影响。**
- **AI 超分减少重复计算（2026-10-18）**：窗口 7 秒 → 12 秒（块 10 秒 + 两侧各 1 秒上下文），重复计算 40% → 20%，整条流水线约快 10–15%，输出与旧版一致（68.5 dB）。**别再减上下文**：0.5 秒会在每个接缝处引入咔嗒声（局部 16.7 dB），1 秒才无缝；窗口也别再放大，17 秒反而更慢。转换时 GPU 满载是预期（模型每秒音频约 0.5–0.7 TFLOP），不是 bug。
- **AI 超分入口改为“从曲库选歌”（2026-10-18）**：设置里不再弹系统文件选择框，而是进选歌页（`/sr-picker`），只列曲库里的 MP3，多选后转换。原因：Android 没有对应的文件选择器，从曲库选两个平台共用。起因是第一版的按钮点了没反应（file_picker 在这个应用的 macOS 上大概率不工作，没抓到日志证实），所以也顺带去掉了这一路。
- **AI 超分 SQ-AI（macOS，2026-10-18）**：设置里新增“AI 超分”，把 MP3 转成 16-bit/44.1k FLAC（Apollo，Core ML，GPU，约 2.4 倍实时，3 分半的歌约 1.5 分钟），原 MP3 保留，新文件 `名称.SQ-AI.flac` 放旁边；标签、歌词、封面用 Rust 写回；普通 FLAC 徽章改名 **SQ**，新增**科技蓝 SQ-AI** 徽章。方案、坑和实测数字见 TECH_SPEC §4.8，任务见 PLAN M11。**坑**：①`jit.trace` 在 CPU 上要把模型完整算一遍（5 秒音频 208 秒），8 分钟没转完，换 `torch.export` 18 秒；②AVAudioFile 写 FLAC 固定 24-bit，会被当成 Hi-Res，改用 ExtAudioFile；③CPU 比 GPU 慢 50–60 倍，CPU+GPU 并行不值得；④FP16 只快 4%，瓶颈是计算量不是精度，INT8 在 GPU 上没有加速；⑤模型输出的开头 0.5 秒与 Python 参考对不上（模型自己在没有上下文的边缘就不可靠），不是 STFT 的 bug。**随后做完**：响度对齐（RMS 对齐加前瞻限幅，差 −0.03 dB）、曲库去重（旁边有 SQ-AI 的 MP3 不进曲库）、神经引擎评估（按现状不可用，整个模型被排到 CPU，比 GPU 慢 9 倍）。**还没做**：在运行的应用里点一遍（M11-6）、批量、收藏转移、Android。
- **均衡器 15 段 + 23 个预设（2026-10-18）**：10 段 → 15 段（25 Hz–16 kHz，⅔ 倍频程，Q≈2.145），Rust / Kotlin（`EqCore.kt`）/ Swift（`MacPlayerCore.swift`）同步；旧的 10 段设置与用户预设读出时插值迁移；预设扩到 23 个（8 个原有 + VLC/Winamp 经典 14 个 + 自制 Loudness）；均衡器页 15 个滑块在窄屏上横向滚动；**Hi-Res 歌曲绕过均衡器**（`lib/services/eq/eq_binding.dart`）。**坑**：Android 的 `DefaultAudioSink` 强制 `setEnableFloatOutput(true)` 会让普通 FLAC 爆音、变速、电音（EQ 关着也有），已还原默认；EQ 处理器还要把输入缓冲区字节序设成原生。macOS 的 Swift 改动尚未在真机上听过。
- **本轮（2026-10-18，自用精简）**：①**Android EQ（M10-4）**：`EqCore.kt` 移植 Rust 10 段 biquad，`EqualizerAudioProcessor` 挂在 ExoPlayer 音频链，音频 sink 开浮点输出（24-bit 不被削成 16-bit）；设置里不用再切到 Rust 内核才有 EQ；`EqCoreTest` 7 项镜像 Rust 用例通过，**真机听感、CPU 还没测**。②**共享元素过渡（UI-11）**：播放条封面 ↔ 完整播放页方形封面共用 Hero，圆角在飞行中渐变；圆盘/唱片机样式不飞；`adaptive_shell_test` 有飞行测试。③**许可证页补全（SET-05）**：登记 122 个 Rust crate（`tool/gen_rust_licenses.py` → `assets/licenses/rust_crates.txt`，改了 `rust/Cargo.toml` 要重跑）、Media3/AndroidX（Apache-2.0）、Hi-Res 标志说明；没有自带许可证文件的 crate 用 MIT/MPL-2.0 标准模板。④**砍掉自用不需要的计划功能**：睡眠定时、倍速、变调、ReplayGain、M3U、自动列表、流派/年份浏览、DSD/APE/WavPack 回归、逐字歌词、歌词偏移微调、歌词来源优先级、M3 Expressive、无障碍检查、无缝开关、Android 桌面 Widget——在 REQUIREMENTS 里标“已砍”，PLAN 里划掉；想要哪项再恢复。**时长过滤（LIB-11）早已做完**（设置里“最短时长”），这次没动。
- **字体精简（2026-10-18，SET-06）**：内置字体 9 份 → 4 份，56.3MB → 32.1MB（−43.0%），三款字符覆盖保留。EB Garamond 使用 400–700 可变字体，HarmonyOS Sans 保留 Regular/Bold，Noto Serif SC 保留 Medium，中文衬线粗体使用合成。`output/` 三份 Release 已更新：arm64 Mac 72.2MB、Intel Mac 73.2MB、Android APK 47.9MB。细节见 `assets/fonts/README.md`。
- **品牌图标与正式名称（2026-10-18，UI-21）**：当前品牌图形为 Flutter 自带 Material `Icons.music_note` 标准音符，按最新要求替换自绘双音符并移除猫耳；几何源、生成命令、平台尺寸与生成记录见 `assets/branding/README.md`。macOS `.icon` 已接入原生资源构建，支持默认/深色/系统着色，Android adaptive icon 含 API 33+ monochrome 图层。正式应用名与 macOS 可执行文件/产品均为 `NyaPlayer`；包标识保留。两个平台 Debug 构建、静态分析、原生图标渲染与资源检查完成，尚未在实际启动器切换主题图标。
- **项目**：NyaPlayer（文档代号 Lyra）——本地离线、无广告的 Material 3 音乐播放器，Flutter，Android + macOS。曲库只有 **FLAC + MP3**，歌词和封面**全部内嵌**，双语歌词是 P0。
- **分支与仓库**：当前版本分支 `2.0.0`，Flutter 版本 `2.0.0+1`（历史：`1.2.0.alpha` / `1.2.0-alpha+1`）；远程 `git@github.com:Kazuma-Kobayashi01/NyaPlayer.git`。2026-10-18 开发者授权提交并推送本轮缓存清理、macOS 桌面组件、正式名称与 Material 标准音符图标；Release 分发产物统一位于根目录 `output/`，按系统和架构分目录，详见 `BUILD_OUTPUTS.md`。具体提交与构建状态以 Git 和本次构建输出为准。
- **README 与许可证（2026-10-18）**：中英文首页增加技术栈徽章及“正在开发中，无法使用”的醒目警告，平台状态标为开发中；许可证采用远程已有的 MIT，合并时保留远程 LICENSE 与双方历史。作者顺序仍为 Kazuma-Kobayashi01、Claude、Codex。本次已明确授权推送 main，覆盖此前未授权推送的限制。
- **阶段**：前端 UI 基本完成；Rust 内核正在 M0 验证。2026-10-18 已在 macOS 实听 FLAC 192kHz/24bit 与 MP3，开发者确认声音正常、MP3 跳转后正常；EQ 顺序修正后复测正常，自制连续 FLAC 两轨切换无可听缝隙。Android 真机仍待验证，详见 `SPIKE_REPORT.md`。
- **本轮新增（开发者指定提前做 M2-6）**：内嵌封面按需获取与两种尺寸磁盘缓存已接入所有封面组件；macOS 三首真实文件正常生成缓存，开发者确认界面封面正常。数据库封面状态与缓存清理待后续接入。
- **本轮界面与快捷键（开发者指定）**：手机封面、背景、歌词和控制栏已按截图调整。侧栏门槛 720dp、双栏 960dp（含宽竖屏），曲库栏封顶 420dp；最新要求已移除侧栏收起按钮与折叠图标栏，桌面侧栏固定 244dp 展开。快捷键说明只在 macOS 显示。随机切换中断已修复并实听确认；同行翻译识别已修复，两首真实 FLAC 的 86 组原译逐组验证通过。播放器按钮现均无常驻背景，进度条可选 Material / 经典圆点 / 细线 / 波浪，切样式不改变播放位置；深浅色遮罩、缩放闪烁、顶部字号调整保留。Flutter 当前 129 个测试通过，Rust 保持上轮 35 个通过、2 个素材测试忽略。
- **系统媒体控制（2026-10-18）**：已接入 `LyraAudioHandler` + audio_service 0.18.19，同步队列、歌曲名/歌手/专辑/时长、播放状态、本地 1024px 封面，远程播放/暂停/切歌/seek/随机/循环通过同一 QueueController；普通轮询不反复推送系统位置，显式 seek（含小幅跳转）独立同步，封面代次防串图。macOS Debug 已重建，开发者确认控制中心及第三方软件的信息、封面与控制均正常。Android 三项媒体服务权限与组件已获授权加入，MainActivity 改继承 AudioServiceActivity；**按开发者最新指示本轮不编译 Android**，后续还需编译、设备验证及 M4-2 音频焦点/中断处理；audio_session 0.2.4 已在允许清单内引入，尚未配置焦点协调器。
- **后台与进程生命周期（2026-10-18）**：已接入 §1 允许的 window_manager 0.5.2，⌘W / 红色关窗隐藏原窗口而不销毁引擎；AppDelegate 保留进程，Dock 可恢复同一窗口。按开发者补充加入 AppKit NSStatusItem 菜单栏常驻图标，可显示窗口、查看当前曲目、播放/暂停、上下首、退出；标签跟随应用语言，状态通过 provider 直接监听，即使隐藏窗口不渲染也更新。⌘Q / 菜单退出经生命周期通道先停止媒体会话、dispose handler/engine/container 再批准 AppKit 退出，并发退出只清理一次，3 秒无响应允许退出。开发者实测关窗后声音连续、控制中心保留、Dock/菜单恢复与控制正常，退出声音停止且图标消失。Android 划除任务由原先主动 stop 改为不干预正在播放的会话，androidStopForegroundOnPause=true，暂停时退出前台；不申请电池豁免、不加守护/定时拉起、不自定义存活时长，插件 START_NOT_STICKY，服从系统/厂商策略。Android 不编译、未真机验证；持久化和音频焦点仍待后续里程碑。格式化、分析、129 个 Flutter 测试通过，macOS Debug 构建成功；Rust 本轮未改。
- **桌面 UI 微调（2026-10-18，为 10 月 19 日计划提前落地）**：macOS 桌面侧栏改为固定 244dp 展开，移除原生收起按钮、折叠导航栏和 Dart 同步入口；播放器面板及沉浸式页面的放大/退出放大按钮缩为 18dp 图标、34dp 点击区域，同时取消 Material 默认 48dp 触摸留白。M1-7/M3-6 子项已记录，格式化、分析及 129 个 Flutter 测试通过，macOS Debug 构建成功；新版视觉效果待开发者实际使用反馈。本轮没有编译 Android，也未改 Rust。
- **M1-5 drift 数据库（2026-10-18，已完成）**：`lib/data/db/tables.dart` 建 §9 全部 11 张表与 4 个索引，`app_database.dart` 开启外键、schemaVersion=1；`drift_schemas/drift_schema_v1.json` 为快照，`test/data/db/generated/` 为 `drift_dev schema generate` 产物。改 schema 时：bump 版本 → 写 onUpgrade → `dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/` → `dart run drift_dev schema generate drift_schemas/ test/data/db/generated/` → 在测试里加旧版本迁移。按开发者“sqlite 用主流版本”不直接依赖 `sqlite3_flutter_libs`（见附录 A），SQLite 来自 `sqlite3` 3.x 官方构建 hook。
- **扫描位置 + 真实曲库 + 自定义歌单（2026-10-18，开发者指定；M1-5 之后紧接做）**：任务编号 M2-2/3/4/5/10、M3-4（播放上下文）、LIB-13（歌单，提前自 M7）。
  - **默认走真实链路**：`main.dart` 现在默认用 `RustPlayerEngine` + drift 数据库曲库；`NYA_SAMPLE=1`（仅 debug）回到假引擎+示例数据；`NYA_MUSIC_DIR=<目录>`（仅 debug）改为“把该目录加为扫描位置”（原 `dev/folder_library.dart` 调试扫描器已删除）。没有任何扫描位置时启动进 `/onboarding`。数据库文件在 `~/Library/Application Support/com.kazuma.nyaplayer/nyaplayer.sqlite`（`drift_flutter` 默认的文档目录在 macOS 上是 ~/Documents，已显式改掉）。
  - **扫描**：`services/library/library_scanner.dart`（遍历在 isolate、`ScanDiff` 纯函数、每批 50 个走 Rust 读标签、按路径原位更新保持曲目 id 稳定、读失败按文件名入库并记 `scan_errors`、扫描末尾清理空专辑/孤立艺术家并选代表曲目）。根目录不存在（硬盘未挂载）时保留其歌曲，避免歌单被清空；已有歌曲被删则从所有歌单消失（外键级联）。添加/移除/排除文件夹、启动、手动“重新扫描”都触发增量扫描，扫描中再次触发会排队补扫一遍。只收 FLAC/MP3，跳过隐藏项与 `._*`。
  - **曲库流**：`LibraryRepository.watchLibrary()` 把数据库行组装成原有的内存 `Library` 模型（250ms 去抖），所以所有页面不用改；`libraryProvider` 改为 `StreamProvider`。歌词不入库，`rawLyricsProvider` 打开时按需从文件读（`Track.hasEmbeddedLyrics` 标记有无）。
  - **歌单**：`PlaylistRepository`（新建/重命名/删除/加入/移除/拖拽排序，位置保持 0..n-1 连续，允许同一首歌重复）；界面 `features/library/playlists_page.dart`、`playlist_detail_page.dart`、`features/playlists/playlist_dialogs.dart`；歌曲菜单新增“加入播放列表”。
  - **播放上下文规则（开发者指定）**：点哪份列表里的歌，队列就是那份列表；同一首歌同时在总曲库和歌单时，以所点列表为准，上一首/下一首/随机都只在该列表内。所有列表页本来就把自己的列表传给 `QueueController.playTracks`，这次补了队列单测和“库里点 vs 歌单里点”的 widget 测试锁定语义。
  - **验证**：Flutter 175 个测试通过（新增 39：键/差集/扫描器/仓库/播放上下文/歌单与设置 widget 流程），分析零问题；macOS 真机（Rust 引擎、音量 0）用 `test_music/` 实测 5 首全部入库（采样率/位深/时长/歌词标志正确），重启后无需重扫（`+0 ~0 -0`）。Android 未编译，`file_picker` 在 Android 上的目录授权/SAF 路径未验证（M0-8）。
  - **已知问题/待你决定**（已更新）：①专辑拆分问题已在下一条修复；②收藏/设置已持久化（见下条），播放队列仍只在内存（M3-9）；③排除文件夹只支持“扫描根目录下的子目录”这一种用法；最短时长过滤（LIB-11）未做；④FTS5 搜索仍是内存子串搜索。
- **专辑归类修复 + 收藏/设置持久化（2026-10-18，开发者指定；任务 LIB-10、M1-6，含 M6-2 的一部分）**：
  - **专辑**：根因是没有 Album Artist 标签时 §7.2 用曲目艺术家做键，合作专辑被拆开。现在无标签时用“同目录+同专辑名”（规格 §7.2 已按此修订），专辑的显示艺术家由 `_tidy` 推导：有标签用标签，否则曲目艺术家都一样就用它，不一样存空串、界面显示“多位艺术家”（`albumArtistLabel`）。`tracks.album_artist` 现在只存标签值。取舍：没有标签又分放不同目录的多碟专辑会被分开。真实库验证：5 张专辑合并为 4 张，《星轨消逝之夜》两首归一。
  - **schema v2**：新增 `favorites(track_id PK, added_at)` 外键级联；迁移同时把所有 `tracks.mtime` 置 -1，让下一次启动的增量扫描重读并重新归类（真实库已按此升级成功）。迁移测试覆盖 v1→v2 保留旧数据；快照 `drift_schemas/drift_schema_v2.json`。
  - **设置**：`SettingsStore`（`data/repositories/settings_repository.dart`）启动时整表读入、后台串行写入；各控制器 `build()` 读初值，用 `listenSelf(skipInitial(...))` 在真正变化时保存（`listenSelf` 首次构建也会触发，所以必须跳过，否则每次启动会把默认值写进库）。覆盖主题模式/配色来源/种子色/字体/播放页背景/进度条样式、语言、启动页、封面形状、歌词显示选项、EQ 当前状态。未知或损坏的值回退默认值。测试里默认用内存 `MemorySettingsStore`，`main` 才换成数据库版本。退出（⌘Q）前会 flush 写队列。调试预览环境变量（NYA_THEME 等）会关闭持久化，不会覆盖你真实的设置。
  - **收藏**：`FavoritesStore` 同样启动时读入集合、后台写库；文件被删后对应收藏随外键清除（与歌单一致）。
  - **验证**：Flutter 193 个测试通过（新增 18：存储往返、各控制器还原、损坏数据兜底、收藏、迁移、新专辑规则），分析零问题；macOS 真实库升级、重扫、合并均已验证。设置/收藏的“重启后保留”在界面层未手工点验（测试覆盖存储与控制器层）。Android 未编译。
- **M3-9 播放状态持久化与启动恢复（2026-10-18，已完成；M4-5 随之满足而勾选）**：`SavedPlayback` / `PlaybackStore`（`data/repositories/playback_repository.dart`，数据库版写 `playback_state` 单行）；`QueueController.restore(saved, lookup)` 剔除已不存在的曲目、校正索引（当前曲目缺失则落到下一首并从头开始）、先 `setLoopMode` 再 `openQueue(autoplay:false)` 再 seek；`PlaybackPersistence`（`services/player/playback_persistence.dart`）负责保存节奏。`main.dart` 在 `runApp` 之前恢复（先于首次扫描），随后启动持久化，⌘Q 的 `flushStores` 包含它。不保存“正在播放”状态，重启一律暂停（PLAY-05）。测试 16 个（存储、恢复各种缺失情形、保存节奏），Flutter 共 210 个通过，分析零问题。注意：恢复后系统控制中心会立刻出现暂停状态的当前曲目（audio_service 随队列同步）。未验证：Android。
- **设置页清理 + 全屏歌词间距自适应（2026-10-18，开发者反馈）**：①设置页下方还留着最初的占位“Library”区块（硬编码 `/Music`、按钮无逻辑），已删除，只保留真正的“音乐库”区块，并清掉 4 个不再使用的字符串。②全屏播放页（`_StageLayout`）原先把宽度平分成左右两栏、封面与歌词各自在栏内居中，窗口拉大后两者相距越来越远（2200 宽实测 496px）。现在每栏宽度设上限 = 舞台高度 − 96，限制在 320–560 之间（矮窗口栏更窄、贴合变小的封面），整组水平居中，多出的宽度留给两侧；栏宽未到上限的窗口（普通窗口模式）布局与之前完全一致。回归测试覆盖 1000×600 到 3200×1400，验证间距 < 220px、整组居中、到达上限后间距不再增长（已确认去掉修复时该测试会失败）。右侧窄面板、手机布局未改动。Flutter 211 个测试通过，分析零问题。
- **大屏全屏间距 + 歌词默认 18pt + 播放页灰白控件（2026-10-18，开发者反馈 16:9 显示器“太拥挤”）**：①`_StageLayout` 以普通窗口（舞台约 1300×750）为基准、此尺寸及以下完全不变；更大时封面和栏宽随舞台高度放大（最多 1.5 倍，封面实测 1400×900:520 → 2200×1200:666 → 3200×1400:780），多出来的宽度还会拉开封面与歌词的间距（随空余宽度增长，上限多 200px；实测 1400×900:34 → 2200×1200:180 → 3200×1400:246），整组始终水平居中；歌词栏不再固定 560 上限（由舞台封顶，≤840）。回归测试覆盖 1400×900 / 1920×1080 / 2200×1200 / 3200×1400。②歌词默认字号 20 → 18pt（只影响没改过的用户；已保存的值不变），测试里写死 20 的断言已更新。③播放页（全屏页、右侧面板、手机页）的控件改用灰白：`player_palette.dart` 取 `ColorScheme.onSurface` 去掉色相（深色下近白，浅色下深灰，仍来自 ColorScheme，无硬编码），用于进度条（四种样式全部）、播放/暂停、上下首、随机/循环/收藏（开=亮、关=60% 透明度，仍可区分）、歌词/队列切换、播放菜单按钮、手机翻页小圆点；不再跟主题色。迷你播放条、列表页和设置页未改。Flutter 212 个测试通过（新增 1 个灰白控件测试，重写 1 个自适应布局测试），分析零问题。
- **歌词字号、内置字体、选择文件夹接系统接口（2026-10-18，开发者指定）**：
  - **歌词**：默认字号改回 20pt；高亮行再加大 2pt（`字号×1.15+3`，手机三行预览同样 +3）。
  - **内置字体（历史记录，当前精简方案见文末）**：非衬线 = HarmonyOS Sans SC（官方包，三字重，**未修改**——协议禁止修改，所以不能裁剪子集；协议要求的显著声明在“关于”页和 README，协议文本进了许可页）；衬线 = 开发者电脑上的 EB Garamond 变量字体切出 400/500/600/700 静态字重（拉丁）+ Noto Serif SC 500/700（中文，思源宋体，OFL）。macOS 自带的 Songti SC 是专有字体不能打包，所以宋体用思源宋体——**如果你想要别的宋体请告诉我**。衬线整体放大 1.08 倍并加重一档（歌词通过 `FontTuning` 一并放大）。设置里新增“使用内置字体”开关（默认开；关＝回到打包字体之前的系统字体配置，已有测试锁定）。内置字体家族名加 `Nya ` 前缀，避免与同名系统字体互相遮蔽——这一点是测试暴露的真实隐患：Android 系统衬线回退列表里本来就有 “Noto Serif SC”，不加前缀的话“关闭内置字体”时也会解析到打包的那份。字体共约 54MB，macOS Debug 包约 257MB；字符覆盖已用 fonttools 验证（简/繁/假名/日文汉字齐全，仅 〜 ♪ ♡ 三个符号在 HarmonyOS 中缺，回退系统字体）。
  - **选择文件夹**：macOS 用原生 `NSOpenPanel`（挂在窗口上的 sheet、可多选、默认 ~/Music、文案跟随应用语言；App 未沙盒，直接用路径，无需安全作用域书签），`Info.plist` 补了桌面/文档/下载/可移动卷/网络卷用途说明；Android 先申请权限再弹系统目录选择器——Android 13+ 申请 `READ_MEDIA_AUDIO`，Android 12 申请 `READ_EXTERNAL_STORAGE`（permission_handler 在 12 上把音频权限当作空操作、在 13+ 拒绝存储权限，所以用 `MainActivity.kt` 里一个返回 `SDK_INT` 的小通道选权限）；被拒时说明原因，永久拒绝时给“打开系统设置”；选择器返回的不是真实路径时报错而不是静默失败；“排除文件夹”不需要权限。**Android 部分按要求未编译、未真机验证**，包括 `file_picker` 在 Android 上返回的路径是否可被 dart:io 递归列出（M0-8）。
  - **验证**：Flutter 239 个测试通过（新增 27：字体方案/解析主题/打包文件与协议存在/设置开关/权限选择/macOS 通道/多选、被拒、出错、取消等流程），分析零问题，macOS Debug 构建与启动成功，截图确认播放页灰白控件与高亮歌词。未手工点验：macOS 原生文件夹面板的实际交互、衬线字体的实际观感（默认是非衬线）。
  - **注意到的一件事**：本次启动时 `test_music/` 里《十年》和《缭花绚烂》两个文件已不在（目录修改时间 13:54），库按磁盘如实移除了这两首（库里现为 3 首）。不是我的操作；保存的上次队列在扫描前就已恢复，所以队列里可能还留着这两首的条目，播放到会被引擎当作无法解码而跳过。
- **语言选择弹窗 + 国际化（2026-10-18，开发者指定；UI-13、M1-9）**：
  - **弹窗**：设置里“语言”改为一行（图标 + 当前语言 + 箭头），点开弹窗：**“跟随系统”在最上面，下面按语言的英文名排序**——简体中文（中国）、繁體中文（香港）、繁體中文（台灣）、English (UK)、English (US)、Français、Deutsch、日本語、한국어、Русский、Español；每项用该语言自己的名称，括号里是地区；选中即生效，当前项带勾。选项表在 `lib/l10n/language_options.dart`（名称不翻译，保证读不懂当前语言的人也能找到自己的语言）。你的示例里台湾写的是“繁体中文（台湾）”，我按“用对应语种自己的写法”写成了繁體字“繁體中文（台灣）”——想要简体字写法改 `languageOptions` 里的 label 即可。
  - **存储**：`ui.locale` 现存语言 id（`zh-CN`/`zh-HK`/`zh-TW`/`en-GB`/`en-US`/`fr`/`de`/`ja`/`ko`/`ru`/`es`/`system`）；旧版本存的 `zh`、`en` 仍可识别（对应简体、美式英语）。
  - **翻译**：新增 fr、de、es、ru、ja、ko、zh_Hant（台灣用语）、zh_Hant_HK（香港用语）、en_GB，每份 196 条；俄语复数按 one/few/many 写全。**注意 gen-l10n 的继承规则**：`zh_Hant_HK` 继承的是简体 `zh` 而不是 `zh_Hant`，所以香港版必须写全（我只覆盖差异时会有 158 条落回简体，已修正）；`en_GB` 继承 `en`，只写 12 条英式拼写差异。台灣用 `zh_Hant`（带台湾国家码的区域会按文字系统匹配到它）。基础英文原来混用英式和美式拼写（“Colour”与“Favorite”并存），已统一成美式，英式放进 en_GB。译文是我写的，**没有母语者审校**——日、韩、俄、法、德、西、繁中尤其建议你或熟悉的人过一遍术语。
  - **清理**：删除 5 条已不再使用的字符串和 2 条旧语言按钮标签；均衡器页那句“当前为界面预览，音频效果将在接入播放引擎后生效”早已不符合事实（EQ 已接入引擎），一并去掉。
  - **macOS**：`Info.plist` 增加 `CFBundleLocalizations`（de/en/es/fr/ja/ko/ru/zh-Hans/zh-Hant），让系统把这些语言识别为应用支持的语言。`MainMenu.xib` 里的系统菜单项（如“Settings…”）没有本地化，保持英文；状态栏菜单的文字来自 Dart，会跟随语言。Android 不需要额外资源（语言在应用内切换），未编译。
  - **测试**：Flutter 262 个通过（新增 23：语言表顺序/存取/旧 id 兼容、每份 ARB 键与占位符与模板一致（以后新增字符串漏翻会直接失败）、所有语种能加载含占位符与复数的文案、俄语复数、区域差异、弹窗完整流程）。**未手工点验**弹窗的视觉效果，也没有逐语种检查排版溢出（德语、俄语文案偏长，设置页和对话框里可能有换行或省略，值得你切换看看）。
- **进度盘点（2026-10-18，已按本轮更新）**：PLAN 的 M0–M6（MVP 范围）有 65 个顶层任务，其中 20 个已勾选、45 个未勾选；按里程碑分别为 M0 13、M1 3、M2 6、M3 6、M4 5、M5 7、M6 5 个未勾选。全 PLAN（含 P1/P2）共 83 个顶层任务，23 个勾选、60 个未勾选（含已提前完成的 LIB-13 歌单）。复选框数不是工时或代码完成度：多个未勾选项已有部分实现/子项验收，M0-10 仅在发现乱码时才需要做，M4-4/5/6 也各有已完成子项。MVP 仍未验收，主要缺口是 M0 Android/报告收尾、M2 FTS 搜索与 SQL 层查询、M3 状态恢复、M4 Android 真机系统行为、M5 完整歌词加载/视图、M6 EQ。
- **紧急事项（接手后第一件事）**：
  1. **接手时工作区干净**，前序改动已提交。2026-10-18 开发者已明确授权提交本轮累计成果，署名按 Kazuma-Kobayashi01（主作者）、Claude、Codex 排列；提交结果以 `git log` / `git status` 为准，不 push。
  2. （已完成）子代理的临时工作区和 `worktree-agent-*` 分支已于 2026-10-18 清理；`.claude/worktrees/` 已在 `.gitignore` 中，今后再用子代理时同样不要提交它。
  3. **macOS 沙盒已获开发者明确授权并关闭**（DebugProfile / Release 两份 entitlements）。Debug 应用签名已核实为 `false`，可读取 `test_music/`；Release 尚未构建验收。
- **用户**：回复一律用**中文**；代码注释中英文均可，标识符用英文。喜欢用截图迭代界面。

## 1. 必须遵守的工作规则（摘自 CLAUDE.md，再强调）

- 一次只做一个里程碑里的任务；开始前先说明做哪几个任务编号。
- **实现与 TECH_SPEC 冲突时先停下来说明**，不要自行改方案；不要新增 TECH_SPEC §1 之外的依赖，除非先在附录 A 记录理由并征得同意。
- UI 不得直接调用 Rust 内核 API（`lib/src/rust/`），必须经过 AudioHandler / QueueController。
- 颜色一律从 `ColorScheme` 取，不得硬编码。耗时操作不阻塞 UI 线程。
- 完成任务后：`dart format . && flutter analyze && flutter test`；改了 `rust/` 再加 `cargo fmt && cargo clippy --all-targets -- -D warnings && cargo test`；然后勾选 `PLAN.md`。
- **改系统权限类设置（如 macOS 沙盒）必须先征得开发者明确同意**；只有开发者说"提交"才 `git commit`。

## 2. 仓库与提交状态

分支 `1.0.1.universal` 上的已有提交（新→旧）：

| 提交 | 内容 |
|---|---|
| `11abb4d` | 更新施工记录：清理子代理 worktree |
| `eb07687` | Rust 播放内核、FRB 桥、EQ、元数据与 Android 12 基线 |
| `88d6724` | 集成 flutter_rust_bridge 2.13.0，Rust crate `nya_core`（M0-R2 的骨架） |
| `6dfb09c` | 文档：播放内核改 Rust（TECH_SPEC v0.2、PLAN M0、CLAUDE.md） |
| `11125fa` | 桌面侧栏 244dp、"Playing" 文案（前端最后一个提交，`main` 同此） |
| 更早 | 横屏桌面布局、macOS 融合标题栏、悬浮播放条、专辑网格溢出、歌词渐隐、窗口最小尺寸、初始提交 |

**以下是前序开发的历史改动清单，已包含在 `eb07687` 中，不是当前待提交项**：

- `rust/`：`src/player/{engine,queue,tracked,mod}.rs`、`src/dsp/{eq,mod}.rs`、`src/meta/{mod,tests}.rs`、`src/api/{player,meta,mod}.rs`、`src/lib.rs`、`examples/{engine_smoke,devices}.rs`、`tests/fixtures/`、`Cargo.toml`（`crate-type` 加了 `rlib`）、`Cargo.lock`。
- `lib/`：`services/player/rust_player_engine.dart`、`services/player/player_engine.dart`（接口新增 `setEqualizer`、`setVolume`）、`services/player/fake_player_engine.dart`、`services/eq/eq_state.dart`（新增 `EqParams`）、`dev/folder_library.dart`、`dev/preview_hook.dart`、`main.dart`、`src/rust/**`（FRB 生成代码）。
- `rust_builder/macos/nya_core.podspec`（链接 CoreAudio 等系统框架）、`macos/Podfile.lock`、`android/app/build.gradle.kts`（`minSdk = 31`）。
- `docs/`：`TECH_SPEC.md`、`PLAN.md`（Android 12 基线），以及本文件。
- 不要提交：`.claude/worktrees/`、`rust/target/`、`build/`、`test_music/`（均已在 `.gitignore` 中）。

## 3. 已完成

### 3.1 前端（UI-first 阶段，全部用 `FakePlayerEngine` + `data/sample_library.dart` 假数据）

- 响应式外壳（`lib/app/layout/adaptive_shell.dart`）：
  - 竖屏且 < 720dp：左滑抽屉（`PhoneDrawer`）+ 悬浮播放条；
  - 横屏（宽 > 高）或 ≥ 720dp：244dp 常驻侧栏（与抽屉共用 `NavigationPanel`）+ 悬浮播放条；
  - 宽 ≥ 960dp、高 ≥ 480dp（含宽竖屏）：再加右侧正在播放面板。中间曲库栏分配余量的约 42%，最小 300dp、最大 420dp，其余宽度给播放器。
  - 侧栏最新决定：按开发者要求移除 macOS 原生收起按钮与 `NavigationIconPanel`，不再提供手动折叠；桌面固定 244dp 展开，双栏门槛统一 960dp。之前的 128dp 图标栏及装饰属于历史方案，已移除。手机抽屉保留；不使用 AX 树读取。
- 播放页：手机左右滑切封面/歌词、上滑拉出队列（`QueueSheet`）；桌面沉浸式（放大）布局；歌词显示设置（字号 20pt 默认、居中、翻译）；Hi-Res 金标（≥24bit 且 ≥96kHz 的无损）；歌词/队列边缘渐隐（`FadedEdges`，固定 32px）。2026-10-18 按开发者要求，桌面沉浸式歌词区下沿延伸到音质标签下沿；先测量歌曲信息区，再在同一布局过程确定封面与歌词边界，移动端/队列维持封面高度。
- 主题：系统调色板逐角色复制（`adoptSystemScheme`，因 `dynamic_color` 返回 `material_ui` 的 `ColorScheme`，见 TECH_SPEC 附录 B-1）、系统/固定色、衬线/非衬线字体。2026-10-18 开发者移除“跟随封面”取色选项与播放器局部主题覆盖，封面模糊背景继续独立保留；格式化、分析及 120 个 Flutter 测试通过。
- 曲库页：歌曲/收藏/专辑/艺术家/文件夹/播放列表/设置；**按名称排序：中文按拼音、英文按字母**（无第三方依赖，拼音表由 `tool/gen_pinyin.swift` + `tool/build_pinyin_table.py` 生成到 `lib/core/pinyin_table.dart`）。
- macOS：去掉系统标题栏，红绿灯向内偏移（`macos/Runner/MainFlutterWindow.swift`），`TitlebarInset`（`lib/app/window_chrome.dart`）留 34dp 顶部安全区，全屏时取消；最小窗口 400×700，无最大限制。
- 设置：默认启动页、字体、封面形状（方/圆唱片）、播放页背景（主题渐变/封面模糊）、语言等——**全部只在内存里，重启丢失**（等 drift，见 M1-5/6）。
- 普通 UI 字号在主题的三种语言排版几何（englishLike/dense/tall）上统一减 1pt，系统字体缩放保留；歌词单独按设置值，默认 20pt，不叠加减量。
- 歌词排版（开发者截图迭代）：桌面展开歌词向左扩展 48pt，保持顶部/底部对齐；展开页和右侧面板底部收藏、播放控制、更多作为一组居中。手机紧凑菜单移除歌词/队列，滑动入口保留。默认行距 1.2 倍、上下留白各 6pt，歌词设置可输入 1–2 倍（±0.1 步进）。主高亮字为字号×1.15+1pt，默认约 24pt，三行预览高亮也增加 1pt。预览高度按行距和系统字体缩放动态预留；暂停打开歌词会立即高亮并居中，修改排版偏好后重新定位。偏好仍暂存内存。
- 播放背景：`PlayerBackground` 共用封面缓存的 256px 缩略图，放大 1.3 倍并应用 sigma 48 模糊，独立重绘层隔开播放控件。开发者纠正后：仅深色在 48% surface 之上叠加 10% ColorScheme.scrim；浅色取消黑色遮罩，surface 不透明度 68% → 50%。播放条深色同样叠黑色遮罩，浅色遮罩 45% → 35%。切歌淡入淡出，无封面回退主题渐变，前景封面不变。手机封面按最终约束尺寸乘 0.94，矮屏同样生效。
- macOS 快捷键：`AppCommands` 使用 Shortcuts / Actions，经 QueueController 播放；⌘, 打开的 `/preferences` 可通过返回或 Esc 回到原页面，不叠加设置页。原生 `Settings…` 菜单通过 `nyaplayer/commands` MethodChannel 调同一入口，macOS Debug 已成功重建并使用 `test_music/` 启动。⌘F 可从展开播放页搜索，复用曲库搜索结果，返回不改变播放；文本编辑期间不抢占空格或 ⌘ 方向键。系统退出/隐藏/最小化/全屏菜单保留。
- 全屏歌词内层上下约 7%、左右约 5% 留白，最大宽度 560dp；在该居中位置基础上，用不对称内边距再向左偏约 16dp。滚动淡出边缘跟随内层，外容器仍保持封面/音质标签边界，右侧面板和紧凑手机页不受此留白调整影响。
- 随机切换严重 bug（2026-10-18）：旧 `toggleShuffle` 按旧规格重新 `openQueue` 再 seek，导致当前音源重建、声音中断、位置短暂为 0。现改 `PlayerEngine.reorder` → FRB `player_reorder` → Rust `Command::Reorder`；排列校验后原子替换队列，保留稳定条目 ID 和当前播放实例，当前音源、进度与播放状态均不变，只刷新下一首。Dart 侧按索引排列，关闭时按重复出现次数匹配原始顺序，整体 O(n)。FRB 代码已生成。开发者在 macOS 连续开关随机实听确认声音连续，进度不再闪回。
- 双语歌词修复：读取《小小奇迹》和《打上花火》的 FLAC 内嵌 LYRICS，发现分别 42 / 44 组原译使用 U+2009 细空格分隔；Rust 已保留该字符，问题在 Dart LrcParser 只识别同时间戳分行。现支持 Unicode 空格、制表符、双空格、`//`、竖线、带空格斜杠、字面换行、`<br>`，结合英/日/中脚本特征拆分，保留普通词间空格和制作信息，支持无时间戳续行及重复译文去重。完整歌词单列译文；三行预览用第三行显示当前译文，否则显示下一原文，翻译开关两处生效。真实文件全部 86 组逐组对照通过，完整歌词未提交。无法可靠区分的同语种/纯汉字片段不强拆。
- 歌词预览旧问题：运行日志曾显示切行淡出时字体几何变化造成 4.8px 溢出；旧动画子项保存了固定行高。改为三行 Expanded 平分当前预览高度并裁剪过渡内容，补了淡出中从 1.5 倍缩回的回归，预览总高度仍按字体/行距动态计算。
- 测试：Flutter 当前共 129 个通过，静态分析零问题；已覆盖解析、双语显示与翻译开关、缩放封面缓存、四种进度条实际 seek、系统媒体元数据/远程指令/位置节流/封面竞态。额外本地真实素材测试逐组核对 86 组原译通过。Rust 未在本次修改，保持上轮 35 个通过、2 个忽略，随机重排修复及桌面/折叠屏测试保留。

### 3.2 Rust 内核（`rust/`，crate `nya_core`）

- **架构**（TECH_SPEC §2、§4.3、§5）：Dart → flutter_rust_bridge（FRB）同步命令（只往通道发消息，立即返回）→ 引擎线程（`rust/src/player/engine.rs`）独占输出设备和 rodio `Player`；状态通过 FRB `StreamSink` 回 Dart；**位置不推流**，Dart 每 200ms 拉 `playerPositionMs()`。
- **队列模型**（`player/queue.rs`，纯逻辑，7 个测试）：与 `FakePlayerEngine` 语义一致；每个条目有稳定 id，用来判断预读的"下一首"是否被编辑作废。
- **无缝播放**：当前曲 + 预读的下一首都追加进 rodio 的顺序队列，同一输出流首尾相接；解码器 `with_gapless(true)`。`Tracked` 包装器（`player/tracked.rs`）在下一首的第一个样本被取用时通过原子量报告"换曲"，并支持取消尚未开始的预读。
- **EQ**（`dsp/eq.rs`，7 个测试）：10 段 RBJ 峰值滤波（biquad，Q≈1.414，f32）、前级增益、无锁更新、20ms 增益平滑、旁路时逐位相同、输出硬限幅。
- **元数据**（`meta/`，lofty 0.25，11 个测试 + 2 个 `#[ignore]` 真实文件测试）：标签、FLAC `LYRICS`/`UNSYNCEDLYRICS`、MP3 `USLT`（优先含时间戳的）、`SYLT` 转 LRC、封面（Front Cover 优先）、批量并行读取（保序）。**已用 `test_music/` 里两首真实文件验证**：十年 FLAC = 192kHz/24bit，带 LRC 歌词和 181KB PNG 封面；缭花绚烂 MP3 = 320kbps，USLT 为 LRC，有封面。
- **Dart 侧**：`RustPlayerEngine`（`lib/services/player/rust_player_engine.dart`）实现 `PlayerEngine`；`main.dart` 在 debug 下设置环境变量 `NYA_MUSIC_DIR=<文件夹>` 即用 Rust 引擎 + `lib/dev/folder_library.dart`（临时调试用的扫描器，**不是 M2 的 LibraryScanner**）；EQ 通过 `container.listen(eqProvider)` 实时转发。
- **前序验证（静音，历史记录）**：Rust 库在 macOS 加载（当时日志 `nya_core 0.1.0`）；`engine_smoke` 例子播放真实 FLAC→MP3，位置计数正常，换曲事件正确，坏文件被跳过且只报一次错；macOS debug 与 Android debug APK 都能编过；当时 `cargo test` 28 通过（2 ignored）。
- 测试：**Rust 35 个通过，2 个 ignored**（2026-10-18）；`cargo fmt`、`cargo clippy --all-targets -- -D warnings` 通过。覆盖重采样后 EQ 频响、输出 Nyquist 限制、连续 FLAC 样本边界，以及原子重排的排列校验、重复实例和采样连续性。
- **2026-10-18 M0 实测**：关闭沙盒后，开发者确认两首真实音乐声音正常；发现 EQ 原先位于重采样之前，经开发者同意修正为 `Decoder → UniformSourceIterator(设备配置) → EqSource → Tracked → Player`，不新增依赖、不修改 FRB API。重新构建后 EQ 调整正常；自制 44.1kHz/16bit 连续 FLAC 两轨无可听缝隙。当前蓝牙默认输出为 FreeBuds 5i，44.1kHz 双声道。

### 3.3 内嵌封面（M2-6，2026-10-18）

- `lib/services/library/cover_cache.dart` 通过已有 Rust `read_cover` 提取 Front Cover，UI 不直接调用 Rust。`CoverSource` 让同专辑的歌曲共用代表曲目，附带 size/mtime；假数据没有来源时继续显示占位图，不触发 FFI。
- 原图只在提取/工作 isolate 期间持有；完成后服务与 UI 只保留文件路径。生成长边不超过 256/1024 的 JPEG、保留比例、不放大小图；同源请求合并，提取和缩放串行，异常保留占位封面。
- 2026-10-18 修复窗口缩放黑闪：原 `CoverArt.cacheWidth` 随布局宽度每个像素变化，反复换解码键并清空画面；现固定 256/1024 两档并保留上一帧。额外缓存最近 128 条源版本的已解析路径（不存图片字节），响应式布局重新挂载时立即复用，同时仍异步验证磁盘完整性；源版本变化不会命中旧图，校验失败移除路径。连续尺寸变化测试检查 RawImage 保留相同图像，模拟磁盘等待的重建首帧仍有封面；格式化、分析、122 个 Flutter 测试通过。
- 缓存位于应用支持目录的 `covers/<revision>/`，JPEG 使用专辑键 SHA-1 命名。源版本目录避免文件修改后读到旧图，写完两张图再写完成标记；完整缓存跨启动复用。
- 已接歌曲/专辑/艺术家列表、搜索、专辑详情、播放页（方形/旋转唱片）、队列、播放条封面和模糊背景。最初沿用原有封面种子主题；后续开发者取消该取色模式，主题只保留系统/固定色，封面背景独立保留。
- 新依赖：原清单内 `image` ^4.12.0、`path_provider` ^2.1.6；`crypto` 3.0.7 从原间接依赖提升为直接依赖，开发者已单独同意，见 TECH_SPEC 附录 A。
- 验证：格式化完成、分析零问题、84 个 Flutter 测试通过，macOS Debug 构建成功；三首真实文件均有两种尺寸的可解码缓存，开发者确认显示正常。本轮未改 Rust/API，不需重跑 FRB 生成。
- 待做：Drift `coverState`、孤立/旧版本缓存清理、Android 真机封面验证。M2-6 主复选框因此仍未勾选；不把临时扫描器视为 M2 曲库扫描完成。

## 4. 关键决定与原因（均已写入 TECH_SPEC，此处是速查）

1. **播放内核改 Rust**（附录 B-3）：原 media_kit 的最大风险是打包的 libmpv 不含 EQ 所需的 libavfilter 滤镜、且维护放缓。现用 symphonia(rodio 内部) 解码、rodio/cpal 输出与重采样、自写 biquad EQ、lofty 读标签。**media_kit 保留为退路**（若 M0 证明无缝/设备切换有阻断问题，经开发者同意后回退，`PlayerEngine` 接口不变）。参考了 Rune（Flutter+Rust 播放器，MPL-2.0），**只参考思路，没有拷贝代码**。
2. **Android 基线 = Android 12（minSdk 31）**（开发者决定）：cpal 在 Android 上直接用 AAudio（需 API 26+）；同时壁纸取色（UI-03）全员可用。不再考虑 Android 11 及以下，相关兼容代码可省。
3. **范围**：只支持 FLAC + MP3；歌词、封面只读内嵌；不引入外挂 `.lrc`（P2）。
4. **不新增 FRB 之外的 Dart 依赖**：Rust 事件用扁平结构 `PlayerEvent { kind, playing, index, message }`，而不是带数据的 Rust enum（会让 FRB 生成 `freezed` 类）。注意 FRB 生成的 Dart 枚举成员**不能叫 `index`**（与 `Enum.index` 冲突），所以是 `PlayerEventKind::CurrentIndex`。
5. **顺序**：先前端（假数据），再验证内核（M0），再接真实播放（M3）。当前正处于 M0 中段。

## 5. PLAN 进度（以 `docs/PLAN.md` 复选框为准，下面是补充）

> 任务清单与验收状态以 `docs/PLAN.md` 的复选框及每项注释为准；下面的较早进度记录不再代表当前状态。未勾选项可能已有部分实现，但仍缺计划中列出的覆盖或验收。

- **已完成的基础设施**：M1 数据库、主题/设置持久化；M2 扫描器、FTS5 搜索、最短时长过滤；M3 播放状态持久化；M4 音频焦点协调器、Android 通知权限流程；M5 MP3 标签编码回退；M6 内置及用户 EQ 预设。具体范围见 `docs/PLAN.md` 和本文件后续记录。
- **仍需优先收尾**：M0 的 Android 真机/更多格式/音频设备等验证、真实曲库标签检查、M3 Expressive 调研与最终 Spike 报告；M2 的封面状态持久化、SQL 查询与歌曲信息页；M3 的队列页及完整播放/队列体验验收；M4 的 Android 真机和锁屏/媒体键验证；M5 的歌词加载器与视图验收；M6 的 EQ 滤镜构建和控制器完善。
- **验收边界**：API 37 模拟器上的 Android 验证不等于真机验证；真实 GBK/Shift-JIS MP3 样本尚未核验；macOS 物理媒体键仍待检查。各项细节与条件任务见 `docs/PLAN.md`。

## 6. 待开发者决定 / 授权

1. **关闭 macOS App Sandbox：已授权并完成**（2026-10-18）。两份 entitlements 均设为 `false`，Debug 可读取真实曲库；不需要再次询问本次相同改动的授权。
2. 测试音乐：本轮开始时 `test_music/` 有两首（FLAC 十年、MP3 缭花绚烂），这两首已获听感反馈。期间开发者新增 `那颗星梦见的春日 - 鸣潮先约电台&jixwang&小林未郁.flac`（界面显示 24bit/48kHz），该文件未纳入本轮正式听感验收。其他规格、真实连续专辑仍需补充。
3. 2026-10-18 已获“提交”指令，本轮累计代码与文档纳入同一次提交；主作者使用现有 Git 身份 Kazuma-Kobayashi01，协作署名依次为 Claude、Codex。worktree 已在前序工作中清理，不 push。

4. **2.0 播放内核改为平台原生（2026-10-18 开发者决定）**：Android 全部使用 Google 的 Media3 ExoPlayer 编解码，macOS 使用系统 AVFoundation；Android 优先。已写入 TECH_SPEC §4.7、附录 A / B-4 和 PLAN M10。我替开发者选的默认项（可改）：EQ 用 Media3 自定义 `AudioProcessor` 保留 10 段，而不是系统 `Equalizer`（后者频段数由设备决定，对不上现有 10 段 UI 与预设）；系统媒体会话继续用 `audio_service`；`RustPlayerEngine` 验收前保留为退路；M4A / OGG / Opus 是否放开留待决定（M10-10）。**尚未写任何实现代码**，下一步是 M10-1（Android 真机基线）。
   - 补充决定（同日）：应用要给别人使用，Android 解码器优先级为**官方硬件 > 官方软件**，只用系统 `MediaCodec` / `AudioTrack` 路径并带自动回退，不限定只用 Google 的 `c2.android.*`（取代此前“只放行 Google 解码器”的写法）。开发者手机（高通 + 三星）的 `MediaCodecList` 里没有音频硬件解码器，真正的硬件路径只可能是 DSP offload，它与自定义 EQ 互斥，见 TECH_SPEC §4.7、PLAN M10-11。

## 7. 下一步建议（按顺序）

### 2026-10-19 计划

1. 继续打磨 UI 并做视觉验收：桌面全屏放大/退出按钮尺寸、侧栏始终展开、不同窗口尺寸下右侧播放面板布局。上述两项实现与 129 个 Flutter 测试已在 10 月 18 日完成；继续根据实际使用反馈调整控件间距、对齐与层次。
2. 之后按 MVP 依赖顺序推进 M0 收尾 → M1 drift/设置持久化 → M2 曲库扫描与查询 → M3 队列接入/状态恢复 → M4 Android 系统媒体验证 → M5 歌词加载和视图 → M6 EQ 控制与预设。
3. Android 编译与真机验证仍按之前约定延后；进入 Android 验收前先完成 macOS UI 与当前 M0 可做部分。

> 这是一份 2026-10-19 的历史待执行计划；后续进度以 `docs/PLAN.md` 当前复选框为准。

1. 先完成 M0 剩余验证并收尾 `docs/SPIKE_REPORT.md`、回填 TECH_SPEC：优先整理已有 macOS 证据，再补 Android 真机格式/EQ/后台/音频焦点/设备切换/文件权限/CPU 与 Release 检查；条件项 M0-10 根据 M0-9 结果决定。
2. 按既定要求，Android 暂不编译；开始 Android 编译或真机验证前先完成 macOS 这一轮工作，运行时带 `LANG=en_US.UTF-8`。
3. M0 验收后做 M1 drift 数据库与设置持久化，再做 M2（扫描器改成 Rust `read_metadata_batch` + drift），接着完成 M3（`QueueController` 接 `RustPlayerEngine`、队列功能和播放状态恢复，移除 `NYA_MUSIC_DIR` 调试通道）。
4. 完成 M4 Android 通知/音频焦点/通知权限和真机系统验证，同时核对 macOS 物理媒体键；随后补完 M5 歌词加载/视图与 M6 EQ 控制器、预设和持久化，按 REQUIREMENTS §8 做 MVP 验收。
5. 未经开发者“提交”指令，不执行 commit。

## 8. 环境与常用命令

- Flutter 3.47.2（stable）、Dart 3.13；Rust stable 1.99.1（rustup，目标含 `aarch64/x86_64-apple-darwin`、`aarch64/armv7/x86_64-linux-android`）；`flutter_rust_bridge_codegen 2.13.0`（`cargo install` 装在 `~/.cargo/bin`，已加入 shell PATH：`. "$HOME/.cargo/env"`）。Android NDK 在 `~/Library/Android/sdk/ndk/`（28.2、30.0）。机器是 Apple Silicon，Xcode 已装。
- **改了 `rust/src/api/` 之后必须重新生成桥接**：`flutter_rust_bridge_codegen generate`（生成 `lib/src/rust/` 与 `rust/src/frb_generated.rs`，要一并提交）。
- 运行：`flutter run -d macos`；Android：`flutter run --release -d <id>`；macOS 构建/`pod install` 时请带 `LANG=en_US.UTF-8`，否则 CocoaPods 会因编码报错。
- 测试：`flutter test`；`cd rust && cargo test`；真实文件测试：`NYA_TEST_MUSIC=$PWD/../test_music cargo test real_test_music -- --ignored --nocapture`。
- 不接 Flutter 直接驱动引擎：`cd rust && NYA_VOLUME=0 cargo run --example engine_smoke -- 文件1 文件2 …`（`NYA_SEEK=秒` 可跳到曲末附近测换曲；`NYA_TIMEOUT=秒`）；`cargo run --example devices` 列出输出设备。
- 调试环境变量（仅 debug，`lib/dev/preview_hook.dart`）：`NYA_PREVIEW=player|panel`、`NYA_TRACK=序号`、`NYA_PAUSE=1`、`NYA_THEME=light|dark`、`NYA_FONT=serif`、`NYA_SHAPE=disc`、`NYA_LYRICS=center,large,notrans`、`NYA_QUEUE=1`、`NYA_DRAWER=1`、`NYA_VOLUME=0..1`、`NYA_MUSIC_DIR=文件夹`（加为扫描位置）、`NYA_SAMPLE=1`（假引擎+示例数据）；`NYA_WINDOW_SIZE=宽x高` 由 `MainFlutterWindow.swift` 读取。
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

- **`drift_flutter` 默认把数据库放在“文档目录”**：macOS 上就是 ~/Documents。已在 `AppDatabase` 里用 `DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory)` 改掉。
- **widget 测试里用到 drift 流会留下零时长定时器**（流取消时 drift 起一个 Timer，被 flutter_test 判为未清理）：旧的外壳测试把 `rootsProvider` 换成 `Stream.value`；新的数据库测试在结尾 `pumpWidget(SizedBox)` 再 `pump` 一次（见 `test/features/playlists/library_flows_test.dart` 的 `finish`）。
- `scrollUntilVisible` 只保证控件被构建，不保证在屏幕内；设置页变高后需再 `ensureVisible`。
- macOS 会产生 `._xxx.mp3` 资源分叉残留文件，扫描器按“以 . 开头”统一跳过。

## 10. 已知限制 / 风险（尚未验证）

- 无缝播放已通过自制连续 FLAC 的 macOS 实听及离线样本边界测试；真实连续专辑、MP3 和 Android 仍待验证，MP3 gapless 依赖 LAME/Xing 头。
- 本轮试听期间曾有独立 5 秒 `engine_smoke` 与应用同时出声，开发者反馈重复音轨；该进程结束后，开发者确认单独运行应用时 EQ 调整正常。该次测试存在并行音源干扰，不作为内核故障复现。后续听感测试只保留一路音源，不在用户试听时另起出声诊断。
- **macOS Debug 原生崩溃（未修复）**：恢复真实曲库后调试连接断开；系统报告 `nyaplayer-2026-10-18-002343.ips` 为主线程 SIGSEGV，首帧是 Flutter `AccessibilityBridge::CreateRemoveReparentedNodesUpdate`，此前持续报 `Failed to update ui::AXTree`。UI 自动化也曾出现陈旧窗口绑定。不能把它当作普通日志提示或归因为 Rust 音频错误；后续应单独排查无障碍树/页面切换。暂不再用 UI 自动化读取语义树，保持系统无障碍设置不变。
- `meta`：`lofty` 读 MP3 一定会把整个 ID3v2 标签（含封面）读进内存；FLAC 里仅靠 Vorbis 注释内嵌的封面（`METADATA_BLOCK_PICTURE`）在 `has_cover` 上会被判为 false（`read_cover` 仍可取到）。
- Android 输出设备切换（拔耳机/蓝牙）后的流重建逻辑已写（`recover_device`），**未在真机验证**；系统媒体服务和共享 AudioHandler 已接入，`AudioFocusCoordinator` 已实现并有单元测试，但模拟器/真机覆盖仍见 `docs/PLAN.md` M4 注释。
- Rust 引擎目前没有 `audioParams` 事件（TECH_SPEC §4.2 草案里有，实现时未包含），"歌曲信息"页的采样率/位深来自元数据而非实时输出参数。
- 曲库、扫描位置、歌单、收藏、设置、EQ 当前状态以及播放队列/位置均已持久化（重启后队列暂停恢复）。
- 播放位置在 macOS 上用 Dart 每 200ms 拉取；播放页歌词用 `positionProvider`，后台时是否节流未处理（NFR-07）。

### 2026-10-18 UI / macOS 命令补充

- GoRouter 的 `push` 默认不更新浏览器式 URL；判断最上层设置页应读取 `routerDelegate.currentConfiguration.last.route.path`，不能使用 `routeInformationProvider.value.uri.path`。入口同时用标志防止路由解析期间快速重复调用。
- 设置列表为惰性 ListView，组件测试需滚动构建屏幕外选项，再断言或点击。

### 2026-10-18 Android 编译（只支持 arm64-v8a）

- 明确不支持 x86、x86_64、armeabi-v7a：不编译、不打包。命令：`flutter build apk --debug|--release --target-platform android-arm64`（debug/release 均已编译通过，APK 内只有 `lib/arm64-v8a/`）。`flutter run` 在 arm64 模拟器上同样只会构建 arm64。
- 为此改了三处：`android/app/build.gradle.kts` 加 `ndk.abiFilters` 和 `packaging.jniLibs.excludes`（`jni` 插件会为所有 ABI 建 `libdartjni.so`，abiFilters 挡不住）；`rust_builder/cargokit/gradle/plugin.gradle` 删掉 debug 时自动追加的 x86/x64 目标（这是 cargokit 的 vendored 文件，升级 flutter_rust_bridge 模板时要重新应用）。
- `permission_handler_android` 要求 compileSdk 37：`app/build.gradle.kts` 改为 `compileSdk = 37`，`gradle.properties` 加 `android.suppressUnsupportedCompileSdk=37`（AGP 9.1 只推荐到 36）。本机 SDK 管理器装出来的目录是 `platforms/android-37.0`，AGP 找 `android-37`，已在 SDK 目录里建符号链接 `android-37 -> android-37.0`（换机器要重做）。
- 坑：切换 ABI 配置后要删 `build/nya_core/jniLibs` 和 `build/jni`，否则旧 ABI 的残留 `.so` 会继续打进 APK。
- 模拟器镜像只有 arm64-v8a（android-36.1 / 37.2），与此配置一致。

### 2026-10-18 Android 模拟器首次运行（API 37 模拟器，非真机）

- 已验证：启动、Rust 内核加载、数据库、系统媒体会话；空曲库引导页；点“添加文件夹”弹出 `READ_MEDIA_AUDIO` 系统权限框，允许后进入系统目录选择器（SAF），选 `Music` 并授权后，扫描得到 3 首 FLAC，标题/艺术家/专辑/时长/内嵌封面/歌词都读到了（**dart:io 能列目录、Rust 能按路径读**——M0-8 的核心问题在模拟器上成立）；重启后队列恢复；播放、暂停、进度、歌词滚动正常，AAudio 流进入 STARTED。
- **坑（已修）**：首次开流时 cpal 的 AAudio 后端 panic：`android context was not initialized`（`ndk-context`），引擎线程随之退出，表现为点歌无声、状态一直暂停、没有任何 Dart 侧错误。修法：`NyaCore.kt` 在 `configureFlutterEngine` 里把 Application Context 经 JNI 传给 `rust/src/android_context.rs`，由 `ndk_context::initialize_android_context` 保存（直接依赖 `jni` 0.22、`ndk-context` 0.1，已记 TECH_SPEC 附录 A）。
- 新增 `rust/src/android_log.rs`：Android 上把 `log` 记录和 panic 写进 logcat（tag `nya_core`），之前这些全部丢失，是定位上面那个 panic 花时间的原因。`LyraAudioHandler` 现在会把引擎 `Error` 事件打到 Dart 日志（`[warning] player:`）。
- 调试方法：`adb logcat -s nya_core flutter`；往模拟器放音乐用 `adb push test_music/. /sdcard/Music/`。
- 仍未验证：真机（M0-8 要求的 Android 13+ 真机）、Android 12 的权限分支、拒绝/永久拒绝权限的降级流程、通知栏与封面（M4-1）、音频焦点（M4-2）、设备切换。模拟器日志里的 `android.hardware.uwb` / `nfc` SIGABRT 是模拟器自带 HAL 的噪音，与本应用无关。

### 2026-10-18 折叠屏展开态歌词区

- 开发者在折叠屏模拟器（2076×2152，约 850×880dp）上反馈歌词区太小：此前只有桌面端让歌词列延伸到标题下沿，Android 一律与封面等高。改为除“矮窗口”（高度 < 500dp 的横屏手机）外都延伸（`_Stage.extendLyrics = lyrics && (desktop || !short)`）。同一台设备上歌词可见行数约从 5 行增加到 9 行；队列面板仍与封面等高。
- 折叠屏外屏（合上，1080×2364）走手机布局，已看过，正常；平板竖屏的沉浸式播放页尚未检查。若仍嫌小，下一步是让歌词列在大屏上占满整个舞台高度（目前与“封面 + 标题”整体等高并垂直居中，上下仍有空白）。
- adb 截折叠屏要带 `-d <display id>`（`dumpsys SurfaceFlinger --display-id` 查），否则警告文字会混进 PNG。

### 2026-10-18 Android 平板：系统栏与应用重叠

- 现象（API 37 平板模拟器 2560×1600）：宽屏三栏布局被状态栏盖住顶部，底部手势条压在卡片上。原因：`SystemUiMode.edgeToEdge` 下手机布局靠 Scaffold/AppBar 避让，而 `AdaptiveShell` 的宽屏分支是按 macOS 画的——卡片刻意顶到窗口上沿、与红绿灯并排，把顶部内边距清零。
- 修法（`lib/app/layout/adaptive_shell.dart`）：非桌面平台（Android 等）把 `MediaQuery.padding` 作为整个宽屏布局的外边距，内部 MediaQuery 的内边距清零（页面和 `PlayerBar` 的 SafeArea 不会重复避让）；macOS/Windows/Linux 行为不变。新增两个测试：平板上侧栏/播放面板在状态栏与手势条之间；macOS 上卡片仍与标题栏并排。
- 已在平板模拟器上看过：状态栏、手势条都在卡片之外。

### 2026-10-18 M4 系统集成 / FTS5 搜索 / 编码修复 / EQ 预设 / 最短时长（分支 1.1.0.alpha）

- **最短时长过滤（LIB-11）**：默认 1 分钟，设置里选 关/15/30/60/120/300 秒；`LibraryRepository.loadLibrary(minDuration:)` 过滤，时长未知（0）的不算短，空了的专辑一并隐藏；搜索结果与队列恢复之外的所有页面都走过滤后的曲库。不做文件夹封面回退（开发者决定：封面就用内置占位）。
- **FTS5 搜索（M2-9、M0-11）**：schema v3，`track_fts` 外部内容表 + 触发器；搜索页改为异步（`trackSearchProvider`，`main` 里接 FTS，测试/示例模式仍是内存搜索）；Android 模拟器上实测可用。
- **编码修复（M5-2、M5-6）**：Rust `encoding_rs`，见 TECH_SPEC §7.4；schema v3 迁移会置 `mtime=-1` 让旧曲重读。**没有真实的 GBK/Shift-JIS MP3 样本**，只有 cargo 里构造的字节测试，需要开发者用真实旧 MP3 看一遍。
- **EQ 预设（M6-3、M6-5）**：内置入库、用户预设保存/重命名/删除，用户预设排最前。
- **M4**：`AudioFocusCoordinator`（M4-2）、通知权限提示（M4-3）、清单补 `POST_NOTIFICATIONS`、M4-1/M4-4 在 API 37 模拟器核对，详见 PLAN 各项注释。**没验证的**：压低音量（只有单元测试）、拔耳机/蓝牙断开、锁屏、真机、Android 12 分支。
- 测试：Dart 293 项、cargo 42 项；Android 上的验证用无窗口模拟器（`emulator -avd Pixel_10_Pro_Fold -no-window`），`adb emu gsm call/cancel` 可模拟来电。
- 坑：`pumpAndSettle` 在均衡器页永远返回不了（滑块一直有帧），用手动 `pump`；Riverpod 3 会暂停没人监听的 StreamProvider，测试里要先 `listen`；`flutter test` 被管道截断输出时看不到卡在哪，输出写文件再读。

### 2026-10-18 Windows 适配评估（只评估，未动手）

- **结论**：可行，核心（Rust 引擎、数据库、扫描、界面）基本不用改；要补的是 Windows 原生外壳和系统媒体控制。Flutter 3.47 的 Windows 目标含 Arm64（`flutter build windows` 输出在 `build\windows\arm64\`），cargokit 已映射 `aarch64-pc-windows-msvc`，`rust_builder/windows/CMakeLists.txt` 已存在。
- **依赖包**：支持 Windows——`window_manager`、`file_picker`（只能选单个文件夹，现有 `GenericFolderPicker` 已按此写）、`dynamic_color`（取系统强调色）、`sqlite3` 3.x 构建 hook（需要 MSVC）、`permission_handler`（空操作）；**不支持**——`audio_service`、`audio_session`（只有 Android/iOS/macOS），代码里本来就只在 macOS/Android 初始化。Rust 侧 cpal 走 WASAPI、rodio/lofty/encoding_rs 平台无关；`jni`/`ndk-context` 只在 Android 目标编译。
- **缺口，按工作量排**：① 系统媒体控制 SMTC + 媒体键（候选：pub 包 `smtc_windows` 1.1.0，FFI 插件，**未声明 arm64，需实测**；或在 `nya_core` 里用 `windows` crate 自己做，要 HWND）约 1–2 天；② 生成 `windows/` 工程（仓库里没有），首次编译与环境搭建约 0.5–1 天；③ 窗口与退出语义：macOS 是“关窗留后台 + 菜单栏图标”（原生通道 `nyaplayer/lifecycle|window|commands`），Windows 先用默认标题栏、关窗即退出最省事，要托盘需新增依赖（`tray_manager` 之类，要先记附录 A）约 1 天；④ 快捷键：现在只在 macOS 注册且帮助文字写死 ⌘，需 Ctrl 版本和文案 约 0.5 天；⑤ 系统字体回退（关闭内置字体时 serif 的回退列表没有 Windows 分支）、路径分隔符与大小写不敏感文件系统的回归 约 0.5 天；⑥ 打包（MSIX 要签名，或 Inno Setup / 压缩包）另算。
- **虚拟机**：Parallels “Windows 11”，ARM64、8 vCPU、6GB 内存、256GB 磁盘，当前是停止状态。在 VM 内构建需要 Flutter（Windows ARM64）、Visual Studio 2022 生成工具（含 ARM64 组件）、Rust `aarch64-pc-windows-msvc`、Git；仓库放共享文件夹或克隆进去。6GB 内存做 MSVC + Rust 偏紧，建议加到 8GB。macOS 上无法交叉编译 Windows。
- **风险**：ARM64 VM 里音频走 Parallels 虚拟声卡，时延/重采样表现不代表真机；WASAPI 共享模式的缓冲区取值（`output_buffer_size`）要实测；`smtc_windows` 与我们的 FRB 同为 FRB+cargokit，两个 Rust 动态库并存要实测。

### 2026-10-18 Hi-Res 徽章、流光背景、高级玻璃（分支 1.1.0.alpha）

- **徽章统一**：手机播放页原来用扁平的 `tonal` 徽章，现在与桌面一致（带波形图标的 `ActionChip`），`QualityBadge` 不再有 `tonal` 参数；`QualityBadge.height = 34` 是布局预留高度（手机封面页按它算歌词行数，原来写死 28 会溢出 0.18px）。
- **Hi-Res 判定**（开发者按维基百科定义要求）：无损且（位深 > 16 或采样率 > 44.1 kHz）。注意 24-bit/48 kHz、16-bit/48 kHz 现在都算 Hi-Res；有损格式永远不是。
- **Hi-Res 徽章样式**：黑底、细金边（与普通标签同为圆角 8、1px 描边）、象牙金文字；一小段暗淡的亮光沿边缘绕行（6 秒一圈），前半圈里有一道很淡的光带掠过，后半圈静止；不再有外发光。配色集中在 `HiResColors` 主题扩展（`lib/app/theme/hires_colors.dart`）——金色是 Hi-Res 标志本身的品牌色，不是 ColorScheme 角色，所以是 CLAUDE.md “不硬编码颜色”的明确例外，且只在主题里定义。系统“减少动画”时静止，文字在窄空间里会省略而不是溢出。
- **流光背景**（`lib/features/now_playing/flowing_light.dart`）：4 团径向渐变（不需要每帧算模糊）沿各自闭合路径漂移，整数圈数保证循环无缝；颜色取封面缩到 4×4 后的四象限均值，抬高饱和度并把亮度限在 0.36–0.64（灰色封面保持灰色）；切歌 700ms 过渡；Hi-Res 歌曲多一团淡金光。接在共用的 `PlayerBackground` 里，所以手机播放页、桌面展开页、桌面面板都有。
- **高级玻璃**：`GlassSurface`（标准模式下与原来的 Material 卡片完全一致，玻璃模式下半透明 + `BackdropFilter` + 顶部亮边 + 细描边）用于播放条、导航卡片、手机抽屉、桌面页面卡片和桌面播放面板；`AmbientBackdrop` 给玻璃提供可模糊的底光；`SeeThroughPages` 让页内 Scaffold/AppBar 透明；设置页的分组行也半透明（不叠模糊）。**范围**：设置页、均衡器页等从壳外 push 的路由页本身仍是实心 Scaffold，只有壳内的页面和卡片是玻璃。
- **设置**：`player.flowingLight`（默认 true）、`theme.material`（默认 standard，“高级玻璃”需要用户主动选）。
- **测试环境**：`test/flutter_test_config.dart` 对所有测试打开系统“减少动画”，否则无限循环的动画会让 `pumpAndSettle` 永远等不到结束；测动画本身的用例自己再把它关掉。
- 已在 API 37 模拟器（折叠屏展开态）看过：徽章两帧对比亮弧确实在转；玻璃模式下侧栏、页面卡片、播放条半透明且无异常日志。**手机竖屏的玻璃抽屉与播放条只有组件测试，没在设备上看。** 动画帧率/耗电未测。

### 2026-10-18 唱片机封面样式（分支 1.1.0.alpha）

- **做了什么**：`lib/features/now_playing/turntable_cover.dart`；`CoverShape` 新增 `turntable`，`PlayerArtwork` 里接入，所以手机播放页、桌面展开页、桌面面板的封面处都能用；设置“封面样式”现在三项（方形 / 圆形（旋转）/ 唱片机），**三项都去掉了图标**（三项带图标在窄屏装不下）。
- **几何**（`TurntableGeometry`，都是占正方形边长的比例）：唱片半径 0.43、圆心 (0.45, 0.56)；标签（封面）半径 0.265；主轴孔半径 0.026；唱臂转轴 (0.88, 0.10)、臂长 0.58。唱针落点由余弦定理从“转轴–圆心–唱针”三角形算出：从外圈 0.405 随进度移到内圈 0.30，摆幅约 20°；休止角 74°，唱针停在唱片外。整体仍在原封面的正方形里，只是唱臂占了原来空着的右上角。
- **打孔**：`TurntableHoleClipper` 用 `Path.combine(difference)` 把整块唱片（沟槽、标签、高光）按“圆减孔”裁剪，孔是真正透出背景的；阴影在孔的位置被挖掉，孔边另画一圈细线表示标签厚度。
- **动作**：唱片用 `AnimationController.unbounded` + 恒速模拟，暂停时换成 `FrictionSimulation` 减速而不是突然停；唱臂用另一个控制器（落下 850ms / 抬起 650ms，easeInOut）；切歌时唱臂抬起（280ms）再落下，封面在标签里交叉淡入，**同一个唱片机不重建**（`ValueKey('turntable')`）。唱臂只在自己的 `Consumer` 里监听播放位置，位置每 200ms 变化时只重绘唱臂。
- **颜色**：黑胶的黑与高光的白是“物体的颜色”不是界面色，定义在文件顶部两个常量里（与 Hi-Res 金色同类的 CLAUDE.md 例外）；唱臂用 ColorScheme 的 outline / outlineVariant / inverseSurface / primary，明暗两种主题都看过渲染图。
- **测试**：`test/features/now_playing/turntable_cover_test.dart`（几何、孔、标签居中、落针/抬起/切歌/暂停停转/减少动画）、设置持久化、桌面面板与手机播放页的集成。
- **没做/没测**：没在设备上看动起来的样子（只有渲染成图片的静态检查和组件测试里对角度、控制器值的断言）；帧率/耗电没测；唱片转一圈 4.5 秒、唱臂摆幅都是凭感觉定的，可能要调。

- **改动（同日追加）**：中心孔半径 0.026 → 0.034；唱片半径 0.43 → 0.405，外面加一圈黑色封套边框（`frameRadius` 0.43，`_FramePainter`，同样打孔）；唱针外圈落点 0.405 → 0.37 以留在唱片内。阴影改按边框画。

### 2026-10-18 1.2.0.alpha：缓存清理与原生桌面卡片准备

- 新建分支 `1.2.0.alpha`；Flutter package 版本设为 `1.2.0-alpha+1`。
- 按开发者决定，M0-2 格式专项验证和 M0-7 输出设备切换验证不列入本版本；播放器现有 FLAC/MP3 范围不扩张。
- 完成封面 `cover_state` 持久化：已缓存/无封面状态存入 Drift；写回前核对专辑仍指向同一代表文件版本，代表曲目或文件版本变化时复位。
- 每次扫描结束后清理封面缓存：保留当前专辑代表曲目的源版本与文件，移除已删除专辑、旧版本目录和同目录下失效的专辑文件；清理与图片生成共用串行队列。清理失败只记录警告，不中断曲库扫描。
- 后续卡片只做 macOS 与 Android 主屏幕原生 Widget，不做 Windows，也不做悬浮播放器。技术路线、共享快照和首版功能已记入 [`DESKTOP_WIDGETS.md`](DESKTOP_WIDGETS.md) 与 `PLAN.md` M9。
- 验证：`dart format` 完成；`flutter analyze` 无问题。本轮未运行测试。

### 2026-10-18 macOS 桌面卡片（SYS-11 / M9，分支 1.2.0.alpha）

- 加入并嵌入 `NyaPlayerWidget.appex`，支持小/中/大：左上圆角封面；小号基本控制，中号进度/随机/循环，大号当前队列（5 首/页、点播、当前项高亮与自动定位）。WidgetKit extension 要求 macOS 14，主应用原部署目标保留。
- `MacOSWidgetBridge` → 原生 App Group 原子 JSON + 封面文件；`AudioPlaybackIntent` 在 app 进程经 QueueController 控制播放，等待冷启动 ready，串行处理点击，过期队列点播拒绝。歌词/音频不复制到共享组。
- 修正上一轮缓存状态重置的 raw SQL 参数：`customStatement` 应传原始值，而不是 Drift `Variable` 包装。
- `flutter analyze` 零问题，Flutter 339 项测试通过；macOS Debug 构建与签名完整性检查通过，PlugInKit 已识别扩展；同权限沙盒应用的共享目录 JSON 读写通过；三种尺寸/明暗/空状态已用原生离屏渲染检查。
- 系统桌面宿主的实际点击、应用退出后的冷启动与多个卡片实例仍待验收。当前运行的旧 App 需要重启新版后发布组件状态，不能用静态预览代替实测。添加方法见 `DESKTOP_WIDGETS.md`。

### 2026-10-18 NyaPlayer 正式名称与分层图标（UI-21）

- 当时按开发者方向，双音符加顶部猫耳（后被下方 Material 标准音符方案替代），纯色扁平；先用内置 ImageGen 生成参考，再用共用矢量几何生成生产素材，避免参考图的像素明暗进入最终图形。两个 SVG 图层可独立编辑，禁止绘制拟物光影。
- macOS 接入 `NyaPlayerIcon.icon`，浅色、深色及系统着色原生渲染成功；分别传入两种系统 tint 参数确认颜色确实变化。图形层禁用 glass / specular / shadow / translucency，系统图标外壳由 macOS 决定。兼容 PNG 覆盖 16–1024px。
- **原生格式的坑**：本机 Xcode 26.3 的 Icon Composer 不接受可选的 `color-space-for-untagged-svg-colors: srgb` 字段，生成器省略该字段。默认 fill 与 dark/tinted 的值统一放入 `fill-specializations`（默认项不写 appearance），否则直接 fill 会遮盖特殊外观。编译与渲染已经核对。
- Android 图标分离背景、前景与单色图层；108dp 自适应画布，逐像素核对 66dp 圆形安全区，图形约 48.1 × 52.9dp。48/72/96/144/192px PNG 一起重建。
- macOS Product、CFBundleName、CFBundleDisplayName、CFBundleExecutable、scheme 和测试宿主改为 `NyaPlayer`；Android application label 使用 `@string/app_name`。bundle identifier、applicationId、Dart package 名保留，避免身份变化。
- `flutter build macos --debug`、`flutter build apk --debug --target-platform android-arm64` 均成功；`flutter analyze` 无问题；最终 `NyaPlayer.app` 签名完整性检查通过，Assets.car 含 21 项新图标资源；APK label 为 NyaPlayer，包内确认 v26/v33 adaptive icon 与 monochrome。Android 另存为 `build/releases/NyaPlayer-1.2.0-alpha-arm64-debug.apk`。
- 本轮未运行测试，未在系统设置/实际启动器手动切换主题图标；未重启当前正在运行的播放器。系统调色与裁剪依赖平台和启动器支持。


### 2026-10-18 图标改为 Material 标准音符（UI-21）

- 开发者否决自绘双音符与猫耳，改用 Flutter 自带 `Icons.music_note`（U+E415）。`tool/import_material_icon.swift` 用系统 CoreText 从 Flutter SDK 的 MaterialIcons-Regular.otf 提取标准轮廓，24px 原始边界 `(6, 3, 12, 18)`；保持原始比例并按可见边界居中，移除旧 SVG 图层与未采用的生成图片。
- 生产资源统一由 `tool/generate_app_icons.swift` 重建：macOS 分层包为背景 + 标准音符，保留默认/深色/系统着色；Android 前景、monochrome、自适应 XML 与 mdpi–xxxhdpi PNG 同步更新。Android 图形约 36.1 × 54.2dp，符合 66dp 圆形安全区。
- 保留 Material 字体随附许可及来源说明。重新导入与生成均不新增第三方依赖，不使用图像生成服务。
- macOS 与 Android arm64 Debug 构建成功，Icon Composer 原生默认/深色/着色导出成功；未运行测试，未重启播放器。保留此前要求：构建目录中的测试 widget 不留系统注册。


### 2026-10-18 Release 按系统 / 架构输出

- 按开发者要求先删除上一轮 Universal `build/macos/Build/Products/Release/NyaPlayer.app`，重新独立构建 arm64 / x86_64，不复用旧 Universal App；Android 也重新构建当前 1.2.0-alpha Release。
- 新增 `tool/build_release.py`，默认依次生成 `output/darwin-arm64/NyaPlayer.app`、`output/darwin-x86_64/NyaPlayer.app`、`output/android-armv8a/NyaPlayer.apk`；可传目标名只构建部分。`output/` 已加入 `.gitignore`，每个目录附应用版本 / 源码 commit 的 `build-info.json`。
- macOS 通过 `FLUTTER_XCODE_ARCHS` 分架构编译主应用、Rust 和 Widget。分发副本逐个检查 Mach-O，预编译框架的多余 slice 去掉后从内到外重新 ad-hoc 签名，保留 entitlement/identifier/flags。两份 App 各含 7 个 Mach-O，均只有目标架构，最终目录中的签名完整性通过。
- 三个 Release 构建均成功；Android APK 核对只含 arm64-v8a；Mac 文件夹约 92MiB / 93MiB，APK 约 62.8MB。构建目录测试 Widget 再次注销。未运行测试或启动新 App。
- 操作说明见 `BUILD_OUTPUTS.md`，中英文 README 已改用统一构建入口。


### 2026-10-18 内置字体资源与包体精简（SET-06）

- 原字体 9 个 TTF 共 56,321,000 字节，占 Mac Release 约 58%。移除 HarmonyOS Sans Medium、Noto Serif SC Bold，并把 EB Garamond 4 个静态字重替换为一个 400–700 可变字体；最终 4 个 TTF 共 32,075,052 字节（减少 43.0%）。
- 保留的 HarmonyOS Sans Regular/Bold、Noto Serif SC Medium 与旧提交的 SHA-256 完全一致。Noto 30,928 / Harmony 29,063 / Garamond 2,091 个字符均保留；没有按 UI 文案子集化，任意歌曲和歌词的原有字符覆盖不缩减。无衬线中等字重会匹配 Regular，中文衬线粗体改为字体引擎合成，EB Garamond 使用真实可变字重。
- FontTools 为现有素材制作工具，不新增应用依赖。新增 `tool/compact_fonts.py`，源文件 / 输出的 SHA-256、可变范围与字符数记录在 `assets/fonts/font-sources.json`，版权和三份协议仍随应用分发。现有字体资源测试名单跟随资源更新；本轮未运行测试。
- 比较过完整 Noto 可变字体与 CFF 编码，体积收益不合适，未作为生产资源；最终保留原 Medium 字形。所有候选只在临时目录，不打入 App。
- `flutter analyze` 无问题；macOS arm64 / x86_64 和 Android arm64-v8a Release 均构建成功并替换 `output/`，包内检查只含 4 份 TTF，合计字节符合预期，Mac 签名完整性通过，测试 Widget 注册已清理。
- 包体按文件逻辑字节计（十进制 MB）：arm64 Mac **96.4 → 72.2MB（−25.15%）**；Intel Mac **97.5 → 73.2MB（−24.87%）**；Android APK **62.8 → 47.9MB（−23.75%）**。重建方法见 `BUILD_OUTPUTS.md`；字体资源说明见 `assets/fonts/README.md`。


### 2026-10-18 桌面默认启动尺寸（UI-05 / M1-4）

- 按开发者提供的 Retina 截图，采用约 1288×852 逻辑像素的默认窗口外框。macOS NIB 初始尺寸同步调整，`MainFlutterWindow.applyInitialWindowSize()` 在初始化与 `applicationDidFinishLaunching` 后应用，启动时在当前屏幕 `visibleFrame` 内居中。
- 可用区域四周预留 8pt，较小显示器按可用宽高限制；内容最小 400×700 在小屏幕上也相应下调，避免最小限制把窗口推到屏幕外。不设置窗口最大限制；隐藏后从 Dock 恢复保留当前尺寸。`NYA_WINDOW_SIZE` 开发预览继续作为内容尺寸覆盖。
- macOS arm64 / x86_64 Release 构建成功，逐 Mach-O 单架构与签名检查通过，两份 App 已替换到 `output/`；未启动新 App 或修改当前安装副本。Android 本轮未重编译，预发布分支快照保留。
- 本轮未运行测试；构建目录的测试 Widget 注册再次清理。

### 2026-10-18 Android 严重问题记录：卡顿 / 切歌闪退 / 发热（未修复，待定位）

**现象（开发者反馈）**：Android 端卡顿、播放时切歌闪退、发热。

**解码路径核查结论：Android 没有使用硬件解码器。**
- 解码是纯软件：`rust/src/player/engine.rs` 的 `open_decoder` 调用 rodio `Decoder`（内部为 symphonia，只启用 FLAC / MP3 feature，见 `rust/Cargo.toml`），全程在 Rust 侧 CPU 完成。
- 之后串联 `UniformSourceIterator` 重采样（`output_source`），再经 `EqSource` 做 10 段 biquad EQ，最后由 cpal 的 AAudio 后端输出。硬解（MediaCodec）的链路在本项目中不存在。
- Dart 侧 `pubspec.yaml` 没有 `just_audio` / `media_kit` / `video_player` 等播放插件，`android/app` 中也没有 ExoPlayer / MediaPlayer / MediaCodec 的引用。`audio_service` 只负责系统媒体会话与通知，不解码。
- 因此“发热、卡顿”的首要怀疑对象是软解加逐样本 EQ 的 CPU 占用，尤其是高码率 FLAC、高采样率（hi-res）文件要重采样时。这一点尚未实测。

**切歌闪退的待查线索（均为推断，未复现）**
- 每次切歌都会走 `start_at`：`cancel_all` 后新建 `Player::connect_new`，并重新 `open_decoder`。如果切换与 `poll` 的 `on_track_started` 或 `refresh_next` 交错，可能存在竞态。
- Android 上 AAudio 输出流出错会触发 `device_lost`，随后走 `recover_device` 重开输出流。流的关闭与重开时机是否与切歌冲突，需要日志确认。
- Rust 侧的 panic 与日志通过 `android_log.rs` 输出到 logcat，JNI 初始化在 `android_context.rs`。闪退时应优先看 logcat 中的 panic / `nya_core` 标签，确认是 Rust panic、AAudio 错误还是 JVM 层异常。

**2026-10-18 真机核查结果（M10-1，已取代下方的推断）**：闪退的根因不在播放内核，而在发布包的资源压缩。
- 系统 DropBox 里有 4 条 `data_app_crash`（18:34，版本 1.2.0-alpha 发布包，`user/release-keys`），堆栈均为 `IllegalArgumentException: Invalid notification (no valid small icon)`，抛在 audio_service 调用 `NotificationManager.notify` 时。每次都是播放后 2.5–4.7 秒，与切歌时更新媒体通知吻合。
- 原因：`lib/main.dart` 里 `androidNotificationIcon: 'drawable/ic_stat_music'` 是按字符串名称在运行时查找的资源，代码里没有直接引用。`output/android-armv8a/NyaPlayer.apk`（17:47 发布构建，commit 587bf4a）的 `resources.arsc` 中**没有 `drawable/ic_stat_music`**，已被资源压缩删除，查找结果为 0，通知抛异常，进程被杀。
- 为什么 debug 复现不了：当前 debug 包（`build/app/outputs/flutter-apk/app-debug.apk`）保留了该资源，播放和切歌正常，AAudio 流一直处于 STARTED，没有重建或错误。
- 因此“切歌闪退”与 EQ / 解码无关。发热与卡顿仍待测量（当时 app 进程 CPU 约 62%，AP 57°C，皮肤温度 39.1°C，线程状态 1）。
- **已修复**：新增 `android/app/src/main/res/raw/keep.xml`，`tools:keep="@drawable/ic_stat_music"`。重新构建发布包后资源表中已有该图标，安装到三星 S9180（Android 15）后：媒体通知正常发出（标题、transport 类别、NO_CLEAR），系统 `MediaOngoingActivity`（胶囊）出现，播放期间没有新的 `data_app_crash`。
- 待观察：systemui 的 `MediaDataManager` 报 `FileNotFoundException` 指向 `files/covers/...`，可能是封面文件尚未生成或系统无权读取应用私有目录，需要确认胶囊上的封面是否显示。
- 日志文件：`scratchpad/logcat_m10_1.txt`（19:06–19:07）。测试曲已推到手机 `/sdcard/Music/NyaTest/`。

**下一步建议**
1. 真机（非模拟器）用 `adb logcat` 抓闪退瞬间的日志，区分 Rust panic、AAudio 错误和 JVM 异常。（已完成：结果见上，闪退是 JVM 层的通知异常。）
2. 用 Android Studio Profiler 或 `top -H` 查 CPU 占用，区分解码、EQ 与 UI 线程的开销；对比 EQ 全平直与关闭时的发热差异，以确定是否要做 bypass 或降低 EQ 计算频率。
3. 如果确认软解开销过大，再评估 Android 硬解路径（例如通过平台通道接 MediaCodec），这属于架构变更，需先在 TECH_SPEC 附录 A 记录并征得开发者同意。

**macOS 对照（同一天补充）**
- 解码与 EQ 与 Android 共用 `engine.rs`：同样是 rodio / symphonia 软解加 biquad EQ，macOS 上也没有硬解。因此“发热”的理论成因相同，只是桌面 CPU 余量大，目前未观察到卡顿或发热。输出后端为 CoreAudio（经 cpal），不是 AAudio。
- 切歌闪退 macOS 未复现，与 Android 的崩溃路径不能直接等同，需单独验证。
- 退出慢是另一条链路，与播放内核无关，属于应用层关闭顺序：
  1. `AppDelegate.applicationShouldTerminate` 把退出挂起，调用 `prepareToExit`，最多等 3 秒兜底（`DispatchQueue.main.asyncAfter`）。
  2. Dart 侧 `lib/main.dart` 的 `onExit` 依次 `await`：`widgets.close()`（经 channel 通知原生桌面卡片）、`flushStores()`（设置、收藏、播放状态落库）、`handler.stop()`，然后 `handler.dispose()`、`engine.dispose()`。
  3. Rust 引擎没有主动关闭流程：`Command::Shutdown` 从未发送，`engine.dispose()` 只调用 `playerPause()`，引擎线程随进程退出。
- 因此退出慢有两个可能：Dart 任一步骤迟迟不返回（最坏被 3 秒兜底截断），或 `flushStores` 落库耗时。尚未用日志确认，建议在 `onExit` 各步前后加耗时日志，并在 `prepareToExit` 完成时打印时间戳，区分是 Dart 还是 Swift 侧等待。


### 2026-10-18 M10-2：Android Media3 播放内核与设置切换

- 通知修复：`res/raw/keep.xml` 保留 `ic_stat_music`，发布包的媒体胶囊恢复显示（见上一节）。
- 新增 `AndroidPlayerEngine.kt`（Media3 ExoPlayer 1.11.1）和 Dart 侧 `lib/services/player/android_player_engine.dart`，实现 `PlayerEngine` 全部方法；行为对齐 Rust 引擎：连续失败 5 首停止、循环模式、`reorder` 保持播放位置。
- 本轮暂缓：EQ（M10-4，原生侧收到 `setEqualizer` 后忽略）、音频焦点与拔耳机（M10-5，仍由 `AudioFocusCoordinator` 处理，ExoPlayer 关闭了自动焦点）。
- 设置：新增 `playback.core`（`system` / `rust`），默认 `system`；设置页仅 Android 显示该选项，切换后重启生效。引擎在 `settings` 打开后创建。
- 测试：因设置页新增一项，库文件夹、语言、最短时长相关的 widget 测试改为先滚动再点击（懒加载列表）；全部 339 项通过。
- 待查：真机 debug 版中间出现一次 Flutter 断言红屏 `'_dependents.isEmpty': is not true`（framework.dart:6281），播放未中断，logcat 未抓到堆栈。需要确认复现步骤（当时在做什么操作）。

### 2026-10-18 播放页滑动卡顿与手感（Android，release 包实测）

- 现象：开着“流光背景”和“模糊封面背景”时全屏播放页滑动明显卡；关掉后好很多。上划播放列表动画不顺；封面→歌词滑动很快，歌词→封面正常。
- 测量方法：`adb shell input swipe` 自动滑动，同时读 `dumpsys SurfaceFlinger --latency <图层>` 的呈现时间戳（`gfxinfo` 对 Flutter 的 Impeller 渲染不统计帧，不能用）。脚本在会话 scratchpad 的 `measure.py`。
- 基线（release，流光与模糊都关）：页面左右滑 302 帧、列表上划 714 帧，帧间隔 p99 = 8.3ms（120Hz），最大 16.7ms，没有超过 20ms 的帧。所以此时不是掉帧，是手感问题。开启流光与模糊的对比数据尚未量到（测量中途被打断，且我临时把手机上的“流光背景”打开了，需要关回去）。
- 手感问题的原因：
  1. `PageView` 默认销毁屏幕外页面，每次滑向歌词页都要从头构建整页歌词（所有行加 GlobalKey），构建发生在手指滑动中，所以“封面→歌词”会突然加速，反方向页面很轻则正常。
  2. 上划列表时每次动画状态变化都会 `setState`，重建整个播放页。
  3. 列表松手后用固定时长曲线，不继承手指速度。
- 修改：`now_playing_page.dart` 两页用 `AutomaticKeepAlive` 保持存活并开启 `allowImplicitScrolling` 提前构建相邻页，翻页物理改为更硬的弹簧；队列浮层只重建自己（`ListenableBuilder`），并用 `RepaintBoundary` 缓存阴影与圆角；`queue_sheet.dart` 松手后用带手指速度的弹簧收尾。339 项测试通过。
- 待真机复测。模糊封面背景（sigma 48 全屏）与流光仍是开启时的主要开销，下一步考虑用更小的预缩放图或预先模糊的位图替代实时 `ImageFiltered`。

#### 播放页性能实测结果与修复（同日，三星 S9180，release，120Hz）

帧间隔均值 / 超过 20ms 的帧占比（`adb input swipe` 自动滑动，SurfaceFlinger 呈现时间戳）：

| 版本 / 组合 | 页面左右滑 | 上划播放列表 |
|---|---|---|
| 旧包，模糊封面开 + 流光开 | 16.5ms / 7% | 20.8ms / 49% |
| 旧包，两者都关 | 8.4ms / 0% | 8.3ms / 0% |
| 页面/列表优化后，模糊开 + 流光开 | 15.4ms / 5% | 19.2ms / 33% |
| 同上，模糊关 + 流光开 | 8.4ms / 0% | 8.3ms / 0% |
| 同上，模糊开 + 流光关 | 9.2ms / 0% | 14.5ms / 16% |
| **预模糊封面后，模糊开 + 流光开** | **8.3ms / 0%** | **8.6ms / 0%（1 帧）** |

- 结论：单独的流光很便宜；开销来自 `player_background.dart` 里的全屏实时 `ImageFilter.blur`（sigma 48），叠加流光动画时更重。
- 修复：新增 `lib/features/now_playing/pre_blurred_cover.dart`。封面缩到 160px 解码、只模糊一次生成 `ui.Image`（sigma 7px，约等于原来的 48dp），之后背景只是一张双线性拉伸的位图。换歌时重新生成，生成前显示渐变底色。`cover_art_test.dart` 相应改为检查 `PreBlurredCover` 与 `RawImage`。339 项测试通过。
- 另外（上一节）：页面保活与预构建、队列浮层局部重建与弹簧松手，对“模糊开 + 流光开”的改善有限（均值 16.5→15.4ms），真正的收益来自预模糊。
- 注意：测试结束时手机上的“模糊封面”和“流光背景”都保持开启（应用默认值），开发者原来是手动关掉的。

#### 播放页常驻动画造成整页 120fps 重绘（同日，三星 S9180，release）

- 发现：全屏播放页静置（甚至暂停）时，SurfaceFlinger 呈现约 100–120fps；歌曲列表页只有 4–5fps。播放时进程 CPU 约 62–70%（单核计），其中 `1.raster` 28–40%，解码线程（`ExoPlayer` + `MediaCodec`）合计不到 8%。也就是说发热主要来自界面渲染，不是解码。
- 原因：只要有一个 `Ticker` 在运行（流光的 `repeat()`、Hi-Res 徽章的 `repeat()`），Flutter 就会在每个 vsync 提交整帧；Impeller（Vulkan）本机日志显示 `enable_vulkan_partial_repaint:0`，没有局部重绘，整页（全屏模糊位图、渐变、歌词）每帧都被重新光栅化。
- 无效的尝试：给两个动画的画布加 `ThrottledListenable` 限到 30Hz / 1Hz，出帧率与 CPU 都没降（Ticker 仍在每帧触发提交），已撤销。
- 修复（开发者决定“流光改成静态装饰，每次换歌换一下”）：
  1. `FlowingLight` 去掉循环动画，灯光相位由歌曲 id 决定（黄金比例步进），换歌时 1.4 秒缓动到新位置后停下；减少动画或 `animate: false` 时直接跳到新位置。播放页背景与毛玻璃环境光（`ambient_backdrop.dart`）都传入 `seed: track?.id`。
  2. Hi-Res 徽章的扫光改为出现或换歌时播放一圈（6 秒）后停下，不再常驻。
  3. 设置里 `flowingLightHint` 与 `surfaceMaterialHint` 的中文、英文说明已改成“光斑、换歌换位置”；**日、韩、德、西、法、俄的说明仍是旧的“缓慢流动”，待校对后更新**。
- 复测（同一首歌、播放中、播放页）：出帧率 ~100–120fps → 4–5fps；进程 CPU 约 62–70% → 约 19%（`raster` 28–40% → 3.9%，解码线程合计约 7%）。
- 教训：Flutter 页面上的任何“常驻小动画”都会让整页持续重绘，不能靠限制画布重绘频率解决，只能让 Ticker 停下来。

#### 修复：播放页默认停在歌词页（回归，同日）

- 现象：冷启动或切歌后打开播放页，默认停在歌词页；播放中歌词每推进一行也会把页面带过去。
- 原因：为消除“封面→歌词”滑动突然加速，我让两页保活并提前构建（`allowImplicitScrolling` + `AutomaticKeepAlive`）。歌词页用 `Scrollable.ensureVisible` 滚到当前行，该方法会滚动**所有外层滚动容器**，包括左右翻页的 `PageView`；歌词页提前构建后，每次定位都会把翻页容器带到歌词页。
- 修复：`lyrics_view.dart` 新增 `_revealIn`，用 `RenderAbstractViewport.getOffsetToReveal` 只滚动歌词自己的 `ScrollController`；`adaptive_shell_test.dart` 新增回归测试（手机尺寸，歌词行推进后 `PageView` 仍在第 0 页）。撤掉修复后该测试会失败（`Expected 0, Actual 1.0`），有修复时通过。
- 真机复测：冷启动→播放页在封面页；播放 14 秒歌词推进数行仍在封面页；切到下一首仍在封面页。343 项测试通过。
- 教训：给页面加“提前构建/保活”时，要检查里面是否有会影响外层滚动的调用（`Scrollable.ensureVisible`、`ScrollController` 共享等）。


### 2026-10-18 M10-6：macOS 改用系统播放内核；两端 EQ 默认关闭

- macOS 新增 `MacPlayerCore.swift`（AVAudioEngine：播放节点 → `AVAudioUnitEQ` 10 段 → 主混音；无缝播放靠在剩余约 6 秒时把下一首排在同一个节点后面，采样率或声道数不同的文件在边界重建图，会有短暂间隙；输出设备变化时重建并从原位置继续）和 `MacPlayerEngine.swift`（通道转接，协议与 Android 相同）。Dart 侧 `AndroidPlayerEngine` 改名 `PlatformPlayerEngine`，Android 与 macOS 共用；设置里的“播放内核”选项在 macOS 也显示（系统 / Rust），切换后重启生效。
- 验证：Swift 核心单独编译成命令行脚本（静音），真实音频文件 20 项断言全过（播放、暂停保持位置、跳转、拖动含暂停时拖动、预排后准点自动切歌、队列移动/插入/删除/重排、跳过坏文件、单曲循环、播完事件、播完后重播）；再启动调试版 App，窗口里播放中、进度 0:19→0:26、歌词同步推进。
- 两端 EQ 默认关闭：`EqState.enabled` 默认改为 `false`（`settings_persistence_test.dart` 相应更新）。已保存的设置不受影响。
- **事故（我的失误，需开发者决定怎么清理）**：上面启动调试版时我想用临时 `HOME` 隔离数据，但没有生效，调试钩子对**真实的 macOS 数据库** `~/Library/Application Support/com.kazuma.nyaplayer/nyaplayer.sqlite` 做了改动：① `library_roots` 多了 id 4 = `.../NyaPlayer/test_music`；② 曲库从 151 首变成 157 首（多出的 6 首都在 test_music）；③ `playback_state` 里已保存的播放队列被替换成整个曲库（当前曲目和进度丢失；此前恢复的队列也是 151 首，估计同样是整库）。设置表（含 `eq.state`）没有迹象被改动。我准备只删除 id 4 那一行（应用自己的“移除目录”也只是这一步，下次启动扫描会连同孤立的专辑、艺术家一并清掉那 6 首），该操作被权限拦截，我没有绕开，等开发者决定：可以在应用设置的“音乐文件夹”里自己移除 test_music，或授权我执行这条 DELETE。当时数据库的副本在会话 scratchpad 的 `dbcopy/nyaplayer.sqlite`。
- 教训：调试钩子（`NYA_MUSIC_DIR`、`NYA_PREVIEW`）会写真实数据，不要在真实 HOME 上运行；需要隔离时给调试版加专用的数据目录开关，而不是依赖环境变量 `HOME`。

#### 歌词页上下滑动偶发卡顿的排查（同日，三星 S9180，release）

- 开发者反馈：上下快速滑动歌词页有时流畅有时卡，怀疑发热；开发者自己用 GPU 面板做“持续疯狂滑动”：模糊封面与流光都开 GPU 约 90%，只开任意一个约 80%，全关也约 80%。
- 我的测量（`adb input swipe` 150ms 快速上下甩动，SurfaceFlinger 帧时间戳）：测试时手机热状态为 3（severe，AP 约 48–51°C，且在充电）。同样的手势：**设置页稳定 8.3ms（120fps）**，歌词页均值 10–18ms、最长 25–33ms，且各轮在“流畅/较卡”之间交替。设置页较轻，不能单独证明“不是发热”（热限频时重页面更容易掉）；但歌词页明显比同样条件下的普通长列表重。
- 已试：① 去掉每行歌词的 `AnimatedOpacity`（50 多个离屏图层），改为文字颜色透明度，译文也用 `AnimatedDefaultTextStyle` 做颜色动画：超过 20ms 的帧略减（每轮 3–6 → 2–4），均值变化不大；② 临时去掉 `FadedEdges` 的 `ShaderMask`：帧间隔几乎没变。①保留，②已撤销。
- 结论：背景效果（模糊封面、流光）在歌词页只多占约 10 个百分点 GPU；歌词页自身滚动加 120Hz 的开销是底数。热限频、GPU 面板自身开销都会放大波动。
- **结案（开发者确认）**：手机本身没问题，卡顿是测试时持续抓包过多、手机发热造成的；不再改歌词列表。已保留的改动：歌词行不再用 `AnimatedOpacity`，改用文字颜色透明度。


### 2026-10-18 收尾：徽章扫光 1.5 秒、清理 Mac 记录、重建并安装

- Hi-Res 徽章的扫光整段时长由 6 秒改为 **1.5 秒**（边缘高光走一圈，光带在前 0.75 秒扫过徽章主体），仍然是出现或换歌时播放一次后停下。
- 清理 Mac 上多出的记录（开发者授权）：已备份数据库后，只删除 `library_roots` 里 `id=4`（`.../NyaPlayer/test_music`）。曲库里那 6 首会在应用下次启动的扫描中被清掉；已保存的播放队列在之前那次调试运行中已被替换成整个曲库，无法恢复原顺序和当前进度。
- 重建三个平台的 release，并把 macOS（Apple Silicon）版复制到 `/Applications`（旧版本先备份到会话临时目录，再覆盖）。


### 2026-10-18 歌词页 GPU 占用高的真正原因：Impeller（已换 Skia）

- 起因：开发者用 GPU 面板对比——同样“疯狂拖动歌词和界面”，SaltPlayer 约 30%，我们约 80%。此前我把卡顿归因于“发热/抓包”，这个对比推翻了它。
- 方法：手机的 GPU 忙碌度可直接读 `/sys/class/kgsl/kgsl-3d0/gpu_busy_percentage` 和 `devfreq/cur_freq`（adb shell 可读）；设备端循环 `input swipe` 连续上下滑，每 0.1 秒采样一次。真实工作量 ≈ 忙碌度 × 当前频率（忙碌度是相对当前频率的百分比，频率不同不能直接比）。脚本在会话 scratchpad 的 `gpu.py`。
- 结果（同一手机，连续滑动 10 秒）：

| 场景 | GPU 忙碌度 | 频率 | 工作量 |
|---|---|---|---|
| SaltPlayer 歌词页 | 52% | 220MHz | 约 114 |
| 我们的设置页（Impeller，普通长列表对照） | 67% | 288MHz | 约 193 |
| 我们的歌词页（Impeller） | 80% | 679MHz | 约 543 |
| 歌词页去掉渐隐遮罩 | 85% | 629MHz | 约 527 |
| 歌词页去掉页面预构建 | 96% | 548MHz | 约 523 |
| **歌词页（Skia）** | **63%** | **293MHz** | **约 184** |
| **正式构建（Skia）** | **64%** | **283MHz** | **约 182** |

- Skia 版帧间隔：歌词页快速上下甩动 8 轮每轮都是 8.3ms，翻页与上划播放列表也是 8.3ms，0 掉帧；外观与 Impeller 一致，截图对照未见差异。
- 结论与改动：问题在 Impeller 后端本身（遮罩、预构建都不是原因）。`AndroidManifest.xml` 加 `io.flutter.embedding.android.EnableImpeller=false`，Android 改用 Skia；已重建并安装到手机，GPU 工作量约为原来的三分之一。风险：Flutter 以后可能移除 Skia，升级时需重新核对；macOS 暂未改。
- 之前“手机没问题、是抓包发热”的结案不准确，应以本节为准；Impeller 在歌词页的开销也部分解释了此前的发热。


### 2026-10-18 Skia 之后的进一步优化：让静态背景被光栅缓存

- 基线（Skia，连续滑动 10 秒，工作量 = 忙碌度 × 频率）：设置页 46、歌曲列表 33、歌词页 191。歌词页是唯一的异类。冷启动只有约 1 秒的忙碌；播放稳态进程 CPU 约 1–6%；封面页静置播放 GPU 为 0。这些不需要动。
- 拆分：背景换成普通渐变且关掉流光时歌词页只有 56，歌词列表本身很轻；只开流光是 144；两者都开是 183。**开销在背景上**，而流光和模糊封面在播放期间根本不变，却被每帧重新绘制。
- 无效的尝试（已撤销）：给每行歌词加 `RepaintBoundary`（183）、去掉渐隐遮罩（176）。
- 有效的修改：Skia 的光栅缓存只会缓存被提示为“复杂”的画布。① `FlowingLight` 的 `CustomPaint` 加 `isComplex: true`（只开流光 144 → 31）；② 模糊封面背景原来由 `Transform.scale` + 图片 + 两层 `ColoredBox` 拼成，改成 `PreBlurredCover` 的一个 `CustomPaint`（`PreBlurredBackdropPainter` 一次画完放大的封面和遮罩色，同样 `isComplex: true`）。`cover_art_test.dart` 相应改为读画布和 `overlays`。
- 最终（模糊封面 + 流光都开，也是默认配置）：歌词页连续滑动工作量 **183 → 65**（Impeller 时是 543，SaltPlayer 是 114）；GPU 忙碌度 30%、频率 220MHz（最低档）；歌词快速上下甩动 5 轮帧间隔都是 8.3ms；换歌后背景、光斑配色和位置都正确更新；外观与之前一致。
- 这些优化依赖 Skia 的光栅缓存；Impeller 没有这套机制，`isComplex` 提示在 Impeller 下不起作用。

### 2026-10-18 普通 FLAC 的银黑徽章

- 需求：普通 FLAC（无损但不是 Hi-Res，例如 16bit/44.1kHz）也要有 Hi-Res 同款特效，配色用银黑，处理逻辑相同。
- 实现：`quality_badge.dart` 里把金色徽章泛化成 `_SweepBadge(silver: bool)`；`isPlainFlac(track)`（codec 为 FLAC 且不是 Hi-Res）走银黑版，Hi-Res 走金色版，MP3 仍是原来的普通小标签。银黑配色放在 `hires_colors.dart` 的 `HiResColors.silver`（近黑底、银色边、浅银高光），图标用 `Icons.graphic_eq`（Hi-Res 才用金色 Hi-Res Audio 标志）。
- 动画逻辑与 Hi-Res 完全一致：徽章出现或换歌时播放一次（总长 1.5 秒：边缘高光走一圈，光带在前 0.75 秒扫过主体），之后停下，没有常驻 Ticker；系统“减少动画”时直接静止。同一个组件在 Hi-Res 与普通 FLAC 之间切歌时也会重播。
- 验证：344 项测试通过（新增“普通 FLAC 用银黑徽章、不是小标签”“银色与金色徽章尺寸和圆角一致”，并把原来以 FLAC 16/44.1 代表普通小标签的几个用例改为用 MP3）；真机屏幕录像抽帧确认扫光按“光带划过主体 → 银色高光绕边一圈 → 停下”进行。
