<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=12,20,24&height=180&section=header&text=NyaPlayer&fontSize=64&fontAlignY=38&desc=%E7%BA%AF%E6%9C%AC%E5%9C%B0%E3%80%81%E7%A6%BB%E7%BA%BF%E7%9A%84%20Material%203%20%E9%9F%B3%E4%B9%90%E6%92%AD%E6%94%BE%E5%99%A8&descAlignY=60&fontColor=ffffff" alt="NyaPlayer" width="100%"/>

**无广告 · 无账号 · 无联网 · 只有你的音乐**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Rust](https://img.shields.io/badge/Rust-000000?style=for-the-badge&logo=rust&logoColor=white)](https://www.rust-lang.org)
[![Material 3](https://img.shields.io/badge/Material%20Design-3-6750A4?style=for-the-badge&logo=materialdesign&logoColor=white)](https://m3.material.io)
[![Offline](https://img.shields.io/badge/100%25-%E7%A6%BB%E7%BA%BF-2ea44f?style=for-the-badge)](#-隐私)

[English](README.md) · **简体中文**

</div>

---

## ✨ 特性

| | |
|---|---|
| 🎵 **稳定播放** | FLAC（含 24bit / 高采样率）与 MP3，支持无缝播放，由 Rust 音频内核驱动 |
| 🖼️ **封面与歌词** | 读取内嵌封面与歌词，支持滚动高亮、点击跳转、双语（原文 + 翻译）歌词 |
| 🎨 **Material 3 界面** | 浅色 / 深色、壁纸动态取色、跟随封面配色，手机、平板、桌面自适应布局 |
| 📱 **系统集成** | 后台播放、媒体通知、锁屏 / 耳机 / 媒体键控制、音频焦点处理 |
| 🎚️ **10 段均衡器** | 31 Hz – 16 kHz，±12 dB，内置与自定义预设，各平台听感一致 |
| 🔒 **隐私优先** | 不发起任何网络请求，不收集任何数据，曲库永远留在你的设备上 |

<sub>**不做：** 流媒体、在线刮削、标签编辑、视频、发烧级 bit‑perfect 输出、账号与云同步。</sub>

## 🖥️ 支持平台

| 平台 | 最低版本 | 架构 | 状态 |
|:--|:--|:--|:--|
| 🤖 **Android** | Android 12（API 31） | ARMv8‑A（`arm64-v8a`） | ✅ 主平台 |
| 🍎 **macOS** | macOS 15 Sequoia | Intel · Apple Silicon | ✅ 已支持 |
| 🍏 **iOS** | iOS 18 | arm64 | 🎯 优先适配（下一个） |
| 🪟 **Windows** | Windows 10 | x64 · arm64 | 🛠️ 次级适配（计划中） |
| 🐧 **Linux** | Ubuntu 22.04 | x64 · aarch64 | 🛠️ 次级适配（计划中） |

> 不计划适配 HarmonyOS。
> 适配难度与优先级见 [`docs/PLATFORM_SUPPORT.md`](docs/PLATFORM_SUPPORT.md)。

## 🧱 技术栈

| 层 | 方案 |
|---|---|
| 界面 | Flutter（stable）· Dart 3 · Material 3 |
| 音频内核 | Rust crate `nya_core`：`symphonia` 解码、`rodio`/`cpal` 输出、`biquad` 均衡器、`lofty` 标签 |
| 桥接 | [`flutter_rust_bridge`](https://github.com/fzyzcjy/flutter_rust_bridge) 2.13（经 Cargokit 构建） |
| 系统控制 | `audio_service` · `audio_session` |
| 状态管理 / 路由 | `flutter_riverpod` · `go_router` |
| 主题 | `dynamic_color` |

架构：**UI**（`features/*`）→ **应用服务**（`services/*`）→ **数据**（`data/*`）。UI 只通过 `AudioHandler` 控制播放，Rust 引擎由 `PlayerEngine` 接口隔离。详见 [`TECH_SPEC`](docs/TECH_SPEC.md)。

## 🚀 快速开始

**前置条件：** Flutter stable（Dart ≥ 3.13）、通过 [`rustup`](https://rustup.rs) 安装的 Rust stable，以及目标平台的工具链（Xcode、Android SDK + NDK 等）。

```bash
git clone <this-repo> && cd NyaPlayer
flutter pub get

# 运行
flutter run -d macos
flutter run --release -d <android-device-id>

# 提交前检查
dart format . && flutter analyze && flutter test
cargo test --manifest-path rust/Cargo.toml

# 发布构建
flutter build apk --release --target-platform android-arm64
flutter build macos --release
```

> Flutter 桌面端不支持跨操作系统交叉编译：Windows 版需在 Windows 上构建，Linux 版需在 Linux 上构建（或使用 CI）。

## 📚 文档

| 文档 | 内容 |
|---|---|
| [`REQUIREMENTS`](docs/REQUIREMENTS.md) | 需求声明：带编号与优先级的功能需求、MVP 与验收标准 |
| [`TECH_SPEC`](docs/TECH_SPEC.md) | 技术要求：依赖、架构、播放引擎、EQ、平台配置、数据设计 |
| [`PLATFORM_SUPPORT`](docs/PLATFORM_SUPPORT.md) | 平台基线、适配难度与优先级 |
| [`PLAN`](docs/PLAN.md) | 里程碑与任务清单 |
| [`PROGRESS`](docs/PROGRESS.md) | 当前进度记录 |

## 🔒 隐私

NyaPlayer 不发起任何网络请求，也不收集任何数据。曲库数据与封面缓存仅保存在本地。

## 作者

1. **Kazuma-Kobayashi01** — 第一作者、项目维护者。
2. **Claude** — 第二作者，AI 辅助开发。
3. **Codex** — 第三作者，AI 辅助开发。

## 📄 许可证

待定。

<div align="center">
<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=12,20,24&height=100&section=footer" width="100%" alt=""/>
</div>
