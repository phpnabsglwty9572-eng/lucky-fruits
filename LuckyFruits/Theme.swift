import SwiftUI
import UIKit

enum Lucky {
    static let canvas = CGSize(width: 375, height: 667)
    static let privacyURL = URL(string: "https://docs.google.com/document/d/13Efpy8BminFvxiN10P9EchS0udkls0YWBKtLSKIvpA0/edit?usp=sharing")!
    static let void = Color(red: 12 / 255, green: 4 / 255, blue: 8 / 255)
    static let gold = Color(red: 255 / 255, green: 211 / 255, blue: 106 / 255)
    static let goldSoft = Color(red: 255 / 255, green: 241 / 255, blue: 184 / 255)
    static let wine = Color(red: 90 / 255, green: 12 / 255, blue: 20 / 255)
    static let maroon = Color(red: 58 / 255, green: 7 / 255, blue: 14 / 255)
    static let cream = Color(red: 255 / 255, green: 246 / 255, blue: 226 / 255)
    static let muted = Color(red: 201 / 255, green: 176 / 255, blue: 150 / 255)
    static let bulbPink = Color(red: 1, green: 90 / 255, blue: 200 / 255)
    static let bulbBlue = Color(red: 90 / 255, green: 200 / 255, blue: 1)

    static var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    static var panelWidth: CGFloat { isPad ? 440 : 314 }

    static func black(_ size: CGFloat) -> Font { .system(size: size, weight: .black) }
    static func extra(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy) }
    static func bold(_ size: CGFloat) -> Font { .system(size: size, weight: .bold) }
}

struct PressScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .offset(y: configuration.isPressed ? 3 : 0)
            .brightness(configuration.isPressed ? 0.14 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.52), value: configuration.isPressed)
    }
}

struct EdgeLights: View {
    var width: CGFloat
    var height: CGFloat
    var corner: CGFloat
    var count: Int = 20
    var speed: Double = 0.5

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate * speed
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    let progress = (CGFloat(i) / CGFloat(count) + CGFloat(t.truncatingRemainder(dividingBy: 1)))
                    let p = Self.point(progress, w: width, h: height, r: corner)
                    let wave = (sin(t * .pi * 2 + Double(i) * 0.7) + 1) / 2
                    let on = wave > 0.42
                    Circle()
                        .fill(i % 2 == 0 ? Lucky.goldSoft : Lucky.bulbPink)
                        .frame(width: on ? 6.5 : 4.5, height: on ? 6.5 : 4.5)
                        .opacity(on ? 0.95 : 0.22)
                        .shadow(color: (i % 2 == 0 ? Lucky.gold : Lucky.bulbPink).opacity(on ? 0.9 : 0.15), radius: on ? 5 : 1)
                        .position(x: p.x, y: p.y)
                }
            }
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }

    private static func point(_ raw: CGFloat, w: CGFloat, h: CGFloat, r: CGFloat) -> CGPoint {
        let p = ((raw.truncatingRemainder(dividingBy: 1)) + 1).truncatingRemainder(dividingBy: 1)
        let rr = min(r, w / 2, h / 2)
        let straightW = max(0, w - 2 * rr)
        let straightH = max(0, h - 2 * rr)
        let arc = CGFloat.pi / 2 * rr
        let peri = 2 * straightW + 2 * straightH + 4 * arc
        var d = p * peri

        if d <= straightW { return CGPoint(x: rr + d, y: 0) }
        d -= straightW
        if d <= arc {
            let a = -CGFloat.pi / 2 + d / rr
            return CGPoint(x: w - rr + cos(a) * rr, y: rr + sin(a) * rr)
        }
        d -= arc
        if d <= straightH { return CGPoint(x: w, y: rr + d) }
        d -= straightH
        if d <= arc {
            let a = d / rr
            return CGPoint(x: w - rr + cos(a) * rr, y: h - rr + sin(a) * rr)
        }
        d -= arc
        if d <= straightW { return CGPoint(x: w - rr - d, y: h) }
        d -= straightW
        if d <= arc {
            let a = CGFloat.pi / 2 + d / rr
            return CGPoint(x: rr + cos(a) * rr, y: h - rr + sin(a) * rr)
        }
        d -= arc
        if d <= straightH { return CGPoint(x: 0, y: h - rr - d) }
        d -= straightH
        let a = CGFloat.pi + d / rr
        return CGPoint(x: rr + cos(a) * rr, y: rr + sin(a) * rr)
    }
}

