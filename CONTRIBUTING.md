# Contributing to AnimationBGView

Thanks for your interest. Bug reports, fixes, documentation, and ideas are all welcome.

## Before you start

- **For a bug,** [open an issue](https://github.com/tahirwaseempk90/AnimationBGView/issues/new) with a small piece of code that shows the problem, the device or simulator, and the OS version.
- **For a new feature,** open an issue first, so we can agree on the approach before you spend time on it.
- **For a security problem,** follow the [security policy](SECURITY.md) instead of opening an issue.

## Set up

You need Xcode 16 or later. There are no dependencies to install.

[Fork the repository](https://github.com/tahirwaseempk90/AnimationBGView/fork), then:

```sh
git clone https://github.com/YOUR_USERNAME/AnimationBGView.git
cd AnimationBGView
git checkout -b my-change
swift build
swift test
```

To work on the package alongside the example app, open `Example/AnimationBGViewExample.xcodeproj`. Changes to the package appear there immediately.

SwiftLint is optional locally, but CI runs it: `brew install swiftlint`. XcodeGen is only needed if you change `Example/project.yml`: `brew install xcodegen`.

## Make your change

### Coding expectations

- **Keep the public API small.** Every public declaration needs a documentation comment (`///`). New options should be additive, with a default value, so existing code keeps working.
- **Keep the drawing pure.** Positions, sizes, and colours are calculated by plain functions that the tests can call without rendering anything. Views only draw the result.
- **Sanitize outside input.** Configuration values go through the `resolved…` accessors. No input may produce non-finite geometry.
- **Keep the loop seamless.** Anything that moves must return to where it started at the end of a cycle.
- **Mind the cost per frame.** The background redraws up to 30 times a second. Avoid blur filters, offscreen passes, and per-frame allocations that grow with the content.
- **Avoid force unwraps, force casts, and `@unchecked Sendable`** in production code.
- **Use no third-party dependencies,** unless we've agreed otherwise in an issue.

### Tests

Every change in behaviour needs a test, and a bug fix needs one that fails without the fix.

```sh
swift test                      # Package tests on macOS
Scripts/test.sh                 # The same, plus the package tests on an iOS simulator
Scripts/test.sh --ui            # And the example app's UI tests
swiftlint lint --strict         # Lint
```

### Snapshots

Rendering tests compare against images in `Tests/AnimationBGViewTests/__Snapshots__`, kept per platform and OS version. After an intentional visual change, record them again and check the new images before committing:

```sh
SNAPSHOT_RECORD=1 swift test --filter SnapshotTests
TEST_RUNNER_SNAPSHOT_RECORD=1 xcodebuild test -scheme AnimationBGView \
  -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:AnimationBGViewTests/SnapshotTests
```

### Screenshots

The README images come from the example app. `Scripts/capture-screenshots.sh` recaptures them on several simulators.

## Open a pull request

Push your branch and open a pull request against `main`. Describe what changed and why, and how you tested it. CI must pass before a change is merged.

## Code of conduct

Be kind and assume good intent. Harassment or personal attacks aren't tolerated in issues, pull requests, or anywhere else in the project.
