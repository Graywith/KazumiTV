import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:kazumi/pages/player/controller/player_playback_controller.dart';
import 'package:kazumi/pages/player/player_controller.dart';
import 'package:kazumi/pages/player/tv_player_controls.dart';
import 'package:kazumi/pages/video/video_side_panel.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/pages/history/history_record_tile.dart';
import 'package:kazumi/modules/roads/road_module.dart';
import 'package:kazumi/pages/video/episode_selection_panel.dart';

class _Playback implements PlayerPlaybackController {
  @override
  Duration get duration => const Duration(minutes: 20);
  @override
  Duration get currentPosition => const Duration(minutes: 1);
  @override
  bool get playing => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Player implements PlayerController {
  final offsets = <Duration>[];
  int toggles = 0;
  @override
  final PlayerPlaybackController playback = _Playback();
  @override
  Future<void> seekBy(Duration offset, {bool enableSync = true}) async =>
      offsets.add(offset);
  @override
  Future<void> playOrPause() async {
    toggles++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
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
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(input.hasFocus, isFalse);
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
        const Duration(seconds: -10),
        const Duration(seconds: 10),
      ]);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
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
      expect(player.offsets.last, const Duration(seconds: -10));
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
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
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
      expect(player.offsets.last, const Duration(seconds: 10));
      await tester.pumpWidget(const SizedBox());
      scope.dispose();
      staleFocus.dispose();
    },
  );

  testWidgets('Continue watching cards scroll with D-pad and activate once', (
    tester,
  ) async {
    final scroll = ScrollController();
    int? selected;
    int activations = 0;
    final histories = List.generate(6, (index) {
      final item = BangumiItem(
        id: index,
        type: 2,
        name: 'Anime $index',
        nameCn: '',
        summary: '',
        airDate: '',
        airWeekday: 1,
        rank: 0,
        images: const {},
        tags: const [],
        alias: const [],
        ratingScore: 0,
        votes: 0,
        votesCount: const [],
        info: '',
      );
      return History(item, 3, 'source', DateTime(2026), '/source', '第 3 话')
        ..progresses[3] = Progress(3, 0, 65000);
    });
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => TvSupport(child: child!),
        home: Scaffold(
          body: SingleChildScrollView(
            controller: scroll,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < histories.length; i++)
                  SizedBox(
                    width: 340,
                    child: HistoryRecordTile(
                      history: histories[i],
                      continueWatching: true,
                      onPlay: () {
                        selected = i;
                        activations++;
                      },
                      onDetails: () {},
                      onDelete: () async {},
                      collectType: CollectType.values.first,
                      onChangeCollect: null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('看到 1:05'), findsNWidgets(6));
    expect(find.byType(IconButton), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(selected, 5);
    expect(activations, 1);
    expect(scroll.offset, greaterThan(1000));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    scroll.dispose();
  });

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
    'TV player seeks 10s, activates controls, hides and handles Back',
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
        const Duration(seconds: -10),
        const Duration(seconds: 10),
      ]);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(find.text('暂停'), findsOneWidget);
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
      expect(player.offsets.last, const Duration(seconds: 10));
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
