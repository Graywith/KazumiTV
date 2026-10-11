import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/services/update/auto_updater.dart';

void main() {
  test('TV updater selects v8a TV package instead of stock or v7a APK', () {
    final assets = [
      {'name': 'kazumi-android-arm64.apk'},
      {'name': 'kazumi-tv-armeabi-v7a-0.1.2.apk'},
      {
        'name': 'kazumi-tv-arm64-v8a-0.1.2.apk',
        'browser_download_url':
            'http://10.0.2.2:18080/kazumi-tv-arm64-v8a-0.1.2.apk',
        'digest': 'sha256:abc',
      },
    ];
    final asset = getUpdateAssetForType(assets, InstallationType.androidApk)!;
    expect(asset['name'], 'kazumi-tv-arm64-v8a-0.1.2.apk');
    expect(getUpdateFileHashFromAsset(asset), 'abc');
    expect(getUpdateDownloadUrlFromAsset(asset), startsWith(tvUpdateBase));
  });
}
