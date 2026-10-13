import 'package:flutter/material.dart';
import 'package:kazumi/bean/card/bangumi_info_card.dart';
import 'package:kazumi/bean/tv/tv_action_focus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:kazumi/bean/widget/collect_button.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';

class _Collect implements CollectController {
  @override
  int getCollectType(BangumiItem item) => 2;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'Detail start action keeps initial focus when loading skeleton disappears',
    (tester) async {
      final loading = ValueNotifier(true);
      final watch = FocusNode();
      final item = BangumiItem.fromJson({
        'id': 2,
        'name': 'test',
        'rating': {},
        'images': <String, String>{},
      });
      final module = createModule(
        register: (c) {
          c.addSingleton<CollectController>(() => _Collect());
          c.route(
            '/test',
            child: (_, _) => Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: loading,
                builder: (_, value, _) => BangumiInfoCardV(
                  bangumiItem: item,
                  isLoading: value,
                  showRating: false,
                  primaryAction: TvActionFocus(
                    child: FilledButton(
                      focusNode: watch,
                      autofocus: true,
                      onPressed: () {},
                      child: const Text('开始观看'),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
      await tester.pumpWidget(
        ModularApp(
          module: module,
          initialRoute: '/test',
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
      await tester.pump(const Duration(milliseconds: 100));
      expect(watch.hasFocus, isTrue);
      loading.value = false;
      await tester.pumpAndSettle();
      expect(watch.hasFocus, isTrue);
      await tester.pumpWidget(const SizedBox());
      loading.dispose();
      watch.dispose();
    },
  );

  testWidgets(
    'Collection menu opens with focus on saved status, not first item',
    (tester) async {
      final item = BangumiItem.fromJson({
        'id': 1,
        'name': 'test',
        'rating': {},
        'images': <String, String>{},
      });
      final module = createModule(
        register: (c) {
          c.addSingleton<CollectController>(() => _Collect());
          c.route(
            '/test',
            child: (_, _) => Scaffold(
              body: Center(child: CollectButton.extend(bangumiItem: item)),
            ),
          );
        },
      );
      await tester.pumpWidget(
        ModularApp(
          module: module,
          initialRoute: '/test',
          child: Builder(
            builder: (context) => MaterialApp.router(
              routerConfig: ModularApp.routerConfigOf(context),
              builder: (_, child) => TvSupport(child: child!),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.byType(FilledButton);
      tester.widget<FilledButton>(button).focusNode!.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final selected = find.widgetWithText(MenuItemButton, '想看');
      expect(selected, findsOneWidget);
      expect(
        tester.widget<MenuItemButton>(selected).focusNode!.hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(find.text('搁置'))).hasFocus, isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
