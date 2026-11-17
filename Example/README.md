# AnimationBGViewExample

A SwiftUI app demonstrating the `AnimationBGView` package. It uses the package through a local Swift
Package reference, exactly as your app would, and contains no drawing code of its own.

## Run it

1. Open `AnimationBGViewExample.xcodeproj` in Xcode.
2. Choose the `AnimationBGViewExample` scheme.
3. Choose an iPhone or iPad simulator, and run.

No account or signing setup is needed for a simulator. To run on a physical device, choose your team
under **Signing & Capabilities**.

## Screens

| Screen | What it shows |
|---|---|
| Home | The background full screen, with text and buttons over it |
| Customize | Every setting, applied live: animation on or off, speed, travel, frame rate, Reduce Motion behaviour, still phase, palette, intensity, softness, the V's visibility, opacity, scale, and edge softness, and scaling. **Reset** restores the defaults |
| Palettes | The same motion in four palettes. Choosing one applies it everywhere |
| Layouts | The background in portrait and landscape phone frames, a tablet frame, cards, and a banner, with `.fit` and `.fillWidth` |
| Motion | The animated background next to what people with Reduce Motion see, and the current system setting |

The customization panel opens at half height, so the V and the lights stay in view while you change
settings. At **Speed** 6×, a whole cycle plays in under nine seconds.

## Launch arguments

The UI tests and `Scripts/capture-screenshots.sh` use launch arguments to open a screen in a known
state. You can set them in the scheme too:

| Argument | Effect |
|---|---|
| `-screen home\|customize\|palettes\|layouts\|accessibility` | The screen to open |
| `-phase 0.25` | A still image at this phase, instead of animation |
| `-speed 6` | The playback speed |
| `-fps 60` | The highest frame rate |
| `-palette reference\|mint\|lavender\|blush` | The starting palette |
| `-content NO` | The bare background, without text and buttons |

## Run the UI tests

Press **⌘U** in Xcode, or:

```sh
xcodebuild test \
  -project Example/AnimationBGViewExample.xcodeproj \
  -scheme AnimationBGViewExample \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:AnimationBGViewExampleUITests/ExampleUITests
```

`ScreenshotTests` captures every screen as test attachments. `Scripts/capture-screenshots.sh` runs it
on several simulators and exports the images.

## Regenerate the project

The project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen), and
the result is committed. Only regenerate it after changing `project.yml`:

```sh
cd Example && xcodegen generate
```
