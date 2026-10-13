import 'package:kazumi/bean/settings/network_mirror_settings.dart';
import 'package:kazumi/pages/settings/update_settings.dart';
import 'package:kazumi/pages/player/danmaku_source_sheet.dart';
import 'package:kazumi/pages/player/controller/player_danmaku_controller.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/pages/search/search_page.dart';
import 'package:kazumi/pages/search/search_controller.dart';
import 'package:kazumi/repositories/search_history_repository.dart';
import 'tv_focus_audit_helpers.dart';
import 'package:kazumi/bean/card/bangumi_card.dart';
import 'package:kazumi/bean/card/bangumi_timeline_card.dart';
import 'package:kazumi/pages/timeline/timeline_page.dart';
import 'package:kazumi/pages/timeline/timeline_controller.dart';
import 'package:kazumi/repositories/collect_repository.dart';
import 'package:kazumi/pages/history/history_list_view.dart';
import 'package:kazumi/pages/history/history_record_tile.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/bean/settings/settings_dropdown_tile.dart';
import 'package:kazumi/pages/collect/collect_library_view.dart';
import 'package:kazumi/modules/collect/collect_module.dart';
import 'package:kazumi/modules/collect/collect_layout.dart';
import 'package:kazumi/pages/settings/settings_module.dart';
import 'package:kazumi/pages/popular/popular_page.dart';
import 'package:kazumi/pages/popular/popular_controller.dart';
import 'package:kazumi/pages/download/download_controller.dart';
import 'package:mobx/mobx.dart';
import 'dart:async';
import 'package:kazumi/pages/info/info_page.dart';
import 'package:kazumi/pages/info/info_controller.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
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

class _StaticSearch extends SearchPageController {
  final bool empty;
  _StaticSearch({this.empty = false})
    : super(CollectRepository(), SearchHistoryRepository()) {
    hasMoreSearchResults = false;
  }
  @override
  Future<void> searchBangumi(String input, {String type = 'add'}) async {
    bangumiList.clear();
    if (empty) return;
    bangumiList.addAll(
      List.generate(
        24,
        (i) => BangumiItem.fromJson({
          'id': 300 + i,
          'name': '搜索$i',
          'rating': {},
          'images': <String, String>{},
        }),
      ),
    );
  }
}

class _StaticPopular extends PopularController {
  @override
  Future<void> queryBangumiByTrend({String type = 'add'}) async {}
  @override
  Future<void> queryBangumiByTag({String type = 'add'}) async {}
}

