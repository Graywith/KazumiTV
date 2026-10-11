import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:kazumi/pages/about/about_widgets.dart';

void main() {
  testWidgets('Scrolled about tile paints focus only inside its own bounds', (
    tester,
  ) async {
    final boundaryKey = GlobalKey();
    final tileKey = GlobalKey();
    final scroll = ScrollController(initialScrollOffset: 60);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          theme: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Colors.green),
          ),
          builder: (_, child) => TvSupport(child: child!),
          home: Scaffold(
            body: Row(
              children: [
                const SizedBox(width: 210),
                Expanded(
                  child: ListView(
                    controller: scroll,
                    children: [
                      const SizedBox(height: 200),
                      Material(
                        child: SizedBox(
                          height: 100,
                          child: AboutLinkTile(
                            key: tileKey,
                            icon: Icons.code,
                            title: 'source',
                            url: 'https://example.com',
                          ),
                        ),
                      ),
                      const SizedBox(height: 1000),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<Uint8List> pixels() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      return (await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data!.buffer.asUint8List();
      }))!;
    }

    final before = await pixels();
    final region = find.descendant(
      of: find.byKey(tileKey),
      matching: find.byType(MouseRegion),
    );
    Focus.of(tester.element(region.first)).requestFocus();
    await tester.pumpAndSettle();
    final after = await pixels();
    final rect = tester.getRect(find.byKey(tileKey)).inflate(4);
    var changed = 0;
    for (var i = 0; i < before.length; i += 4) {
      if (before[i] == after[i] &&
          before[i + 1] == after[i + 1] &&
          before[i + 2] == after[i + 2])
        continue;
      final pixel = i ~/ 4;
      final point = Offset((pixel % 800).toDouble(), (pixel ~/ 800).toDouble());
      expect(
        rect.contains(point),
        isTrue,
        reason: 'Focus painted outside the tile at $point; tile is $rect',
      );
      changed++;
    }
    expect(
      changed,
      greaterThan(1000),
      reason: 'Focus must remain clearly visible',
    );
    await tester.pumpWidget(const SizedBox());
    scroll.dispose();
  });
}
