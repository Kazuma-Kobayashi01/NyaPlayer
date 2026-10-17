# M0 技术验证阶段报告

> 更新：2026-10-18 · 分支 `1.0.1.universal`
> 本文是阶段记录，不代表 M0 整体验收通过。任务进度以 PLAN 复选框为准。

## 1. 本轮范围与环境

- 任务：M0-2、M0-3、M0-4 的 macOS 部分；关闭 App Sandbox 是实听的前置条件。
- 开发者已明确授权将 DebugProfile / Release 两份 entitlements 的 `com.apple.security.app-sandbox` 改为 `false`。Debug 构建成功，`codesign` 核对实际签名中的值为 `false`；Release 本轮未构建。
- 启动：`LANG=en_US.UTF-8 NYA_MUSIC_DIR="$PWD/test_music" flutter run -d macos`，未设置 `NYA_VOLUME=0`。
- CoreAudio 设备查询：默认输出 HUAWEI FreeBuds 5i，双声道、44.1kHz、F32、缓冲范围 14–1024 帧；内置扬声器默认 48kHz。引擎按已打开设备的配置进行格式转换，沿用既有的缓冲范围适配。
- 听感由开发者实际确认；进度、界面及自动化测试由代理检查。

## 2. M0-2 格式与播放控制：部分通过

| 素材 | macOS 结果 | 证据 |
|---|---|---|
| `十年 - 陈奕迅.flac`，192kHz / 24bit | 正常出声 | 开发者确认“能听到，音质正常”；播放进度与内嵌歌词更新 |
| `缭花绚烂.mp3`，320kbps | 正常出声、跳转后正常 | 暂停状态下从约 0:40 拖动至 1:36，恢复后推进至 1:57；开发者确认声音及跳转正常 |

EQ 管线修正后已重新构建应用；开发者复测当前应用 EQ 调整正常。独立 Rust 引擎短时播放同一 FLAC 的位置持续推进，未发出引擎错误。

自动化补充：192kHz 单声道正弦转换为 48kHz 双声道后，时长/样本数在一个立体声帧误差内，左右声道一致；1kHz EQ +6dB 的稳态增益误差 < 0.2dB。

待测：FLAC 16/24bit 的其他采样率、MP3 CBR/VBR 的明确覆盖、Android 真机。当前设备默认 44.1kHz，不将离线 48kHz 测试写成实际扬声器试听结果。

## 3. M0-3 EQ：修正顺序，macOS 基础复测通过

发现原实现为 `EqSource(Decoder)`，后由 rodio mixer 转换设备格式，EQ 系数实际按音源采样率计算，与 TECH_SPEC §4.3 / §5.1 要求不符。

说明差异并获开发者同意后，修正为：

```
Decoder → UniformSourceIterator(已打开设备的声道数、采样率)
        → EqSource → Tracked → rodio Player → mixer
```

使用已有 rodio API，不新增依赖，不修改 `rust/src/api/` 或 FRB 生成接口。每首歌和设备恢复时重新取设备配置；mixer 后续格式转换在相同采样率下直通。

新增测试验证：192kHz→48kHz 的时长与 EQ 中心频率；192kHz 音源转换到 22.05kHz 输出时，16kHz 频段应跳过；44.1kHz→48kHz 后高频段保持生效。

试听中曾报告“原音继续、又从头响起一路”。当时代理另起过一次 5 秒出声 `engine_smoke`，与应用并行，污染了听感测试。诊断进程结束、确认只剩一个应用进程后，开发者重新调整 EQ，确认“这次没有重复，EQ 调整也正常”。该次并行诊断不作为内核故障复现，也不据此声称修复了重复播放 bug。后续听感测试只保留一路音源。

待测：全部预设及频段的完整听感覆盖、Android 实听。

## 4. M0-4 无缝：自制连续 FLAC 通过 macOS 实听

