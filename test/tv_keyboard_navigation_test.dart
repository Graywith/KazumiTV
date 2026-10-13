import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/tv/tv_support.dart';

void main() {
  testWidgets(
    'TV fields browse without IME, OK starts editing, Back restores browse',
    (tester) async {
      final first = FocusNode();
      final second = FocusNode();
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => TvSupport(child: child!),
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  focusNode: first,
                  decoration: const InputDecoration(labelText: 'first'),
                ),
                TextField(
                  focusNode: second,
                  controller: controller,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(labelText: 'second'),
                ),
                TextButton(onPressed: () {}, child: const Text('save')),
              ],
            ),
          ),
        ),
      );
      first.requestFocus();
      await tester.pumpAndSettle();
      expect(
        tester.testTextInput.setClientArgs!['inputType']['name'],
        'TextInputType.none',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(second.hasFocus, isTrue);
      expect(
        tester.testTextInput.setClientArgs!['inputType']['name'],
        'TextInputType.none',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(second.hasFocus, isTrue);
      expect(
        tester.testTextInput.setClientArgs!['inputType']['name'],
        'TextInputType.url',
      );
      tester.testTextInput.enterText('https://example.com');
      await tester.pumpAndSettle();
      expect(controller.text, 'https://example.com');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(second.hasFocus, isTrue);
      expect(
        tester.testTextInput.setClientArgs!['inputType']['name'],
        'TextInputType.none',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(first.hasFocus, isTrue);
      expect(
        tester.testTextInput.setClientArgs!['inputType']['name'],
        'TextInputType.none',
      );
      await tester.pumpWidget(const SizedBox());
      first.dispose();
      second.dispose();
      controller.dispose();
    },
  );
  testWidgets(
    'Dialog form keyboard dismisses to browse before closing dialog',
    (tester) async {
      final input = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => TvSupport(child: child!),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('地址'),
                    content: TextFormField(
                      focusNode: input,
                      autofocus: true,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(input.hasFocus, isTrue);
      expect(
        tester.testTextInput.setClientArgs!['inputType']['name'],
        'TextInputType.none',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(
        tester.testTextInput.setClientArgs!['inputType']['name'],
        'TextInputType.emailAddress',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(input.hasFocus, isTrue);
      expect(
        tester.testTextInput.setClientArgs!['inputType']['name'],
        'TextInputType.none',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      await tester.pumpWidget(const SizedBox());
      input.dispose();
    },
  );
  testWidgets(
    'Android IME closing removes input edit layer without an extra Back',
    (tester) async {
      final input = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => TvSupport(child: child!),
          home: Scaffold(body: TextField(focusNode: input)),
        ),
      );
      input.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      tester.view.viewInsets = FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();
      expect(input.hasFocus, isTrue);
      expect(
        tester.testTextInput.setClientArgs!['inputType']['name'],
        'TextInputType.none',
      );
      expect(TvSupport.isInputEditing, isFalse);
      tester.view.resetViewInsets();
      await tester.pumpWidget(const SizedBox());
      input.dispose();
    },
  );
}
