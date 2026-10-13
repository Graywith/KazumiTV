/// TV automatic output uses Android's decoder Surface directly.
String androidPlaybackRenderer({
  required bool isTv,
  required String selected,
  required int sdkVersion,
}) {
  if (selected != 'auto') return selected;
  if (isTv) return 'mediacodec_embed';
  return sdkVersion >= 34 ? 'gpu-next' : 'gpu';
}

String androidPlaybackAudioOutput({
  required bool isTv,
  required bool lowLatency,
}) => !isTv && lowLatency ? 'opensles' : 'audiotrack';

/// Downloaded media is already on disk; don't write a second demuxer cache.
Map<String, String> androidPlaybackCache({
  required bool isTv,
  required bool isLocalPlayback,
}) => isTv && isLocalPlayback
    ? {'cache': 'no', 'cache-on-disk': 'no', 'demuxer-readahead-secs': '1'}
    : {};
