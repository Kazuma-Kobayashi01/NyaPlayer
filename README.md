<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=12,20,24&height=180&section=header&text=NyaPlayer&fontSize=64&fontAlignY=38&desc=A%20local%2C%20offline%20Material%203%20music%20player&descAlignY=60&fontColor=ffffff" alt="NyaPlayer" width="100%"/>

**No ads. No accounts. No network. Just your music.**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Rust](https://img.shields.io/badge/Rust-000000?style=for-the-badge&logo=rust&logoColor=white)](https://www.rust-lang.org)
[![Material 3](https://img.shields.io/badge/Material%20Design-3-6750A4?style=for-the-badge&logo=materialdesign&logoColor=white)](https://m3.material.io)
[![Offline](https://img.shields.io/badge/100%25-Offline-2ea44f?style=for-the-badge)](#-privacy)
[![License: MIT](https://img.shields.io/badge/License-MIT-22C55E?style=for-the-badge)](LICENSE)

[![Android](https://img.shields.io/badge/Android-Media3_ExoPlayer-3DDC84?style=for-the-badge&logo=android&logoColor=white)](docs/TECH_SPEC.md)
[![macOS](https://img.shields.io/badge/macOS-AVAudioEngine-000000?style=for-the-badge&logo=apple&logoColor=white)](docs/TECH_SPEC.md)
[![FRB](https://img.shields.io/badge/Flutter_Rust_Bridge-2.13-2563EB?style=for-the-badge)](docs/TECH_SPEC.md)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-00A6A6?style=for-the-badge)](docs/TECH_SPEC.md)
[![Drift](https://img.shields.io/badge/DB-Drift_%2F_SQLite-0EA5E9?style=for-the-badge)](docs/TECH_SPEC.md)
[![Lofty](https://img.shields.io/badge/Tags-Lofty-F59E0B?style=for-the-badge)](docs/TECH_SPEC.md)

**English** · [简体中文](README.zh-CN.md)

</div>

> [!NOTE]
> **Usable alpha (1.2.0-alpha).** NyaPlayer plays and manages a local library on **Android** and **macOS** today.
> It is developed and tested on a Galaxy phone (Android 15) and an Apple Silicon Mac. There is no store release yet: you build it yourself, see [Getting started](#-getting-started). Rough edges and [known limitations](#-known-limitations) remain.

---

## ✨ Features

| | |
|---|---|
| 🎵 **Playback** | FLAC (incl. 24‑bit / hi‑res) and MP3 with gapless playback, decoded by the platform itself: Media3 ExoPlayer on Android, AVAudioEngine on macOS |
| 📚 **Library** | Scans your music folders; browse by songs, albums, artists, folders; playlists, favourites, full‑text search, exclude folders, hide very short tracks |
| 🖼️ **Cover art & lyrics** | Embedded artwork and lyrics or `.lrc` files (UTF‑8, GBK, Shift‑JIS), scrolling highlight, tap‑to‑seek, bilingual lines (original + translation) |
| 🏅 **Quality badges** | A gold **Hi‑Res** badge and a silver‑black **FLAC** badge show the real format and sample rate, each with a one‑off sweep of light |
| 🎨 **Material 3 design** | Light / dark, wallpaper‑based dynamic colour, blurred cover backdrop with coloured light, square / spinning‑disc / turntable covers, several progress‑bar styles, adaptive layouts for phone, tablet, foldable and desktop |
| 📱 **System integration** | Background playback, media notification (works with Samsung's media capsule), lock‑screen / headset / media‑key controls, audio focus; macOS menu‑bar menu and desktop widgets |
| 🎚️ **10‑band equalizer** | 31 Hz – 16 kHz, ±12 dB, built‑in and custom presets, off by default |
| 🌍 **Languages** | English, 简体中文, 繁體中文, 日本語, 한국어, Deutsch, Español, Français, Русский |
| 🔒 **Privacy first** | Zero network requests, zero telemetry. Your library never leaves your device |

<sub>**Not planned:** streaming, online metadata scraping, tag editing, video, audiophile bit‑perfect output, accounts and cloud sync.</sub>

## 🖥️ Supported platforms

| Platform | Minimum version | Architectures | Status |
|:--|:--|:--|:--|
| 🤖 **Android** | Android 12 (API 31) | ARMv8‑A (`arm64-v8a`) | ✅ Usable alpha · primary platform |
| 🍎 **macOS** | macOS 15 Sequoia | Apple Silicon · Intel | ✅ Usable alpha (Apple Silicon tested; the Intel build is produced but not yet run) |
| 🍏 **iOS** | iOS 18 | arm64 | 🎯 Priority (next) |
| 🪟 **Windows** | Windows 10 | x64 · arm64 | 🛠️ Secondary (planned) |
| 🐧 **Linux** | Ubuntu 22.04 | x64 · aarch64 | 🛠️ Secondary (planned) |

> HarmonyOS is not planned.
> Developer-side difficulty and priorities live in [`docs/PLATFORM_SUPPORT.md`](docs/PLATFORM_SUPPORT.md) (Chinese).

## 🚧 Known limitations

- **Android equalizer.** The Media3 core does not apply the equalizer yet. To use it, switch **Settings → Playback core** to *Rust core* and restart the app (macOS applies the equalizer natively).
- **Android is `arm64-v8a` only**, and release builds are signed with the debug key for now.
- **macOS gapless:** two files with different sample rates or channel counts are joined with a very short gap, because the audio graph has to be rebuilt between them.
- **Android renders with Skia**, not Impeller (see below). Re‑check the `EnableImpeller` flag in `AndroidManifest.xml` whenever Flutter is upgraded.
- Not built yet: Android home‑screen widget, sleep timer, ReplayGain.

## ⚡ Performance notes

Measured on a Galaxy S23‑class phone (Snapdragon 8 Gen 2, Android 15), release build:

- Frantically scrolling the lyrics costs about **one eighth** of the GPU work it did at first (GPU busy × clock: 543 → 65), at steady 8.3 ms frames.
- Playing a song with the player page open uses roughly **1–6 %** of one CPU core.
- On Android, Skia drew the same screens with about a third of the GPU work Impeller needed. The static backdrop is painted once and cached, and nothing animates forever while a song plays.

Method, numbers and the dead ends are in [`docs/PROGRESS.md`](docs/PROGRESS.md).

## 🧱 Tech stack

| Layer | Choice |
|---|---|
| UI | Flutter (stable) · Dart 3 · Material 3 |
| Playback — Android | Media3 ExoPlayer 1.11, using the device's own decoders |
| Playback — macOS | `AVAudioEngine` + `AVAudioPlayerNode` + `AVAudioUnitEQ` (Swift) |
| Rust core `nya_core` | Tags and lyrics (`lofty`), legacy‑encoding repair (`encoding_rs`), and the optional Rust playback core (`symphonia` decode, `rodio`/`cpal` output, biquad EQ) |
| Bridge | [`flutter_rust_bridge`](https://github.com/fzyzcjy/flutter_rust_bridge) 2.13 (built via Cargokit) |
| System controls | `audio_service` · `audio_session` |
| State / routing | `flutter_riverpod` · `go_router` |
| Storage | `drift` on SQLite (FTS5 search) |
| Theming | `dynamic_color` |

Architecture: **UI** (`features/*`) → **services** (`services/*`) → **data** (`data/*`). The UI controls playback only through `AudioHandler`; every audio core sits behind the `PlayerEngine` interface (`PlatformPlayerEngine` for Media3 and AVAudioEngine, `RustPlayerEngine` as the fallback). See [`TECH_SPEC`](docs/TECH_SPEC.md).

## 🚀 Getting started

**Prerequisites:** Flutter stable (Dart ≥ 3.13), Rust stable via [`rustup`](https://rustup.rs), and the toolchain for your target platform (Xcode, Android SDK + NDK, …).

```bash
git clone git@github.com:Kazuma-Kobayashi01/NyaPlayer.git && cd NyaPlayer
flutter pub get

# Run
flutter run -d macos
flutter run --release -d <android-device-id>

# Checks
dart format . && flutter analyze && flutter test
cargo test --manifest-path rust/Cargo.toml

# Release builds
python3 tool/build_release.py
# output/darwin-arm64/NyaPlayer.app
# output/darwin-x86_64/NyaPlayer.app
# output/android-armv8a/NyaPlayer.apk
```

**Installing a build**

- **Android:** sideload `output/android-armv8a/NyaPlayer.apk`, then grant the audio permission when asked.
- **macOS:** copy the `.app` for your Mac to *Applications*. It is ad‑hoc signed, so on first launch use right‑click → *Open* (or clear the quarantine flag with `xattr -dr com.apple.quarantine`).

> Flutter desktop builds can't be cross‑compiled across operating systems: build Windows on Windows and Linux on Linux (or use CI).
> More on the build outputs: [`docs/BUILD_OUTPUTS.md`](docs/BUILD_OUTPUTS.md).

## 📚 Documentation

> Project docs are written in Chinese.

| Document | Contents |
|---|---|
| [`REQUIREMENTS`](docs/REQUIREMENTS.md) | Requirements with IDs and priorities, MVP and acceptance criteria |
| [`TECH_SPEC`](docs/TECH_SPEC.md) | Dependencies, architecture, playback engines, EQ, platform config, data design |
| [`PLATFORM_SUPPORT`](docs/PLATFORM_SUPPORT.md) | Platform baselines, porting difficulty and priority |
| [`BUILD_OUTPUTS`](docs/BUILD_OUTPUTS.md) | How the release builds are produced and checked |
| [`DESKTOP_WIDGETS`](docs/DESKTOP_WIDGETS.md) | Desktop widget design and native route |
| [`PLAN`](docs/PLAN.md) | Milestones and task list |
| [`PROGRESS`](docs/PROGRESS.md) | Working log: decisions, measurements, pitfalls |

## 🔒 Privacy

NyaPlayer never makes network requests and collects nothing. Library data and cover caches are stored locally only.

## Contributors

1. **Kazuma-Kobayashi01** — primary author and maintainer.
2. **Claude** — AI development assistance.
3. **Codex** — AI development assistance.

## 📄 License

Licensed under the [MIT License](LICENSE).

**Fonts.** NyaPlayer bundles *HarmonyOS Sans* (© Huawei Device Co., Ltd., [HarmonyOS Sans Fonts License Agreement](assets/fonts/licenses/HarmonyOS-Sans.txt), used unmodified), *EB Garamond* and *Noto Serif SC* (both [SIL OFL 1.1](assets/fonts/licenses/)). The fonts keep their own licences; the MIT licence covers the app's code.

<div align="center">
<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=12,20,24&height=100&section=footer" width="100%" alt=""/>
</div>
