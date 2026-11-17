#!/usr/bin/env bash
# Captures the README images from the real example app on simulators: a set of screenshots per
# device, and an animated GIF of the background running at 6× speed.
#
# usage: Scripts/capture-screenshots.sh [output-directory]     (default: Screenshots)
#
# Optional environment variables:
#   SCREENSHOT_TESTS   Which tests to run, relative to the UI test target (default: ScreenshotTests).
#                      For example, ScreenshotTests/testCaptureLandscape recaptures only landscape.
#   SKIP_GIF=1         Don't record the GIFs.
#
# Devices that aren't installed are skipped. Needs Xcode, ImageMagick, and, for the GIF, ffmpeg.
set -euo pipefail

cd "$(dirname "$0")/.."
OUTPUT="${1:-Screenshots}"
TESTS="${SCREENSHOT_TESTS:-ScreenshotTests}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

DEVICES=(
  "iPhone SE (3rd generation)"
  "iPhone 17"
  "iPhone 18 Pro"
  "iPhone 18 Pro Max"
  "iPad Pro 13-inch (M5)"
)

slug() { echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-|-$//g'; }

for DEVICE in "${DEVICES[@]}"; do
  if ! ID="$(python3 Scripts/first-simulator.py "$DEVICE" 2>/dev/null)"; then
    echo "• Skipping $DEVICE: not installed"
    continue
  fi
  echo "▸ $DEVICE"
  FOLDER="$OUTPUT/$(slug "$DEVICE")"
  xcodebuild test -project Example/AnimationBGViewExample.xcodeproj -scheme AnimationBGViewExample \
    -destination "platform=iOS Simulator,id=$ID" \
    -only-testing:"AnimationBGViewExampleUITests/$TESTS" \
    -derivedDataPath "$WORK/DerivedData" -resultBundlePath "$WORK/$(slug "$DEVICE").xcresult" -quiet
  python3 Scripts/export-screenshots.py "$WORK/$(slug "$DEVICE").xcresult" "$FOLDER"
  # Landscape screenshots are of the whole display, stored upright for portrait with an orientation
  # tag, so turn them the right way up first. Then, because Swift Package Manager clones the whole
  # repository, keep the images small: half size, as JPEG.
  for PNG in "$FOLDER"/*.png; do
    magick "$PNG" -auto-orient -resize 50% -strip -quality 86 "${PNG%.png}.jpg"
    rm "$PNG"
  done
done

if [[ "${SKIP_GIF:-0}" != 1 ]] && command -v ffmpeg >/dev/null; then
  echo "▸ Recording the GIF"
  ID="$(python3 Scripts/first-simulator.py "iPhone 17")"
  APP="$(find "$WORK/DerivedData/Build/Products" -name AnimationBGViewExample.app -path '*iphonesimulator*' | head -1)"
  xcrun simctl boot "$ID" 2>/dev/null || true
  xcrun simctl bootstatus "$ID" -b >/dev/null
  xcrun simctl install "$ID" "$APP"
  for VARIANT in home background; do
    CONTENT=YES
    [[ "$VARIANT" == background ]] && CONTENT=NO
    xcrun simctl launch --terminate-running-process "$ID" com.example.AnimationBGViewExample \
      -speed 6 -content "$CONTENT" >/dev/null
    sleep 2
    xcrun simctl io "$ID" recordVideo --codec=h264 --force "$WORK/$VARIANT.mov" >/dev/null 2>&1 &
    RECORDER=$!
    # One cycle at 6× speed is 51.5 / 6 ≈ 8.6 seconds. Record a little more, then trim to one cycle,
    # so the GIF loops exactly as the animation does.
    sleep 11
    kill -INT "$RECORDER"
    wait "$RECORDER" || true
    ffmpeg -v error -y -ss 1 -t 8.583 -i "$WORK/$VARIANT.mov" \
      -vf "fps=15,scale=320:-2:flags=lanczos,split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle" \
      -loop 0 "$OUTPUT/demo-$VARIANT.gif"
  done
fi

echo "✓ Images written to $OUTPUT"
