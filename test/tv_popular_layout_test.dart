import 'package:kazumi/bean/widget/state_presentation.dart';
import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/card/bangumi_card.dart';
import 'package:kazumi/bean/tv/tv_action_focus.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/pages/popular/popular_controller.dart';
import 'package:kazumi/pages/popular/popular_page.dart';

class _MenuPopular extends PopularController {
  @override
  Future<void> queryBangumiByTag({String type = 'add'}) async {}
}

void main() {
  testWidgets(
    'TV category menu focuses current choice, switches with OK and closes with Back',
    (tester) async {
      final controller = _MenuPopular();
      controller.currentTag = '恋爱';
      controller.trendList.add(
        BangumiItem.fromJson({
          'id': 1,
          'name': 'test',
          'rating': {},
          'images': <String, String>{},
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => TvSupport(child: child!),
          home: PopularPage(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      Focus.of(tester.element(find.text('恋爱'))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MenuItemButton>(find.widgetWithText(MenuItemButton, '恋爱'))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      final selected = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, selected);
      for (var i = 0; i < 30; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      }
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsWidgets);
      expect(
        tester
            .widgetList<MenuItemButton>(find.byType(MenuItemButton))
            .any((item) => item.focusNode?.hasFocus == true),
        isTrue,
      );
      for (var i = 0; i < 30; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      }
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MenuItemButton>(find.widgetWithText(MenuItemButton, '热门番组'))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNothing);
      expect(Focus.of(tester.element(find.text('恋爱'))).hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(controller.currentTag, '悬疑');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MenuItemButton>(find.widgetWithText(MenuItemButton, '悬疑'))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNothing);
      expect(find.byType(PopularPage), findsOneWidget);
    },
  );

  testWidgets('TV recommendation shows two complete rows under compact title', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(960, 540));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = PopularController();
    controller.trendList.addAll(
      List.generate(
        24,
        (i) => BangumiItem.fromJson({
          'id': i + 1,
          'name': '番剧 $i',
          'name_cn': '番剧 $i',
          'rating': {},
          'images': <String, String>{},
        }),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            const SizedBox(width: 88),
            Expanded(child: PopularPage(controller: controller)),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final title = tester.widget<Text>(find.text('热门番组'));
    expect(
      title.style!.fontSize,
      Theme.of(
        tester.element(find.text('热门番组')),
      ).textTheme.headlineSmall!.fontSize,
    );
    final cards = find.byType(BangumiCardV);
    final rects = [
      for (final element in cards.evaluate())
        tester.getRect(find.byWidget(element.widget)),
    ];
    final rows =
        rects
            .where((r) => r.top < 540)
            .map((r) => r.top.round())
            .toSet()
            .toList()
          ..sort();
    expect(rows.length, 2);
    expect(rows.first, lessThanOrEqualTo(58));
    expect(
      rects
          .where((r) => r.top.round() == rows[1])
          .every((r) => r.bottom <= 540),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Detail action reuses Bangumi tonal focus style and grows slightly',
    (tester) async {
      final focus = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => TvSupport(child: child!),
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Column(
              children: [
                TvActionFocus(
                  child: FilledButton.tonal(
                    focusNode: focus,
                    onPressed: () {},
                    child: const Text('开始观看'),
                  ),
                ),
                StateActionButton.tonal(onPressed: () {}, text: '连接 Bangumi'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '开始观看'),
      );
      final context = tester.element(find.widgetWithText(FilledButton, '开始观看'));
      final style = button
          .defaultStyleOf(context)
          .merge(FilledButtonTheme.of(context).style);
      final referenceFinder = find.widgetWithText(FilledButton, '连接 Bangumi');
      final reference = tester.widget<FilledButton>(referenceFinder);
      final referenceContext = tester.element(referenceFinder);
      final referenceStyle = reference
          .defaultStyleOf(referenceContext)
          .merge(reference.themeStyleOf(referenceContext))
          .merge(reference.style);
      expect(
        style.backgroundColor!.resolve({}),
        referenceStyle.backgroundColor!.resolve({}),
      );
      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(
        style.overlayColor!.resolve({WidgetState.focused}),
        referenceStyle.overlayColor!.resolve({WidgetState.focused}),
      );
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        1.05,
      );
      focus.unfocus();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await tester.pumpWidget(const SizedBox());
      focus.dispose();
    },
  );
}
