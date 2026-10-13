import 'package:kazumi/bean/settings/settings_dropdown_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/tv/tv_support.dart';

void main() {
  testWidgets(
    'Settings dropdown enters current choice, contains focus and closes with Back',
    (tester) async {
      final value = ValueNotifier(1);
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => TvSupport(child: child!),
          home: Scaffold(
            body: TvSettingsPane(
              child: Column(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: value,
                    builder: (_, selected, _) => SettingsDropdownTile<int>(
                      title: const Text('视频比例'),
                      value: selected,
                      options: const {0: '自动', 1: '原始', 2: '拉伸'},
                      onChanged: (next) => value.value = next,
                    ),
                  ),
                  TextButton(onPressed: () {}, child: const Text('下一个设置')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Focus.of(tester.element(find.text('视频比例'))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final current = tester.widget<MenuItemButton>(
        find.widgetWithText(MenuItemButton, '原始'),
      );
      expect(current.focusNode?.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(current.focusNode!.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(value.value, 2);
      expect(find.byType(MenuItemButton), findsNothing);
      expect(Focus.of(tester.element(find.text('视频比例'))).hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MenuItemButton>(find.widgetWithText(MenuItemButton, '拉伸'))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      for (var i = 0; i < 10; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      }
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MenuItemButton>(find.widgetWithText(MenuItemButton, '拉伸'))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNothing);
      expect(Focus.of(tester.element(find.text('视频比例'))).hasFocus, isTrue);
      await tester.pumpWidget(const SizedBox());
      value.dispose();
    },
  );

  testWidgets('Settings columns keep visible focus at their vertical edges', (
    tester,
  ) async {
    final sidebar = List.generate(3, (_) => FocusNode());
    final controls = List.generate(12, (_) => FocusNode());
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => TvSupport(child: child!),
        home: Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 180,
                child: TvSettingsPane(
                  child: Column(
                    children: [
                      for (var i = 0; i < sidebar.length; i++)
                        SizedBox(
                          height: 90,
                          child: TextButton(
                            focusNode: sidebar[i],
                            onPressed: () {},
                            child: Text('menu $i'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TvSettingsPane(
                  child: FocusScope(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var i = 0; i < controls.length; i++)
                            SizedBox(
                              height: 90,
                              child: i == 5
                                  ? Slider(
                                      focusNode: controls[i],
                                      value: .5,
                                      onChanged: (_) {},
                                    )
                                  : TextButton(
                                      focusNode: controls[i],
                                      onPressed: () {},
                                      child: Text('control $i'),
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    sidebar.first.requestFocus();
    await tester.pumpAndSettle();
    for (var i = 0; i < 15; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }
    expect(sidebar.last.hasPrimaryFocus, isTrue);
    controls.first.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    for (var i = 0; i < 30; i++) {
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 10));
    }
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(controls.last.hasPrimaryFocus, isTrue);
    final last = tester.getRect(find.text('control 11'));
    expect(last.top, greaterThanOrEqualTo(0));
    expect(last.bottom, lessThanOrEqualTo(600));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(controls[10].hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(sidebar.any((node) => node.hasPrimaryFocus), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(controls.any((node) => node.hasPrimaryFocus), isTrue);
    await tester.pumpWidget(const SizedBox());
    for (final node in [...sidebar, ...controls]) {
      node.dispose();
    }
  });
}
