# Kazumi TV

<img src="tools/branding/kazumi_tv_banner.png" alt="Kazumi TV" width="640">

基于 [Kazumi](https://github.com/Predidit/Kazumi) 的非官方 Android TV 适配版，由个人开发者维护。使用 Flutter 开发，支持自定义规则、番剧浏览、搜索和在线观看，并针对遥控器做了焦点导航与播放控制适配。

本项目为个人维护的开源项目，遵循 GPL-3.0 许可，非商业、无广告、无收费、无赞助或导流。不内置、不提供任何视频内容，仅作为播放与采集工具。弹幕通过弹弹play官方接口提供，需自备开发者凭证。

## 功能

- 番剧浏览、搜索、详情与选集
- 历史记录、播放进度与观看足迹
- 遥控器焦点、高亮与列表滚动
- 播放时显示实测分辨率
- 播放、暂停、快进快退与上下集切换
- 系统输入法搜索
- 局域网检查更新
- 弹弹play官方弹幕接口

## 支持设备

- Android 10 及以上的 Android TV 设备
- `armeabi-v7a`：Sony XR65-X90K，Android TV 12
- `arm64-v8a`：ARM64 TV 模拟器

焦点导航、输入法与播放控制仍需实机验证。

## 遥控器操作

| 场景 | 按键 | 操作 |
| --- | --- | --- |
| 页面 | 方向键 | 移动焦点 |
| 首页、设置侧栏 | 上 / 下 | 移动菜单焦点，按 OK 切换内容 |
| 页面 | OK / Back | 确认 / 返回 |
| 播放中 | 左 / 右 | 按播放设置的跨度快退 / 快进，并显示进度条 |
| 播放中 | OK / 菜单键 | 显示控制栏 |
| 控制栏 | 方向键、OK | 选择并操作控件 |
| 播放中 | Back | 先关闭控制栏；隐藏时两秒内按两次退出播放 |
| 设置 | Back | 右侧回左栏，左栏回首页设置按钮 |
| 首页 | Back | 两秒内按两次退出应用 |

## 构建与更新

需要 Flutter、Android SDK 和 JDK。

```bash
flutter pub get
# Sony 电视包（v7a）
bash tools/build_tv.sh 0.3.20 20344
# 仅构建电视包
bash tools/build_tv.sh 0.3.20 20344 armeabi-v7a
```

APK 命名为 `kazumi-tv-<ABI>-<版本>.apk`，输出到 `build/app/outputs/flutter-apk/`，同时发布到 `build/tv-updates/`。每次发布递增版本和构建号。

默认仅构建 v7a，发布到局域网更新目录，供电视在线升级。

局域网更新配置见 [TV 构建与更新](tools/TV_UPDATES.md)。

## 弹幕配置

弹幕能力由 [弹弹play开放平台](https://doc.dandanplay.com/open/) 提供。使用前请在 [弹弹play开发者中心](https://dev.dandanplay.com/) 以开发者身份申请自己的 AppId 与 AppSecret。

在电视「设置 → 弹幕设置 → 弹幕服务」填写 App ID 和 App Secret，点击「保存并测试」。

凭证仅保存在设备本地，Secret 隐藏显示，不写入 APK、日志或应用同步数据，也不提交到 GitHub。使用官方接口请遵守弹弹play开放平台协议。

## 开发

见 [贡献指引](static/doc/CONTRIBUTING.md) 和 [项目结构](static/doc/STRUCTURE.md)。上游说明见 [Kazumi](https://github.com/Predidit/Kazumi)。

## 许可与资源

本项目是 [Kazumi](https://github.com/Predidit/Kazumi)（[GPL-3.0](LICENSE)）的衍生作品，按相同的 GPL-3.0 许可发布，并保留上游版权声明与第三方许可。TV 版修改的源代码随仓库公开，修改内容包括遥控器操作、焦点导航、播放控制、启动图标与局域网更新。

TV 图标采用纯文字与渐变背景，使用 AI 辅助制作，不含上游角色形象。仓库历史及上游说明中保留的角色美术来自 [Yuquanaaa](https://www.pixiv.net/users/66219277) 的 [Pixiv 作品](https://www.pixiv.net/artworks/116666979)，版权归原作者，使用、修改和分发须获得其许可。

内嵌 [Mi Sans](https://hyperos.mi.com/font/zh/details/sc/) 字体由 Xiaomi 开发。第三方许可见 [licenses](licenses)。

## 免责声明

本项目基于 GPL-3.0 授权，不提供任何明示或暗示的保证，作者与贡献者不对因使用本软件产生的直接或间接损失承担责任。本软件不内置、不提供任何视频内容，播放内容均来自用户配置的规则与第三方视频源。

使用本项目须遵守所在地法律法规，不得侵犯第三方知识产权。本项目不收集用户数据，不使用遥测组件。因使用本项目产生的数据与缓存应及时清除，持续保存需获得相关权利人的授权。

## 致谢

特别感谢 [XpathSelector](https://github.com/simonkimi/xpath_selector) 这个优秀的项目是本项目的基石。

特别感谢 [弹弹play](https://www.dandanplay.com/) 本项目使用了 弹弹play开放平台 以提供弹幕交互。

特别感谢 [Bangumi](https://bangumi.tv/) 本项目使用了 Bangumi 开放 API 以提供番剧元数据。

特别感谢 [Anime4K](https://github.com/bloc97/Anime4K) 本项目使用 Anime4K 进行实时超分。

特别感谢 [SyncPlay](https://github.com/Syncplay/syncplay) 本项目使用 SyncPlay 协议并通过 SyncPlay 公共服务器实现一起看功能。

特别感谢 [所有贡献者](https://github.com/Predidit/Kazumi/graphs/contributors) 本项目因为你们变得更好。

特别感谢 [trace.moe](https://trace.moe) 本项目使用了 trace.moe 提供的图片识别番剧功能。

感谢 [media-kit](https://github.com/media-kit/media-kit) 本项目跨平台媒体播放能力来自 media-kit。

感谢 [avbuild](https://github.com/wang-bin/avbuild) 本项目使用了来自 avbuild 的树外补丁实现非标准视频流播放。

感谢 [hive](https://github.com/isar/hive) 本项目持久化储存能力来自 hive。
