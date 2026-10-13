import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:kazumi/bean/widget/state_presentation.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/download/download_module.dart';
import 'package:kazumi/modules/roads/road_module.dart';
import 'package:kazumi/pages/download/download_controller.dart';
import 'package:kazumi/pages/download/download_episode_sheet.dart';
import 'package:kazumi/pages/video/video_controller.dart';
import 'package:kazumi/plugins/plugins.dart';

class _Downloads implements DownloadController {
  @override
  DownloadRecord? getRecord(int bangumiId, String pluginName) => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Video implements VideoPageController {
  @override
  ObservableList<Road> get roadList => ObservableList.of([
    Road(name: 'test', data: ['/1', '/2'], identifier: ['第1集', '第2集']),
  ]);
  @override
  Plugin get currentPlugin => Plugin.fromJson({'name': 'test'});
  @override
  BangumiItem get bangumiItem => BangumiItem.fromJson({
    'id': 1,
    'name': 'test',
    'rating': {},
    'images': <String, String>{},
  });
  @override
  VideoEpisodeSelection get playbackEpisode =>
      const VideoEpisodeSelection(episode: 1, road: 0);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Color background(WidgetTester tester, Finder button) => tester
    .widget<Material>(
      find.descendant(of: button, matching: find.byType(Material)).first,
    )
    .color!;
double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'MI_Sans_Regular',
    )..addFont(rootBundle.load('assets/fonts/MiSans-Regular.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final brightness in Brightness.values) {
    testWidgets(
      'All TV action variants have a clear green focus in $brightness theme',
      (tester) async {
        final scheme = ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: brightness,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: scheme,
              fontFamily: 'MI_Sans_Regular',
            ),
            builder: (_, child) => TvSupport(child: child!),
            home: Scaffold(
              body: Column(
                children: [
                  FilledButton(onPressed: () {}, child: const Text('普通')),
                  FilledButton.tonal(
                    onPressed: () {},
                    child: const Text('tonal'),
                  ),
                  StateActionButton(onPressed: () {}, text: '共享操作'),
                  const FilledButton(onPressed: null, child: Text('禁用')),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final label in ['普通', 'tonal', '共享操作']) {
          final text = find.text(label);
          final button = find.ancestor(
            of: text,
            matching: find.byType(FilledButton),
          );
          final before = background(tester, button);
          final beforeText = DefaultTextStyle.of(
            tester.element(text),
          ).style.color!;
          expect(contrast(before, beforeText), greaterThanOrEqualTo(4.5));
          Focus.of(tester.element(text)).requestFocus();
          await tester.pumpAndSettle();
          final after = background(tester, button);
          final afterText = DefaultTextStyle.of(
            tester.element(text),
          ).style.color!;
          expect(
            before.computeLuminance() - after.computeLuminance(),
            greaterThan(.15),
          );
          expect(contrast(after, afterText), greaterThanOrEqualTo(4.5));
        }
        final disabled = find.ancestor(
          of: find.text('禁用'),
          matching: find.byType(FilledButton),
        );
        expect(
          background(tester, disabled),
          isNot(
            background(
              tester,
              find.ancestor(
                of: find.text('共享操作'),
                matching: find.byType(FilledButton),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Actual download selection action visibly changes on remote focus',
    (tester) async {
      final boundary = GlobalKey();
      final module = createModule(
        register: (c) {
          c.addSingleton<DownloadController>(() => _Downloads());
          c.route(
            '/',
            child: (_, _) => Scaffold(
              body: DownloadEpisodeSheet(
                road: 0,
                videoPageController: _Video(),
              ),
            ),
          );
        },
      );
      await tester.pumpWidget(
        ModularApp(
          module: module,
          initialRoute: '/',
          defaultTransition: TransitionType.none,
          child: Builder(
            builder: (context) => RepaintBoundary(
              key: boundary,
              child: MaterialApp.router(
                theme: ThemeData(
                  fontFamily: 'MI_Sans_Regular',
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.green,
                    brightness: Brightness.dark,
                  ),
                ),
                routerConfig: ModularApp.routerConfigOf(context),
                builder: (_, child) => TvSupport(child: child!),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('第1集'));
      await tester.pumpAndSettle();
      expect(find.text('下载 1 集'), findsOneWidget);
      final button = find.byType(FilledButton);
      final before = background(tester, button);
      Future<void> capture(String name) async {
        final render =
            boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/tmp/kazumi-tv-download-$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('normal');
      Focus.of(tester.element(find.text('下载 1 集'))).requestFocus();
      await tester.pumpAndSettle();
      final after = background(tester, button);
      expect(
        before.computeLuminance() - after.computeLuminance(),
        greaterThan(.15),
      );
      expect(Focus.of(tester.element(find.text('下载 1 集'))).hasFocus, isTrue);
      await capture('focused');
      expect(tester.takeException(), isNull);
    },
  );
}
