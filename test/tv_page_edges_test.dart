import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:kazumi/pages/video/video_side_panel.dart';
import 'package:kazumi/pages/video/episode_selection_panel.dart';
import 'package:kazumi/modules/roads/road_module.dart';

void main() {
  testWidgets('Up at first control reveals non-focusable page heading', (
    tester,
  ) async {
    final scroll = ScrollController();
    final first = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => TvSupport(child: child!),
        home: Scaffold(
          body: SingleChildScrollView(
            controller: scroll,
            child: Column(
              children: [
                const SizedBox(
                  height: 650,
                  child: Text('heading without a button'),
                ),
                TextButton(
                  focusNode: first,
                  onPressed: () {},
                  child: const Text('first control'),
                ),
                const SizedBox(height: 700),
              ],
            ),
          ),
        ),
      ),
    );
    first.requestFocus();
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(scroll.offset, 0);
    expect(first.hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
    first.dispose();
    scroll.dispose();
  });

  testWidgets(
    'Episode panel retains focus at horizontal edges and reaches lower episodes',
    (tester) async {
      final panel = GlobalKey<VideoSidePanelState>();
      var selected = 0;
      final episodesKey = GlobalKey<EpisodeSelectionPanelState>();
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => TvSupport(child: child!),
          home: Scaffold(
            body: Stack(
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text('outside panel'),
                ),
                VideoSidePanel(
                  key: panel,
                  onOpened: () => WidgetsBinding.instance.addPostFrameCallback((
                    _,
                  ) {
                    episodesKey.currentState!.revealCurrentEpisode(focus: true);
                  }),
                  fullscreen: true,
                  disableAnimations: true,
                  child: EpisodeSelectionPanel(
                    key: episodesKey,
                    title: 'test',
                    roads: [
                      Road(
                        name: 'source',
                        data: List.generate(16, (i) => 'url$i'),
                        identifier: List.generate(
                          16,
                          (i) => 'episode ${i + 1}',
                        ),
                      ),
                    ],
                    selectedRoad: 0,
                    selectedEpisode: 8,
                    downloads: const {},
                    disableAnimations: true,
                    onEpisodeSelected: (episode, _) => selected = episode,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      panel.currentState!.toggle();
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(find.text('episode 8'))).hasFocus, isTrue);
      Focus.of(tester.element(find.text('episode 8'))).requestFocus();
      await tester.pumpAndSettle();
      for (final key in [
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        expect(
          FocusManager.instance.primaryFocus,
          isNot(isA<FocusScopeNode>()),
        );
        expect(
          FocusManager.instance.primaryFocus!.context!
              .findAncestorWidgetOfExactType<VideoSidePanel>(),
          isNotNull,
        );
      }
      Focus.of(tester.element(find.text('episode 8'))).requestFocus();
      await tester.pumpAndSettle();
      for (var i = 0; i < 8; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selected, 16);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(panel.currentState!.isOpen, isFalse);
    },
  );
}
