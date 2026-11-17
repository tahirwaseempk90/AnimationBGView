# Reference material

The material the package was built from. None of it is used at runtime: the package draws
everything with SwiftUI, and nothing in this folder is part of the library or the example app.

| File | What it is | Used for |
|---|---|---|
| `Shape.png` | A capture of the top of the screen, showing the V without any text over it | The V's geometry |
| `Color.png` | A capture of the coloured layer on its own, with no V | The palette and the arrangement at phase 0 |
| `chatgpt-sample-code/AnimatedBackground.swift` | A first attempt at the animation, written before any analysis | Comparison only. It isn't compiled, and none of its animation logic was reused |

Both images are Display P3 screenshots. Their colours were converted to sRGB before being measured.

## The recording

The main reference, a 72-second screen recording of the animation (`Animation-Video.mov`, 41 MB), is
not in the repository. Swift Package Manager clones a package's whole repository, so every app that
depended on this package would download it. What was measured from it, frame by frame, is in
[Visual Analysis](../Documentation/VisualAnalysis.md), with figures generated from the recording in
[Documentation/Assets](../Documentation/Assets).
