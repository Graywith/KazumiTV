import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:kazumi/pages/player/controller/player_debug_controller.dart';
import 'package:kazumi/pages/player/controller/player_playback_controller.dart';
import 'package:kazumi/pages/player/controller/player_super_resolution.dart';
import 'package:kazumi/pages/player/player_controller.dart';
import 'package:kazumi/pages/player/video_details_sheet.dart';

class _Native implements NativePlayer {
  String hardwareDecoder = 'mediacodec';
  @override
  Future<String> getProperty(
    String property, {
    bool waitForInitialization = true,
  }) async {
    return switch (property) {
      'path' => '/downloads/playlist.m3u8',
      'hwdec-current' => hardwareDecoder,
      'container-fps' => '23.976',
      'frame-drop-count' => '12',
      'paused-for-cache' => 'no',
      _ => throw StateError('Unavailable'),
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Media implements Player {
  _Media(this.platform);
  @override
  final NativePlayer platform;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Playback implements PlayerPlaybackController {
  _Playback(this.mediaPlayer);
  @override
  final Player mediaPlayer;
  @override
  SuperResolutionMode get superResolutionMode => SuperResolutionMode.off;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Controller implements PlayerController {
  _Controller(this.playback);
  @override
  final PlayerPlaybackController playback;
  @override
  final debug = PlayerDebugController();
  @override
  bool get isLocalPlayback => true;
  @override
  String get videoUrl => '/downloads/playlist.m3u8';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'Playback info reads actual decoder and local path, refreshes and handles unavailable properties',
    (tester) async {
      final native = _Native();
      final controller = _Controller(_Playback(_Media(native)));
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => TvSupport(child: child!),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showVideoDetailsSheet(
                  context,
                  playerController: controller,
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      expect(find.text('本地下载'), findsOneWidget);
      expect(find.text('mediacodec'), findsOneWidget);
      expect(find.text('23.976'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('不可用'), findsWidgets);
      native.hardwareDecoder = 'no';
      await tester.ensureVisible(find.text('刷新播放状态'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('刷新播放状态'));
      await tester.pumpAndSettle();
      expect(find.text('mediacodec'), findsNothing);
      expect(find.text('/downloads/playlist.m3u8'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
