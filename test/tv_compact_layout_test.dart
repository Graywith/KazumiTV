import 'package:kazumi/pages/history/history_list_view.dart';
import 'package:kazumi/pages/history/history_record_tile.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:kazumi/pages/onboarding/onboarding_step_layout.dart';

void main() {
  setUpAll(() async {
    final fonts = FontLoader('MI_Sans_Regular')
      ..addFont(rootBundle.load('assets/fonts/MiSans-Regular.ttf'));
    await fonts.load();
  });
  testWidgets(
    'Four history records remain fully visible below compact stats and date',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 540));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final entries = List.generate(
        4,
        (i) => History(
          BangumiItem.fromJson({
            'id': i + 1,
            'name': '番剧 $i',
            'rating': {},
            'images': <String, String>{},
          }),
          1,
          'source',
          DateTime.now(),
          '',
          '第 1 集',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'MI_Sans_Regular'),
          builder: (_, child) => TvSupport(child: child!),
          home: Scaffold(
            appBar: AppBar(toolbarHeight: 44, title: const Text('历史')),
            body: HistoryListView(
              entries: entries,
              header: const Text('观看足迹 · 4 部番剧 · 4 集'),
              itemBuilder: (entry, shape) => HistoryRecordTile(
                history: entry,
                borderRadius: shape,
                onPlay: () {},
                onDetails: () {},
                onDelete: () async {},
                collectType: CollectType.none,
                onChangeCollect: null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fourth = find.byWidgetPredicate(
        (widget) =>
            widget is HistoryRecordTile && widget.history.bangumiItem.id == 4,
      );
      expect(tester.getRect(fourth).bottom, lessThanOrEqualTo(540));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Compact TV onboarding gives full width to eight configuration rows',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 540));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'MI_Sans_Regular',
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.dark,
              ),
            ),
            builder: (_, child) => TvSupport(child: child!),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      children: [Text('添加规则'), Spacer(), Text('4 / 4')],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: OnboardingStepLayout(
                        leading: const OnboardingStepIcon(
                          icon: Icons.extension_rounded,
                        ),
                        title: '发现更多番剧来源',
                        subtitle: '添加喜欢的规则，也可以稍后在设置中添加。',
                        child: SettingsSection(
                          tiles: List.generate(
                            8,
                            (i) => SettingsTile.switchTile(
                              title: Text('规则 ${i + 1}'),
                              leading: Icons.extension_rounded,
                              initialValue: true,
                              onToggle: (_) {},
                              description: const Text('用于番剧搜索与播放'),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(onPressed: () {}, child: const Text('上一步')),
                        const Spacer(),
                        FilledButton(
                          onPressed: () {},
                          child: const Text('开始使用'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(SettingsSection)).width,
        greaterThan(850),
      );
      expect(tester.getRect(find.text('规则 8')).bottom, lessThan(480));
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        lessThanOrEqualTo(40),
      );
      expect(tester.widget<Text>(find.text('发现更多番剧来源')).style!.fontSize, 20);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '/tmp/kazumi-tv-030-onboarding.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    },
  );
}
