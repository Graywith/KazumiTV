#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Next deliveries must increment both version and build number.
version=${1:-0.3.20}
build_number=${2:-20344}
abi=${3:-armeabi-v7a}
if [[ "$abi" == all ]]; then
  bash "$0" "$version" "$build_number" arm64-v8a
  bash "$0" "$version" "$build_number" armeabi-v7a
  exit 0
fi
case "$abi" in
  arm64-v8a) target=android-arm64 ;;
  armeabi-v7a) target=android-arm ;;
  *) echo "Unsupported ABI: $abi" >&2; exit 1 ;;
esac
update_base=${TV_UPDATE_BASE:-}
# TV credentials are configured on the device, never bundled into the APK.
flutter build apk --release --split-per-abi \
  --target-platform "$target" --build-name="$version" --build-number="$build_number" \
  --dart-define=KAZUMI_TV=true --dart-define=FLUTTER_BUILD_NAME="$version" \
  --dart-define=TV_UPDATE_ABI="$abi" --dart-define=TV_UPDATE_BASE="$update_base"
output=build/app/outputs/flutter-apk
name="kazumi-tv-$abi-$version.apk"
cp "$output/app-$abi-release.apk" "$output/$name"
mkdir -p build/tv-updates
cp "$output/$name" "build/tv-updates/$name"
ls -lh "$output/$name"
