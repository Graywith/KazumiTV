import 'tv_focus_audit_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:kazumi/pages/player/controller/player_playback_controller.dart';
import 'package:kazumi/pages/player/player_controller.dart';
import 'package:kazumi/pages/player/controller/player_debug_controller.dart';
import 'package:kazumi/pages/player/controller/player_danmaku_controller.dart';
import 'package:kazumi/pages/player/tv_player_controls.dart';
import 'package:kazumi/pages/video/video_side_panel.dart';
import 'package:kazumi/modules/roads/road_module.dart';
import 'package:kazumi/pages/video/episode_selection_panel.dart';

class _Playback implements PlayerPlaybackController {
  @override
  int arrowKeySkipTime = 5;
  @override
  Duration get duration => const Duration(minutes: 20);
  final _position = Observable(const Duration(minutes: 1));
  @override
  Duration get currentPosition => _position.value;
  @override
  set currentPosition(Duration value) =>
      runInAction(() => _position.value = value);
  @override
  bool get playing => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Danmaku implements PlayerDanmakuController {
  final enabled = Observable(false);
  @override
  bool get danmakuOn => enabled.value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Player implements PlayerController {
  @override
  final _Danmaku danmaku = _Danmaku();
  @override
  final debug = PlayerDebugController();
  final offsets = <Duration>[];
  int toggles = 0;
  @override
  final _Playback playback = _Playback();
  @override
  Future<void> seekBy(Duration offset, {bool enableSync = true}) async {
    offsets.add(offset);
    playback.currentPosition = Duration(
      milliseconds: (playback.currentPosition + offset).inMilliseconds.clamp(
        0,
        playback.duration.inMilliseconds,
      ),
    );
  }

  @override
  Future<void> playOrPause() async {
    toggles++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'Audit player control bar directions with global TV focus support',
    (tester) async {
      final scope = FocusNode();
      final player = _Player();
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => TvSupport(child: child!),
          home: Scaffold(
            body: Focus(
              focusNode: scope,
              autofocus: true,
              child: TvPlayerControls(
                player: player,
                scope: scope,
                onEpisode: (_) async {},
                onBack: () {},
                onDanmakuSearch: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pumpAndSettle();
      await auditKeys(tester, '播放器/控制栏', [
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowRight,
      ]);
      await tester.pumpWidget(const SizedBox());
      scope.dispose();
    },
  );

  testWidgets('TV remote activates danmaku search from control bar', (
    tester,
  ) async {
    final player = _Player();
    final scope = FocusNode();
    var searches = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Focus(
            focusNode: scope,
            autofocus: true,
            child: TvPlayerControls(
              player: player,
              scope: scope,
              onEpisode: (_) async {},
              onBack: () {},
              onDanmakuSearch: () => searches++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(searches, 1);
    expect(find.text('搜索弹幕'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    scope.dispose();
  });

  testWidgets('TV remote opens playback information and hides controls', (
    tester,
  ) async {
    final player = _Player();
    final scope = FocusNode();
    var opens = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => TvSupport(child: child!),
        home: Scaffold(
          body: Focus(
            focusNode: scope,
            autofocus: true,
            child: TvPlayerControls(
              player: player,
              scope: scope,
              onEpisode: (_) async {},
              onBack: () {},
              onEpisodes: () {},
              onDanmakuSearch: () {},
              onVideoInfo: () => opens++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
    }
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'TV playback info');
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(opens, 1);
    expect(find.text('播放信息'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    scope.dispose();
  });

  testWidgets(
    'Seven controls follow requested order with play exactly centered',
    (tester) async {
      final scope = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => TvSupport(child: child!),
          home: Scaffold(
            body: Focus(
              focusNode: scope,
              autofocus: true,
              child: TvPlayerControls(
                player: _Player(),
                scope: scope,
                onEpisode: (_) async {},
                onBack: () {},
                onEpisodes: () {},
                onVideoInfo: () {},
                onToggleDanmaku: () {},
                onDanmakuSearch: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pumpAndSettle();
      final labels = ['播放信息', '选集', '上一集', '暂停', '下一集', '弹幕：关', '搜索弹幕'];
      final xs = [
        for (final label in labels) tester.getCenter(find.text(label)).dx,
      ];
      expect(xs, orderedEquals([...xs]..sort()));
      final playRect = tester.getRect(
        find.ancestor(of: find.text('暂停'), matching: find.byType(FilledButton)),
      );
      final screenRect = tester.getRect(find.byType(Scaffold));
      expect(playRect.center.dx, screenRect.center.dx);
      for (var i = 0; i < 3; i++)
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus!.debugLabel,
        'TV playback info',
      );
      for (final label in labels.skip(1)) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(Focus.of(tester.element(find.text(label))).hasFocus, isTrue);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      scope.dispose();
    },
  );

  testWidgets('TV remote toggles danmaku using existing callback', (
    tester,
  ) async {
    final scope = FocusNode();
    final player = _Player();
    var toggles = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => TvSupport(child: child!),
        home: Scaffold(
          body: Focus(
            focusNode: scope,
            autofocus: true,
            child: TvPlayerControls(
              player: player,
              scope: scope,
              onEpisode: (_) async {},
              onBack: () {},
              onDanmakuSearch: () {},
              onEpisodes: () {},
              onVideoInfo: () {},
              onToggleDanmaku: () {
                toggles++;
                runInAction(
                  () =>
                      player.danmaku.enabled.value = !player.danmaku.danmakuOn,
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'TV danmaku toggle');
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(toggles, 1);
    expect(find.text('弹幕：开'), findsOneWidget);
    expect(find.text('弹幕：关'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(toggles, 2);
    expect(find.text('弹幕：关'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    scope.dispose();
  });

  testWidgets(
    'Playback controls show actual measured resolution and available video bitrate',
    (tester) async {
      final scope = FocusNode();
      final player = _Player();
      player.debug.playerWidth = 1920;
      player.debug.playerHeight = 1080;
      player.debug.playerVideoBitrate = '3500000';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Focus(
              focusNode: scope,
              autofocus: true,
              child: TvPlayerControls(
                player: player,
                scope: scope,
                onEpisode: (_) async {},
                onBack: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pumpAndSettle();
      expect(find.text('实测 1920×1080 · 3.5 Mbps'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      scope.dispose();
    },
  );

  testWidgets('TV sliders use left/right for value and up/down to leave', (
    tester,
  ) async {
    final slider = FocusNode();
    final above = FocusNode();
    final below = FocusNode();
    var value = .5;
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => TvSupport(child: child!),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (_, setState) => Column(
              children: [
                TextButton(
                  focusNode: above,
                  onPressed: () {},
                  child: const Text('above'),
                ),
                Slider(
                  focusNode: slider,
                  value: value,
                  divisions: 10,
                  onChanged: (next) => setState(() => value = next),
                ),
                TextButton(
                  focusNode: below,
                  onPressed: () {},
                  child: const Text('below'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    slider.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(value, closeTo(.6, .001));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(value, closeTo(.5, .001));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(below.hasFocus, isTrue);
    expect(value, closeTo(.5, .001));
    slider.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(above.hasFocus, isTrue);
    expect(value, closeTo(.5, .001));
    await tester.pumpWidget(const SizedBox.shrink());
    slider.dispose();
    above.dispose();
    below.dispose();
  });

  testWidgets('TV text fields release focus and Escape uses route back', (
    tester,
  ) async {
    final input = FocusNode();
    final button = FocusNode();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        builder: (_, child) => TvSupport(child: child!),
        home: const Scaffold(body: Text('home')),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: Column(
            children: [
              TextField(focusNode: input),
              TextButton(
                focusNode: button,
                onPressed: () {},
                child: const Text('save'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    input.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(button.hasFocus, isTrue);
    input.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(input.hasFocus, isTrue);
    expect(find.text('save'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    input.dispose();
    button.dispose();
  });

  testWidgets(
    'TV player owns remote keys after focus loss and yields to episodes',
    (tester) async {
      final player = _Player();
      final scope = FocusNode();
      final staleFocus = FocusNode();
      final panel = GlobalKey<VideoSidePanelState>();
      final navigator = GlobalKey<NavigatorState>();
      final episodes = <String>[];
      var chosenEpisode = 0;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          builder: (_, child) => TvSupport(child: child!),
          home: Scaffold(
            body: Stack(
              children: [
                Focus(
                  focusNode: staleFocus,
                  child: const SizedBox(width: 1, height: 1),
                ),
                Focus(
                  focusNode: scope,
                  autofocus: true,
                  child: TvPlayerControls(
                    player: player,
                    scope: scope,
                    onEpisode: (direction) async => episodes.add(direction),
                    onBack: () {},
                    isBlocked: () => panel.currentState?.isOpen ?? false,
                    onEpisodes: () => panel.currentState!.toggle(),
                  ),
                ),
                VideoSidePanel(
                  key: panel,
                  fullscreen: true,
                  disableAnimations: true,
                  onClosed: scope.requestFocus,
                  child: EpisodeSelectionPanel(
                    title: '剧集',
                    roads: [
                      Road(
                        name: '线路1',
                        data: ['/1', '/2'],
                        identifier: ['第1集', '第2集'],
                      ),
                    ],
                    selectedRoad: 0,
                    selectedEpisode: 1,
                    downloads: const {},
                    disableAnimations: true,
                    onEpisodeSelected: (episode, _) => chosenEpisode = episode,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Loading/header removal can leave primary focus outside the player holder.
      staleFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(player.offsets, [
        const Duration(seconds: -5),
        const Duration(seconds: 5),
      ]);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus!.debugLabel, 'TV progress');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      expect(player.toggles, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      expect(episodes, ['prev', 'next']);
      final before = player.offsets.length;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      expect(player.offsets.length, before);
      expect(player.toggles, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(player.offsets.last, const Duration(seconds: -5));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(player.offsets.length, before + 1);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      expect(
        player.toggles,
        2,
        reason: 'Holding OK must not toggle repeatedly',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlayPause);
      expect(player.toggles, 3);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(panel.currentState!.isOpen, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      expect(chosenEpisode, 2);
      expect(player.offsets.length, before + 1);
      await navigator.currentState!.maybePop();
      await tester.pumpAndSettle();
      expect(panel.currentState!.isOpen, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(player.offsets.last, const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
      scope.dispose();
      staleFocus.dispose();
    },
  );

  testWidgets('D-pad activates existing controls and scrolls a lazy list', (
    tester,
  ) async {
    final focus = List.generate(30, (_) => FocusNode());
    final scroll = ScrollController();
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => TvSupport(child: child!),
        home: Scaffold(
          body: ListView.builder(
            controller: scroll,
            itemCount: 30,
            itemBuilder: (_, i) => SizedBox(
              height: 90,
              child: TextButton(
                focusNode: focus[i],
                onPressed: () => selected = i,
                child: Text('番剧 $i'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focus.first.hasFocus, isTrue);
    for (var i = 0; i < 12; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(selected, 12);
    expect(scroll.offset, greaterThan(400));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    for (final node in focus) {
      node.dispose();
    }
    scroll.dispose();
  });

  testWidgets(
    'TV progress uses 5s steps, clamps start and keeps track bounds',
    (tester) async {
      final player = _Player();
      player.playback.currentPosition = Duration.zero;
      final scope = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Focus(
              focusNode: scope,
              autofocus: true,
              child: TvPlayerControls(
                player: player,
                scope: scope,
                onEpisode: (_) async {},
                onBack: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      for (final entry in [
        (LogicalKeyboardKey.arrowRight, 5),
        (LogicalKeyboardKey.arrowRight, 10),
        (LogicalKeyboardKey.arrowLeft, 5),
        (LogicalKeyboardKey.arrowLeft, 0),
        (LogicalKeyboardKey.arrowLeft, 0),
      ]) {
        await tester.sendKeyEvent(entry.$1);
        await tester.pumpAndSettle();
        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.value, entry.$2 * 1000);
        expect(slider.label, '左右调整 5 秒');
        expect(FocusManager.instance.primaryFocus!.debugLabel, 'TV progress');
      }
      player.playback.currentPosition = const Duration(seconds: 59);
      await tester.pumpAndSettle();
      final bounds = tester.getRect(find.byType(Slider));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(find.byType(Slider)).value, 64000);
      expect(tester.getRect(find.byType(Slider)), bounds);
      expect(player.toggles, 0);
      await tester.pumpWidget(const SizedBox());
      scope.dispose();
    },
  );

  testWidgets(
    'TV player seeks configured 5s, activates controls, hides and handles Back',
    (tester) async {
      final player = _Player();
      final scope = FocusNode();
      final navigator = GlobalKey<NavigatorState>();
      final episodes = <String>[];
      int exits = 0;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: Scaffold(
            body: Focus(
              focusNode: scope,
              autofocus: true,
              child: TvPlayerControls(
                player: player,
                scope: scope,
                onEpisode: (direction) async => episodes.add(direction),
                onBack: () => exits++,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(player.offsets, [
        const Duration(seconds: -5),
        const Duration(seconds: 5),
      ]);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(find.text('暂停'), findsOneWidget);
      expect(FocusManager.instance.primaryFocus!.debugLabel, 'TV progress');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(player.toggles, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(episodes, ['next']);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(episodes, ['next', 'prev']);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(player.offsets.last, const Duration(seconds: 5));
      await navigator.currentState!.maybePop();
      await tester.pump();
      expect(find.text('暂停'), findsNothing);
      expect(exits, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('暂停'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('暂停'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(exits, 1);
      await tester.pumpWidget(const SizedBox());
      scope.dispose();
    },
  );
  testWidgets('TV episode side panel takes focus and native Back closes it', (
    tester,
  ) async {
    expect(isTv, isTrue, reason: 'Run with --dart-define=KAZUMI_TV=true');
    final panel = GlobalKey<VideoSidePanelState>();
    final navigator = GlobalKey<NavigatorState>();
    final playerFocus = FocusNode();
    int selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: Scaffold(
          body: Stack(
            children: [
              Focus(
                focusNode: playerFocus,
                autofocus: true,
                child: const SizedBox.expand(),
              ),
              VideoSidePanel(
                key: panel,
                fullscreen: false,
                onClosed: playerFocus.requestFocus,
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () => selected = 1,
                      child: const Text('第1集'),
                    ),
                    TextButton(
                      onPressed: () => selected = 2,
                      child: const Text('第2集'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    panel.currentState!.toggle();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(selected, 2);
    await navigator.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('第1集'), findsNothing);
    expect(playerFocus.hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
    playerFocus.dispose();
  });

  testWidgets('Left/right leave a radio group without needing Tab', (
    tester,
  ) async {
    final radio = FocusNode();
    final next = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => TvSupport(child: child!),
        home: Scaffold(
          body: Column(
            children: [
              RadioGroup<bool>(
                groupValue: true,
                onChanged: (_) {},
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      focusNode: radio,
                      value: true,
                      title: const Text('来源 A'),
                    ),
                    const RadioListTile<bool>(
                      value: false,
                      title: Text('来源 B'),
                    ),
                  ],
                ),
              ),
              TextButton(
                focusNode: next,
                onPressed: () {},
                child: const Text('继续'),
              ),
            ],
          ),
        ),
      ),
    );
    radio.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(next.hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
    radio.dispose();
    next.dispose();
  });

  testWidgets('D-pad leaves nested page focus scopes for the sidebar', (
    tester,
  ) async {
    final sidebar = FocusNode();
    final card = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => TvSupport(child: child!),
        home: Scaffold(
          body: Row(
            children: [
              TextButton(
                focusNode: sidebar,
                onPressed: () {},
                child: const Text('搜索'),
              ),
              Expanded(
                child: FocusScope(
                  child: TextButton(
                    focusNode: card,
                    onPressed: () {},
                    child: const Text('番剧'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    card.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(sidebar.hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
    sidebar.dispose();
    card.dispose();
  });
}
