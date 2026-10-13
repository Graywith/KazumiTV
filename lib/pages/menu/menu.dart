import 'dart:async';
import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:flutter/material.dart';
import 'package:kazumi/bean/widget/kazumi_menu.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/widget/embedded_native_control_area.dart';
import 'package:kazumi/navigation.dart';
import 'package:kazumi/pages/menu/route_visibility.dart';
import 'package:kazumi/pages/router.dart';

class ScaffoldMenu extends StatefulWidget {
  const ScaffoldMenu({super.key, required this.location});

  final String location;

  @override
  State<ScaffoldMenu> createState() => _ScaffoldMenu();
}

class _ScaffoldMenu extends State<ScaffoldMenu> with RouteAware {
  final _outletKey = GlobalKey<RouterOutletState>();
  final _contentFocus = FocusScopeNode(
    directionalTraversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
  );
  final _lastContentFocus = <int, FocusNode>{};
  final _tvMenuFocus = List.generate(6, (_) => FocusNode());
  late int _selectedIndex = menu.indexForPath(widget.location);
  DateTime? _lastExitPromptAt;
  bool _tvSettingsOpen = false;
  bool _tvSettingsSelected = false;
  bool _closingMenu = false;

  /// The shell sits at the bottom of the root stack and stays mounted while
  /// other pages cover it, so it publishes that state for its subtree.
  bool _isCovered = false;

  @override
  void initState() {
    super.initState();
    if (isTv) {
      FocusManager.instance.addEarlyKeyEventHandler(_cancelExitOnInput);
      FocusManager.instance.addListener(_rememberContentFocus);
    }
  }

  void _rememberContentFocus() {
    final node = FocusManager.instance.primaryFocus;
    if (!_isCovered &&
        node != null &&
        node is! FocusScopeNode &&
        node.canRequestFocus &&
        node.ancestors.contains(_contentFocus)) {
      _lastContentFocus[_selectedIndex] = node;
    }
  }

