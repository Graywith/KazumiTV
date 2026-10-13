part of 'timeline_page.dart';

class _TimelineWeekSelector extends StatefulWidget {
  const _TimelineWeekSelector({
    required this.counts,
    this.todayIndex,
    this.isLoading = false,
    this.onDown,
    this.onUp,
  });

  final VoidCallback? onDown;
  final VoidCallback? onUp;
  final List<int> counts;
  final int? todayIndex;
  final bool isLoading;

  static const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  static double heightFor(TextScaler scaler) =>
      isTv ? 44 : 40 + scaler.scale(20) + scaler.scale(16);

  @override
  State<_TimelineWeekSelector> createState() => _TimelineWeekSelectorState();
}

class _TimelineWeekSelectorState extends State<_TimelineWeekSelector> {
  final _days = List.generate(7, (_) => FocusNode());
  List<int> get counts => widget.counts;
  int? get todayIndex => widget.todayIndex;
  bool get isLoading => widget.isLoading;
  static const _weekdays = _TimelineWeekSelector._weekdays;
  static double heightFor(TextScaler scaler) =>
      _TimelineWeekSelector.heightFor(scaler);
  @override
  void dispose() {
    for (final node in _days) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final scaler = MediaQuery.textScalerOf(context);
    if (isTv) {
      final controller = DefaultTabController.of(context);
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          for (var day = 0; day < 7; day++) {
            _days[day].debugLabel = day == controller.index
                ? 'TV weekday content entry'
                : 'TV weekday $day';
          }
          return Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) {
              if (event is KeyUpEvent) return KeyEventResult.ignored;
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                widget.onDown?.call();
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                widget.onUp?.call();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    for (var day = 0; day < 7; day++)
                      Expanded(
                        child: TextButton(
                          focusNode: _days[day],
                          onPressed: () => controller.animateTo(day),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            backgroundColor: controller.index == day
                                ? colors.primary
                                : null,
                            foregroundColor: controller.index == day
                                ? colors.onPrimary
                                : colors.onSurfaceVariant,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                day == todayIndex ? '今天' : '周${_weekdays[day]}',
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isLoading ? '—' : '${counts[day]}',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final minTabWidth = (scaler.scale(14) * 2 + 16).clamp(48.0, 112.0);
        final scrollable = constraints.maxWidth - 8 < minTabWidth * 7;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: TabBar(
              isScrollable: scrollable,
              tabAlignment: scrollable ? TabAlignment.start : TabAlignment.fill,
              dividerHeight: 0,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              indicatorAnimation: TabIndicatorAnimation.elastic,
              labelColor: colors.onPrimary,
              unselectedLabelColor: colors.onSurfaceVariant,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              overlayColor: WidgetStateProperty.resolveWith(
                (states) =>
                    states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.focused)
                    ? colors.primary.withValues(alpha: .08)
                    : null,
              ),
              splashBorderRadius: BorderRadius.circular(24),
              tabs: [
                for (var day = 0; day < 7; day++)
                  Tab(
                    height: heightFor(scaler) - 8,
                    child: Semantics(
                      label:
                          '星期${_weekdays[day]}'
                          '${day == todayIndex ? '，今天' : ''}'
                          '${isLoading ? '，加载中' : '，${counts[day]}部'}',
                      excludeSemantics: true,
                      child: SizedBox(
                        width: scrollable ? minTabWidth : null,
                        child: isTv
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    day == todayIndex
                                        ? '今天'
                                        : '周${_weekdays[day]}',
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isLoading ? '—' : '${counts[day]}',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    day == todayIndex
                                        ? '今天'
                                        : '周${_weekdays[day]}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isLoading ? '—' : '${counts[day]}',
                                    style: TextStyle(
                                      fontSize:
                                          theme.textTheme.labelSmall?.fontSize,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
