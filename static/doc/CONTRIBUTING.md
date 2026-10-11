# 贡献指引

欢迎提交 Issue 和 Pull Request。

## 开发环境

安装 Flutter、Android SDK 和 JDK，并确保依赖下载源可访问。

```bash
flutter doctor -v
flutter pub get
flutter run
```

TV 构建与配置见 [TV 构建与更新](../../tools/TV_UPDATES.md)。

## 检查

运行与改动相关的测试，提交前检查格式和分析结果。

```bash
dart format lib test
flutter test
flutter analyze --no-fatal-infos --fatal-warnings
```

## 代码与提交

- 优先复用已有页面、组件和业务逻辑。
- 日志使用 `KazumiLogger`。
- 行为修改补充相应测试。
- 提交采用 [Conventional Commits](https://www.conventionalcommits.org/)，如 `fix(player): 修复遥控器快进`。
- 一个 PR 处理一项功能或问题，说明改动和验证结果。
- AI 辅助代码须经检查，提交时注明模型。

向上游提交 PR 时，请遵循 [Kazumi 上游贡献指引](https://github.com/Predidit/Kazumi/blob/main/static/doc/CONTRIBUTING.md)。

## 许可证

贡献代码遵循 [GPL-3.0](../../LICENSE)。
