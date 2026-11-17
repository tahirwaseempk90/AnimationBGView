# Animation Design

How the background is constructed, and how its loop stays seamless. The measurements behind every
number are in [Visual Analysis](VisualAnalysis.md).

- [Coordinates](#coordinates)
- [The V](#the-v)
- [The lights](#the-lights)
- [Colour model](#colour-model)
- [Phase and time](#phase-and-time)
- [The infinite loop](#the-infinite-loop)
- [How the loop was verified](#how-the-loop-was-verified)

---

## Coordinates

Everything is placed in **design units**: fractions of the composition's width, measured from its
top-left corner, with y increasing downward. One design unit is the composition's width in points.

`CompositionLayout` decides how large the composition is:

| Scaling | Composition width | Horizontal position |
|---|---|---|
| `.fit` (default) | `min(width, height / 1.2)` | Centred |
| `.fillWidth` | `width` | Left edge |

The composition is always anchored to the top, because the V runs off the top edge. 1.2 is the V's
depth, 1.07, plus a margin. On phones in portrait and on iPads, `.fit` and `.fillWidth` give the same
result. They differ only on short, wide frames, such as a phone in landscape.

---

## The V

### Construction

The V is the region between two pairs of straight lines, each written as `u = slope · v + intercept`:

| Edge | Slope | Crosses the top at | Angle from vertical |
|---|---|---|---|
| Left stroke, outer edge | 0.3630 | 0.2497 | 20.0° |
| Left stroke, inner edge | 0.3460 | 0.4896 | 19.1° |
| Right stroke, inner edge | −0.2970 | 0.8587 | −16.5° |
| Right stroke, outer edge | −0.3380 | 0.9981 | −18.7° |

`VShapeGeometry` stores each edge as the point where it crosses the top edge, plus the two points
where the edges meet: the **vertex** at (0.6372, 1.0676), and the **notch apex** at (0.6882, 0.5740).
`VShapeOutline` turns those into lines and builds a polygon of six corners: the two outer top corners,
the vertex, the two inner top corners, and the notch apex. If the notch is cut off by the top edge,
only the outer triangle remains.

Working with lines rather than corners makes the two transformations the V needs exact:

- **Scaling** around a point keeps every slope and only moves the intercepts:
  `intercept′ = k · intercept + (1 − k) · (anchorU − slope · anchorV)`. The anchor is halfway between the
  notch apex and the vertex, so the V grows and shrinks around its middle, and its strokes still run
  off the top edge.
- **Offsetting** an edge by a distance `d` along its normal moves only the intercept:
  `intercept′ = intercept + d · √(1 + slope²)`.

### Fill and soft edges

The V is filled with the base colour at 58% opacity, so the lights show through it at 42%. The
recording's edges fade over about 1.15% of the screen's width, a Gaussian with a standard deviation of
about 1.75 pt on a phone, so the V is drawn as four nested copies, offset from half the softness
inside each edge to half outside it.

The copies are the same colour, and copies composited "over" each other combine to `1 − ∏(1 − aᵢ)`.
A point covered by the `r` largest copies should have `r / n` of the full opacity α, which gives each
copy, from largest to smallest, the opacity

```text
a_r = 1 − (1 − α·r/n) / (1 − α·(r − 1)/n)
```

For α = 0.58 and n = 4, that's 0.145, 0.170, 0.204, and 0.257, which ramp in four equal steps to
exactly 0.58. The same formula works at full opacity, where equal copies would collapse into one hard
edge. `edgeSoftness = 0` draws a single crisp copy.

The V doesn't move, so it's drawn in its own layer, once, and not on every frame.

---

## The lights

Each light is a soft round glow. Its opacity at distance `d` from its centre is

```text
a(d) = A · g(d / σ),   g(x) = (e^(−x²/2) − e^(−4.5)) / (1 − e^(−4.5))   for x < 3, else 0
```

`A` is the light's peak opacity and σ is its size. `g` is a Gaussian, shifted to reach exactly zero at
three standard deviations, so a light has no visible edge. `GaussianFalloff` samples it into 12
gradient stops. The straight segments between the stops are within 1.5% of the curve, and a test holds
them to it.

Each light's centre travels along an ellipse:

```text
centre(φ) = orbitCenter + (rₓ · travel · cos θ, r_y · travel · sin θ)
θ(φ) = startAngle − 2π · revolutions · φ
```

The y axis points down, so a decreasing θ is counter-clockwise on screen.

| Light | Colour | Orbit centre | Radii | Start angle | Size σ | Peak opacity |
|---|---|---|---|---|---|---|
| Green-yellow | `#DEEB94` | 0.721, 0.435 | 0.204, 0.121 | −156.6° | 0.175 | 0.8 |
| Golden | `#F5DD6D` | 0.679, 0.377 | 0.253, 0.156 | −27.3° | 0.162 | 0.8 |
| Peach | `#F3C485` | 0.761, 0.498 | 0.213, 0.123 | 75.9° | 0.127 | 0.8 |
| Tan | `#DDC48F` | 0.591, 0.385 | 0.187, 0.150 | 101.0° | 0.172 | 0.8 |

All four make one counter-clockwise turn per cycle around the middle of the V. At phase 0 they're
arranged as in the colour reference: golden at the upper right, green-yellow at the upper left, peach at
the lower right, and tan at the lower left. Where a light passes behind the thick left stroke, the V
hides 58% of its colour, which is why the left of the screen stays calm.

The lights are drawn in order, each composited "over" the result so far. Light `n` takes colour `n`
from the palette.

---

## Colour model

| Layer | Colour | Opacity |
|---|---|---|
| Base | `#FAEEA3` | 1 |
| Lights | `#DEEB94`, `#F5DD6D`, `#F3C485`, `#DDC48F` | Up to 0.8 at their centres |
| V | The base colour | 0.58, softened at the edges |

All colours are sRGB, converted from the Display P3 screenshots they were measured in. Compositing
happens in SwiftUI's default gamma-encoded space, the same space the colours were measured in.

`gradient.intensity` multiplies every light's peak opacity, up to 1, and `gradient.softness`
multiplies every light's size. The default, 0.8, sits between the average of the recording, which
least squares matches best at about 0.6, and the strongest colours seen in the recording and in
Color.png, which need 1.0.

---

## Phase and time

`AnimationPhase` is a position in the cycle, from 0 up to, but not including, 1. Values wrap, and
non-finite values become 0.

The phase advances at `speed / cycleDuration` cycles per second, 1 / 51.5 by default. It's computed
by `AnimationTimeline` from an anchor date and the phase at that date, so it stays continuous when the
speed changes, when the background pauses and resumes, and when animation is turned off and on again.
See [Architecture](Architecture.md#animation-lifecycle).

`motion.intensity` scales how far the lights travel, without changing the timing. `motion.speed = 0`
holds the current frame.

---

## The infinite loop

The loop is seamless by construction, not by keyframes that happen to match:

1. Every position is a function of the phase alone.
2. Every light's angle is `startAngle − 2π · revolutions · φ`, with a whole number of revolutions. When φ
   reaches 1, every angle has changed by a whole number of turns, and `cos` and `sin` return exactly
   to their starting values.
3. Nothing else moves: the V, the palette, and the sizes are constant.
4. `AnimationPhase` wraps 1 back to 0, so the frame after the last is the first.

So the frame at time `t` and the frame at `t + cycleDuration / speed` are the same frame, whatever the
cycle length and however long the animation has been running. There is no restart, because nothing is
ever restarted. The phase just keeps advancing.

The reference recording itself doesn't contain a complete repeat. Its 70 continuous seconds cover 1.35
cycles, and frames 51–52 seconds apart are similar but not identical. The exact loop is a design
decision, based on the period measured in the recording.

---

## How the loop was verified

| Check | Where | Result |
|---|---|---|
| A light returns to its start after one cycle | `GradientLightTests` | Within 10⁻⁹ design units |
| The phase one cycle later is the same | `AnimationPhaseTests`, `AnimationTimelineTests` | Within 10⁻⁹, including after three days of running |
| A light never jumps between frames | `GradientLightTests` | Each step is at most the arc length its speed allows |
| The rendered frame one cycle later is identical | `RenderingTests` | Every pixel equal |
| The last frame flows into the first | `RenderingTests` | The step across the loop point is no bigger than an ordinary step |
| No frame jumps anywhere in the cycle | `RenderingTests` | 120 frames per cycle, each within 6 levels of the next, including the wrap-around |
| The running app repeats exactly | A 20-second simulator recording at 6× speed | Frames one cycle apart differ by a mean of 0.13–0.20 levels, the same as frames 1/30 s apart (0.17). Frames half a cycle apart differ by 4.0–4.6 |
