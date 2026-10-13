import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:kazumi/modules/download/download_module.dart';
import 'package:kazumi/pages/download/download_widgets.dart';

void main() {
  testWidgets(
    'Download row arrows reach play and delete without activating row',
    (tester) async {
      var plays = 0;
      var deletes = 0;
      final episode = DownloadEpisode(
        1,
        '第1集',
        0,
        DownloadStatus.completed,
        1,
        1,
        1,
        '/local/playlist.m3u8',
        '/local',
        'https://example.com/video',
        DateTime.now(),
        '',
        100,
        '/episode',
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => TvSupport(child: child!),
          home: Scaffold(
            body: DownloadEpisodeTile(
              episode: episode,
              statusText: '已完成',
              onPlay: () => plays++,
              actions: [
                IconButton(
                  tooltip: '播放',
                  onPressed: () => plays++,
                  icon: const Icon(Icons.play_arrow),
                ),
                IconButton(
                  tooltip: '删除',
                  onPressed: () => deletes++,
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final row = tester.widget<InkWell>(find.byType(InkWell).first);
      // Start on the row using OK's initial focus fallback.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus!.context!
            .findAncestorWidgetOfExactType<InkWell>(),
        isNotNull,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(plays, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(deletes, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(plays, 2);
      expect(row.onTap, isNotNull);
    },
  );
  testWidgets(
    'Download header right reaches more menu and Back restores its focus',
    (tester) async {
      var resumes = 0;
      var toggles = 0;
      final record = DownloadRecord(1, '离线番剧', '', '规则', {}, DateTime.now());
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => TvSupport(child: child!),
          home: Scaffold(
            body: DownloadRecordCard(
              record: record,
              expanded: true,
              onToggle: () => toggles++,
              onResumeAll: () => resumes++,
              onDeleteAll: () {},
              totalSpeed: 0,
              episodeTileBuilder: () => [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('全部开始'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(resumes, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('全部开始'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(toggles, 1);
    },
  );
}
