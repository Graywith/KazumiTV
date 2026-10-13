import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/modules/download/download_module.dart';
import 'package:kazumi/services/download/download_manager.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/request/core/dio_factory.dart';

DownloadEpisode episode(String dir) => DownloadEpisode(
  1,
  '第1集',
  0,
  DownloadStatus.pending,
  0,
  0,
  0,
  '',
  dir,
  '',
  null,
  '',
  0,
  '/1',
);
DownloadRequest request(DownloadEpisode e, String url) => DownloadRequest(
  recordKey: 'test_1',
  bangumiId: 1,
  pluginName: 'test',
  episodeNumber: 1,
  m3u8Url: url,
  httpHeaders: const {},
  adBlockerEnabled: false,
  episode: e,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  late Directory storage;
  setUpAll(() async {
    storage = await Directory.systemTemp.createTemp('download-pause-test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => storage.path,
        );
    Hive.init(storage.path);
    await GStorage.init();
    await GStorage.putSetting(SettingsKeys.proxyEnable, false);
    DioFactory.reset();
  });
  tearDownAll(() async {
    DioFactory.reset();
    await Hive.close();
    await storage.delete(recursive: true);
  });
  for (final scenario in [(false, true), (true, true), (true, false)]) {
    final immediate = scenario.$1;
    final supportsRange = scenario.$2;
    test(
      'Real MP4 pause and ${immediate ? "immediate" : "normal"} resume (Range: $supportsRange) preserve bytes without cancellation error',
      () async {
        final dir = await Directory.systemTemp.createTemp('download-mp4-pause');
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final payload = Uint8List.fromList(
          List.generate(3 * 1024 * 1024, (i) => i % 251),
        );
        final hold = Completer<void>();
        final ranges = <int>[];
        var wholeRequests = 0;
        server.listen((incoming) async {
          final response = incoming.response;
          final range = incoming.headers.value('range');
          final start = range == null || !supportsRange
              ? 0
              : int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!);
          if (range != null) {
            ranges.add(
              int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!),
            );
            if (supportsRange) {
              response.statusCode = 206;
              response.headers.set(
                'content-range',
                'bytes $start-${payload.length - 1}/${payload.length}',
              );
            }
          } else {
            wholeRequests++;
          }
          response.headers.contentType = ContentType('video', 'mp4');
          response.contentLength = payload.length - start;
          try {
            if (range == null && wholeRequests == 2) {
              response.add(payload.sublist(0, 256 * 1024));
              await response.flush();
              await hold.future;
              response.add(payload.sublist(256 * 1024));
            } else {
              response.add(payload.sublist(start));
            }
            await response.close();
          } catch (_) {
            /* Expected disconnected server response after pause. */
          }
        });
        final e = episode(dir.path);
        final r = request(e, 'http://127.0.0.1:${server.port}/video.mp4');
        final manager = DownloadManager();
        final ready = Completer<void>(),
            paused = Completer<void>(),
            done = Completer<void>();
        final states = <int>[];
        manager.onProgress = (_, _, value, _) {
          states.add(value.status);
          if (value.status == DownloadStatus.downloading &&
              value.totalBytes > 0 &&
              !ready.isCompleted)
            ready.complete();
          if (value.status == DownloadStatus.paused && !paused.isCompleted)
            paused.complete();
          if (value.status == DownloadStatus.completed && !done.isCompleted)
            done.complete();
        };
        try {
          await manager.enqueue(r);
          await ready.future.timeout(const Duration(seconds: 15));
          manager.pause(r.recordKey, 1);
          final resume = immediate ? manager.resume(r) : null;
          await paused.future.timeout(const Duration(seconds: 10));
          expect(e.errorMessage, isEmpty);
          expect(states, isNot(contains(DownloadStatus.failed)));
          if (!immediate) {
            expect(e.status, DownloadStatus.paused);
            expect(e.progressPercent, greaterThan(0));
            expect(
              await File('${dir.path}/video.mp4.tmp').length(),
              greaterThan(0),
            );
            await manager.resume(r);
          } else {
            await resume;
          }
          await done.future.timeout(const Duration(seconds: 15));
          expect(ranges, hasLength(1));
          expect(ranges.single, greaterThan(0));
          expect(
            await File(e.localM3u8Path).readAsBytes(),
            orderedEquals(payload),
          );
          expect(e.errorMessage, isEmpty);
          expect(states, isNot(contains(DownloadStatus.failed)));
        } finally {
          manager.cancel(r.recordKey, 1);
          if (!hold.isCompleted) hold.complete();
          await server.close(force: true);
          await dir.delete(recursive: true);
        }
      },
    );
  }
  test(
    'HLS pause drains cancelled writers and resumes without redownloading completed segments',
    () async {
      final dir = await Directory.systemTemp.createTemp('download-hls-pause');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final hold = Completer<void>();
      var firstRequests = 0, secondRequests = 0;
      server.listen((incoming) async {
        final response = incoming.response;
        try {
          if (incoming.uri.path == '/list.m3u8') {
            response.write(
              '#EXTM3U\n#EXT-X-TARGETDURATION:5\n#EXTINF:5,\na.ts\n#EXTINF:5,\nb.ts\n#EXT-X-ENDLIST\n',
            );
          } else if (incoming.uri.path == '/a.ts') {
            firstRequests++;
            response.add(List.filled(4096, 1));
          } else {
            secondRequests++;
            response.contentLength = 8192;
            response.add(List.filled(4096, 2));
            await response.flush();
            if (secondRequests == 1) await hold.future;
            response.add(List.filled(4096, 2));
          }
          await response.close();
        } catch (_) {}
      });
      final e = episode(dir.path);
      final r = request(e, 'http://127.0.0.1:${server.port}/list.m3u8');
      final manager = DownloadManager();
      final ready = Completer<void>(),
          paused = Completer<void>(),
          done = Completer<void>();
      final states = <int>[];
      manager.onProgress = (_, _, value, _) {
        states.add(value.status);
        if (value.downloadedSegments == 1 && !ready.isCompleted)
          ready.complete();
        if (value.status == DownloadStatus.paused && !paused.isCompleted)
          paused.complete();
        if (value.status == DownloadStatus.completed && !done.isCompleted)
          done.complete();
      };
      try {
        await manager.enqueue(r);
        await ready.future.timeout(const Duration(seconds: 15));
        manager.pause(r.recordKey, 1);
        final resume = manager.resume(r);
        await paused.future.timeout(const Duration(seconds: 10));
        expect(e.errorMessage, isEmpty);
        await resume;
        await done.future.timeout(const Duration(seconds: 15));
        expect(firstRequests, 1);
        expect(e.downloadedSegments, 2);
        expect(e.totalBytes, 12288);
        expect(states, isNot(contains(DownloadStatus.failed)));
      } finally {
        manager.cancel(r.recordKey, 1);
        if (!hold.isCompleted) hold.complete();
        await server.close(force: true);
        await dir.delete(recursive: true);
      }
    },
  );
}
