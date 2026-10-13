import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/bean/widget/kazumi_menu.dart';
import 'package:kazumi/bean/widget/loading_indicator.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/modules/history/history_module.dart';

class HistoryRecordTile extends StatefulWidget {
  const HistoryRecordTile({
    super.key,
    required this.history,
    required this.onPlay,
    required this.onDetails,
    required this.onDelete,
    required this.collectType,
    required this.onChangeCollect,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.editing = false,
    this.busy = false,
  });

  final History history;
  final VoidCallback onPlay;
  final VoidCallback onDetails;
  final Future<void> Function() onDelete;
  final CollectType collectType;
  final ValueChanged<CollectType>? onChangeCollect;
  final BorderRadius borderRadius;
  final bool editing;
  final bool busy;

  @override
  State<HistoryRecordTile> createState() => _HistoryRecordTileState();
}

class _HistoryRecordTileState extends State<HistoryRecordTile> {
  final _rowFocus = FocusNode();
  final _playFocus = FocusNode();
  final _moreFocus = FocusNode();
  History get history => widget.history;
  VoidCallback get onPlay => widget.onPlay;
  VoidCallback get onDetails => widget.onDetails;
  Future<void> Function() get onDelete => widget.onDelete;
  CollectType get collectType => widget.collectType;
  ValueChanged<CollectType>? get onChangeCollect => widget.onChangeCollect;
  BorderRadius get borderRadius => widget.borderRadius;
  bool get editing => widget.editing;
  bool get busy => widget.busy;
  @override
  void dispose() {
    _rowFocus.dispose();
    _playFocus.dispose();
    _moreFocus.dispose();
    super.dispose();
  }

