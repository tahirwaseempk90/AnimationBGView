#!/usr/bin/env bash
# Builds the package for macOS and the iOS Simulator, and the example app, with warnings as errors.
#
# usage: Scripts/build.sh [simulator name]     (default: "iPhone 17")
set -euo pipefail

cd "$(dirname "$0")/.."
SIMULATOR_NAME="${1:-iPhone 17}"
SIMULATOR_ID="$(python3 Scripts/first-simulator.py "$SIMULATOR_NAME")"

echo "▸ Package, macOS"
swift build -Xswiftc -warnings-as-errors

echo "▸ Package, iOS Simulator"
xcodebuild build -scheme AnimationBGView -destination "generic/platform=iOS Simulator" \
  CODE_SIGNING_ALLOWED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES -quiet

echo "▸ Example app, $SIMULATOR_NAME"
xcodebuild build -project Example/AnimationBGViewExample.xcodeproj -scheme AnimationBGViewExample \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" -quiet

echo "✓ Build succeeded"
