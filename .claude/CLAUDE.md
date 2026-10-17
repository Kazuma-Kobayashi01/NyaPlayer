# NyaPlayer（文档代号 Lyra）— 本地音乐播放器（Flutter，Android + macOS）

## 必读文档
- docs/REQUIREMENTS.md — 需求与编号（FMT/LIB/META/LRC/PLAY/SYS/EQ/UI/SET）
- docs/TECH_SPEC.md — 技术决定与约束（以此为准）
- docs/PLAN.md — 里程碑与任务清单（当前进度看这里的复选框）
- docs/PROGRESS.md — 施工记录：当前状态、已做/未做、决定、坑、下一步（接手先读这个）
- docs/SPIKE_REPORT.md — M0 实测结论（存在时优先于 TECH_SPEC 中的 🔍 假设）

## 工作规则
- 一次只做一个里程碑里的任务；开始前先说明要做哪几个任务编号。
- 实现与 TECH_SPEC 冲突时先停下来说明，不要自行改方案。
- 不要新增 TECH_SPEC §1 之外的依赖，除非先在附录 A 记录理由并征得同意。
- UI 不得直接调用 Rust 内核 API（lib/src/rust/），必须经过 AudioHandler / QueueController。
- 耗时操作放 isolate；不要硬编码颜色，全部从 ColorScheme 取。
- 完成任务后：dart format . && flutter analyze && flutter test（改了 rust/ 时再加 cargo fmt && cargo clippy -- -D warnings && cargo test），然后勾选 PLAN.md 中的复选框。

## 常用命令
- flutter run -d macos
- flutter run --release -d <android-device-id>
- dart run build_runner build --delete-conflicting-outputs   # drift 代码生成
- flutter test
- flutter_rust_bridge_codegen generate          # 改了 rust/src/api 后重新生成桥接代码
- (cd rust && cargo test)

## 开发者偏好
- 回复用中文；代码注释中英文均可，标识符用英文。