- 离线测试使用已有 FLAC 夹具 `rust/tests/fixtures/sine_44k_16bit_mono.flac.bin`：250ms、44.1kHz、16bit、440Hz（110 个完整周期）。
- 两次独立解码，经输出格式转换、EQ 平坦旁路、Tracked 与 rodio 顺序队列，在 44.1kHz 和 48kHz 输出下逐样本核对：未插入静音或丢失样本；边界相邻帧变化 < 0.02，最终换曲 token 正确。
- 实听素材生成在 `/private/tmp/nyaplayer-m0-gapless/`：`01-continuous.flac`、`02-continuous.flac`，各 5 秒、44.1kHz / 16bit / 双声道，440Hz，峰值约 0.1。按整段 10 秒的连续相位生成，只在整段首尾各淡入/淡出 100ms，5 秒分割点不淡化。Python 标准库写 PCM WAV，macOS 自带 `afconvert -f flac -d flac` 编码，不新增项目依赖。
- 退出原应用后，用同一应用加载该目录；开发者从第一首开始、EQ 平坦且不循环，确认“切换连续，没有可听见的缝隙”。

待测：真实连续专辑、MP3 编码器延迟/填充裁剪、Android 及设备变化场景。上述离线队列测试不代替设备音频回调的实测。

## 5. 本轮检查与其余 M0 项

- `dart format .`：完成；只额外格式化了被忽略的构建工具产物，Dart 源文件无改动。扫描 `build/` 时有 lint include 解析提示，后续分析正常。
- `flutter analyze`：零问题。
- `flutter test`：75 通过。
- `cargo fmt`：完成。
- `cargo clippy --all-targets -- -D warnings`：通过。
- `cargo test`：32 通过、2 ignored；新增 4 个引擎管线/边界测试。
- macOS Debug：修正 Rust 后重新构建并启动成功。

M0-5/6/7/8/9/11/12/14 仍需继续验证；M0-10 按 PLAN 为条件性 P2。M0-13 最终报告与 TECH_SPEC 全面回填尚未完成，本轮只记录已获得的证据。

未解决的调试阻断问题：恢复真实曲库后出现原生崩溃。系统报告 `nyaplayer-2026-10-18-002343.ips` 显示主线程 `EXC_BAD_ACCESS / SIGSEGV`，首帧为 Flutter `AccessibilityBridge::CreateRemoveReparentedNodesUpdate`，随后为 `CommitUpdates` / `FlutterViewController updateSemantics:`；此前日志持续出现 `Failed to update ui::AXTree`，UI 自动化也有陈旧窗口绑定。崩溃栈不能证明 Rust 音频错误，仍须排查页面/歌词语义树与 Flutter 无障碍桥，不能将本轮记录视作整体稳定性验收。暂不再读取 UI 自动化语义树，未禁用系统无障碍能力或更改相关权限。

本轮后段开发者新增第三首 FLAC（那颗星梦见的春日，界面显示 24bit/48kHz），未取得该文件单独的听感验收结果。

构建另提示本地 `nya_core` 插件尚不支持 Swift Package Manager，目前未处理。

### 后续补充：同行双语内嵌歌词（2026-10-18）

- 直接读取 `test_music/` 两首 FLAC 的 Vorbis Comment `LYRICS`：《小小奇迹》共 66 行，其中 42 组原文 + 中译；《打上花火》共 60 行，其中 44 组原文 + 中译。
- 两者均不是重复时间标签的分行双语，而是在单个时间标签内用 **U+2009 THIN SPACE** 分隔。旧 LrcParser 未拆分该字符，原译被作为一个正文块显示。
- 新解析器保留原时间戳，将细空格前后映射到 `LyricLine.text / translation`。本地额外测试逐组核对全部 86 组正文与译文，均一致；原始歌词只留在用户素材和会话临时文件中，未提交歌词全文。
- 合成测试覆盖其他分隔符、普通词间空格/制作信息保护、同时间戳与续行，以及完整歌词/预览的翻译开关。全量 Flutter 120 个测试通过。此结果只验证上述两首的歌词形态，不替代 M0-9 的完整曲库与读取性能验收。

命令行 `cargo run --example devices` 会直接用 rodio 默认 2048 帧尝试打开设备，仍可能在 FreeBuds 5i 上报缓冲范围错误；该例子未调用引擎的 `output_buffer_size()`，不能据此判断实际应用输出失败。终端沙盒内的 CoreAudio 查询、FLAC 编码器枚举亦受限，相关系统工具需在获准的沙盒外环境执行。
