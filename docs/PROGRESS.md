# 施工记录（PROGRESS）

> 最后更新：2026-10-18 · 写给接手开发的人（或 AI）。先读本文，再读 `.claude/CLAUDE.md`、`docs/TECH_SPEC.md`、`docs/PLAN.md`、`docs/REQUIREMENTS.md`。
> 本文只记录**当前状态、决定、坑和下一步**；需求和技术规范以另外三份文档为准，冲突时以 TECH_SPEC 为准。

## 0. 一眼看完

- **项目**：NyaPlayer（文档代号 Lyra）——本地离线、无广告的 Material 3 音乐播放器，Flutter，Android + macOS。曲库只有 **FLAC + MP3**，歌词和封面**全部内嵌**，双语歌词是 P0。
- **分支与仓库**：开发成果在 `1.0.1.universal`，2026-10-18 开发者要求合并至 `main` 并推送 `git@github.com:Kazuma-Kobayashi01/NyaPlayer.git`；具体提交与分支状态以 `git log` / `git status` 为准。接手时 HEAD 为 `11abb4d`，工作区干净。
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
  - **内置字体**：非衬线 = HarmonyOS Sans SC（官方包，三字重，**未修改**——协议禁止修改，所以不能裁剪子集；协议要求的显著声明在“关于”页和 README，协议文本进了许可页）；衬线 = 开发者电脑上的 EB Garamond 变量字体切出 400/500/600/700 静态字重（拉丁）+ Noto Serif SC 500/700（中文，思源宋体，OFL）。macOS 自带的 Songti SC 是专有字体不能打包，所以宋体用思源宋体——**如果你想要别的宋体请告诉我**。衬线整体放大 1.08 倍并加重一档（歌词通过 `FontTuning` 一并放大）。设置里新增“使用内置字体”开关（默认开；关＝回到打包字体之前的系统字体配置，已有测试锁定）。内置字体家族名加 `Nya ` 前缀，避免与同名系统字体互相遮蔽——这一点是测试暴露的真实隐患：Android 系统衬线回退列表里本来就有 “Noto Serif SC”，不加前缀的话“关闭内置字体”时也会解析到打包的那份。字体共约 54MB，macOS Debug 包约 257MB；字符覆盖已用 fonttools 验证（简/繁/假名/日文汉字齐全，仅 〜 ♪ ♡ 三个符号在 HarmonyOS 中缺，回退系统字体）。
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

> **剩余量（按顶层复选框统计，2026-10-18）**：MVP 的 M0–M6 共 65 项，20 项已勾选，45 项未勾选；分项：M0 13、M1 3、M2 6、M3 6、M4 5、M5 7、M6 5。整个计划（再含 M7/M8）共 83 项，23 项已勾选，60 项未勾选。该数字用于看清待验收清单，不能当成工作量百分比：未勾选项中有部分代码或子项已完成，条件任务 M0-10 也不一定需要实施。

- **M0**：M0-1、M0-R1、M0-R2 已勾选。M0-2/3/4 的 macOS 部分已有实测结果（`SPIKE_REPORT.md`），因 Android 等覆盖未完成，整项保持未勾选。
  - 待做：M0-2 更多格式规格及 Android、M0-3 Android EQ 与完整预设覆盖、M0-4 MP3 gapless/真实连续专辑与 Android、M0-5 后台/通知栏/耳机键、M0-6 音频焦点、M0-7 输出设备切换（含 Android 真机）、M0-8 Android 文件权限（只给 `READ_MEDIA_AUDIO`）、M0-9 标签（lofty 已验证两首真实文件；还要用开发者更多真实曲库样本、粗测 1000 文件耗时）、M0-11 FTS5、M0-12 M3 Expressive 调研、M0-14 Release 包体与 192k 在 Android 的 CPU、M0-13 补全 `docs/SPIKE_REPORT.md`（已有阶段记录，尚非最终验收报告）。
- **M1**：外壳、路由、日志、主题大部分、i18n 骨架、macOS window_manager 和关闭拦截已做；未做：drift 数据库（M1-5）、设置/收藏持久化（M1-6）、Android 曲库访问授权流程及真机验证（M1-3 媒体服务清单/audio_service 已配置）、ja 语言。
- **M2 曲库**：M2-6 的提取、缓存和显示已完成，数据库状态/清理待接；真实扫描与 drift 未做。**M3 播放核心**、M4 系统集成、M5 歌词加载、M6 持久化等仍待推进；M3/M6 的 Rust 部分已超前完成。
- **M4 本次验收边界**：macOS 关窗后台播放、Dock/菜单栏恢复、菜单控制及 ⌘Q 退出均已由开发者实测；⌘Q 后声音停止、菜单栏图标消失。M4-5 仍需 M3-9 的持久化后才能满足“退出前保存状态”；M4-6 的控制中心/第三方软件已通过，物理媒体键仍待核对。Android 系统服务已接线但本轮按要求没有编译或上真机，M4 父任务不勾选。

## 6. 待开发者决定 / 授权

1. **关闭 macOS App Sandbox：已授权并完成**（2026-10-18）。两份 entitlements 均设为 `false`，Debug 可读取真实曲库；不需要再次询问本次相同改动的授权。
2. 测试音乐：本轮开始时 `test_music/` 有两首（FLAC 十年、MP3 缭花绚烂），这两首已获听感反馈。期间开发者新增 `那颗星梦见的春日 - 鸣潮先约电台&jixwang&小林未郁.flac`（界面显示 24bit/48kHz），该文件未纳入本轮正式听感验收。其他规格、真实连续专辑仍需补充。
3. 2026-10-18 已获“提交”指令，本轮累计代码与文档纳入同一次提交；主作者使用现有 Git 身份 Kazuma-Kobayashi01，协作署名依次为 Claude、Codex。worktree 已在前序工作中清理，不 push。

## 7. 下一步建议（按顺序）

### 2026-10-19 计划

1. 继续打磨 UI 并做视觉验收：桌面全屏放大/退出按钮尺寸、侧栏始终展开、不同窗口尺寸下右侧播放面板布局。上述两项实现与 129 个 Flutter 测试已在 10 月 18 日完成；继续根据实际使用反馈调整控件间距、对齐与层次。
2. 之后按 MVP 依赖顺序推进 M0 收尾 → M1 drift/设置持久化 → M2 曲库扫描与查询 → M3 队列接入/状态恢复 → M4 Android 系统媒体验证 → M5 歌词加载和视图 → M6 EQ 控制与预设。
3. Android 编译与真机验证仍按之前约定延后；进入 Android 验收前先完成 macOS UI 与当前 M0 可做部分。

> 这是一份待执行计划，不代表 10 月 19 日的工作已经完成。全计划仍有 71 个未勾选顶层任务，其中 MVP 范围 M0–M6 有 55 项；按里程碑拆分见 §5 的剩余量统计。

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
- Android 输出设备切换（拔耳机/蓝牙）后的流重建逻辑已写（`recover_device`），**未在真机验证**；系统媒体服务和共享 AudioHandler 已接入，但尚未进行本轮 Android 编译/真机验证。`AudioFocusCoordinator` 仍未实现（M4-2）。
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