  KeyEventResult _cancelExitOnInput(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey != LogicalKeyboardKey.goBack &&
        event.logicalKey != LogicalKeyboardKey.escape)
      _lastExitPromptAt = null;
    return KeyEventResult.ignored;
  }

  @override
  void didUpdateWidget(covariant ScaffoldMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _selectedIndex = menu.indexForPath(widget.location);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) {
      rootRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    if (isTv)
      FocusManager.instance.removeEarlyKeyEventHandler(_cancelExitOnInput);
    if (isTv) FocusManager.instance.removeListener(_rememberContentFocus);
    _contentFocus.dispose();
    for (final node in _tvMenuFocus) {
      node.dispose();
    }
    rootRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() => _setCovered(true);

  @override
  void didPopNext() => _setCovered(false);

  void _setCovered(bool value) {
    if (!mounted || _isCovered == value) {
      return;
    }
    _lastExitPromptAt = null;
    setState(() => _isCovered = value);
  }

  void _openTvPage(String path) {
    if (_tvSettingsOpen) return;
    _tvSettingsOpen = true;
    unawaited(
      context.pushNamed<void>(path).then((_) {
        if (!mounted) return;
        _tvMenuFocus[5].requestFocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tvSettingsOpen = false;
        });
      }),
    );
  }

  void _selectDestination(int index) {
    _lastExitPromptAt = null;
    if (isTv && index == 4) {
      setState(() => _tvSettingsSelected = true);
      _openTvPage('/settings/player');
      return;
    }
    if (_tvSettingsSelected) setState(() => _tvSettingsSelected = false);
    if (index == _selectedIndex) {
      return;
    }
    final outlet = _outletKey.currentState;
    if (outlet == null) return;
    final sidebarFocus = isTv ? _tvMenuFocus[index + 1] : null;
    outlet.navigate('/tab${menu.getPath(index)}/');
    setState(() => _selectedIndex = index);
    if (sidebarFocus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(Duration.zero, () {
          if (mounted &&
              _selectedIndex == index &&
              sidebarFocus.context != null) {
            sidebarFocus.requestFocus();
          }
        });
      });
    }
  }

  void _handleSystemBack(BuildContext context) {
    if (_closingMenu) return;
    _closingMenu = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _closingMenu = false;
    });
    WidgetsBinding.instance.scheduleFrame();
    if (KazumiMenuButton.closeActiveTvMenu()) return;
    if (TvSupport.finishInputEditing()) return;
    if (isTv && ModalRoute.of(context)?.willHandlePopInternally == true) {
      Navigator.of(context).pop();
      return;
    }
    if (_outletKey.currentState?.maybePop() ?? false) {
      _lastExitPromptAt = null;
      return;
    }

    if (isTv && _contentFocus.hasFocus) {
      _lastExitPromptAt = null;
      _tvMenuFocus[_selectedIndex + 1].requestFocus();
      return;
    }
    if (_selectedIndex != 0) {
      _selectDestination(0);
      return;
    }

    final now = DateTime.now();
    final lastPromptAt = _lastExitPromptAt;
    if (lastPromptAt == null ||
        now.difference(lastPromptAt) >= const Duration(seconds: 2)) {
      _lastExitPromptAt = now;
      KazumiDialog.showToast(message: '再按一次退出应用', context: context);
      return;
    }

    _lastExitPromptAt = null;
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return RouteVisibility(
      isCovered: _isCovered,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _handleSystemBack(context);
          }
        },
        child: OrientationBuilder(
          builder: (context, orientation) {
            return orientation == Orientation.portrait
                ? _bottomMenu(context, _selectedIndex)
                : _sideMenu(context, _selectedIndex);
          },
        ),
      ),
    );
  }

  Widget _outlet(BuildContext context, {BorderRadius? borderRadius}) {
    Widget child = FocusScope(
      node: _contentFocus,
      onKeyEvent: (_, event) {
        if (!isTv ||
            event is KeyUpEvent ||
            event.logicalKey != LogicalKeyboardKey.arrowLeft) {
          return KeyEventResult.ignored;
        }
        final focus = FocusManager.instance.primaryFocus;
        if (focus == null ||
            focus.context == null ||
            focus.context!.findAncestorWidgetOfExactType<EditableText>() !=
                null) {
          return KeyEventResult.ignored;
        }
        final rect = focus.rect;
        final hasLeft = _contentFocus.traversalDescendants.any((node) {
          if (node is FocusScopeNode ||
              node.hasFocus ||
              node.context == null ||
              !node.canRequestFocus ||
              node.skipTraversal)
            return false;
          final other = node.rect;
          return other.width > 0 &&
              other.height > 0 &&
              other.right <= rect.left + 1 &&
              other.bottom > rect.top &&
              other.top < rect.bottom;
        });
        if (hasLeft) return KeyEventResult.ignored;
        _tvMenuFocus[_selectedIndex + 1].requestFocus();
        return KeyEventResult.handled;
      },
      child: NotificationListener<NavigationNotification>(
        // A non-poppable outlet must not override the shell's PopScope state.
        onNotification: (notification) => !notification.canHandlePop,
        child: RouterOutlet(key: _outletKey),
      ),
    );
    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius, child: child);
    }
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }

  Widget _bottomMenu(BuildContext context, int selectedIndex) {
    return Scaffold(
      body: _outlet(context),
      bottomNavigationBar: NavigationBar(
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: '推荐',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.timeline),
            icon: Icon(Icons.timeline_outlined),
            label: '时间表',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.favorite),
            icon: Icon(Icons.favorite_outlined),
            label: '追番',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings),
            icon: Icon(Icons.settings),
            label: '我的',
          ),
        ],
        selectedIndex: selectedIndex,
        onDestinationSelected: _selectDestination,
      ),
    );
  }

  Widget _tvRail(BuildContext context, int selectedIndex) {
    const icons = [
      Icons.home_outlined,
      Icons.timeline,
      Icons.favorite_border,
      Icons.history,
      Icons.settings_outlined,
    ];
    const labels = ['推荐', '时间表', '追番', '历史', '设置'];
    final colors = Theme.of(context).colorScheme;
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) {
        if (event is KeyUpEvent) return KeyEventResult.ignored;
        final step = event.logicalKey == LogicalKeyboardKey.arrowDown
            ? 1
            : event.logicalKey == LogicalKeyboardKey.arrowUp
            ? -1
            : 0;
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          final nodes =
              _contentFocus.traversalDescendants
                  .where(
                    (node) =>
                        node is! FocusScopeNode &&
                        node.canRequestFocus &&
                        !node.skipTraversal &&
                        node.context != null &&
                        node.rect.width > 0 &&
                        node.rect.height > 0,
                  )
                  .toList()
                ..sort(
                  (a, b) => a.rect.top == b.rect.top
                      ? a.rect.left.compareTo(b.rect.left)
                      : a.rect.top.compareTo(b.rect.top),
                );
          final previous = _lastContentFocus[_selectedIndex];
          if (previous != null && nodes.contains(previous)) {
            previous.requestFocus();
          } else if (nodes.isNotEmpty) {
            final entry = nodes.where(
              (node) => node.debugLabel?.endsWith('content entry') == true,
            );
            (entry.isNotEmpty ? entry.first : nodes.first).requestFocus();
          }
          return KeyEventResult.handled;
        }
        if (step == 0) return KeyEventResult.ignored;
        final index = _tvMenuFocus.indexWhere((node) => node.hasFocus);
        if (index < 0) return KeyEventResult.ignored;
        _tvMenuFocus[(index + step).clamp(0, _tvMenuFocus.length - 1)]
            .requestFocus();
        return KeyEventResult.handled;
      },
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            const SizedBox(height: 12),
            IconButton(
              focusNode: _tvMenuFocus[0],
              tooltip: '搜索',
              onPressed: () => context.pushNamed('/search/'),
              icon: const Icon(Icons.search),
            ),
            const Spacer(),
            for (var index = 0; index < labels.length; index++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: TextButton(
                  focusNode: _tvMenuFocus[index + 1],
                  onPressed: () => _selectDestination(index),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(60, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    backgroundColor:
                        index == (_tvSettingsSelected ? 4 : selectedIndex)
                        ? colors.secondaryContainer
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icons[index], size: 20),
                      const SizedBox(height: 2),
                      Text(labels[index], maxLines: 1, softWrap: false),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sideMenu(BuildContext context, int selectedIndex) {
    const borderRadius = BorderRadius.only(
      topLeft: Radius.circular(16),
      bottomLeft: Radius.circular(16),
    );
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      body: Row(
        children: [
          EmbeddedNativeControlArea(
            child: isTv
                ? _tvRail(context, selectedIndex)
                : NavigationRail(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainer,
                    groupAlignment: 1,
                    leading: FloatingActionButton(
                      elevation: 0,
                      heroTag: null,
                      onPressed: () => context.pushNamed('/search/'),
                      child: const Icon(Icons.search),
                    ),
                    trailing: isTv
                        ? IconButton(
                            tooltip: '历史记录',
                            onPressed: () =>
                                context.pushNamed('/settings/history/'),
                            icon: const Icon(Icons.history),
                          )
                        : null,
                    labelType: NavigationRailLabelType.selected,
                    destinations: const <NavigationRailDestination>[
                      NavigationRailDestination(
                        selectedIcon: Icon(Icons.home),
                        icon: Icon(Icons.home_outlined),
                        label: Text('推荐'),
                      ),
                      NavigationRailDestination(
                        selectedIcon: Icon(Icons.timeline),
                        icon: Icon(Icons.timeline_outlined),
                        label: Text('时间表'),
                      ),
                      NavigationRailDestination(
                        selectedIcon: Icon(Icons.favorite),
                        icon: Icon(Icons.favorite_border),
                        label: Text('追番'),
                      ),
                      NavigationRailDestination(
                        selectedIcon: Icon(Icons.settings),
                        icon: Icon(Icons.settings_outlined),
                        label: Text('我的'),
                      ),
                    ],
                    selectedIndex: selectedIndex,
                    onDestinationSelected: _selectDestination,
                  ),
          ),
          Expanded(child: _outlet(context, borderRadius: borderRadius)),
        ],
      ),
    );
  }
}
