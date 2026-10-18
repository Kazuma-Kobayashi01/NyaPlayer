# Release 构建产物

从仓库根目录运行：

```sh
python3 tool/build_release.py
```

脚本依次构建当前源码的三个 Release 目标，并放到根目录 `output/`：

```text
output/
├── darwin-arm64/
│   ├── NyaPlayer.app
│   └── build-info.json
├── darwin-x86_64/
│   ├── NyaPlayer.app
│   └── build-info.json
└── android-armv8a/
    ├── NyaPlayer.apk
    └── build-info.json
```

| 目录 | 系统 / 架构 | 模式 |
| --- | --- | --- |
| `darwin-arm64` | macOS / Apple Silicon | Release |
| `darwin-x86_64` | macOS / Intel 64 位 | Release |
| `android-armv8a` | Android / `arm64-v8a` | Release |

只构建指定目标：

```sh
python3 tool/build_release.py darwin-arm64 darwin-x86_64
python3 tool/build_release.py android-armv8a
```

## macOS

- 每次构建前移除 `build/macos/Build/Products/Release/NyaPlayer.app`，避免上一种架构的旧 bundle 混入。
- 使用 Flutter 的 `FLUTTER_XCODE_ARCHS` 向 Xcode 传入 `arm64` 或 `x86_64`，主应用、Rust 核心及 Widget 扩展分别按目标架构构建，不修改全局 Flutter 配置。
- 分发副本的所有 Mach-O 文件（包括 Flutter 引擎、原生框架和 Widget）只保留目标架构；预编译框架的多余 slice 用 `lipo` 移除。
- 分离后按从内到外的顺序重新 ad-hoc 签名，保留原有 identifier、entitlements 与 flags，并核对整个 bundle 的签名完整性。
- `output/` 中的两份 App 互不覆盖；可将适合当前 Mac 的那一份复制到“应用程序”。构建临时目录仍由 Flutter 管理，不作为分发位置。
- 脚本不启动 App，不主动注册测试小组件。构建后的系统测试扩展注册另行清理，安装后的 App 仍自带 Widget。

## Android

- 使用 `flutter build apk --release --target-platform android-arm64`，输出归档为 `android-armv8a/NyaPlayer.apk`。
- 不复用旧 APK；仓库现有 `arm64-v8a` ABI 限制保持不变。
- 当前 Gradle Release 仍使用项目原先的 debug signing 配置；此脚本不更换签名身份。

`build-info.json` 记录目标、Release 模式、应用版本号及源码 Git commit。`output/` 被 Git 忽略，仓库不提交二进制产物。
