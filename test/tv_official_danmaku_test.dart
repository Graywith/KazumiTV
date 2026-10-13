import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:kazumi/bean/settings/danmaku_service_tile.dart';
import 'package:kazumi/bean/settings/tv_update_server_tile.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/request/clients/danmaku_client.dart';
import 'package:kazumi/services/update/auto_updater.dart';
import 'package:kazumi/utils/dandan_credentials.dart';
import 'package:kazumi/utils/crypto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;
  setUpAll(() async {
    storage = await Directory.systemTemp.createTemp('tv-official-danmaku-test');
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
  test(
    'Only official API is used and saved credentials still sign requests',
    () async {
      await GStorage.putSetting(SettingsKeys.dandanAppId, 'sample-app');
      await GStorage.putSetting(SettingsKeys.dandanAppSecret, 'sample-key');
      expect(DanmakuClient.apiBase, 'https://api.dandanplay.net');
      expect(DanmakuClient.isConfigured, true);
      expect(dandanCredentials['value'], 'sample-key');
      expect(
        generateDandanSignature('/api/v2/search/episodes', 1),
        'fE35e+RF1K7T/ZTijxiH3xpcc6lKjzWffn1/Gdee6Kc=',
      );
      await GStorage.putSetting(SettingsKeys.dandanAppSecret, '');
      expect(DanmakuClient.isConfigured, false);
      await expectLater(
        DanmakuClient.instance.testConnection(),
        throwsStateError,
      );
    },
  );
  testWidgets(
    'Official-only editor masks Secret and validates without erasing saved keys',
    (tester) async {
      await tester.runAsync(() async {
        await GStorage.putSetting(SettingsKeys.dandanAppId, 'sample-app');
        await GStorage.putSetting(SettingsKeys.dandanAppSecret, 'sample-key');
      });
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => TvSupport(child: child!),
          home: const Scaffold(body: DanmakuServiceTile()),
        ),
      );
      await tester.tap(find.text('弹幕服务'));
      await tester.pumpAndSettle();
      expect(find.text('弹幕来源'), findsNothing);
      expect(find.widgetWithText(TextField, '服务器地址'), findsNothing);
      final secret = tester.widget<TextField>(
        find.widgetWithText(TextField, 'App Secret'),
      );
      expect(secret.obscureText, true);
      expect(secret.controller!.text, 'sample-key');
      await tester.enterText(find.widgetWithText(TextField, 'App Secret'), '');
      await tester.tap(find.text('保存并测试'));
      await tester.pumpAndSettle();
      expect(find.text('请填写 App ID 和 App Secret'), findsOneWidget);
      expect(GStorage.getSetting(SettingsKeys.dandanAppSecret), 'sample-key');
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'Update server starts empty and preserves an existing device address',
    (tester) async {
      expect(tvUpdateBase, isEmpty);
      await tester.runAsync(
        () => GStorage.putSetting(SettingsKeys.tvUpdateServer, ''),
      );
      Future<void> mount() async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (_, child) => TvSupport(child: child!),
            home: const Scaffold(body: TvUpdateServerTile()),
          ),
        );
        await tester.pumpAndSettle();
      }

      await mount();
      expect(find.text('未配置'), findsOneWidget);
      await tester.tap(find.text('TV 更新服务器'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(
        () => GStorage.putSetting(
          SettingsKeys.tvUpdateServer,
          'http://192.168.5.21:18080',
        ),
      );
      await mount();
      expect(find.text('http://192.168.5.21:18080'), findsOneWidget);
      await tester.tap(find.text('TV 更新服务器'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'http://192.168.5.21:18080',
      );
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
    },
  );
}
