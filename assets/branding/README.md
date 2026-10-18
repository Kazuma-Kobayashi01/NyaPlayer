# NyaPlayer 图标

品牌图形直接采用 **Material Icons 的 `music_note`（Flutter `Icons.music_note`）**：纯色、平面几何，不绘制渐变、纹理、高光、投影或拟物材质。默认紫色 `#6750A4`；背景 `#F3EDF7`。

## 源文件与生成

- `icon_geometry.json`：生产几何与品牌色源；标准音符保持原始比例，以可见图形边界居中。
- `nyaplayer.svg`：透明矢量标志。
- `nyaplayer-foreground.png`：1024px 透明标志。
- `nyaplayer-1024.png`：1024px 方形底色版本。
- `material_music_note.svg`：从 Flutter 自带 Material 字体提取的原始 24px 矢量轮廓。
- `MaterialIcons_LICENSE.txt`：随 Flutter 字体提供的原始许可；图标来源为 Google Material Icons，本次仅改变尺寸、居中位置与颜色。

在 macOS 仓库根目录运行（仅使用系统 Swift / CoreGraphics）：

```sh
swift -module-cache-path /tmp/nyaplayer-icon-swift-cache tool/generate_app_icons.swift
```

命令会更新两个平台的资源，并生成 `build/icon_previews/` 预览。Android 前景逐像素检查 108dp 画布内的 66dp 圆形安全区；当前图形占约 36.1 × 54.2dp。

## 平台接入

### macOS

`macos/Runner/NyaPlayerIcon.icon` 是 Icon Composer 原生分层包：背景与标准 Material 音符。浅色/深色/着色外观在 `icon.json` 配置；关闭图形图层的玻璃、投影、高光与半透明。Xcode 资源构建阶段编译 `.icon`，`ASSETCATALOG_COMPILER_APPICON_NAME = NyaPlayerIcon`。

图形源不预先裁角；macOS 26+ 的系统负责遮罩、着色和系统图标表面效果。系统外壳可能仍呈现系统提供的边缘光，并非素材绘制的立体效果。旧版 macOS 使用编译器生成的 ICNS；同时保留 `AppIcon.appiconset` 的 16/32/64/128/256/512/1024px 平面兼容素材（832px 内容区及透明外边距）。

### Android

- API 26+ adaptive icon：108dp 背景和矢量前景，交给桌面启动器裁成圆形、圆角方形等形状。
- API 33+ 增加独立 `monochrome` 矢量图层，用户启用主题图标且启动器支持时，由系统壁纸调色盘着色。
- 兼容 PNG：mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi 分别为 48/72/96/144/192px。
- `android:icon` / `android:roundIcon` 共用同一自适应资源。

平台参考：[Apple Icon Composer](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer)、[Android adaptive icons](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive)。

## 正式名称

macOS `PRODUCT_NAME`、`CFBundleDisplayName`、共享 scheme 与测试宿主使用 `NyaPlayer`，直接构建产物为 `NyaPlayer.app`。Android application label 引用 `@string/app_name`，值为 `NyaPlayer`。Flutter 本地化原已使用该名字。

bundle identifier、Android applicationId 和 Dart package 名称保持 `com.kazuma.nyaplayer` / `nyaplayer`，保证已有数据和包身份连续。Flutter 默认 APK 文件名仍为 `app-debug.apk`；可在分发时另存为 `NyaPlayer-1.2.0-alpha-arm64-debug.apk`。

## 标准图标来源与重新导入

使用本地 Flutter SDK 的 `bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf`，以 `packages/flutter/lib/src/material/icons.dart` 中 `Icons.music_note` 的 U+E415 码位读取原始轮廓。不是手工重画，也不使用生成式图片。

原始 24px 图形边界为 `(6, 3, 12, 18)`；保持原始 2:3 比例，按可见边界居中，macOS 1024px 画布上的图形高 608px。Android 再应用安全区缩放；单音符本来就是较窄的符号，不拉宽成正方形。

需要从 Flutter 重新导入时，在仓库根目录运行：

```sh
swift -module-cache-path /tmp/nyaplayer-icon-swift-cache tool/import_material_icon.swift /path/to/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf
swift -module-cache-path /tmp/nyaplayer-icon-swift-cache tool/generate_app_icons.swift
```

来源：[Google Material Icons](https://github.com/google/material-design-icons)、[Flutter Icons.music_note](https://api.flutter.dev/flutter/material/Icons/music_note-constant.html)。保留字体随附的 [许可原文](MaterialIcons_LICENSE.txt)。
