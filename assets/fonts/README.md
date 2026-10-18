# 内置字体与包体精简

当前打包 4 个字体文件，共 **32,075,052 字节（约 32.1 MB）**；此前为 9 个文件、56,321,000 字节，字体资源减少 **43.0%**。

| 家族 | 打包文件 | 字重与字符 |
| --- | --- | --- |
| HarmonyOS Sans SC | Regular / Bold 两份原始 TTF | 400 / 700；每份 29,063 个字符 |
| EB Garamond | 一个 Variable TTF | 连续 400–700；2,091 个字符 |
| Noto Serif SC | Medium 原始 TTF | 500；30,928 个字符，粗体由字体引擎合成 |

- HarmonyOS Sans 移除重复的 Medium 文件，保留常规与真实粗体；500 字重会匹配最接近的可用字体，因此中等字重会稍轻。
- EB Garamond 从 4 个静态字重合并为一个可变字体，保留原先实际使用的 400–700 区间，字符集与原四份文件一致。
- Noto Serif SC 保留整套 Medium 字形，移除单独的 Bold 文件；较粗的中文衬线文本使用合成粗体。
- 三款字体的字符覆盖均保留，未按界面文案裁字；歌曲名与歌词继续使用完整的字形与系统回退。字体家族别名、内置字体开关、衬线字号补偿和许可页保持原有行为。
- HarmonyOS Sans 与 Noto Serif SC 保留文件的 SHA-256 已与旧提交核对一致；没有修改它们的字形或元数据。EB Garamond 的衍生字体使用 `Nya EB Garamond` 内部名称，保留版权与 OFL 声明。

## 重建 EB Garamond 资源

使用已经安装的 FontTools（仅为素材制作工具，不是应用运行时依赖）：

```sh
python tool/compact_fonts.py /path/to/EBGaramond-VariableFont_wght.ttf
```

脚本核对源文件 SHA-256，把 `wght` 轴限定为 400–700，不删除字符，输出 `EBGaramond-Variable.ttf` 和 `font-sources.json`。输入来源与输出校验值在 `font-sources.json` 中。

项目使用的 Flutter 版本支持直接用 `FontWeight` 控制变量字体的 `wght` 轴，无需逐个声明相同字体文件，也无需改变现有 TextStyle。参考：[Flutter 变量字体字重说明](https://docs.flutter.dev/release/breaking-changes/font-weight-variation)。TTF 是 macOS/Android 的原生支持格式，未使用桌面端不支持的 WOFF/WOFF2，见 [Flutter 字体格式](https://docs.flutter.dev/cookbook/design/fonts)。

协议文本在 `licenses/`。Release 包体对比与重新构建方式见 `docs/PROGRESS.md`、`docs/BUILD_OUTPUTS.md`。
