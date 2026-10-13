import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/card/bangumi_card.dart';
import 'package:kazumi/bean/card/bangumi_timeline_card.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/pages/history/history_record_tile.dart';

String auditFocusLabel(FocusNode? node) {
  if (node == null) return 'NO_FOCUS';
  if (node is FocusScopeNode) return 'SCOPE:${node.debugLabel}';
  var label = node.debugLabel ?? 'UNLABELLED';
  node.context?.visitAncestorElements((element) {
    final widget = element.widget;
    if (widget is SearchBar)
      label = 'SEARCH_ENTRY';
    else if (widget is EditableText)
      label = 'INPUT:${widget.controller.text}';
    else if (widget is Slider)
      label = 'SLIDER';
    else if (widget is BangumiCardV)
      label = 'POSTER:${widget.bangumiItem.id}';
    else if (widget is BangumiTimelineCard)
      label = 'TIMELINE:${widget.bangumiItem.id}';
    else if (widget is HistoryRecordTile)
      label = 'HISTORY:${widget.history.bangumiItem.id}';
    else if (widget is SettingsTile)
      label = 'SETTING:${widget.title}';
    else if (widget is IconButton)
      label = 'ICON:${widget.tooltip ?? widget.icon}';
    else if (widget is TextButton ||
        widget is FilledButton ||
        widget is MenuItemButton ||
        widget.runtimeType.toString() == '_SearchResultCard') {
      final texts = <String>[];
      void collect(Element child) {
        if (child.widget is Text) texts.add((child.widget as Text).data ?? '');
        child.visitChildren(collect);
      }

      element.visitChildren(collect);
      label = '${widget.runtimeType}:${texts.join('/')}';
    } else if (widget.key is ValueKey<String> &&
        (widget.key as ValueKey<String>).value.startsWith('collect-')) {
      label = (widget.key as ValueKey<String>).value;
    } else {
      return true;
    }
    return false;
  });
  if (label == 'UNLABELLED' && node.context is Element) {
    final texts = <String>[];
    void collect(Element child) {
      if (child.widget is Text) texts.add((child.widget as Text).data ?? '');
      child.visitChildren(collect);
    }

    (node.context as Element).visitChildren(collect);
    if (texts.isNotEmpty) label = 'CONTROL:${texts.take(4).join('/')}';
  }
  return label;
}

Future<void> auditKeys(
  WidgetTester tester,
  String path,
  List<LogicalKeyboardKey> keys,
) async {
  for (final key in keys) {
    final before = auditFocusLabel(FocusManager.instance.primaryFocus);
    await tester.sendKeyEvent(key);
    await tester.pumpAndSettle();
    final node = FocusManager.instance.primaryFocus;
    final rect = node?.context != null ? node!.rect : null;
    debugPrint(
      'FOCUS_AUDIT ${jsonEncode({'path': path, 'from': before, 'key': key.keyLabel, 'to': auditFocusLabel(node), 'rect': rect?.toString(), 'scope': node?.nearestScope?.debugLabel, 'valid': node != null && node is! FocusScopeNode && node.canRequestFocus})}',
    );
  }
}
