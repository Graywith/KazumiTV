import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/services/player/android_playback_output.dart';

void main() {
  test(
    'TV automatic output selects direct MediaCodec across supported Android versions',
    () {
      for (final sdk in [31, 33, 34, 36]) {
        expect(
          androidPlaybackRenderer(
            isTv: true,
            selected: 'auto',
            sdkVersion: sdk,
          ),
          'mediacodec_embed',
        );
      }
    },
  );
  test(
    'Manual renderer selections remain available for compatibility fallback',
    () {
      for (final selected in ['gpu', 'gpu-next', 'mediacodec_embed']) {
        expect(
          androidPlaybackRenderer(
            isTv: true,
            selected: selected,
            sdkVersion: 31,
          ),
          selected,
        );
      }
    },
  );
  test('Phone automatic GPU selection is unchanged', () {
    expect(
      androidPlaybackRenderer(isTv: false, selected: 'auto', sdkVersion: 31),
      'gpu',
    );
    expect(
      androidPlaybackRenderer(isTv: false, selected: 'auto', sdkVersion: 34),
      'gpu-next',
    );
  });
  test('TV uses AudioTrack even with the old saved OpenSLES preference', () {
    for (final lowLatency in [true, false]) {
      expect(
        androidPlaybackAudioOutput(isTv: true, lowLatency: lowLatency),
        'audiotrack',
      );
    }
    expect(
      androidPlaybackAudioOutput(isTv: false, lowLatency: true),
      'opensles',
    );
    expect(
      androidPlaybackAudioOutput(isTv: false, lowLatency: false),
      'audiotrack',
    );
  });
  test(
    'TV local files bypass redundant disk caching, online and phone keep existing policy',
    () {
      expect(androidPlaybackCache(isTv: true, isLocalPlayback: true), {
        'cache': 'no',
        'cache-on-disk': 'no',
        'demuxer-readahead-secs': '1',
      });
      expect(androidPlaybackCache(isTv: true, isLocalPlayback: false), isEmpty);
      expect(androidPlaybackCache(isTv: false, isLocalPlayback: true), isEmpty);
    },
  );
}
