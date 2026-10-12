import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:kazumi/pages/menu/menu.dart';
import 'package:kazumi/pages/settings/settings_page.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/services/storage/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;
  setUpAll(() async {
    storage = await Directory.systemTemp.createTemp('tv-sidebar-test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => storage.path,
        );
    Hive.init(storage.path);
    await GStorage.init();
  });
  tearDownAll(() async {
    await Hive.close();
    await storage.delete(recursive: true);
  });
  Future<void> mount(WidgetTester tester, bool settings) async {
    final paths = settings
        ? ['player', 'danmaku', 'keyboard', 'plugin']
        : ['popular', 'timeline', 'collect', 'history', 'my'];
    final prefix = settings ? '/settings' : '/tab';
    final module = createModule(
      register: (c) {
        if (!settings) {
          c.route(
            '/settings/player',
            child: (_, _) => const Scaffold(body: Text('TV settings page')),
          );
        }
        c.route(
          prefix,
          child: (_, state) => settings
              ? SettingsPage(location: state.uri.path)
              : ScaffoldMenu(location: state.uri.path),
          children: (sub) {
            for (final path in paths) {
              sub.route(
                '/$path',
                child: (_, _) => Center(
                  child: TextButton(
                    onPressed: () {},
                    child: Text('page $path'),
                  ),
                ),
              );
            }
          },
        );
      },
    );
    await tester.pumpWidget(
      ModularApp(
        module: module,
        initialRoute: '$prefix/${paths.first}',
        defaultTransition: TransitionType.none,
        child: Builder(
          builder: (context) => MaterialApp.router(
            routerConfig: ModularApp.routerConfigOf(context),
            builder: (_, child) => TvSupport(child: child!),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> focusLabel(WidgetTester tester, String label) async {
    Focus.of(tester.element(find.text(label))).requestFocus();
    await tester.pumpAndSettle();
  }

  testWidgets('Android Back is counted once and exits only on second press', (
    tester,
  ) async {
    var exits = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exits++;
        return null;
      },
    );
    await mount(tester, false);
    await focusLabel(tester, '推荐');
    await tester.sendKeyEvent(
      LogicalKeyboardKey.goBack,
      physicalKey: PhysicalKeyboardKey.escape,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(exits, 0);
    await tester.sendKeyEvent(
      LogicalKeyboardKey.goBack,
      physicalKey: PhysicalKeyboardKey.escape,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(exits, 1);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  testWidgets('TV home labels remain visible and focus switches content', (
    tester,
  ) async {
    await mount(tester, false);
    for (final label in ['推荐', '时间表', '追番', '历史', '设置']) {
      expect(find.text(label), findsOneWidget);
    }
    await focusLabel(tester, '推荐');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('page timeline'), findsOneWidget);
    expect(Focus.of(tester.element(find.text('时间表'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('page collect'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('page history'), findsOneWidget);
    expect(Focus.of(tester.element(find.text('历史'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('TV settings page'), findsOneWidget);
    Navigator.of(tester.element(find.text('TV settings page'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('page history'), findsOneWidget);
    expect(Focus.of(tester.element(find.text('设置'))).hasFocus, isTrue);
  });

  testWidgets('TV settings category focus switches content without OK', (
    tester,
  ) async {
    await mount(tester, true);
    expect(find.text('操作设置'), findsNothing);
    expect(Focus.of(tester.element(find.text('播放设置'))).hasFocus, isTrue);
    await focusLabel(tester, '弹幕设置');
    expect(find.text('page danmaku'), findsOneWidget);
    expect(Focus.of(tester.element(find.text('弹幕设置'))).hasFocus, isTrue);
    await focusLabel(tester, '规则管理');
    expect(find.text('page plugin'), findsOneWidget);
    await focusLabel(tester, 'page plugin');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('规则管理'))).hasFocus, isTrue);
  });
}
