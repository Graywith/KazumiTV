import 'dart:async';
import 'package:flutter/material.dart';
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
    this.isBlocked,
  });
  final PlayerController player;
  final FocusNode scope;
  final Future<void> Function(String direction) onEpisode;
  final VoidCallback onBack;
  final VoidCallback? onEpisodes;
  final bool Function()? isBlocked;

  @override
  State<TvPlayerControls> createState() => _TvPlayerControlsState();
}

class _TvPlayerControlsState extends State<TvPlayerControls> {
  final _previousFocus = FocusNode(debugLabel: 'TV previous episode');
  final _playFocus = FocusNode(debugLabel: 'TV play/pause');
  final _nextFocus = FocusNode(debugLabel: 'TV next episode');
  final _episodesFocus = FocusNode(debugLabel: 'TV episode list');
  final _progressFocus = FocusNode(debugLabel: 'TV progress');
  Timer? _timer;
  LocalHistoryEntry? _entry;
  bool _visible = false;
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

  void _show() {
    if (!_visible) {
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
        if (mounted && _visible) _playFocus.requestFocus();
      });
    }
    _restartTimer();
  }

  void _hide() => _entry?.remove();

  List<FocusNode> get _buttons => [
    _previousFocus,
    _playFocus,
    _nextFocus,
    if (widget.onEpisodes != null) _episodesFocus,
  ];

  void _seek(bool forward) =>
      unawaited(widget.player.seekBy(Duration(seconds: forward ? 10 : -10)));

  void _openEpisodes() {
    _hide();
    widget.onEpisodes?.call();
  }

  void _activate() {
    if (_previousFocus.hasFocus) {
      unawaited(widget.onEpisode('prev'));
    } else if (_nextFocus.hasFocus) {
      unawaited(widget.onEpisode('next'));
    } else if (_episodesFocus.hasFocus) {
      _openEpisodes();
    } else if (!_progressFocus.hasFocus) {
      unawaited(widget.player.playOrPause());
    }
  }

  KeyEventResult _key(KeyEvent event) {
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
    } else if (_progressFocus.hasFocus) {
      _seek(right);
    } else {
      final buttons = _buttons;
      final current = buttons.indexWhere((node) => node.hasFocus);
      final index = current < 0
          ? 1
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
    _progressFocus.dispose();
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
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
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
                    Row(
                      children: [
                        Text(
                          _time(playback.currentPosition),
                          style: const TextStyle(color: Colors.white),
                        ),
                        Expanded(
                          child: Slider(
                            focusNode: _progressFocus,
                            label: '左右调整 10 秒',
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
                        Text(
                          _time(playback.duration),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          focusNode: _previousFocus,
                          onPressed: () => widget.onEpisode('prev'),
                          icon: const Icon(Icons.skip_previous),
                          label: const Text('上一集'),
                        ),
                        const SizedBox(width: 24),
                        FilledButton.icon(
                          focusNode: _playFocus,
                          onPressed: widget.player.playOrPause,
                          icon: Icon(
                            playback.playing ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(playback.playing ? '暂停' : '播放'),
                        ),
                        const SizedBox(width: 24),
                        TextButton.icon(
                          focusNode: _nextFocus,
                          onPressed: () => widget.onEpisode('next'),
                          icon: const Icon(Icons.skip_next),
                          label: const Text('下一集'),
                        ),
                        if (widget.onEpisodes != null) ...[
                          const SizedBox(width: 24),
                          TextButton.icon(
                            focusNode: _episodesFocus,
                            onPressed: _openEpisodes,
                            icon: const Icon(Icons.list),
                            label: const Text('选集'),
                          ),
                        ],
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
