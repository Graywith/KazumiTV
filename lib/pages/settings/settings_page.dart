import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/bean/widget/content_section.dart';
import 'package:kazumi/pages/settings/player_settings.dart';
import 'package:kazumi/utils/constants.dart';

class _SettingsCategory {
  const _SettingsCategory({
    required this.label,
    required this.description,
    required this.icon,
    required this.path,
  });

  final String label;
  final String description;
  final IconData icon;
  final String path;
}

class _SettingsGroup {
  const _SettingsGroup({required this.title, required this.categories});

  final String title;
  final List<_SettingsCategory> categories;
}

const List<_SettingsGroup> _settingsGroups = [
  _SettingsGroup(
    title: '播放',
    categories: [
      _SettingsCategory(
        label: '播放设置',
        description: '解码、渲染与播放行为',
        icon: Icons.display_settings_rounded,
        path: '/settings/player',
      ),
      _SettingsCategory(
        label: '弹幕设置',
        description: '弹幕来源与显示效果',
        icon: Icons.subtitles_rounded,
        path: '/settings/danmaku',
      ),
      if (!isTv)
        _SettingsCategory(
          label: '操作设置',
          description: '播放器按键映射',
          icon: Icons.keyboard_rounded,
          path: '/settings/keyboard',
        ),
    ],
  ),
  _SettingsGroup(
    title: '资源',
    categories: [
      _SettingsCategory(
        label: '规则管理',
        description: '番剧资源规则',
        icon: Icons.extension_rounded,
        path: '/settings/plugin',
      ),
      if (isTv)
        _SettingsCategory(
          label: '离线下载',
          description: '已缓存剧集与下载任务',
          icon: Icons.download_rounded,
          path: '/settings/download',
        ),
      _SettingsCategory(
        label: '下载设置',
        description: '并发数与弹幕缓存',
        icon: Icons.downloading_rounded,
        path: '/settings/download-settings',
      ),
    ],
  ),
  _SettingsGroup(
    title: '应用',
    categories: [
      _SettingsCategory(
        label: '外观设置',
        description: '主题、配色与字体',
        icon: Icons.palette_rounded,
        path: '/settings/theme',
      ),
      _SettingsCategory(
        label: '界面设置',
        description: '启动、窗口行为与展示信息',
        icon: Icons.pages_rounded,
        path: '/settings/interface',
      ),
      _SettingsCategory(
        label: '同步设置',
        description: '追番状态与多设备同步',
        icon: Icons.cloud_rounded,
        path: '/settings/sync',
      ),
      _SettingsCategory(
        label: '网络设置',
        description: '访问加速与代理',
        icon: Icons.language_rounded,
        path: '/settings/proxy',
      ),
    ],
  ),
  _SettingsGroup(
    title: '其他',
    categories: [
      _SettingsCategory(
        label: '更新设置',
        description: '应用与规则更新',
        icon: Icons.update_rounded,
        path: '/settings/update',
      ),
      _SettingsCategory(
        label: '存储与日志',
        description: '图片缓存与错误日志',
        icon: Icons.storage_rounded,
        path: '/settings/storage',
      ),
      _SettingsCategory(
        label: '关于',
        description: '版本与开源信息',
        icon: Icons.info_outline_rounded,
        path: '/settings/about',
      ),
    ],
  ),
];

String _normalizePath(String path) =>
    path.endsWith('/') ? path.substring(0, path.length - 1) : path;

bool _isWithinPath(String location, String path) =>
    location == path || location.startsWith('$path/');

String _categoryPath(String location) {
  if (location == '/settings') {
    return '/settings/player';
  }
  if (_isWithinPath(location, '/settings/bangumi') ||
      _isWithinPath(location, '/settings/webdav')) {
    return '/settings/sync';
  }
  for (final group in _settingsGroups) {
    for (final category in group.categories) {
      if (_isWithinPath(location, category.path)) {
        return category.path;
      }
    }
  }
  return location;
}

class _SettingsCategorySelected extends Notification {
  const _SettingsCategorySelected(this.path);

