# TV 构建与更新

## 构建

```bash
bash tools/build_tv.sh <版本> <构建号> [ABI]
```

默认仅构建 `armeabi-v7a`，用于 Sony 实机验证。每次发布递增版本与构建号。APK 输出到 `build/app/outputs/flutter-apk/` 和 `build/tv-updates/`。

v7a 包同时复制到 iCloud 云盘的 `Downloads` 目录；目录不存在时保留本地 APK 并提示。

## 局域网更新

```bash
python3 tools/tv_update_server.py
```

服务监听 `0.0.0.0:18080`，读取 `build/tv-updates/` 中各 ABI 的最新 APK。电脑与设备须处于可互通的局域网，更新时保持服务运行。

应用「设置 → 网络设置 → TV 更新服务器」填写 `http://<电脑局域网 IP>:18080`，在「关于 → 检查更新」下载安装。首次安装使用 adb；系统提示时允许安装未知应用。

构建脚本自动探测电脑局域网 IP，可通过 `TV_UPDATE_BASE` 指定默认地址。模拟器也可使用 `http://10.0.2.2:18080`。

## 弹幕凭证

将 `tools/tv-secrets.example.json` 复制为 `.tv-secrets.json`，填写：

- `DANDANAPI_APPID`：AppId
- `DANDANAPI_KEY`：AppSecret

构建脚本自动读取，也可通过 `TV_DART_DEFINES_FILE` 指定私有文件。不要提交凭证。

申请入口：[弹弹play开发者中心](https://dev.dandanplay.com/)。
