# TV 交付约定

- 用户电视为 Sony XR65-X90K，Android TV 12（API 31），应用 ABI 为 armeabi-v7a。
- 用户于 2026-10-12 调整交付：停止操作和测试 TV 虚拟机，默认只构建 armeabi-v7a，在 Sony 实机验证。不要自动构建 arm64-v8a 或安装到虚拟机。
- v7a 包发布到局域网更新服务器，并复制到 `/Users/gray/Library/Mobile Documents/com~apple~CloudDocs/Downloads`。
- 使用 `tools/build_tv.sh` 构建并发布到局域网更新目录。APK 命名为 `kazumi-tv-<完整 ABI>-<TV 版本>.apk`。
- 每次交付递增 TV 版本和 Flutter build-number；当前交付为 0.2.1 / 20319。
- 复用现有业务与控件，优先修复遥控器操作，避免大规模重构。