class _DetailCollect implements CollectController {
  @override
  int getCollectType(BangumiItem item) => 0;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DetailInfo extends InfoController {
  _DetailInfo(super.collectController);
  final ready = Completer<void>();
  @override
  Future<void> queryBangumiInfoByID(int id, {String type = 'init'}) async {
    isLoading = true;
    await ready.future;
    bangumiItem.votesCount = List.filled(10, 1);
    bangumiItem.votes = 10;
    isLoading = false;
  }
}

class _Downloads implements DownloadController {
  @override
  final recordKeys = ObservableList<String>();
  @override
  void refreshRecords() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SearchDanmaku implements PlayerDanmakuController {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
  Future<void> mount(
    WidgetTester tester,
    bool settings, {
    bool realPopular = false,
    bool realCollect = false,
    bool realDropdown = false,
    bool realInput = false,
    bool realNested = false,
    bool realTimeline = false,
    bool realHistory = false,
    int popularCount = 1,
    CollectLayout collectLayout = CollectLayout.cards,
  }) async {
    final popular = _StaticPopular();
    popular.trendList.add(
      BangumiItem.fromJson({
        'id': 1,
        'name': 'test',
        'rating': {},
        'images': <String, String>{},
      }),
    );
    for (var i = 1; i < popularCount; i++) {
      popular.trendList.add(
        BangumiItem.fromJson({
          'id': i + 1,
          'name': 'audit $i',
          'rating': {},
          'images': <String, String>{},
        }),
      );
    }
    final timeline = TimelineController(CollectRepository());
    timeline.bangumiCalendar.addAll(
      List.generate(
        7,
        (day) => List.generate(
          9,
          (i) => BangumiItem.fromJson({
            'id': 1000 + day * 10 + i,
            'name': 'day $day/$i',
            'rating': {},
            'images': <String, String>{},
          }),
        ),
      ),
    );
    final histories = List.generate(
      12,
      (i) => History(
        BangumiItem.fromJson({
          'id': 200 + i,
          'name': '历史$i',
          'rating': {},
          'images': <String, String>{},
        }),
        1,
        'source',
        DateTime.now().subtract(Duration(minutes: i)),
        '',
        '第1集',
      ),
    );
    final paths = settings
        ? ['player', 'danmaku', 'keyboard', 'plugin']
        : ['popular', 'timeline', 'collect', 'history', 'my'];
    final prefix = settings ? '/settings' : '/tab';
    final module = createModule(
      register: (c) {
        if (!settings) {
          c.route(
            '/settings',
            child: (_, state) => SettingsPage(location: state.uri.path),
            children: (sub) {
              sub.route(
                '/player',
                child: (_, _) => const TextButton(
                  onPressed: null,
                  child: Text('TV settings page'),
                ),
              );
              sub.route(
                '/danmaku',
                child: (_, _) => TextButton(
                  onPressed: () {},
                  child: const Text('TV settings content'),
                ),
              );
            },
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
                child: (_, _) => realInput && settings && path == 'player'
                    ? Column(
                        children: [
                          const TextField(
                            decoration: InputDecoration(labelText: '代理地址'),
                          ),
                          TextButton(onPressed: () {}, child: const Text('保存')),
                        ],
                      )
                    : realNested && settings && path == 'player'
                    ? Builder(
                        builder: (context) => TextButton(
                          onPressed: () =>
                              context.pushNamed('/settings/player/detail'),
                          child: const Text('打开子设置'),
                        ),
                      )
                    : realDropdown && settings && path == 'player'
                    ? SettingsDropdownTile<int>(
                        title: const Text('默认视频比例'),
                        value: 1,
                        options: const {0: '自动', 1: '原始', 2: '拉伸'},
                        onChanged: (_) {},
                      )
                    : realPopular && path == 'popular'
                    ? PopularPage(controller: popular)
                    : realTimeline && path == 'timeline'
                    ? TimelinePage(controller: timeline)
                    : realHistory && path == 'history'
                    ? HistoryListView(
                        entries: histories,
                        header: const Text('观看足迹'),
                        itemBuilder: (entry, shape) => HistoryRecordTile(
                          history: entry,
                          borderRadius: shape,
                          onPlay: () {},
                          onDetails: () {},
                          onDelete: () async {},
                          collectType: CollectType.none,
                          onChangeCollect: null,
                        ),
                      )
                    : realCollect && path == 'collect'
                    ? CollectLibraryView(
                        entries: List.generate(
                          12,
                          (i) => CollectedBangumi(
                            BangumiItem.fromJson({
                              'id': 100 + i,
                              'name': 'TV收藏$i',
                              'rating': {},
                              'images': <String, String>{},
                            }),
                            DateTime(2026, 1, 1),
                            1,
                          ),
                        ),
                        showRating: false,
                        layout: collectLayout,
                        onLayoutChanged: (_) {},
                        canEdit: (_) => true,
                        onOpen: (_) {},
                        onChangeType: (_, _) {},
                      )
                    : Center(
                        child: TextButton(
                          onPressed: () {},
                          child: Text('page $path'),
                        ),
                      ),
              );
            }
            if (realNested && settings)
              sub.route(
                '/player/detail',
                child: (_, _) =>
                    TextButton(onPressed: () {}, child: const Text('子设置保存')),
              );
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

  Future<void> activateLabel(WidgetTester tester, String label) async {
    await focusLabel(tester, label);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
  }

  testWidgets('Real direction step setting passes 5 seconds and reaches 15', (
    tester,
  ) async {
    await tester.runAsync(
      () => GStorage.putSetting(SettingsKeys.arrowKeySkipTime, 5),
    );
    final module = createModule(register: (c) => c.module(settingsModule));
    await tester.pumpWidget(
      ModularApp(
        module: module,
        initialRoute: '/settings/player',
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
    await tester.scrollUntilVisible(
      find.text('方向键跳转'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    final tile = find.ancestor(
      of: find.text('方向键跳转'),
      matching: find.byType(SettingsSliderTile),
    );
    final sliderFinder = find.descendant(
      of: tile,
      matching: find.byType(Slider),
    );
    final slider = tester.widget<Slider>(sliderFinder);
    // The Slider's internal focus is below its widget context.
    final focus = find
        .descendant(of: sliderFinder, matching: find.byType(Focus))
        .last;
    tester.widget<Focus>(focus).focusNode!.requestFocus();
    await tester.pumpAndSettle();
    for (var seconds = 6; seconds <= 15; seconds++) {
      await tester.runAsync(
        () => tester.sendKeyEvent(LogicalKeyboardKey.arrowRight),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(sliderFinder).value, seconds.toDouble());
      expect(GStorage.getSetting(SettingsKeys.arrowKeySkipTime), seconds);
    }
    expect(slider.max, 15);
    await tester.runAsync(
      () => tester.sendKeyEvent(LogicalKeyboardKey.arrowRight),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(sliderFinder).value, 15);
  });

  testWidgets(
    'Danmaku search uses the same tonal green action as TV settings',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.dark,
            ),
          ),
          builder: (_, child) => TvSupport(child: child!),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDanmakuSourceSheet(
                  context,
                  bangumiId: 9,
                  initialKeyword: 'test',
                  danmakuController: _SearchDanmaku(),
                  onBeforeApply: () {},
                ),
                child: const Text('open search'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open search'));
      await tester.pumpAndSettle();
      final buttonFinder = find.ancestor(
        of: find.text('搜索'),
        matching: find.byType(FilledButton),
      );
      final button = tester.widget<FilledButton>(buttonFinder);
      final context = tester.element(buttonFinder);
      expect(
        button.defaultStyleOf(context).backgroundColor!.resolve({}),
        Theme.of(context).colorScheme.secondaryContainer,
      );
      Focus.of(tester.element(find.text('搜索'))).requestFocus();
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(find.text('搜索'))).hasFocus, isTrue);
      final focusStates = {WidgetState.focused};
      final themeStyle = Theme.of(context).filledButtonTheme.style!;
      expect(
        themeStyle.overlayColor!.resolve(focusStates),
        isNot(themeStyle.overlayColor!.resolve({})),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Update server appears only in update settings', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => TvSupport(child: child!),
        home: const Scaffold(body: NetworkMirrorSettings()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('规则仓库镜像'), findsOneWidget);
    expect(find.text('TV 更新服务器'), findsNothing);
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => TvSupport(child: child!),
        home: const UpdateSettingsPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('TV 更新服务器'), findsOneWidget);
  });

  testWidgets(
    'Settings download route renders original download manager inside settings',
    (tester) async {
      final module = createModule(
        register: (c) {
          c.addSingleton<DownloadController>(() => _Downloads());
          c.module(settingsModule);
        },
      );
      await tester.pumpWidget(
        ModularApp(
          module: module,
          initialRoute: '/settings/download',
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
      expect(find.text('下载管理'), findsOneWidget);
      expect(find.text('还没有下载记录'), findsOneWidget);
      expect(find.text('离线下载'), findsOneWidget);
    },
  );

  testWidgets(
    'Opening real detail route focuses start watching after metadata load',
    (tester) async {
      final collect = _DetailCollect();
      final info = _DetailInfo(collect);
      final item = BangumiItem.fromJson({
        'id': 7,
        'name': 'test',
        'rating': {},
        'images': <String, String>{},
      });
      final module = createModule(
        register: (c) {
          c.addSingleton<CollectController>(() => collect);
          c.route(
            '/home',
            child: (context, _) => Scaffold(
              body: TextButton(
                autofocus: true,
                onPressed: () => context.pushNamed('/info'),
                child: const Text('open detail'),
              ),
            ),
          );
          c.route(
            '/info',
            child: (_, _) =>
                InfoPage(inputBangumiItem: item, infoController: info),
          );
        },
      );
      await tester.binding.setSurfaceSize(const Size(960, 540));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ModularApp(
          module: module,
          initialRoute: '/home',
          defaultTransition: TransitionType.none,
          child: Builder(
            builder: (context) => MaterialApp.router(
              routerConfig: ModularApp.routerConfigOf(context),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(.85)),
                child: TvSupport(child: child!),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open detail'));
      await tester.pump(const Duration(milliseconds: 100));
      info.ready.complete();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('开始观看'), findsOneWidget);
      expect(Focus.of(tester.element(find.text('开始观看'))).hasFocus, isTrue);
      final initialWatch = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, initialWatch);
      await auditKeys(tester, '详情/主按钮往返', [
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowUp,
      ]);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Native Android Back closes category overlay inside real TV shell',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 540));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await mount(tester, false, realPopular: true);
      await focusLabel(tester, '热门番组');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsWidgets);
      await tester.sendKeyEvent(
        LogicalKeyboardKey.goBack,
        physicalKey: PhysicalKeyboardKey.escape,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNothing);
      expect(find.byType(PopularPage), findsOneWidget);
      expect(Focus.of(tester.element(find.text('热门番组'))).hasFocus, isTrue);
      expect(find.text('再按一次退出应用'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final layout in CollectLayout.values) {
    testWidgets(
      'TV collection ${layout.name} can return to rail and climb to categories',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(960, 540));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await mount(tester, false, realCollect: true, collectLayout: layout);
        await activateLabel(tester, '追番');
        final cardNodes = FocusManager.instance.rootScope.descendants.where((
          node,
        ) {
          if (!node.canRequestFocus ||
              node.context == null ||
              node is FocusScopeNode)
            return false;
          var inside = false;
          node.context!.visitAncestorElements((element) {
            if (element.widget.key == const ValueKey('collect-100'))
              inside = true;
            return !inside;
          });
          return inside;
        }).toList()..sort((a, b) => b.rect.width.compareTo(a.rect.width));
        expect(cardNodes, isNotEmpty);
        cardNodes.first.requestFocus();
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
        expect(Focus.of(tester.element(find.text('追番'))).hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        cardNodes.first.requestFocus();
        await tester.pumpAndSettle();
        Finder category(String label) => find.descendant(
          of: find.widgetWithText(TextButton, label),
          matching: find.text(label),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        expect(Focus.of(tester.element(category('在看'))).hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, cardNodes.first);
        const categories = ['全部', '在看', '想看', '看过', '搁置', '抛弃'];
        for (var i = 0; i < 4; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pumpAndSettle();
          if (categories.any(
            (label) => Focus.of(tester.element(category(label))).hasFocus,
          ))
            break;
        }
        expect(
          categories.any(
            (label) => Focus.of(tester.element(category(label))).hasFocus,
          ),
          isTrue,
        );
        Focus.of(tester.element(category('在看'))).requestFocus();
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(Focus.of(tester.element(category('想看'))).hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(Focus.of(tester.element(category('想看'))).hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(Focus.of(tester.element(category('想看'))).hasFocus, isFalse);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'Settings native Back closes dropdown before leaving content pane',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 540));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await mount(tester, true, realDropdown: true);
      await focusLabel(tester, '默认视频比例');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MenuItemButton>(find.widgetWithText(MenuItemButton, '原始'))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(
        LogicalKeyboardKey.goBack,
        physicalKey: PhysicalKeyboardKey.escape,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNothing);
      expect(Focus.of(tester.element(find.text('默认视频比例'))).hasFocus, isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Audit real TV directional paths without changing behavior', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(960, 540));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const left = LogicalKeyboardKey.arrowLeft;
    const right = LogicalKeyboardKey.arrowRight;
    const up = LogicalKeyboardKey.arrowUp;
    const down = LogicalKeyboardKey.arrowDown;
    for (final page in ['推荐', '时间表', '追番', '历史']) {
      await mount(
        tester,
        false,
        realPopular: true,
        popularCount: 36,
        realTimeline: true,
        realHistory: true,
        realCollect: true,
      );
      await activateLabel(tester, page);
      await auditKeys(tester, '$page/侧栏进入', [
        right,
        down,
        down,
        up,
        left,
        right,
      ]);
      if (page == '推荐') {
        final card = find.byWidgetPredicate(
          (w) => w is BangumiCardV && w.bangumiItem.id == 1,
        );
        Focus.of(
          tester.element(
            find.descendant(of: card, matching: find.byType(Text)).first,
          ),
        ).requestFocus();
        await tester.pumpAndSettle();
        await auditKeys(tester, '推荐/第一海报', [
          right,
          left,
          left,
          right,
          up,
          down,
        ]);
        for (var i = 0; i < 10; i++) {
          await auditKeys(tester, '推荐/向下滚动', [down]);
        }
      } else if (page == '时间表') {
        final cards = find.byType(BangumiTimelineCard);
        final text = find
            .descendant(of: cards.first, matching: find.byType(Text))
            .first;
        Focus.of(tester.element(text)).requestFocus();
        await tester.pumpAndSettle();
        await auditKeys(tester, '时间表/第一番剧', [
          right,
          left,
          up,
          down,
          left,
          right,
        ]);
        Focus.of(tester.element(find.text('周日'))).requestFocus();
        await tester.pumpAndSettle();
        await auditKeys(tester, '时间表/周几向下', [down, down, down, down, down]);
        Focus.of(tester.element(text)).requestFocus();
        await tester.pumpAndSettle();
        await auditKeys(tester, '时间表/番剧向上往返', [up, down, down, down]);
      } else if (page == '追番') {
        await focusLabel(tester, 'TV收藏0');
        await auditKeys(tester, '追番/第一海报', [
          right,
          left,
          down,
          up,
          left,
          right,
        ]);
        await focusLabel(tester, 'TV收藏0');
        await auditKeys(tester, '追番/上方控件', [up, up, left, right, down, down]);
      } else {
        final first = find.byWidgetPredicate(
          (w) => w is HistoryRecordTile && w.history.bangumiItem.id == 200,
        );
        final node = FocusManager.instance.rootScope.descendants.firstWhere((
          node,
        ) {
          if (!node.canRequestFocus ||
              node.context == null ||
              node is FocusScopeNode)
            return false;
          var found = false;
          node.context!.visitAncestorElements((e) {
            if (e.widget == tester.widget(first)) found = true;
            return !found;
          });
          return found && node.rect.width > 100;
        });
        node.requestFocus();
        await tester.pumpAndSettle();
        await auditKeys(tester, '历史/第一记录', [
          left,
          right,
          up,
          down,
          right,
          left,
        ]);
        node.requestFocus();
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(right);
        await tester.pumpAndSettle();
        expect(
          auditFocusLabel(FocusManager.instance.primaryFocus),
          'ICON:继续播放',
        );
        await tester.sendKeyEvent(right);
        await tester.pumpAndSettle();
        expect(
          auditFocusLabel(FocusManager.instance.primaryFocus),
          'ICON:更多操作',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(Focus.of(tester.element(find.text('番剧详情'))).hasFocus, isTrue);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          auditFocusLabel(FocusManager.instance.primaryFocus),
          'ICON:更多操作',
        );
        await tester.sendKeyEvent(left);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(left);
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, node);
        node.requestFocus();
        await tester.pumpAndSettle();
        for (var i = 0; i < 14; i++) {
          await auditKeys(tester, '历史/向下滚动', [down]);
        }
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('Audit search input and actual result grid directional paths', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(960, 540));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => TvSupport(child: child!),
        home: SearchPage(controller: _StaticSearch()),
      ),
    );
    await tester.pumpAndSettle();
    final input = find.byType(TextField);
    await tester.enterText(input, '测试');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    debugPrint(
      'FOCUS_AUDIT search after submit: ${auditFocusLabel(FocusManager.instance.primaryFocus)}',
    );
    expect(
      auditFocusLabel(FocusManager.instance.primaryFocus),
      startsWith('_SearchResultCard:搜索0'),
    );
    await auditKeys(tester, '搜索/提交后', [
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowDown,
    ]);
    tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    final text = find.text('搜索0');
    expect(text, findsOneWidget);
    Focus.of(tester.element(text)).requestFocus();
    await tester.pumpAndSettle();
    await auditKeys(tester, '搜索/首个结果', [
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowLeft,
    ]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Sidebar returns to current destination and restores content focus on all pages',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 540));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final page in ['推荐', '时间表', '追番', '历史']) {
        await mount(
          tester,
          false,
          realPopular: true,
          popularCount: 36,
          realTimeline: true,
          realHistory: true,
          realCollect: true,
        );
        await activateLabel(tester, page);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        final entry = auditFocusLabel(FocusManager.instance.primaryFocus);
        if (page == '推荐') expect(entry, 'POSTER:1');
        if (page == '时间表') expect(entry, contains('今天'));
        if (page == '时间表') {
          final weekday = FocusManager.instance.primaryFocus;
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
          expect(
            auditFocusLabel(FocusManager.instance.primaryFocus),
            'TIMELINE:${1000 + (DateTime.now().weekday - 1) * 10}',
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pumpAndSettle();
          expect(FocusManager.instance.primaryFocus, weekday);
        }
        if (page == '追番') expect(entry, 'TextButton:在看');
        final label = page == '推荐'
            ? 'POSTER:1'
            : page == '时间表'
            ? 'TIMELINE:${1000 + (DateTime.now().weekday - 1) * 10}'
            : page == '追番'
            ? 'collect-100'
            : 'HISTORY:200';
        final nodes =
            FocusManager.instance.rootScope.descendants
                .where(
                  (n) =>
                      n is! FocusScopeNode &&
                      n.canRequestFocus &&
                      n.context != null &&
                      auditFocusLabel(n) == label,
                )
                .toList()
              ..sort((a, b) => b.rect.width.compareTo(a.rect.width));
        expect(nodes, isNotEmpty);
        final original = nodes.first;
        original.requestFocus();
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
        expect(
          auditFocusLabel(FocusManager.instance.primaryFocus),
          'TextButton:$page',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, original);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets('Search with no results restores input focus', (tester) async {
    await tester.binding.setSurfaceSize(const Size(960, 540));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => TvSupport(child: child!),
        home: SearchPage(controller: _StaticSearch(empty: true)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '不存在的番剧');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Editing Back restores input browse, next Back returns settings sidebar',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 540));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final native in [false, true]) {
        await mount(tester, true, realInput: true);
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        expect(
          tester.testTextInput.setClientArgs!['inputType']['name'],
          'TextInputType.none',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(
          tester.testTextInput.setClientArgs!['inputType']['name'],
          'TextInputType.text',
        );
        Future<void> back() async {
          if (native) {
            await tester.sendKeyEvent(
              LogicalKeyboardKey.goBack,
              physicalKey: PhysicalKeyboardKey.escape,
            );
            await tester.binding.handlePopRoute();
          } else
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        }

        await back();
        expect(find.byType(SettingsPage), findsOneWidget);
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .hasFocus,
          isTrue,
        );
        expect(
          tester.testTextInput.setClientArgs!['inputType']['name'],
          'TextInputType.none',
        );
        await back();
        expect(Focus.of(tester.element(find.text('播放设置'))).hasFocus, isTrue);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
  testWidgets('Audit Back from nested settings pane', (tester) async {
    await tester.binding.setSurfaceSize(const Size(960, 540));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mount(tester, true, realNested: true);
    await activateLabel(tester, '打开子设置');
    await focusLabel(tester, '子设置保存');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    debugPrint(
      'BACK_AUDIT nested => ${auditFocusLabel(FocusManager.instance.primaryFocus)}; child still shown=${find.text('子设置保存').evaluate().isNotEmpty}; parent shown=${find.text('打开子设置').evaluate().isNotEmpty}',
    );
    expect(find.text('子设置保存'), findsNothing);
    expect(find.text('打开子设置'), findsOneWidget);
    expect(Focus.of(tester.element(find.text('打开子设置'))).hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Audit toolbar Back compared with native settings Back', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(960, 540));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mount(tester, false);
    await activateLabel(tester, '设置');
    await activateLabel(tester, '弹幕设置');
    await focusLabel(tester, 'TV settings content');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    debugPrint(
      'BACK_AUDIT remote => settings shown=${find.byType(SettingsPage).evaluate().isNotEmpty}, focus=${auditFocusLabel(FocusManager.instance.primaryFocus)}',
    );
    await focusLabel(tester, 'TV settings content');
    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();
    debugPrint(
      'BACK_AUDIT toolbar => settings shown=${find.byType(SettingsPage).evaluate().isNotEmpty}, focus=${auditFocusLabel(FocusManager.instance.primaryFocus)}',
    );
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(Focus.of(tester.element(find.text('弹幕设置'))).hasFocus, isTrue);
    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsNothing);
    expect(Focus.of(tester.element(find.text('设置'))).hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Audit main content Back destination', (tester) async {
    await tester.binding.setSurfaceSize(const Size(960, 540));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mount(tester, false);
    await activateLabel(tester, '历史');
    await focusLabel(tester, 'page history');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    debugPrint(
      'BACK_AUDIT main content => ${auditFocusLabel(FocusManager.instance.primaryFocus)}, history=${find.text('page history').evaluate().isNotEmpty}, recommended=${find.text('page popular').evaluate().isNotEmpty}',
    );
    expect(find.text('page history'), findsOneWidget);
    expect(Focus.of(tester.element(find.text('历史'))).hasFocus, isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('page popular'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

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
    expect(find.text('page popular'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('page timeline'), findsOneWidget);
    expect(Focus.of(tester.element(find.text('时间表'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('page collect'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('page history'), findsOneWidget);
    expect(Focus.of(tester.element(find.text('历史'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(
      Focus.of(tester.element(find.text('page history'))).hasFocus,
      isTrue,
    );
    await focusLabel(tester, '历史');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('TV settings page'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('page history'), findsOneWidget);
    expect(Focus.of(tester.element(find.text('设置'))).hasFocus, isTrue);
    final settingsButton = tester.widget<TextButton>(
      find.ancestor(of: find.text('设置'), matching: find.byType(TextButton)),
    );
    final historyButton = tester.widget<TextButton>(
      find.ancestor(of: find.text('历史'), matching: find.byType(TextButton)),
    );
    expect(settingsButton.style!.backgroundColor!.resolve({}), isNotNull);
    expect(historyButton.style!.backgroundColor?.resolve({}), isNull);
  });

  testWidgets(
    'Settings native Back returns right to left then to home without blank page',
    (tester) async {
      await mount(tester, false);
      await activateLabel(tester, '设置');
      expect(find.text('TV settings page'), findsOneWidget);
      expect(Focus.of(tester.element(find.text('播放设置'))).hasFocus, isTrue);
      await activateLabel(tester, '弹幕设置');
      await focusLabel(tester, 'TV settings content');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(find.text('弹幕设置'))).hasFocus, isTrue);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('page popular'), findsOneWidget);
      expect(Focus.of(tester.element(find.text('设置'))).hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('TV settings category requires OK before switching content', (
    tester,
  ) async {
    await mount(tester, true);
    expect(find.text('操作设置'), findsNothing);
    expect(Focus.of(tester.element(find.text('播放设置'))).hasFocus, isTrue);
    await activateLabel(tester, '弹幕设置');
    expect(find.text('page danmaku'), findsOneWidget);
    expect(Focus.of(tester.element(find.text('弹幕设置'))).hasFocus, isTrue);
    await activateLabel(tester, '规则管理');
    expect(find.text('page plugin'), findsOneWidget);
    await focusLabel(tester, 'page plugin');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('规则管理'))).hasFocus, isTrue);
  });
}
