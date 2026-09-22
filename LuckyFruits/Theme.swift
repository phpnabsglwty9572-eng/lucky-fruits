import SwiftUI

enum Lucky {
    static let canvas = CGSize(width: 375, height: 667)
    static let void = Color(red: 12 / 255, green: 4 / 255, blue: 8 / 255)
    static let gold = Color(red: 255 / 255, green: 211 / 255, blue: 106 / 255)
    static let goldSoft = Color(red: 255 / 255, green: 241 / 255, blue: 184 / 255)
    static let wine = Color(red: 90 / 255, green: 12 / 255, blue: 20 / 255)
    static let maroon = Color(red: 58 / 255, green: 7 / 255, blue: 14 / 255)
    static let cream = Color(red: 255 / 255, green: 246 / 255, blue: 226 / 255)
    static let muted = Color(red: 201 / 255, green: 176 / 255, blue: 150 / 255)
    static let bulbPink = Color(red: 1, green: 90 / 255, blue: 200 / 255)
    static let bulbBlue = Color(red: 90 / 255, green: 200 / 255, blue: 1)

    static func black(_ size: CGFloat) -> Font { .system(size: size, weight: .black) }
    static func extra(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy) }
    static func bold(_ size: CGFloat) -> Font { .system(size: size, weight: .bold) }
}

struct PressScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct DesignCanvas<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / Lucky.canvas.width, geo.size.height / Lucky.canvas.height)
            ZStack {
                Lucky.void
                content()
                    .frame(width: Lucky.canvas.width, height: Lucky.canvas.height)
                    .scaleEffect(scale, anchor: .center)
                    .frame(width: Lucky.canvas.width * scale, height: Lucky.canvas.height * scale)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }
}
