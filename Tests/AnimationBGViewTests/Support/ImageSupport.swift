import ImageIO
import SwiftUI
import UniformTypeIdentifiers
import XCTest
@testable import AnimationBGView

/// An image's pixels as 8-bit sRGB, for assertions on what was actually drawn.
struct PixelBuffer {
    struct RGBA: Equatable, CustomStringConvertible {
        let red: Int
        let green: Int
        let blue: Int
        let alpha: Int

        var description: String { "(\(red), \(green), \(blue), \(alpha))" }

        /// The largest difference in any colour channel.
        func maximumDifference(from other: RGBA) -> Int {
            max(abs(red - other.red), abs(green - other.green), abs(blue - other.blue))
        }
    }

    let width: Int
    let height: Int
    private let bytes: [UInt8]
    private static let bytesPerPixel = 4

    init?(_ image: CGImage) {
        width = image.width
        height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * Self.bytesPerPixel)
        let drawn: Bool = pixels.withUnsafeMutableBytes { buffer in
            guard
                let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                let context = CGContext(
                    data: buffer.baseAddress,
                    width: image.width,
                    height: image.height,
                    bitsPerComponent: 8,
                    bytesPerRow: image.width * Self.bytesPerPixel,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                )
            else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        guard drawn else { return nil }
        bytes = pixels
    }

    func pixel(x: Int, y: Int) -> RGBA {
        let offset = (y * width + x) * Self.bytesPerPixel
        return RGBA(red: Int(bytes[offset]), green: Int(bytes[offset + 1]), blue: Int(bytes[offset + 2]), alpha: Int(bytes[offset + 3]))
    }

    /// The pixel at a position given as fractions of the width and height.
    func pixel(atFractionX fractionX: Double, y fractionY: Double) -> RGBA {
        pixel(
            x: min(width - 1, max(0, Int(fractionX * Double(width)))),
            y: min(height - 1, max(0, Int(fractionY * Double(height))))
        )
    }

    /// Whether any pixel is less than fully opaque.
    var hasTransparentPixels: Bool {
        stride(from: 3, to: bytes.count, by: Self.bytesPerPixel).contains { bytes[$0] < 255 }
    }

    /// The largest difference in any colour channel between two same-sized images.
    func maximumDifference(from other: PixelBuffer) -> Int {
        guard width == other.width, height == other.height else { return 255 }
        var result = 0
        for offset in stride(from: 0, to: bytes.count, by: Self.bytesPerPixel) {
            for channel in 0..<3 {
                result = max(result, abs(Int(bytes[offset + channel]) - Int(other.bytes[offset + channel])))
            }
        }
        return result
    }

    /// The share of pixels that differ by more than a tolerance in any channel.
    func differingFraction(from other: PixelBuffer, channelTolerance: Int) -> Double {
        guard width == other.width, height == other.height else { return 1 }
        var differing = 0
        for offset in stride(from: 0, to: bytes.count, by: Self.bytesPerPixel) {
            for channel in 0..<4 where abs(Int(bytes[offset + channel]) - Int(other.bytes[offset + channel])) > channelTolerance {
                differing += 1
                break
            }
        }
        return Double(differing) / Double(width * height)
    }

    /// The first column in a row, from the left, whose pixel satisfies a condition.
    func firstColumn(inRow y: Int, where condition: (RGBA) -> Bool) -> Int? {
        (0..<width).first { condition(pixel(x: $0, y: y)) }
    }

    /// The last row, from the top, that has any pixel satisfying a condition.
    func lastRow(where condition: (RGBA) -> Bool) -> Int? {
        (0..<height).last { y in (0..<width).contains { condition(pixel(x: $0, y: y)) } }
    }
}

/// The conditions a view is rendered under.
struct RenderEnvironment {
    var layoutDirection: LayoutDirection = .leftToRight
    var displayScale: CGFloat = 1
}

@MainActor
enum BackgroundRendering {
    /// Renders a view with the real SwiftUI layout and drawing passes, without a window.
    static func image<V: View>(of view: V, size: CGSize, environment: RenderEnvironment = RenderEnvironment()) -> CGImage? {
        let content = view
            .frame(width: size.width, height: size.height)
            .environment(\.layoutDirection, environment.layoutDirection)
            .environment(\.displayScale, environment.displayScale)
        let renderer = ImageRenderer(content: content)
        renderer.scale = environment.displayScale
        renderer.proposedSize = ProposedViewSize(size)
        return renderer.cgImage
    }

    static func pixels<V: View>(of view: V, size: CGSize, environment: RenderEnvironment = RenderEnvironment()) -> PixelBuffer? {
        image(of: view, size: size, environment: environment).flatMap(PixelBuffer.init)
    }

    /// The background as a still image at a phase.
    static func background(
        _ configuration: AnimatedBackgroundConfiguration = .default,
        phase: AnimationPhase,
        size: CGSize,
        environment: RenderEnvironment = RenderEnvironment()
    ) -> PixelBuffer? {
        var still = configuration
        still.motion.isEnabled = false
        still.motion.staticPhase = phase
        return pixels(of: AnimatedBackgroundView(configuration: still), size: size, environment: environment)
    }
}

enum PNGFile {
    static func write(_ image: CGImage, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw CocoaError(.fileWriteUnknown)
        }
    }

    static func read(from url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}

/// Common sizes, in points.
enum DeviceSize {
    static let iPhone = CGSize(width: 393, height: 852)
    static let iPhoneSE = CGSize(width: 375, height: 667)
    static let iPhoneProMax = CGSize(width: 440, height: 956)
    static let iPhoneLandscape = CGSize(width: 852, height: 393)
    static let iPadPortrait = CGSize(width: 820, height: 1180)
    static let iPadLandscape = CGSize(width: 1180, height: 820)
    static let card = CGSize(width: 320, height: 320)
}
