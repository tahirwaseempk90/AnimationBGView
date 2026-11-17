# Performance

The background is designed to cost little while it runs, and nothing when it doesn't.

- [What a frame costs](#what-a-frame-costs)
- [Measurements](#measurements)
- [Decisions](#decisions)
- [Recommendations](#recommendations)

---

## What a frame costs

| Work | Per frame |
|---|---|
| Phase | One subtraction and multiplication from an anchor date |
| Lights | Four positions and sizes, then a base fill and four radial gradient fills in one `Canvas` |
| V | Nothing. It's drawn once, in its own layer, and redrawn only when its configuration or the size changes |
| Blur | None. Soft edges come from four polygon fills, drawn with the V |
| Allocations | Four gradients of 12 stops |

At the default 30 frames per second, that happens 30 times a second, half as often as a 60 Hz display
refreshes. The motion is slow, with each light taking 51.5 seconds to circle the V, so 30 frames per
second looks as smooth as 60.

When drawing stops:

| Situation | What happens |
|---|---|
| The scene is inactive or in the background | `TimelineView` is paused. No frames are drawn |
| Reduce Motion is on | A still image. No frames are drawn after the first |
| `motion.isEnabled` is `false` | The same |

A background that stays in the view hierarchy while covered, for example under a pushed navigation
screen, hasn't been measured. If that matters, turn `motion.isEnabled` off while it's covered.

---

## Measurements

### In the simulator

CPU use of the example app's process, on an Apple silicon Mac running the iPhone 17 simulator with
iOS 27.2, with the home screen showing. Each figure is the median of 10 one-second samples from `ps`.
The simulator runs on the Mac's CPU and GPU, so these figures show relative cost, not what a phone
uses.

| State | CPU |
|---|---|
| Animating at 15 fps | ≈ 3% |
| Animating at 30 fps (default) | ≈ 6% |
| Animating at 60 fps | ≈ 9–10% |
| Animating at 120 fps | ≈ 8–9%, the same as 60, because the simulator didn't draw faster |
| Still image | 0% |
| In the background | 0% |

### In the test suite

`PerformanceTests` guards against regressions:

| Test | Limit |
|---|---|
| Resolving the clock and the lights for one frame, 10,000 times over | Under 0.5 ms per frame |
| An offscreen render of a phone-sized frame at 3x | Under 500 ms per frame |

These run offscreen with `ImageRenderer`, so the times aren't what a device sees on screen.

### Not measured

The background hasn't been profiled on a physical device, so there are no figures here for a phone's
GPU, battery, or temperature. Use Instruments' Core Animation and Energy templates on your own target
devices if the background runs for long periods, or alongside other heavy rendering.

---

## Decisions

| Decision | Effect |
|---|---|
| **Radial gradients, not blur** | A blurred circle needs an offscreen pass every frame. A gradient that follows a Gaussian looks the same and is a single fill |
| **The V in its own static layer** | The V is drawn once instead of every frame |
| **Soft edges from four polygon copies** | Matches the reference's soft edges without a blur pass, and costs nothing per frame because the V isn't redrawn |
| **30 frames per second by default** | Half the work of 60, with no visible difference at this speed |
| **`TimelineView` paused with the scene** | No work while the app isn't active |
| **A still image for Reduce Motion** | No work at all after the first frame |
| **Only four lights** | The fewest that reproduce the reference. Each extra light adds one gradient fill per frame |

---

## Recommendations

- **Keep the defaults** unless you have a reason. 30 frames per second is smooth for this motion.
- **Lower the frame rate** to 15–20 to save more, for example on a screen people stay on for a long time.
- **Use one background per screen.** Each instance has its own timeline and draws its own frames.
  Several small previews are fine, but avoid many in a scrolling list.
- **Use `.static`** for places that don't need motion, such as a thumbnail.
- **Leave `pausesWhenInactive` on.** It stops all work when the app isn't active.
- **Don't add a `.blur` or `.drawingGroup()`** on top. The background is already a single drawing pass.
