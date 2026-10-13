import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef KazumiMenuBuilder =
    Widget Function(BuildContext context, VoidCallback? toggle);

const _menuItemStyle = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(144, isTv ? 36 : 48)),
  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
  alignment: AlignmentDirectional.centerStart,
  visualDensity: VisualDensity.standard,
);

class KazumiMenuButton extends StatefulWidget {
  const KazumiMenuButton({
    super.key,
    required this.builder,
    required this.menuChildren,
    this.controller,
    this.childFocusNode,
    this.enabled = true,
    this.animated = false,
    this.crossAxisUnconstrained = true,
    this.onOpen,
    this.onClose,
    this.style,
    this.trapTvFocus = false,
  });

  final KazumiMenuBuilder builder;
  final List<Widget> menuChildren;
  final MenuController? controller;
  final FocusNode? childFocusNode;
  final bool enabled;

  /// Opt in only for menus that previously animated.
  final bool animated;
  final bool crossAxisUnconstrained;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final MenuStyle? style;
  final bool trapTvFocus;
  static _KazumiMenuButtonState? _activeTvMenu;

  static bool closeActiveTvMenu() {
    final menu = _activeTvMenu;
    if (menu == null || !menu.controller.isOpen) return false;
    menu.controller.close();
    return true;
  }

  static KeyEventResult handleTvMenuKey(KeyEvent event) {
    final menu = _activeTvMenu;
    if (menu == null ||
        !menu.controller.isOpen ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      closeActiveTvMenu();
      return KeyEventResult.handled;
    }
    if (!menu.widget.trapTvFocus) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      final nodes = menu.widget.menuChildren
          .whereType<KazumiMenuItem>()
          .where((item) => item.onPressed != null)
          .map((item) => item.focusNode)
          .whereType<FocusNode>()
          .toList();
      if (nodes.isNotEmpty) {
        final current = nodes.indexWhere((node) => node.hasFocus);
        final next = (current + (key == LogicalKeyboardKey.arrowUp ? -1 : 1))
            .clamp(0, nodes.length - 1);
        nodes[next].requestFocus();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  State<KazumiMenuButton> createState() => _KazumiMenuButtonState();
}

class _KazumiMenuButtonState extends State<KazumiMenuButton> {
  final _ownedController = MenuController();
  LocalHistoryEntry? _entry;
  bool _disposed = false;
  MenuController get controller => widget.controller ?? _ownedController;

  void _open() {
    if (isTv) KazumiMenuButton._activeTvMenu = this;
    if (isTv && ModalRoute.of(context) != null) {
      _entry = LocalHistoryEntry(
        onRemove: () {
          _entry = null;
          if (!_disposed && controller.isOpen) controller.close();
        },
      );
      ModalRoute.of(context)!.addLocalHistoryEntry(_entry!);
    }
    widget.onOpen?.call();
  }

  void _close() {
    if (KazumiMenuButton._activeTvMenu == this)
      KazumiMenuButton._activeTvMenu = null;
    if (isTv) widget.childFocusNode?.requestFocus();
    final entry = _entry;
    _entry = null;
    entry?.remove();
    widget.onClose?.call();
  }

  @override
  void dispose() {
    _disposed = true;
    if (KazumiMenuButton._activeTvMenu == this)
      KazumiMenuButton._activeTvMenu = null;
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuButtonTheme(
      data: MenuButtonThemeData(
        // Submenu entries must use the same inset as ordinary menu items.
        style: _menuItemStyle.merge(MenuButtonTheme.of(context).style),
      ),
      child: MenuAnchor(
        controller: controller,
        childFocusNode: widget.childFocusNode,
        consumeOutsideTap: true,
        crossAxisUnconstrained: widget.crossAxisUnconstrained,
        animated: widget.animated && !MediaQuery.disableAnimationsOf(context),
        onOpen: _open,
        onClose: _close,
        style: widget.style,
        menuChildren: widget.menuChildren,
        builder: (context, controller, _) => widget.builder(
          context,
          widget.enabled && widget.menuChildren.isNotEmpty
              ? () => controller.isOpen ? controller.close() : controller.open()
              : null,
        ),
      ),
    );
  }
}

class KazumiMenuItem extends StatelessWidget {
  const KazumiMenuItem({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.focusNode,
    this.selected,
    this.destructive = false,
    this.requestFocusOnHover = true,
    this.autofocus = false,
  });

  final bool autofocus;
  final String label;
  final VoidCallback? onPressed;
  final Widget? leadingIcon;
  final FocusNode? focusNode;

  /// Null for actions; a bool exposes single-choice selection semantics.
  final bool? selected;
  final bool destructive;
  final bool requestFocusOnHover;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = destructive
        ? colors.error
        : selected == true
        ? colors.primary
        : null;
    final foregroundColor = color == null
        ? null
        : WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.disabled) ? null : color,
          );
    return MenuItemButton(
      autofocus: autofocus,
      focusNode: focusNode,
      onPressed: onPressed,
      requestFocusOnHover: requestFocusOnHover,
      style: ButtonStyle(
        foregroundColor: foregroundColor,
        iconColor: foregroundColor,
      ),
      leadingIcon: leadingIcon,
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: selected == null ? null : true,
        child: Text(label, textAlign: TextAlign.start),
      ),
    );
  }
}
