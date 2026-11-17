
import SwiftUI

// MARK: - 1. Color Palette

enum AnimatedBackgroundPalette {

    static let colors: [Color] = [
        Color(red: 0.99, green: 0.93, blue: 0.59),
        Color(red: 0.98, green: 0.94, blue: 0.72),
        Color(red: 0.91, green: 0.87, blue: 0.70),
        Color(red: 0.85, green: 0.79, blue: 0.64),
        Color(red: 0.96, green: 0.81, blue: 0.66),
        Color(red: 1.00, green: 0.95, blue: 0.73)
    ]

    static let base = Color(
        red: 0.98,
        green: 0.93,
        blue: 0.69
    )
}


// MARK: - 2. Configuration

struct AnimatedBackgroundConfiguration {

    var animationDuration: Double = 30
    var animationFPS: Double = 30

    var vShapeOpacity: Double = 0.65
    var vShapeWidth: CGFloat = 0.20
    var vShapeBlur: CGFloat = 0.09

    var gradientIntensity: Double = 1.0
    var enablesVAnimation: Bool = true

    var colors: [Color] = AnimatedBackgroundPalette.colors

    static let standard = AnimatedBackgroundConfiguration()
}


// MARK: - 3. Animation Phase

struct BackgroundAnimationPhase {

    let value: Double

    init(date: Date, duration: Double) {

        let safeDuration = max(duration, 0.1)

        let elapsed = date.timeIntervalSinceReferenceDate

        let normalized = (
            elapsed / safeDuration
        ).truncatingRemainder(dividingBy: 1)

        value = normalized * 2 * .pi
    }

    static let zero = BackgroundAnimationPhase(
        date: Date(timeIntervalSinceReferenceDate: 0),
        duration: 30
    )
}


// MARK: - 4. V Shape

struct AnimatedVShape: Shape {

    var horizontalInset: CGFloat = 0.12
    var centerDepth: CGFloat = 0.68

    func path(in rect: CGRect) -> Path {

        let width = rect.width
        let height = rect.height

        var path = Path()

        path.move(
            to: CGPoint(
                x: width * horizontalInset,
                y: height * 0.02
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: width * 0.50,
                y: height * centerDepth
            ),
            control: CGPoint(
                x: width * 0.29,
                y: height * 0.42
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: width * (1 - horizontalInset),
                y: height * 0.02
            ),
            control: CGPoint(
                x: width * 0.71,
                y: height * 0.42
            )
        )

        return path
    }
}


// MARK: - 5. Animated Gradient

struct AnimatedGradientView: View {

    let phase: Double
    let configuration: AnimatedBackgroundConfiguration

    private var colors: [Color] {
        let palette = configuration.colors

        guard palette.count >= 6 else {
            return AnimatedBackgroundPalette.colors
        }

        return palette
    }

    var body: some View {

        GeometryReader { geometry in

            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {

                configuration.colors.first ?? AnimatedBackgroundPalette.base

                // Main warm yellow illumination

                RadialGradient(
                    colors: [
                        colors[0].opacity(0.85),
                        colors[1].opacity(0.55),
                        .clear
                    ],
                    center: UnitPoint(
                        x: 0.50 + 0.18 * sin(phase),
                        y: 0.25 + 0.12 * cos(phase)
                    ),
                    startRadius: 0,
                    endRadius: width * 0.85
                )

                // Left / bottom beige illumination

                RadialGradient(
                    colors: [
                        colors[3].opacity(0.50),
                        colors[4].opacity(0.30),
                        .clear
                    ],
                    center: UnitPoint(
                        x: 0.15 + 0.12 * cos(phase),
                        y: 0.75 + 0.10 * sin(phase)
                    ),
                    startRadius: 0,
                    endRadius: height * 0.80
                )

                // Right-side soft cream illumination

                RadialGradient(
                    colors: [
                        colors[5].opacity(0.65),
                        colors[1].opacity(0.20),
                        .clear
                    ],
                    center: UnitPoint(
                        x: 0.85 + 0.10 * sin(phase * 2),
                        y: 0.55 + 0.12 * cos(phase * 2)
                    ),
                    startRadius: 0,
                    endRadius: width * 0.70
                )

                // Center soft beige color

                RadialGradient(
                    colors: [
                        colors[2].opacity(0.20),
                        .clear
                    ],
                    center: UnitPoint(
                        x: 0.50 + 0.10 * cos(phase * 3),
                        y: 0.50 + 0.10 * sin(phase * 3)
                    ),
                    startRadius: 0,
                    endRadius: width * 0.60
                )
            }
            .opacity(configuration.gradientIntensity)
            .frame(
                width: width,
                height: height
            )
        }
    }
}


// MARK: - 6. V Shape Layer

struct AnimatedVShapeLayer: View {

    let phase: Double
    let configuration: AnimatedBackgroundConfiguration

    var body: some View {

        GeometryReader { geometry in

            let width = geometry.size.width
            let height = geometry.size.height

            AnimatedVShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.10),
                            configuration.colors.count > 2
                                ? configuration.colors[2].opacity(0.24)
                                : .white.opacity(0.20),
                            .white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: width * configuration.vShapeWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .blur(
                    radius: width * configuration.vShapeBlur
                )
                .opacity(configuration.vShapeOpacity)
                .scaleEffect(
                    x: configuration.enablesVAnimation
                        ? 1.0 + 0.012 * sin(phase)
                        : 1.0,
                    y: configuration.enablesVAnimation
                        ? 1.0 + 0.008 * cos(phase)
                        : 1.0
                )
                .frame(
                    width: width,
                    height: height
                )
        }
    }
}


// MARK: - 7. Main Animated Background

struct AnimatedBackgroundView: View {

    var configuration: AnimatedBackgroundConfiguration = .standard

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Environment(\.scenePhase)
    private var scenePhase

    var body: some View {

        TimelineView(
            .animation(
                minimumInterval: 1.0 / max(configuration.animationFPS, 1),
                paused: reduceMotion || scenePhase != .active
            )
        ) { context in

            let phase = BackgroundAnimationPhase(
                date: context.date,
                duration: configuration.animationDuration
            ).value

            GeometryReader { geometry in

                ZStack {

                    // Background colors

                    AnimatedGradientView(
                        phase: reduceMotion ? 0 : phase,
                        configuration: configuration
                    )

                    // V shape

                    AnimatedVShapeLayer(
                        phase: reduceMotion ? 0 : phase,
                        configuration: configuration
                    )

                }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                .clipped()
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}


// MARK: - 8. Demo Screen

struct AnimatedBackgroundDemoView: View {

    var body: some View {

        ZStack {

            AnimatedBackgroundView()

            VStack(spacing: 16) {

                Spacer()

                Text("Welcome")
                    .font(.system(
                        size: 34,
                        weight: .bold
                    ))
                    .foregroundStyle(.black.opacity(0.75))

                Text("Your experience starts here")
                    .font(.system(size: 16))
                    .foregroundStyle(.black.opacity(0.55))

                Spacer()

                Button(action: {}) {

                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            Color.black.opacity(0.75)
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16)
                        )
                }
            }
            .padding(24)
        }
    }
}


// MARK: - 9. SwiftUI Preview

#Preview {
    AnimatedBackgroundDemoView()
}
