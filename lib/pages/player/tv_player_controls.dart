import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:kazumi/pages/player/player_controller.dart';

/// Remote controls delegate all playback and episode operations to Kazumi.
class TvPlayerControls extends StatefulWidget {
  const TvPlayerControls({
    super.key,
    required this.player,
    required this.scope,
    required this.onEpisode,
    required this.onBack,
    this.onEpisodes,
    this.onDanmakuSearch,
    this.onVideoInfo,
    this.onToggleDanmaku,
    this.isBlocked,
  });
  final PlayerController player;
  final FocusNode scope;
  final Future<void> Function(String direction) onEpisode;
  final VoidCallback onBack;
  final VoidCallback? onEpisodes;
  final VoidCallback? onDanmakuSearch;
  final VoidCallback? onVideoInfo;
  final VoidCallback? onToggleDanmaku;
  final bool Function()? isBlocked;

  @override
  State<TvPlayerControls> createState() => _TvPlayerControlsState();
}

class _TvPlayerControlsState extends State<TvPlayerControls> {
  final _previousFocus = FocusNode(debugLabel: 'TV previous episode');
  final _playFocus = FocusNode(debugLabel: 'TV play/pause');
  final _nextFocus = FocusNode(debugLabel: 'TV next episode');
  final _episodesFocus = FocusNode(debugLabel: 'TV episode list');
  final _danmakuFocus = FocusNode(debugLabel: 'TV danmaku search');
  final _danmakuToggleFocus = FocusNode(debugLabel: 'TV danmaku toggle');
  final _infoFocus = FocusNode(debugLabel: 'TV playback info');
  final _progressFocus = FocusNode(debugLabel: 'TV progress');
  Timer? _timer;
  LocalHistoryEntry? _entry;
  bool _visible = false;
  bool _openingOnProgress = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addEarlyKeyEventHandler(_key);
    // Loading removes the old focus holder. Restore it when playback mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          ModalRoute.of(context)?.isCurrent == true &&
          widget.isBlocked?.call() != true) {
        widget.scope.requestFocus();
      }
    });
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 5), _hide);
  }

  void _show({bool focusProgress = false}) {
    if (!_visible) {
      _openingOnProgress = focusProgress;
      setState(() => _visible = true);
      _entry = LocalHistoryEntry(
        impliesAppBarDismissal: false,
        onRemove: () {
          _entry = null;
          _timer?.cancel();
          if (mounted && !_disposed) {
            setState(() => _visible = false);
            widget.scope.requestFocus();
          }
        },
      );
      ModalRoute.of(context)!.addLocalHistoryEntry(_entry!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _visible) {
          (focusProgress ? _progressFocus : _playFocus).requestFocus();
          _openingOnProgress = false;
        }
      });
    }
    _restartTimer();
  }

  void _hide() => _entry?.remove();

  List<FocusNode> get _buttons => [
    if (widget.onVideoInfo != null) _infoFocus,
    if (widget.onEpisodes != null) _episodesFocus,
    _previousFocus,
    _playFocus,
    _nextFocus,
    if (widget.onToggleDanmaku != null) _danmakuToggleFocus,
    if (widget.onDanmakuSearch != null) _danmakuFocus,
  ];

  void _seek(bool forward) => unawaited(
    widget.player.seekBy(
      Duration(
        seconds: (forward ? 1 : -1) * widget.player.playback.arrowKeySkipTime,
      ),
    ),
  );

  void _openEpisodes() {
    _hide();
    widget.onEpisodes?.call();
  }

  void _openVideoInfo() {
    _hide();
    widget.onVideoInfo?.call();
  }

  void _activate() {
    if (_openingOnProgress) return;
    if (_previousFocus.hasFocus) {
      unawaited(widget.onEpisode('prev'));
    } else if (_nextFocus.hasFocus) {
      unawaited(widget.onEpisode('next'));
    } else if (_episodesFocus.hasFocus) {
      _openEpisodes();
    } else if (_danmakuToggleFocus.hasFocus) {
      widget.onToggleDanmaku?.call();
    } else if (_infoFocus.hasFocus) {
      _openVideoInfo();
    } else if (_danmakuFocus.hasFocus) {
      _hide();
      widget.onDanmakuSearch?.call();
    } else if (!_progressFocus.hasFocus) {
      unawaited(widget.player.playOrPause());
    }
  }

  KeyEventResult _key(KeyEvent event) {
    // Android sends a native Back event as well; let the route handle it once.
    if (defaultTargetPlatform == TargetPlatform.android &&
        event.logicalKey == LogicalKeyboardKey.goBack)
      return KeyEventResult.ignored;

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (ModalRoute.of(context)?.isCurrent != true ||
        widget.isBlocked?.call() == true) {
      return KeyEventResult.ignored;
    }
    // Own remote input for this active player route, even when loading or a
    // disappearing control left focus on the route scope instead of the player.
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.goBack || key == LogicalKeyboardKey.escape) {
      if (event is KeyDownEvent) {
        if (_visible) {
          _hide();
        } else {
          widget.onBack();
        }
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.contextMenu ||
        key == LogicalKeyboardKey.settings) {
      if (event is KeyDownEvent) _show();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaPlayPause) {
      if (event is KeyDownEvent) unawaited(widget.player.playOrPause());
      if (_visible) _restartTimer();
      return KeyEventResult.handled;
    }
    final left = key == LogicalKeyboardKey.arrowLeft;
    final right = key == LogicalKeyboardKey.arrowRight;
    final up = key == LogicalKeyboardKey.arrowUp;
    final down = key == LogicalKeyboardKey.arrowDown;
    final confirm =
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    if (!(left || right || up || down || confirm)) {
      return KeyEventResult.ignored;
    }
    if (!_visible) {
      if (left || right) {
        _show(focusProgress: true);
        _seek(right);
      } else if (event is KeyDownEvent) {
        _show();
      }
      return KeyEventResult.handled;
    }
    _restartTimer();
    if (confirm) {
      if (event is KeyDownEvent) _activate();
    } else if (up) {
      if (widget.player.playback.duration > Duration.zero) {
        _progressFocus.requestFocus();
      }
    } else if (down) {
      _playFocus.requestFocus();
    } else if (_progressFocus.hasFocus || _openingOnProgress) {
      _seek(right);
    } else {
      final buttons = _buttons;
      final current = buttons.indexWhere((node) => node.hasFocus);
      final index = current < 0
          ? buttons.indexOf(_playFocus)
          : (current + (right ? 1 : -1)).clamp(0, buttons.length - 1);
      buttons[index].requestFocus();
    }
    // Never let Slider's default up/down shortcuts alter playback progress.
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _disposed = true;
    FocusManager.instance.removeEarlyKeyEventHandler(_key);
    _timer?.cancel();
    _entry?.remove();
    _previousFocus.dispose();
    _playFocus.dispose();
    _nextFocus.dispose();
    _episodesFocus.dispose();
    _danmakuFocus.dispose();
    _progressFocus.dispose();
    _infoFocus.dispose();
    _danmakuToggleFocus.dispose();
    super.dispose();
  }

  String _time(Duration value) =>
      '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Theme.of(context).colorScheme.primary,
          brightness: Brightness.dark,
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.black87,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Observer(
              builder: (_) {
                final playback = widget.player.playback;
                final total = playback.duration.inMilliseconds.toDouble();
                final value = playback.currentPosition.inMilliseconds
                    .toDouble()
                    .clamp(0.0, total > 0 ? total : 1.0);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Observer(
                      builder: (_) {
                        final debug = widget.player.debug;
                        if (debug.playerWidth <= 0 || debug.playerHeight <= 0)
                          return const SizedBox.shrink();
                        final bitrate = double.tryParse(
                          debug.playerVideoBitrate,
                        );
                        return Text(
                          '实测 ${debug.playerWidth}×${debug.playerHeight}'
                          '${bitrate != null && bitrate > 0 ? ' · ${(bitrate / 1000000).toStringAsFixed(1)} Mbps' : ''}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            _time(playback.currentPosition),
                            style: const TextStyle(
                              color: Colors.white,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            focusNode: _progressFocus,
                            label: '左右调整 ${playback.arrowKeySkipTime} 秒',
                            value: value,
                            max: total > 0 ? total : 1,
                            onChanged: total > 0
                                ? (value) {
                                    _restartTimer();
                                    widget.player.seek(
                                      Duration(milliseconds: value.round()),
                                    );
                                  }
                                : null,
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            _time(playback.duration),
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (widget.onVideoInfo != null)
                                TextButton.icon(
                                  focusNode: _infoFocus,
                                  onPressed: _openVideoInfo,
                                  icon: const Icon(Icons.info_outline),
                                  label: const Text('播放信息'),
                                ),
                              if (widget.onEpisodes != null)
                                TextButton.icon(
                                  focusNode: _episodesFocus,
                                  onPressed: _openEpisodes,
                                  icon: const Icon(Icons.list),
                                  label: const Text('选集'),
                                ),
                              TextButton.icon(
                                focusNode: _previousFocus,
                                onPressed: () => widget.onEpisode('prev'),
                                icon: const Icon(Icons.skip_previous),
                                label: const Text('上一集'),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: FilledButton.icon(
                            focusNode: _playFocus,
                            onPressed: widget.player.playOrPause,
                            icon: Icon(
                              playback.playing ? Icons.pause : Icons.play_arrow,
                            ),
                            label: Text(playback.playing ? '暂停' : '播放'),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              TextButton.icon(
                                focusNode: _nextFocus,
                                onPressed: () => widget.onEpisode('next'),
                                icon: const Icon(Icons.skip_next),
                                label: const Text('下一集'),
                              ),
                              if (widget.onToggleDanmaku != null)
                                TextButton.icon(
                                  focusNode: _danmakuToggleFocus,
                                  onPressed: widget.onToggleDanmaku,
                                  icon: Icon(
                                    widget.player.danmaku.danmakuOn
                                        ? Icons.subtitles
                                        : Icons.subtitles_off_outlined,
                                  ),
                                  label: Text(
                                    widget.player.danmaku.danmakuOn
                                        ? '弹幕：开'
                                        : '弹幕：关',
                                  ),
                                ),
                              if (widget.onDanmakuSearch != null)
                                TextButton.icon(
                                  focusNode: _danmakuFocus,
                                  onPressed: () {
                                    _hide();
                                    widget.onDanmakuSearch?.call();
                                  },
                                  icon: const Icon(Icons.search),
                                  label: const Text('搜索弹幕'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
