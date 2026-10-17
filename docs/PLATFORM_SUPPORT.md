# 平台适配清单（开发者版）

> 文档版本：v2.0 · 2026-10-18 · 读者：开发者本人
> 配套文档：[`REQUIREMENTS.md`](./REQUIREMENTS.md)、[`TECH_SPEC.md`](./TECH_SPEC.md)、[`PLAN.md`](./PLAN.md)
> 面向用户的支持列表见根目录 [`README.md`](../README.md)。

本文回答三个问题：**要支持哪些平台、各自适配难度多大、先做哪个**。标注 🔍 的是我凭经验判断、动手前需要先核实的点（尤其是第三方插件的平台支持情况，版本变化快）。

---

## 1. 支持基线

| 平台 | 系统基线 | 架构 | Rust target | 音频后端（cpal） |
|---|---|---|---|---|
| Android | Android 12（`minSdk 31`） | `armv8-a`（`arm64-v8a`） | `aarch64-linux-android` | AAudio |
| macOS | macOS 15 Sequoia | Intel / arm64 | `x86_64-apple-darwin`、`aarch64-apple-darwin` | CoreAudio |
| Windows | Windows 10 | x64 / arm64 | `x86_64-pc-windows-msvc`、`aarch64-pc-windows-msvc` | WASAPI |
| Linux | Ubuntu 22.04（glibc ≥ 2.35） | x64 / aarch64 | `x86_64-unknown-linux-gnu`、`aarch64-unknown-linux-gnu` | ALSA |
| iOS | iOS 18 | arm64 | `aarch64-apple-ios`（模拟器：`aarch64-apple-ios-sim`） | CoreAudio |

不计划适配 HarmonyOS 和 Android 32 位（`armeabi-v7a`）。

---

## 2. 难度与优先级总览

| 优先级 | 平台 | 适配难度 | 当前状态 | 主要原因 |
|---|---|---|---|---|
| **优先** | Android 12+ | ★☆☆☆☆ 已完成 | 主平台，开发中 | 主力设备 |
| **优先** | macOS 15（Intel + arm64） | ★☆☆☆☆ 已完成 | 开发中 | 本机可直接跑；仅需补 Intel 构建验证 |
| **优先** | iOS 18 | ★★★☆☆ | 未开始（Android/macOS 稳定后立即开始） | 同属 Apple 工具链、Rust/插件支持成熟；难点在沙盒文件访问与签名 |
| 次级 | Windows 10+ | ★★★☆☆ | 未开始 | 难点在系统媒体控制插件与无本机调试环境 |
| 次级 | Linux（Ubuntu 22.04） | ★★★☆☆ | 未开始 | 难点在 MPRIS、aarch64 构建与发行版碎片 |
| 不计划 | HarmonyOS | — | 不适配 | — |

> 优先级依据：① 本机能否直接调试（Apple 平台免虚拟机）；② 第三方插件是否开箱即用；③ 使用人群规模。
> 难度星级仅衡量**在已有 Android/macOS 代码基础上**的新增工作量。

---

## 3. 各平台详细评估

### 3.1 Android 12+（优先，已完成）

- 已有：Cargokit 编译 Rust，`audio_service` 前台服务，`dynamic_color` 壁纸取色（API 31 起全员可用）。
- 只发 `arm64-v8a`：在 `android/app/build.gradle` 中用 `ndk { abiFilters += "arm64-v8a" }` 限制，并从 `rust_builder` 的 Cargokit 配置去掉 `armv7`/`x86_64` target，减小包体与编译时间。
- 待办：无阻塞项。

### 3.2 macOS 15（优先，已完成）

- 已有：窗口管理（`window_manager`）、控制中心/媒体键（`audio_service`）。
- 待办：
  - `MACOSX_DEPLOYMENT_TARGET` 提升到 `15.0`（`macos/Runner.xcodeproj` 与 `Podfile` 两处）。
  - 验证 Intel 构建：`flutter build macos` 在 arm64 机器上默认产出当前架构；发布时需 Universal 或分别打包，Cargokit 需同时编译 `x86_64-apple-darwin` 与 `aarch64-apple-darwin`。

### 3.3 iOS 18（优先，难度 ★★★）

**好处**：Rust 源码零改动；`cpal` CoreAudio 后端同 macOS；`audio_service`、`audio_session` 官方支持 iOS；Cargokit 支持 iOS。

**工作项**

| 工作项 | 难度 | 说明 |
|---|---|---|
| `flutter create --platforms=ios .` 生成 runner | 低 | 部署目标设为 `18.0` |
| 后台播放 | 低 | `Info.plist` 增加 `UIBackgroundModes = audio`；`AVAudioSession` 类别为 `playback`（`audio_session` 配置） |
| 锁屏/控制中心 | 低 | `audio_service` 自动接 `MPNowPlayingInfoCenter` / `MPRemoteCommandCenter` |
| **曲库文件访问（核心难点）** | 中高 | iOS 沙盒无法像 Android/macOS 那样任意递归目录。选目录需使用 security-scoped bookmark，扫描前 `startAccessingSecurityScopedResource`，并持久化 bookmark；🔍 `file_picker` 在 iOS 选目录返回路径的持久性需实测。备选：用户通过「文件」App 把音乐导入应用 Documents 目录，由应用扫描 |
| 签名与真机调试 | 中 | 免费开发者账号签名 7 天过期；上架/TestFlight 需付费账号 |
| `window_manager` | 低 | 仅桌面使用，需用 `Platform.isIOS` 守卫或条件导入 |
| UI 适配 | 低 | 现有手机布局可复用；注意安全区域与 iOS 返回手势 |
| 动态取色 | 低 | `dynamic_color` 在 iOS 无壁纸色，回退到封面取色/种子色（已有降级路径则无需改） |