  KeyEventResult _keys(FocusNode _, KeyEvent event) {
    if (!isTv || editing || busy || event is KeyUpEvent)
      return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight) {
      if (_rowFocus.hasPrimaryFocus)
        _playFocus.requestFocus();
      else if (_playFocus.hasPrimaryFocus)
        _moreFocus.requestFocus();
      else if (!_moreFocus.hasPrimaryFocus)
        return KeyEventResult.ignored;
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (_moreFocus.hasPrimaryFocus)
        _playFocus.requestFocus();
      else if (_playFocus.hasPrimaryFocus)
        _rowFocus.requestFocus();
      else
        return KeyEventResult.ignored;
      return KeyEventResult.handled;
    }
    if ((key == LogicalKeyboardKey.arrowUp ||
            key == LogicalKeyboardKey.arrowDown) &&
        (_playFocus.hasPrimaryFocus || _moreFocus.hasPrimaryFocus)) {
      _rowFocus.requestFocus();
      _rowFocus.focusInDirection(
        key == LogicalKeyboardKey.arrowUp
            ? TraversalDirection.up
            : TraversalDirection.down,
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String get _position {
    final progress = history.progresses[history.lastWatchEpisode]?.progress;
    if (progress == null || progress.inSeconds <= 0) return '';
    final seconds = (progress.inSeconds % 60).toString().padLeft(2, '0');
    final minutes = (progress.inMinutes % 60).toString().padLeft(2, '0');
    final position = progress.inHours > 0
        ? '${progress.inHours}:$minutes:$seconds'
        : '${progress.inMinutes}:$seconds';
    return '看到 $position';
  }

  @override
  Widget build(BuildContext context) => !isTv
      ? _buildTile(context)
      : Focus(
          canRequestFocus: false,
          onKeyEvent: _keys,
          child: _buildTile(context),
        );

  Widget _buildTile(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = history.bangumiItem.nameCn.isEmpty
        ? history.bangumiItem.name
        : history.bangumiItem.nameCn;
    final episode = history.lastWatchEpisodeName.isEmpty
        ? '第 ${history.lastWatchEpisode} 话'
        : history.lastWatchEpisodeName;
    final source =
        HistoryEntryKind.normalize(history.entryKind) ==
            HistoryEntryKind.offline
        ? '缓存'
        : '在线';
    final time = TimeOfDay.fromDateTime(
      history.lastWatchTime.toLocal(),
    ).format(context);
    final image = history.bangumiItem.images['large'] ?? '';
    final position = _position;

    return Dismissible(
      key: ValueKey(history.key),
      direction: busy || editing
          ? DismissDirection.none
          : DismissDirection.endToStart,
      // The parent removes saved deletions; failed writes keep the row usable.
      confirmDismiss: (_) async {
        await onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: borderRadius,
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: colors.onErrorContainer,
        ),
      ),
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Keep menu focus outside the card's InkWell to prevent stuck highlights.
            Positioned.fill(
              child: Semantics(
                button: !editing && !busy,
                label: [
                  title,
                  episode,
                  position,
                  if (!isTv) source,
                  history.adapterName,
                  time,
                ].where((text) => text.isNotEmpty).join('，'),
                child: InkWell(
                  focusNode: isTv ? _rowFocus : null,
                  onTap: editing || busy ? null : onPlay,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isTv ? 8 : 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 600;
                  final largeText =
                      MediaQuery.textScalerOf(context).scale(14) > 21;
                  final coverWidth = isTv
                      ? 56.0
                      : wide
                      ? 72.0
                      : 60.0;
                  final content = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        episode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (position.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          position,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        [
                          if (!isTv) source,
                          if (history.adapterName.isNotEmpty)
                            history.adapterName,
                          time,
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                  final actions = _actions(context, wide: wide || largeText);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ExcludeSemantics(
                            child: IgnorePointer(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: image.isEmpty
                                    ? Container(
                                        width: coverWidth,
                                        height: coverWidth * 1.4,
                                        color: colors.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.movie_outlined,
                                          color: colors.onSurfaceVariant,
                                        ),
                                      )
                                    : NetworkImgLayer(
                                        src: image,
                                        width: coverWidth,
                                        height: coverWidth * 1.4,
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(width: isTv ? 10 : 16),
                          Expanded(
                            child: ExcludeSemantics(
                              child: IgnorePointer(child: content),
                            ),
                          ),
                          if (!largeText) ...[
                            const SizedBox(width: 8),
                            actions,
                          ],
                        ],
                      ),
                      if (largeText) ...[
                        const SizedBox(height: 12),
                        Align(alignment: Alignment.centerRight, child: actions),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, {required bool wide}) {
    final colors = Theme.of(context).colorScheme;
    if (busy) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: Center(child: LoadingIndicator(size: 24)),
      );
    }
    if (editing) {
      return IconButton.filledTonal(
        tooltip: '删除记录',
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: colors.errorContainer,
          foregroundColor: colors.onErrorContainer,
        ),
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded),
      );
    }

    final buttons = [
      IconButton.filledTonal(
        focusNode: isTv ? _playFocus : null,
        tooltip: '继续播放',
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
        ),
        onPressed: onPlay,
        icon: const Icon(Icons.play_arrow_rounded),
      ),
      KazumiMenuButton(
        childFocusNode: isTv ? _moreFocus : null,
        menuChildren: [
          KazumiMenuItem(autofocus: isTv, onPressed: onDetails, label: '番剧详情'),
          SubmenuButton(
            menuChildren: [
              for (final type in CollectType.values)
                KazumiMenuItem(
                  selected: collectType == type,
                  onPressed: onChangeCollect == null
                      ? null
                      : () => onChangeCollect!(type),
                  label: type.label,
                ),
            ],
            child: Text(collectType.label),
          ),
          const Divider(),
          KazumiMenuItem(destructive: true, onPressed: onDelete, label: '删除记录'),
        ],
        builder: (context, toggle) => IconButton(
          focusNode: isTv ? _moreFocus : null,
          tooltip: '更多操作',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: toggle,
          icon: const Icon(Icons.more_horiz_rounded),
        ),
      ),
    ];
    return wide
        ? Row(mainAxisSize: MainAxisSize.min, children: buttons)
        : Column(mainAxisSize: MainAxisSize.min, children: buttons);
  }
}
