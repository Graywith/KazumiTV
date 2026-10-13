## 插件使用边界

- 简单遥控器、文案、样式和配置小改由当前 agent 直接实现并必要验证；复杂开发、关键逻辑、TDD 和疑难调试按需使用 Superpowers，默认 inline，避免重复审查。Ponytail 默认 lite，复用现有业务和控件。
- Impeccable 仅在当前任务涉及 TV UI 设计、布局、焦点导航、交互或可访问性时按需调用；构建发布、网络运维和普通 QA 用例任务不调用其 Skills。自动 Hook 默认关闭，只有用户明确要求时才启用。
- Flutter/Android TV UI 使用原生平台资料及 Sony 实机证据验证，重点检查遥控器焦点、返回行为、可读性及操作距离；不运行网页 detector，不因设计检查重新启用 TV 虚拟机或改变交付 ABI。

# TV 交付约定

- 用户电视为 Sony XR65-X90K，Android TV 12（API 31），应用 ABI 为 armeabi-v7a。
- 用户于 2026-10-12 调整交付：停止操作和测试 TV 虚拟机，默认只构建 armeabi-v7a，在 Sony 实机验证。不要自动构建 arm64-v8a 或安装到虚拟机。
- v7a 包仅发布到局域网更新服务器，供电视在线升级；用户于 2026-10-12 取消自动复制到 iCloud 的步骤。
- 使用 `tools/build_tv.sh` 构建并发布到局域网更新目录。APK 命名为 `kazumi-tv-<完整 ABI>-<TV 版本>.apk`。
- 每次交付递增 TV 版本和 Flutter build-number；当前交付为 0.3.19 / 20343。
- 复用现有业务与控件，优先修复遥控器操作，避免大规模重构。