**风险**：文件访问方案决定扫描器（LIB-01/02）的改动量，建议动手前先做 1 天 spike。

### 3.4 Windows 10+（次级，难度 ★★★）

**好处**：Flutter、Cargokit、`cpal`（WASAPI）、`window_manager`、`path_provider`、`dynamic_color`（读取系统强调色）均支持；Rust 代码无需改动。

**工作项**

| 工作项 | 难度 | 说明 |
|---|---|---|
| `flutter create --platforms=windows .` | 低 | arm64 构建需 Visual Studio 安装 ARM64 工作负载 |
| Rust 构建 | 低 | Cargokit 在 Windows 上可用；需 `rustup target add aarch64-pc-windows-msvc`；🔍 arm64 交叉编译需 Flutter 版本已支持 Windows arm64 |
| **系统媒体控制（SMTC）** | 中 | 🔍 `audio_service` 不支持 Windows。需引入 `smtc_windows` 之类的插件，或把媒体键/SMTC 做成独立适配层，接入现有 `AudioHandler` |
| 窗口行为 | 低 | 复用 `window_manager`；托盘与关窗隐藏行为按需 |
| 文件访问 | 低 | 无沙盒，选目录用 `file_picker`；注意长路径与 UNC/盘符路径 |
| 路径与编码 | 低 | 路径分隔符统一走 `package:path`；Windows 文件名 UTF-16，确认 Rust `lofty` 读取含中日文路径正常 |
| **本机无法调试** | 中 | 需要 Windows 虚拟机（UTM/Parallels/VMware，选 Win11 ARM）或 GitHub Actions `windows-latest`（仅编译，无法听音） |
| 打包 | 中 | MSIX 或 Inno Setup；arm64 与 x64 各一份 |

### 3.5 Linux · Ubuntu 22.04（次级，难度 ★★★）

**好处**：Rust 代码无需改动；`cpal` ALSA 后端成熟；文件访问无沙盒。

**工作项**

| 工作项 | 难度 | 说明 |
|---|---|---|
| `flutter create --platforms=linux .` | 低 | |
| 构建依赖 | 低 | `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libasound2-dev` |
| **系统媒体控制（MPRIS）** | 中 | 🔍 `audio_service` 不支持 Linux，需 `audio_service_mpris` 之类的适配包，或自行经 D-Bus 暴露 `org.mpris.MediaPlayer2` |
| 音频输出 | 中 | `cpal` 走 ALSA，在 PipeWire/PulseAudio 桌面上通过兼容层工作；🔍 需在 Ubuntu 22.04 实机验证无爆音、设备热切换行为 |
| aarch64 构建 | 中 | 需 aarch64 机器、`qemu` 或 GitHub 的 arm64 runner；`cpal`/ALSA 在交叉编译时需 aarch64 的 `libasound2-dev` |
| glibc 基线 | 中 | 为保证 Ubuntu 22.04 可运行，**必须在 22.04（或更老）环境中构建**，不能用新系统产出再拿到旧系统跑 |
| **本机无法调试** | 中 | Mac 上用 UTM/Parallels 装 Ubuntu 22.04 arm64 虚拟机（可直接验证 aarch64）；x64 靠 CI 编译 |
| 打包 | 中 | AppImage / `.deb` / tar.gz，Flatpak 视需要 |

---

## 4. 本机（macOS）能做与不能做的事

Flutter 桌面构建**不支持跨操作系统交叉编译**：

| 目标 | 在 Mac 上能否直接 `flutter build` | 做法 |
|---|---|---|
| Android / macOS / iOS | ✅ | 本机 |
| Windows | ❌ | Windows 虚拟机，或 GitHub Actions `windows-latest` |
| Linux | ❌ | Ubuntu 22.04 虚拟机/容器，或 GitHub Actions `ubuntu-22.04`（及 `ubuntu-22.04-arm`） |

在 Mac 上仅检查 Rust 代码能否通过目标平台的类型检查（不产出可用二进制）：

```bash
rustup target add x86_64-pc-windows-msvc aarch64-apple-ios
cargo check --manifest-path rust/Cargo.toml --target aarch64-apple-ios
```

> Windows/Linux 目标涉及 C 依赖（`alsa-sys` 等）时，`cargo check` 可能因缺少系统头文件失败，属正常现象，以 CI 为准。

建议用 GitHub Actions 矩阵做**编译 + 单元测试**，真机/虚拟机做**听感与系统集成验证**。

---

## 5. 推荐实施顺序

1. **优先平台收尾（Android、macOS）**：Android 仅 arm64；macOS 部署目标 15.0 + Intel 构建验证。
2. **平台抽象**：先把「系统媒体控制」「选目录/文件访问」「窗口管理」三处平台差异收敛为接口（`AudioHandler` 已是入口），否则后续每加一个平台都会改业务代码。
3. **优先：iOS**：先做 1 天 spike 验证目录授权与 bookmark 持久化，通过后再铺开。
4. **次级：Windows**：搭虚拟机 + CI，接入 SMTC。
5. **次级：Linux**：Ubuntu 22.04 虚拟机，接入 MPRIS，最后补 aarch64 与打包。

## 6. 通用注意事项

- 每新增平台，先在 CI 里让 `flutter analyze` + `flutter test` + `cargo test` 通过，再谈运行。
- `flutter_rust_bridge` 的 Dart 与 Rust 版本必须一致（当前 `2.13.0`），升级需同步。
- 平台差异代码一律用 `Platform.isXxx` 守卫或条件导入，不要让桌面插件（`window_manager`）在移动端被调用。
- 新增平台前，先改本文与 `TECH_SPEC.md`，再改代码（与项目既有规则一致）。
