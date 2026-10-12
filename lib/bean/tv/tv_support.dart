import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const isTv = bool.fromEnvironment('KAZUMI_TV');

/// Adds visible focus highlights to existing Material controls without replacing
/// their activation, navigation, or business logic.
class TvSupport extends StatefulWidget {
  const TvSupport({super.key, required this.child});
  final Widget child;

  @override
  State<TvSupport> createState() => _TvSupportState();
}

class _TvSupportState extends State<TvSupport> {
  @override
  void initState() {
    super.initState();
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    FocusManager.instance.addListener(_focusChanged);
    FocusManager.instance.addEarlyKeyEventHandler(_initialFocus);
  }

  KeyEventResult _initialFocus(KeyEvent event) {
    // Android sends a native Back event as well; let the route handle it once.
    if (defaultTargetPlatform == TargetPlatform.android &&
        event.logicalKey == LogicalKeyboardKey.goBack)
      return KeyEventResult.ignored;

    if ((event is KeyDownEvent || event is KeyRepeatEvent) &&
        (event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.arrowDown)) {
      final focus = FocusManager.instance.primaryFocus;
      var inSlider = false;
      focus?.context?.visitAncestorElements((element) {
        if (element.widget is Slider || element.widget is RangeSlider) {
          inSlider = true;
          return false;
        }
        return true;
      });
      if (!inSlider && focus?.context != null) {
        final scroll = Scrollable.maybeOf(focus!.context!);
        if (scroll != null && scroll.axisDirection == AxisDirection.down) {
          final up = event.logicalKey == LogicalKeyboardKey.arrowUp;
          final hasNext = focus.nearestScope!.traversalDescendants.any((node) {
            if (node == focus ||
                node is FocusScopeNode ||
                node.context == null ||
                !node.canRequestFocus ||
                node.skipTraversal)
              return false;
            if (Scrollable.maybeOf(node.context!) != scroll) return false;
            return up
                ? node.rect.center.dy < focus.rect.center.dy - 1
                : node.rect.center.dy > focus.rect.center.dy + 1;
          });
          final position = scroll.position;
          final edge = up ? position.minScrollExtent : position.maxScrollExtent;
          if (!hasNext && (position.pixels - edge).abs() > 1) {
            position.jumpTo(edge);
            return KeyEventResult.handled;
          }
        }
      }
      if (inSlider) {
        final up = event.logicalKey == LogicalKeyboardKey.arrowUp;
        if (FocusTraversalGroup.maybeOf(focus!.context!)
            is _TvSettingsTraversalPolicy) {
          focus.focusInDirection(
            up ? TraversalDirection.up : TraversalDirection.down,
          );
        } else if (up) {
          focus.previousFocus();
        } else {
          focus.nextFocus();
        }
        return KeyEventResult.handled;
      }
    }
    if (event is KeyDownEvent) {
      final focus = FocusManager.instance.primaryFocus;
      EditableTextState? editor;
      focus?.context?.visitAncestorElements((element) {
        if (element is StatefulElement && element.state is EditableTextState) {
          editor = element.state as EditableTextState;
          return false;
        }
        return true;
      });
      final key = event.logicalKey;
      if (editor != null) {
        if (key == LogicalKeyboardKey.arrowUp ||
            key == LogicalKeyboardKey.arrowDown ||
            key == LogicalKeyboardKey.escape ||
            key == LogicalKeyboardKey.goBack) {
          SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
          final direction = key == LogicalKeyboardKey.arrowUp
              ? TraversalDirection.up
              : TraversalDirection.down;
          if (!focus!.focusInDirection(direction)) focus.nextFocus();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.select) {
          editor!.requestKeyboard();
          return KeyEventResult.handled;
        }
      }
      if (key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.goBack) {
        WidgetsBinding.instance.handlePopRoute();
        return KeyEventResult.handled;
      }
    }
    if (event is KeyDownEvent &&
        FocusManager.instance.primaryFocus is FocusScopeNode &&
        [
          LogicalKeyboardKey.arrowUp,
          LogicalKeyboardKey.arrowDown,
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowRight,
          LogicalKeyboardKey.select,
          LogicalKeyboardKey.enter,
        ].contains(event.logicalKey)) {
      FocusManager.instance.primaryFocus!.nextFocus();
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.arrowRight)) {
      final focus = FocusManager.instance.primaryFocus;
      var inRadioGroup = false;
      focus?.context?.visitAncestorElements((element) {
        if (element.widget is RadioGroup) {
          inRadioGroup = true;
          return false;
        }
        return true;
      });
      if (inRadioGroup) {
        // RadioGroup cycles all four arrows. Let TV users leave it without Tab.
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          focus!.nextFocus();
        } else {
          focus!.previousFocus();
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _focusChanged() {
    final focus = FocusManager.instance.primaryFocus;
    final focusContext = focus?.context;
    final scope = focus?.nearestScope;
    if (focusContext != null &&
        focusContext.mounted &&
        ModalRoute.of(focusContext) is PageRoute &&
        scope != null &&
        scope.debugLabel != 'TV episodes') {
      // RouterOutlet creates nested scopes; D-pad edges must reach the sidebar.
      scope.directionalTraversalEdgeBehavior =
          TraversalEdgeBehavior.parentScope;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = FocusManager.instance.primaryFocus?.context;
      if (target != null && target.mounted) {
        Scrollable.ensureVisible(
          target,
          duration: Duration.zero,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
        if (target.mounted &&
            FocusManager.instance.primaryFocus?.context == target) {
          Scrollable.ensureVisible(
            target,
            duration: Duration.zero,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_focusChanged);
    FocusManager.instance.removeEarlyKeyEventHandler(_initialFocus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final overlay = WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.focused)
          ? color.withValues(alpha: .45)
          : null,
    );
    ButtonStyle buttonStyle(ButtonStyle? original) =>
        (original ?? const ButtonStyle()).copyWith(
          overlayColor: overlay,
          side: WidgetStateProperty.resolveWith<BorderSide?>(
            (states) => states.contains(WidgetState.focused)
                ? BorderSide(color: theme.colorScheme.onSurface, width: 3)
                : original?.side?.resolve(states),
          ),
        );
    // Paint focus inside each Material control, so scrolling, clipping and
    // nested routes cannot detach its highlight from its actual bounds.
    return Theme(
      data: theme.copyWith(
        focusColor: color.withValues(alpha: .45),
        textButtonTheme: TextButtonThemeData(
          style: buttonStyle(theme.textButtonTheme.style),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: buttonStyle(theme.filledButtonTheme.style),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: buttonStyle(theme.outlinedButtonTheme.style),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: buttonStyle(theme.iconButtonTheme.style),
        ),
        sliderTheme: theme.sliderTheme.copyWith(
          overlayColor: color.withValues(alpha: .45),
        ),
      ),
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        },
        child: widget.child,
      ),
    );
  }
}

/// Keep vertical navigation in its settings column; horizontal arrows can
/// still cross the nested RouterOutlet scope to the other column.
class TvSettingsPane extends StatelessWidget {
  const TvSettingsPane({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => !isTv
      ? child
      : FocusScope(
          child: Builder(
            builder: (context) {
              FocusScope.of(context).directionalTraversalEdgeBehavior =
                  TraversalEdgeBehavior.parentScope;
              return FocusTraversalGroup(
                policy: _TvSettingsTraversalPolicy(),
                child: child,
              );
            },
          ),
        );
}

class _TvSettingsTraversalPolicy extends ReadingOrderTraversalPolicy {
  @override
  bool inDirection(FocusNode node, TraversalDirection direction) {
    final scope = node.nearestScope!;
    final previous = scope.directionalTraversalEdgeBehavior;
    if (direction == TraversalDirection.up ||
        direction == TraversalDirection.down) {
      scope.directionalTraversalEdgeBehavior = TraversalEdgeBehavior.stop;
    }
    try {
      return super.inDirection(node, direction);
    } finally {
      scope.directionalTraversalEdgeBehavior = previous;
    }
  }
}
