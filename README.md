<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=12,20,24&height=180&section=header&text=NyaPlayer&fontSize=64&fontAlignY=38&desc=A%20local%2C%20offline%20Material%203%20music%20player&descAlignY=60&fontColor=ffffff" alt="NyaPlayer" width="100%"/>

**No ads. No accounts. No network. Just your music.**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Rust](https://img.shields.io/badge/Rust-000000?style=for-the-badge&logo=rust&logoColor=white)](https://www.rust-lang.org)
[![Material 3](https://img.shields.io/badge/Material%20Design-3-6750A4?style=for-the-badge&logo=materialdesign&logoColor=white)](https://m3.material.io)
[![Offline](https://img.shields.io/badge/100%25-Offline-2ea44f?style=for-the-badge)](#-privacy)

**English** · [简体中文](README.zh-CN.md)

</div>

---

## ✨ Features

| | |
|---|---|
| 🎵 **Reliable playback** | FLAC (incl. 24‑bit / hi‑res) and MP3 with gapless playback, powered by a Rust audio core |
| 🖼️ **Cover art & lyrics** | Reads embedded artwork and lyrics, with scrolling highlight, tap‑to‑seek and bilingual (original + translation) lines |
| 🎨 **Material 3 design** | Light / dark themes, wallpaper‑based dynamic color, cover‑derived palettes, adaptive layouts for phone, tablet and desktop |
| 📱 **System integration** | Background playback, media notifications, lock‑screen / headset / media‑key controls, audio focus handling |
| 🎚️ **10‑band equalizer** | 31 Hz – 16 kHz, ±12 dB, built‑in and custom presets — identical sound on every platform |
| 🔒 **Privacy first** | Zero network requests, zero telemetry. Your library never leaves your device |

<sub>**Not planned:** streaming, online metadata scraping, tag editing, video, audiophile bit‑perfect output, accounts and cloud sync.</sub>

## 🖥️ Supported platforms

| Platform | Minimum version | Architectures | Status |
|:--|:--|:--|:--|
| 🤖 **Android** | Android 12 (API 31) | ARMv8‑A (`arm64-v8a`) | ✅ Primary |
| 🍎 **macOS** | macOS 15 Sequoia | Intel · Apple Silicon | ✅ Supported |
| 🍏 **iOS** | iOS 18 | arm64 | 🎯 Priority (next) |
| 🪟 **Windows** | Windows 10 | x64 · arm64 | 🛠️ Secondary (planned) |
| 🐧 **Linux** | Ubuntu 22.04 | x64 · aarch64 | 🛠️ Secondary (planned) |

> HarmonyOS is not planned.
> Developer-side difficulty and priorities live in [`docs/PLATFORM_SUPPORT.md`](docs/PLATFORM_SUPPORT.md) (Chinese).

## 🧱 Tech stack

| Layer | Choice |
|---|---|
| UI | Flutter (stable) · Dart 3 · Material 3 |
| Audio core | Rust crate `nya_core` — `symphonia` decode, `rodio`/`cpal` output, `biquad` EQ, `lofty` tags |
| Bridge | [`flutter_rust_bridge`](https://github.com/fzyzcjy/flutter_rust_bridge) 2.13 (built via Cargokit) |
| System controls | `audio_service` · `audio_session` |
| State / routing | `flutter_riverpod` · `go_router` |
| Theming | `dynamic_color` |

Architecture: **UI** (`features/*`) → **services** (`services/*`) → **data** (`data/*`). The UI controls playback only through `AudioHandler`; the Rust engine sits behind the `PlayerEngine` interface. See [`TECH_SPEC`](docs/TECH_SPEC.md).

## 🚀 Getting started

**Prerequisites:** Flutter stable (Dart ≥ 3.13), Rust stable via [`rustup`](https://rustup.rs), and the toolchain for your target platform (Xcode, Android SDK + NDK, …).

```bash
git clone <this-repo> && cd NyaPlayer
flutter pub get

# Run
flutter run -d macos
flutter run --release -d <android-device-id>

# Checks
dart format . && flutter analyze && flutter test
cargo test --manifest-path rust/Cargo.toml

# Release builds
flutter build apk --release --target-platform android-arm64
flutter build macos --release
```

> Flutter desktop builds can't be cross‑compiled across operating systems: build Windows on Windows and Linux on Linux (or use CI).

## 📚 Documentation

> Project docs are written in Chinese.

| Document | Contents |
|---|---|
| [`REQUIREMENTS`](docs/REQUIREMENTS.md) | Requirements with IDs and priorities, MVP and acceptance criteria |
| [`TECH_SPEC`](docs/TECH_SPEC.md) | Dependencies, architecture, playback engine, EQ, platform config, data design |
| [`PLATFORM_SUPPORT`](docs/PLATFORM_SUPPORT.md) | Platform baselines, porting difficulty and priority |
| [`PLAN`](docs/PLAN.md) | Milestones and task list |
| [`PROGRESS`](docs/PROGRESS.md) | Current progress log |

## 🔒 Privacy

NyaPlayer never makes network requests and collects nothing. Library data and cover caches are stored locally only.

## Contributors

1. **Kazuma-Kobayashi01** — primary author and maintainer.
2. **Claude** — AI development assistance.
3. **Codex** — AI development assistance.

## 📄 License

To be decided.

<div align="center">
<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=12,20,24&height=100&section=footer" width="100%" alt=""/>
</div>
