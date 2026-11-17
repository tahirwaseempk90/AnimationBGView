# ``AnimationBGView``

A soft, slowly moving pale-yellow background with a large V, drawn entirely with SwiftUI.

## Overview

Four soft lights, green-yellow, golden, peach, and tan, circle behind a translucent V, completing one
turn about every 51 seconds and looping without a seam. Everything is drawn with `TimelineView` and
`Canvas`: there are no images, videos, or third-party dependencies.

```swift
import AnimationBGView
import SwiftUI

struct WelcomeView: View {
    var body: some View {
        ZStack {
            AnimatedBackgroundView()
            Text("Welcome")
        }
    }
}
```

Start from ``AnimatedBackgroundConfiguration/default`` and change only what you need:

```swift
var configuration = AnimatedBackgroundConfiguration.default
configuration.motion.speed = 1.5
configuration.gradient.intensity = 0.7
configuration.vShape.opacity = 0.45

AnimatedBackgroundView(configuration: configuration)
```

The background pauses while its scene isn't active, shows a still image when Reduce Motion is on, and
is hidden from VoiceOver.

## Topics

### The background

- ``AnimatedBackgroundView``
- ``AnimatedBackgroundConfiguration``

### Motion

- ``AnimationConfiguration``
- ``AnimationPhase``
- ``ReduceMotionPolicy``

### Colour

- ``BackgroundColorPalette``
- ``GradientConfiguration``
- ``GradientLight``

### The V

- ``VShapeConfiguration``
- ``VShapeGeometry``
- ``VShape``

### Layout

- ``CompositionScaling``
