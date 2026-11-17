#!/usr/bin/env bash
# Runs the package tests on macOS and on an iOS simulator, and, with --ui, the example app's UI tests.
#
# usage: Scripts/test.sh [--ui] [simulator name]     (default simulator: "iPhone 17")
set -euo pipefail

cd "$(dirname "$0")/.."
RUN_UI_TESTS=false
if [[ "${1:-}" == "--ui" ]]; then
  RUN_UI_TESTS=true
  shift
fi
SIMULATOR_NAME="${1:-iPhone 17}"
SIMULATOR_ID="$(python3 Scripts/first-simulator.py "$SIMULATOR_NAME")"

echo "▸ Package tests, macOS"
swift test

echo "▸ Package tests, $SIMULATOR_NAME"
xcodebuild test -scheme AnimationBGView -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  CODE_SIGNING_ALLOWED=NO -quiet

if [[ "$RUN_UI_TESTS" == true ]]; then
  echo "▸ Example UI tests, $SIMULATOR_NAME"
  xcodebuild test -project Example/AnimationBGViewExample.xcodeproj -scheme AnimationBGViewExample \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -only-testing:AnimationBGViewExampleUITests/ExampleUITests -quiet
fi

echo "✓ All tests passed"