struct CircleLights: View {
    var diameter: CGFloat
    var spinning: Bool
    var armed: Bool
    var count: Int = 16

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let speed = spinning ? 7.2 : (armed ? 2.1 : 0.7)
            ZStack {
                Circle()
                    .stroke(Lucky.gold.opacity(armed ? 0.35 : 0.12), lineWidth: 2)
                    .frame(width: diameter + 8, height: diameter + 8)
                    .scaleEffect(armed && !spinning ? 1 + 0.04 * sin(t * 3) : 1)
                ForEach(0..<count, id: \.self) { i in
                    let ang = Double(i) / Double(count) * .pi * 2 + t * speed
                    let radius = (diameter / 2) + 2
                    let wave = (sin(t * (spinning ? 10 : 4) + Double(i)) + 1) / 2
                    Circle()
                        .fill(i % 2 == 0 ? Lucky.gold : Lucky.bulbPink)
                        .frame(width: 6.5, height: 6.5)
                        .opacity(armed ? 0.35 + 0.65 * wave : 0.18)
                        .shadow(color: Lucky.gold.opacity(armed ? 0.8 * wave : 0.1), radius: 4)
                        .offset(x: cos(ang) * radius, y: sin(ang) * radius)
                }
            }
        }
        .frame(width: diameter + 18, height: diameter + 18)
        .allowsHitTesting(false)
    }
}

struct DesignCanvas<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geo in
            let inset = geo.safeAreaInsets
            let play = CGSize(
                width: max(1, geo.size.width - inset.leading - inset.trailing),
                height: max(1, geo.size.height - inset.top - inset.bottom)
            )
            let scale = Lucky.canvasScale(for: play)
            ZStack {
                Image("imgLoadBg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .allowsHitTesting(false)
                content()
                    .frame(width: Lucky.canvas.width, height: Lucky.canvas.height)
                    .scaleEffect(x: scale.width, y: scale.height, anchor: .center)
                    .frame(width: Lucky.canvas.width * scale.width, height: Lucky.canvas.height * scale.height)
                    .position(
                        x: inset.leading + play.width / 2,
                        y: inset.top + play.height / 2
                    )
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(.easeInOut(duration: 0.28), value: geo.size)
        }
        .background(Lucky.void)
        .ignoresSafeArea()
    }
}

extension Lucky {
    static func isLandscape(_ size: CGSize) -> Bool {
        size.width > size.height + 12
    }

    static func canvasScale(for play: CGSize) -> CGSize {
        let dw = canvas.width
        let dh = canvas.height
        if isLandscape(play) {
            let s = min(play.width / dw, play.height / dh)
            return CGSize(width: s, height: s)
        }
        let aspect = play.width / max(play.height, 1)
        if aspect > dw / dh + 0.02 {
            return CGSize(width: play.width / dw, height: play.height / dh)
        }
        let s = min(play.width / dw, play.height / dh)
        return CGSize(width: s, height: s)
    }
}

extension View {
    func luckySheetChrome(
        phoneDetents: Set<PresentationDetent>? = [.medium],
        colorScheme: ColorScheme = .dark,
        background: Color = Lucky.void
    ) -> some View {
        modifier(LuckySheetChrome(phoneDetents: phoneDetents, colorScheme: colorScheme, background: background))
    }
}

private struct LuckySheetChrome: ViewModifier {
    var phoneDetents: Set<PresentationDetent>?
    var colorScheme: ColorScheme
    var background: Color

    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            padSheet(content)
        } else if let phoneDetents {
            content
                .presentationDetents(phoneDetents)
                .presentationBackground(background)
                .preferredColorScheme(colorScheme)
        } else {
            content
                .presentationBackground(background)
                .preferredColorScheme(colorScheme)
        }
    }

    @ViewBuilder
    private func padSheet(_ content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .presentationSizing(.form)
                .presentationBackground(background)
                .frame(minWidth: 440, idealWidth: 480, minHeight: 460)
                .preferredColorScheme(colorScheme)
        } else {
            content
                .presentationDetents([.large])
                .presentationBackground(background)
                .preferredColorScheme(colorScheme)
        }
    }
}
