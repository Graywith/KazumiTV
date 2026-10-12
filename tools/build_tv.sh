#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Next deliveries must increment both version and build number.
version=${1:-0.2.1}
build_number=${2:-20319}
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
lan_ip=$(ipconfig getifaddr en0 || ipconfig getifaddr en1)
update_base=${TV_UPDATE_BASE:-http://$lan_ip:18080}
# Private API credentials are never committed or printed.
defines_file=${TV_DART_DEFINES_FILE:-.tv-secrets.json}
private_defines=()
if [[ -f "$defines_file" ]]; then
  private_defines+=("--dart-define-from-file=$defines_file")
else
  echo "提示：未配置弹幕 API 凭证；可在 .tv-secrets.json 配置后重新构建。" >&2
fi
flutter build apk --release --split-per-abi \
  ${private_defines[@]+"${private_defines[@]}"} \
  --target-platform "$target" --build-name="$version" --build-number="$build_number" \
  --dart-define=KAZUMI_TV=true --dart-define=FLUTTER_BUILD_NAME="$version" \
  --dart-define=TV_UPDATE_ABI="$abi" --dart-define=TV_UPDATE_BASE="$update_base"
output=build/app/outputs/flutter-apk
name="kazumi-tv-$abi-$version.apk"
cp "$output/app-$abi-release.apk" "$output/$name"
mkdir -p build/tv-updates
cp "$output/$name" "build/tv-updates/$name"
ls -lh "$output/$name"
if [[ "$abi" == armeabi-v7a ]]; then
  icloud_downloads="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Downloads"
  if [[ -d "$icloud_downloads" ]]; then
    cp "$output/$name" "$icloud_downloads/$name"
    echo "已复制到 iCloud 云盘：$icloud_downloads/$name"
  else
    echo "未找到 iCloud 下载目录，APK 保留在 $output/$name" >&2
  fi
fi
