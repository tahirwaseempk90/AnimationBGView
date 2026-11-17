# API Reference

Every public type, with its properties, ranges, and defaults. Values outside a range are kept as set,
and limited to the range when the background draws. Non-finite values fall back to the default.

- [AnimatedBackgroundView](#animatedbackgroundview)
- [AnimatedBackgroundConfiguration](#animatedbackgroundconfiguration)
- [AnimationConfiguration](#animationconfiguration)
- [ReduceMotionPolicy](#reducemotionpolicy)
- [AnimationPhase](#animationphase)
- [BackgroundColorPalette](#backgroundcolorpalette)
- [GradientConfiguration](#gradientconfiguration)
- [GradientLight](#gradientlight)
- [VShapeConfiguration](#vshapeconfiguration)
- [VShapeGeometry](#vshapegeometry)
- [VShape](#vshape)
- [CompositionScaling](#compositionscaling)

---

## AnimatedBackgroundView

```swift
public struct AnimatedBackgroundView: View {
    public init(configuration: AnimatedBackgroundConfiguration = .default)
}
```

The background. It fills the space it's given, extends under the safe areas unless
`ignoresSafeArea` is `false`, and is hidden from accessibility.

| Behaviour | Detail |
|---|---|
| Scene inactive or in the background | Stops drawing, and continues from the same frame when active again |
| Reduce Motion on | Shows `motion.staticPhase` as a still image, unless `motion.reduceMotion` is `.never` |
| Configuration changes | Applied immediately. Speed changes continue from the frame on screen |
| VoiceOver | Nothing to read or focus |

---

## AnimatedBackgroundConfiguration

```swift
public struct AnimatedBackgroundConfiguration: Equatable, Sendable
```

| Property | Type | Default | Description |
|---|---|---|---|
| `palette` | `BackgroundColorPalette` | `.reference` | The colours |
| `motion` | `AnimationConfiguration` | `.default` | How the background moves |
| `vShape` | `VShapeConfiguration` | `.default` | The V |
| `gradient` | `GradientConfiguration` | `.default` | The moving lights |
| `scaling` | `CompositionScaling` | `.fit` | How the composition is sized to the view |
| `ignoresSafeArea` | `Bool` | `true` | Whether the background extends under the safe areas |

| Preset | Description |
|---|---|
| `.default` | The reference animation |
| `.static` | The reference background as a still image at `motion.staticPhase` |

---

## AnimationConfiguration

```swift
public struct AnimationConfiguration: Equatable, Sendable
```

| Property | Type | Range | Default | Description |
|---|---|---|---|---|
| `isEnabled` | `Bool` | | `true` | Whether the background moves. `false` shows `staticPhase` |
| `cycleDuration` | `TimeInterval` | 1–3,600 | `51.5` | Seconds per cycle at normal speed, measured from the reference |
| `speed` | `Double` | 0–20 | `1` | A playback-rate multiplier. `0` holds the current frame |
| `intensity` | `Double` | 0–2 | `1` | How far the lights travel along their paths |
| `frameRate` | `Double` | 1–120 | `30` | The highest number of frames drawn per second |
| `staticPhase` | `AnimationPhase` | | `0` | The still image, and the frame the animation starts from |
| `reduceMotion` | `ReduceMotionPolicy` | | `.followsSystem` | How Reduce Motion is handled |
| `pausesWhenInactive` | `Bool` | | `true` | Whether drawing stops while the scene isn't active |

| Preset | Description |
|---|---|
| `.default` | The reference animation |
| `.static` | `isEnabled` set to `false` |

---

## ReduceMotionPolicy

```swift
public enum ReduceMotionPolicy: Hashable, Sendable
```

| Case | Behaviour |
|---|---|
| `.followsSystem` | A still image when Reduce Motion is on. The default |
| `.always` | Always a still image. For apps with their own motion setting, and for previewing |
| `.never` | Always animated. Only for apps that offer their own way to turn the animation off |

---

## AnimationPhase

```swift
public struct AnimationPhase: Hashable, Sendable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral
```

A position in the cycle, from 0 up to, but not including, 1. Phase 0 and phase 1 are the same moment.

| Member | Description |
|---|---|
| `init(_ fraction: Double)` | Wraps the value into `0..<1`. Non-finite values become `0` |
| `fraction` | The position, from 0 up to 1 |
| `radians` | The position as an angle, from 0 up to 2π |
| `advanced(by cycles: Double)` | The phase after a number of cycles, which may be negative |
| `static func elapsed(_:cycleDuration:speed:from:)` | The phase reached after a period of time |
| `.zero` | The start of the cycle |

```swift
configuration.motion.staticPhase = 0.25
let phase = AnimationPhase.elapsed(10, cycleDuration: 51.5)   // 10 seconds in
```

---

## BackgroundColorPalette

```swift
public struct BackgroundColorPalette: Equatable, Sendable {
    public init(base: Color, lights: [Color], vShape: Color? = nil)
}
```

| Property | Type | Description |
|---|---|---|
| `base` | `Color` | Fills the whole background |
| `lights` | `[Color]` | One colour per light, in the order of `gradient.lights`. They repeat if there are fewer colours than lights. With none, no lights are drawn |
| `vShape` | `Color` | The V's colour. Defaults to `base` |
| `lightColor(at:)` | `Color?` | The colour for a light, repeating the colours, or `nil` if there are none |

`.reference`, measured from the reference images:

| Role | Value |
|---|---|
| Base and V | `#FAEEA3` |
| Lights | `#DEEB94` green-yellow, `#F5DD6D` golden, `#F3C485` peach, `#DDC48F` tan |

---

## GradientConfiguration

```swift
public struct GradientConfiguration: Equatable, Sendable
```

| Property | Type | Range | Default | Description |
|---|---|---|---|---|
| `lights` | `[GradientLight]` | | `GradientLight.reference` | The lights, drawn in order |
| `intensity` | `Double` | 0–2 | `1` | Multiplies each light's peak opacity, up to full opacity |
| `softness` | `Double` | 0.25–3 | `1` | Multiplies each light's size |

---

## GradientLight

```swift
public struct GradientLight: Equatable, Sendable
```

Positions and sizes are in design units: fractions of the composition's width, from its top-left
corner, with y increasing downward.

| Property | Type | Description |
|---|---|---|
| `orbitCenter` | `CGPoint` | The centre of the light's ellipse |
| `orbitRadii` | `CGSize` | The ellipse's horizontal and vertical radii. Zero keeps the light still |
| `startAngle` | `Angle` | The light's position at phase 0, clockwise from three o'clock |
| `revolutions` | `Int` | Whole turns per cycle. Positive is counter-clockwise, negative clockwise, zero still. The default is `1` |
| `size` | `Double` | The Gaussian's standard deviation. The glow fades to nothing at three times this |
| `peakOpacity` | `Double` | The opacity at the light's centre, from 0 to 1 |
| `center(at:travel:)` | `CGPoint` | The light's centre at a phase |

| Static property | Description |
|---|---|
| `.referenceGreenYellow`, `.referenceGolden`, `.referencePeach`, `.referenceTan` | The four reference lights |
| `.reference` | All four, in palette order |

---

## VShapeConfiguration

```swift
public struct VShapeConfiguration: Equatable, Sendable
```

| Property | Type | Range | Default | Description |
|---|---|---|---|---|
| `isVisible` | `Bool` | | `true` | Whether the V is drawn |
| `opacity` | `Double` | 0–1 | `0.58` | The opacity of the V's fill, measured from the reference |
| `scale` | `Double` | 0.25–3 | `1` | The V's size around its middle. Its strokes always reach the top edge |
| `edgeSoftness` | `Double` | 0–0.1 | `0.0115` | The width of the fade across each edge, as a fraction of the composition's width. `0` is crisp |
| `geometry` | `VShapeGeometry` | | `.reference` | The V's proportions and position |

| Preset | Description |
|---|---|
| `.default` | The reference V |
| `.hidden` | No V |

---

## VShapeGeometry

```swift
public struct VShapeGeometry: Equatable, Sendable
```

In design units:

| Property | Type | Reference | Description |
|---|---|---|---|
| `outerLeftTop` | `Double` | `0.2497` | Where the left stroke's outer edge crosses the top edge |
| `innerLeftTop` | `Double` | `0.4896` | Where the left stroke's inner edge crosses the top edge |
| `innerRightTop` | `Double` | `0.8587` | Where the right stroke's inner edge crosses the top edge |
| `outerRightTop` | `Double` | `0.9981` | Where the right stroke's outer edge crosses the top edge |
| `vertex` | `CGPoint` | `(0.6372, 1.0676)` | The bottom point, where the outer edges meet |
| `notchApex` | `CGPoint` | `(0.6882, 0.5740)` | The bottom of the notch, where the inner edges meet |
| `isValid` | `Bool` | | Whether the values describe a drawable V. Invalid geometry isn't drawn |

A V is valid when every value is finite, the top crossings are in order from left to right, the notch
apex is below the top edge and above the vertex, and the notch lies inside the V.

---

## VShape

```swift
public struct VShape: Shape {
    public init(geometry: VShapeGeometry = .reference, scale: Double = 1)
}
```

The V as a reusable shape. The rectangle's width is one design unit, so the V keeps its proportions in
any frame, and its strokes run up to the rectangle's top edge. `scale` is the animatable data, and the
V doesn't mirror in right-to-left layouts.

```swift
VShape()
    .fill(.white.opacity(0.5))
    .frame(width: 300, height: 360)
```

---

## CompositionScaling

```swift
public enum CompositionScaling: Hashable, Sendable
```

| Case | Behaviour |
|---|---|
| `.fit` | Matches the width, but shrinks so the whole V fits when the view is shorter than 1.2 times its width, and centres it. The default |
| `.fillWidth` | Always matches the width. On short, wide views the bottom of the V runs past the bottom edge |
