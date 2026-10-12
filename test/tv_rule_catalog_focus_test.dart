import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/card/rule_card.dart';
import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:kazumi/modules/plugin/plugin_http_module.dart';
import 'package:kazumi/pages/plugin_editor/plugin_catalog_view.dart';
import 'package:kazumi/plugins/plugins.dart';
import 'package:kazumi/plugins/plugins_controller.dart';

void main() {
  testWidgets('D-pad reaches rules after ten installed non-focusable rows', (
    tester,
  ) async {
    final catalog = List.generate(
      16,
      (i) => PluginHTTPItem(
        name: 'rule $i',
        version: '1.0',
        useNativePlayer: false,
        author: '',
        lastUpdate: 16 - i,
      ),
    );
    final controller = PluginsController(catalogLoader: () async => catalog);
    controller.pluginList.addAll(
      List.generate(
        10,
        (i) => Plugin.fromTemplate()
          ..name = 'rule $i'
          ..version = '1.0',
      ),
    );
    await controller.refreshPluginCatalog();
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => TvSupport(child: child!),
        home: Scaffold(
          body: TvSettingsPane(
            child: PluginCatalogView(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final refresh = tester.element(
      find.descendant(
        of: find.byTooltip('刷新规则列表'),
        matching: find.byIcon(Icons.refresh_rounded),
      ),
    );
    Focus.of(refresh).requestFocus();
    await tester.pumpAndSettle();
    for (var i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    RuleCard? focusedRule;
    FocusManager.instance.primaryFocus!.context!.visitAncestorElements((
      element,
    ) {
      if (element.widget is RuleCard) focusedRule = element.widget as RuleCard;
      return true;
    });
    expect(focusedRule?.title, 'rule 15');
    final button = find.descendant(
      of: find.byWidget(focusedRule!),
      matching: find.text('安装'),
    );
    expect(
      tester
          .getRect(find.byType(CustomScrollView))
          .contains(tester.getCenter(button)),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
