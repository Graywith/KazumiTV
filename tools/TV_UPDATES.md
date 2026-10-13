# TV 构建与更新

## 构建

```bash
bash tools/build_tv.sh <版本> <构建号> [ABI]
```

默认仅构建 `armeabi-v7a`，用于 Sony 实机验证。每次发布递增版本与构建号。APK 输出到 `build/app/outputs/flutter-apk/` 和 `build/tv-updates/`。

v7a 包仅发布到局域网更新目录，供电视在线升级。

## 局域网更新

```bash
python3 tools/tv_update_server.py
```

服务监听 `0.0.0.0:18080`，读取 `build/tv-updates/` 中各 ABI 的最新 APK。电脑与设备须处于可互通的局域网，更新时保持服务运行。

应用「设置 → 更新设置 → TV 更新服务器」填写 `http://<电脑局域网 IP>:18080`，在「关于 → 检查更新」下载安装。首次安装使用 adb；系统提示时允许安装未知应用。

TV 更新服务器默认留空，在设备上填写。构建时可通过 `TV_UPDATE_BASE` 指定默认地址。

## 弹幕凭证

电视「设置 → 弹幕设置 → 弹幕服务」使用弹弹play官方接口。

填写 App ID 和 App Secret。点击「保存并测试」后生效，不需重新构建。TV 构建脚本不读取或打包弹幕凭证。
