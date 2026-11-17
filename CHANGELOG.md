# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com), and the project uses
[Semantic Versioning](https://semver.org).

## [1.0.0] - 2026-11-17

First release.

### Added

- `AnimatedBackgroundView`, a pale-yellow animated background with a large translucent V, drawn
  entirely with SwiftUI: no images, video, or third-party code.
- Four soft lights, green-yellow, golden, peach, and tan, that circle behind the V counter-clockwise,
  with colours, paths, and timing measured from the reference recording and images.
- A seamless loop: every moving part completes a whole number of turns per cycle, so the last frame
  flows into the first. The default cycle is 51.5 seconds.
- `AnimatedBackgroundConfiguration`, with separate value types for the palette, motion, V, and
  lights. Speed, travel, colour intensity, softness, V visibility, opacity, scale, edge softness, frame
  rate, and a still image at any phase are all configurable.
- Custom palettes through `BackgroundColorPalette`, without changing the motion.
- `VShape`, the V as a reusable SwiftUI `Shape`.
- Responsive layout through `CompositionScaling`: `.fit` keeps the whole V in view on short, wide
  screens, and `.fillWidth` always matches the width.
- Pausing while the scene isn't active, a still image for Reduce Motion, and no accessibility elements.
- Support for iOS 16 and later, including iPadOS, and macOS 13 and later.
- An example app with live customization, palettes, layouts, and a Reduce Motion comparison.

[1.0.0]: https://github.com/tahirwaseempk90/AnimationBGView/releases/tag/v1.0.0