  final String path;
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.location});

  final String location;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _outletKey = GlobalKey<RouterOutletState>();
  Object? _categoryNavigation;
  final _sidebarFocus = FocusScopeNode();
  final _playerFocus = FocusNode(debugLabel: 'TV playback settings');

  @override
  void initState() {
    super.initState();
    if (isTv)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(Duration.zero, () {
          if (mounted) _playerFocus.requestFocus();
        });
      });
  }

  @override
  void dispose() {
    _sidebarFocus.dispose();
    _playerFocus.dispose();
    super.dispose();
  }

  late String _location = _normalizePath(widget.location);

  String get _selectedCategoryPath => _categoryPath(_location);
  bool get _isSecondaryRoute =>
      _location != '/settings' && _location != _selectedCategoryPath;

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _categoryNavigation = null;
      _location = _normalizePath(widget.location);
    }
  }

  void _replaceCategory(String path) {
    final outlet = _outletKey.currentState;
    if (outlet == null) return;
    // Nested pushes leave _location unchanged, so check the stack as well.
    if (!outlet.canPop && !_isSecondaryRoute && _selectedCategoryPath == path) {
      return;
    }
    _categoryNavigation = null;
    outlet.navigate(path);
    setState(() => _location = path);
  }

  Future<void> _pushCategory(String path) async {
    if (_categoryNavigation != null) return;
    final navigation = Object();
    final previousLocation = _location;
    _categoryNavigation = navigation;
    setState(() => _location = path);
    await _outletKey.currentState!.push<void>(path);
    // Ignore completions from history replaced by a rail selection.
    if (!mounted || _categoryNavigation != navigation) return;
    setState(() {
      _categoryNavigation = null;
      _location = previousLocation;
    });
  }

  void _goBack() {
    if (isTv) {
      if (!_sidebarFocus.hasFocus) {
        _sidebarFocus.requestFocus();
      } else {
        _exitSettings();
      }
      return;
    }
    if (_outletKey.currentState?.maybePop() ?? false) return;
    _exitSettings();
  }

  void _exitSettings() {
    if (isTv) {
      Navigator.of(context).pop();
      return;
    }
    if (!context.maybePop())
      context.navigate(isTv ? '/tab/popular' : '/tab/my');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > LayoutBreakpoint.compact['width']!;
        return PopScope(
          canPop: !isTv,
          onPopInvokedWithResult: (didPop, result) {
            if (isTv && !didPop) _goBack();
          },
          child: NavigatorPopHandler<Object?>(
            enabled: !isTv,
            onPopWithResult: (_) => _goBack(),
            child: Scaffold(
              appBar: wide
                  ? SysAppBar(
                      title: const Text('设置'),
                      leading: BackButton(onPressed: _exitSettings),
                    )
                  : null,
              body: SafeArea(
                top: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Keep the outlet at the same tree position on resize.
                    SizedBox(
                      width: wide ? (isTv ? 210 : 280) : 0,
                      child: Offstage(
                        offstage: !wide,
                        child: TvSettingsPane(
                          child: FocusScope(
                            node: _sidebarFocus,
                            child: _SettingsMenu(
                              wide: true,
                              firstFocusNode: _playerFocus,
                              selectedPath: _selectedCategoryPath,
                              onSelect: _replaceCategory,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TvSettingsPane(
                        child: Focus(
                          canRequestFocus: false,
                          onKeyEvent: (_, event) {
                            if (!isTv ||
                                event is KeyUpEvent ||
                                event.logicalKey !=
                                    LogicalKeyboardKey.arrowLeft)
                              return KeyEventResult.ignored;
                            var editingValue = false;
                            FocusManager.instance.primaryFocus?.context
                                ?.visitAncestorElements((element) {
                                  if (element.widget is Slider ||
                                      element.widget is EditableText)
                                    editingValue = true;
                                  return !editingValue;
                                });
                            if (editingValue) return KeyEventResult.ignored;
                            _sidebarFocus.requestFocus();
                            return KeyEventResult.handled;
                          },
                          child: SettingsPaneScope(
                            embedded: wide,
                            showBackButton: _isSecondaryRoute,
                            onBack: _goBack,
                            child:
                                NotificationListener<_SettingsCategorySelected>(
                                  onNotification: (notification) {
                                    _pushCategory(notification.path);
                                    return true;
                                  },
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      pageTransitionsTheme:
                                          settingsPageTransitionsTheme,
                                    ),
                                    child: RouterOutlet(key: _outletKey),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SettingsIndexPage extends StatelessWidget {
  const SettingsIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (SettingsPaneScope.of(context)?.embedded ?? false) {
      return const PlayerSettingsPage();
    }
    return Scaffold(
      appBar: SysAppBar(
        title: const Text('设置'),
        leading: BackButton(
          onPressed: () {
            if (!context.maybePop())
              context.navigate(isTv ? '/tab/popular' : '/tab/my');
          },
        ),
      ),
      body: _SettingsMenu(
        wide: false,
        onSelect: (path) => _SettingsCategorySelected(path).dispatch(context),
      ),
    );
  }
}

class _SettingsMenu extends StatelessWidget {
  const _SettingsMenu({
    required this.wide,
    this.selectedPath,
    this.firstFocusNode,
    required this.onSelect,
  });

  final bool wide;
  final String? selectedPath;
  final FocusNode? firstFocusNode;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView(
        padding: wide
            ? const EdgeInsets.fromLTRB(4, 0, 0, 12)
            : const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (final group in _settingsGroups)
            if (wide) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
                child: SectionHeader(title: Text(group.title)),
              ),
              for (final category in group.categories)
                _RailDestination(
                  category: category,
                  focusNode: category.path == '/settings/player'
                      ? firstFocusNode
                      : null,
                  selected: selectedPath == category.path,
                  onTap: () => onSelect(category.path),
                ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ContentSection.group(
                  title: group.title,
                  children: [
                    for (final category in group.categories)
                      SettingsCategoryTile(
                        icon: category.icon,
                        title: category.label,
                        description: category.description,
                        onTap: () => onSelect(category.path),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _RailDestination extends StatefulWidget {
  const _RailDestination({
    required this.category,
    this.focusNode,
    required this.selected,
    required this.onTap,
  });

  final _SettingsCategory category;
  final FocusNode? focusNode;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_RailDestination> createState() => _RailDestinationState();
}

class _RailDestinationState extends State<_RailDestination> {
  late final _focusNode = widget.focusNode ?? FocusNode();

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final selected = widget.selected;
    final onTap = widget.onTap;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = selected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? colorScheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          focusNode: _focusNode,
          onFocusChange: isTv
              ? (focused) {
                  if (focused) {
                    onTap();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Future<void>.delayed(Duration.zero, () {
                        if (mounted) _focusNode.requestFocus();
                      });
                    });
                  }
                }
              : null,
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(category.icon, size: 24, color: foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.label,
                    style: textTheme.labelLarge?.copyWith(color: foreground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
