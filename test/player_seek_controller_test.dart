import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/pages/player/controller/player_danmaku_controller.dart';
import 'package:kazumi/pages/player/controller/player_playback_controller.dart';
import 'package:kazumi/pages/player/controller/player_seek_controller.dart';
import 'package:kazumi/services/player/seek_position_tracker.dart';
import 'package:media_kit/media_kit.dart';

class _NativePlayer implements Player {
  final targets = <Duration>[];
  final completions = <Completer<void>>[];
  @override
  Future<void> seek(Duration position) {
    targets.add(position);
    final completion = Completer<void>();
    completions.add(completion);
    return completion.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Playback implements PlayerPlaybackController {
  _Playback(this.mediaPlayer);
  @override
  final Player mediaPlayer;
  @override
  Duration currentPosition = Duration.zero;
  @override
  Duration duration = const Duration(seconds: 12);
  @override
  final seekPosition = SeekPositionTracker();
  @override
  bool isCurrentPlayer(Player player) => identical(mediaPlayer, player);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Danmaku implements PlayerDanmakuController {
  @override
  void clearAndInvalidateScheduledDanmakus() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'Real seek queue accumulates 5s targets despite stale positions and clamps boundaries',
    () async {
      final native = _NativePlayer();
      final playback = _Playback(native);
      final seek = PlayerSeekController(
        playback: playback,
        danmaku: _Danmaku(),
        pause: ({bool enableSync = true}) async {},
        play: ({bool enableSync = true}) async {},
        onSeekCompleted: (_) async {},
      );
      final first = seek.seekBy(const Duration(seconds: 5));
      await Future<void>.delayed(Duration.zero);
      playback.currentPosition = playback.seekPosition.position(Duration.zero);
      final second = seek.seekBy(const Duration(seconds: 5));
      expect(playback.currentPosition, const Duration(seconds: 10));
      native.completions[0].complete();
      await first;
      await Future<void>.delayed(Duration.zero);
      playback.currentPosition = playback.seekPosition.position(
        const Duration(seconds: 5),
      );
      expect(playback.currentPosition, const Duration(seconds: 10));
      expect(native.targets, [
        const Duration(seconds: 5),
        const Duration(seconds: 10),
      ]);
      native.completions[1].complete();
      await second;
      final end = seek.seekBy(const Duration(seconds: 5));
      expect(playback.currentPosition, const Duration(seconds: 12));
      await Future<void>.delayed(Duration.zero);
      native.completions[2].complete();
      await end;
      final start = seek.seekBy(const Duration(seconds: -20));
      expect(playback.currentPosition, Duration.zero);
      await Future<void>.delayed(Duration.zero);
      native.completions[3].complete();
      await start;
      expect(native.targets.last, Duration.zero);
    },
  );
}
