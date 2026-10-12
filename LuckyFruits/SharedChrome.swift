import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        ZStack {
            switch store.route {
            case .loading: LoadingView()
            case .home: HomeView()
            case .modes: ModeSelectView()
            case .stages: StageMapView()
            case .game: GameView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.45), value: store.route)
        .sheet(isPresented: $store.showSettings) { SettingsSheet() }
        .sheet(isPresented: $store.showPrivacy) { PrivacySheet() }
        .sheet(isPresented: $store.showRules) { RulesSheet() }
    }
}

struct ArtButton: View {
    var image: String
    var w: CGFloat
    var h: CGFloat
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: w, height: h)
        }
        .buttonStyle(PressScale())
    }
}

struct MarqueeRing: View {
    var pulse: Bool
    var width: CGFloat
    var height: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.08, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<22, id: \.self) { i in
                    let p = CGFloat(i) / 22
                    let x = edgeX(p, w: width, h: height)
                    let y = edgeY(p, w: width, h: height)
                    let phase = (t * 6 + Double(i)).truncatingRemainder(dividingBy: 22)
                    let on = phase < 8
                    Circle()
                        .fill(i % 2 == 0 ? Lucky.bulbPink : Lucky.bulbBlue)
                        .frame(width: on ? 7 : 5, height: on ? 7 : 5)
                        .opacity(on ? 1 : 0.28)
                        .shadow(color: (i % 2 == 0 ? Lucky.bulbPink : Lucky.bulbBlue).opacity(on ? 0.9 : 0.2), radius: on ? 6 : 1)
                        .position(x: x, y: y)
                        .scaleEffect(pulse && on ? 1.15 : 1)
                }
            }
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }

    private func edgeX(_ p: CGFloat, w: CGFloat, h: CGFloat) -> CGFloat {
        let peri = 2 * (w + h)
        let d = p * peri
        if d < w { return d }
        if d < w + h { return w }
        if d < 2 * w + h { return w - (d - w - h) }
        return 0
    }

    private func edgeY(_ p: CGFloat, w: CGFloat, h: CGFloat) -> CGFloat {
        let peri = 2 * (w + h)
        let d = p * peri
        if d < w { return 0 }
        if d < w + h { return d - w }
        if d < 2 * w + h { return h }
        return h - (d - 2 * w - h)
    }
}

struct WinBurstOverlay: View {
    var amount: Int
    var title: String = "LUCKY WIN"
    var subtitle: String = "Tap to continue"
    @State private var burst = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(Lucky.gold.opacity(0.35))
                    .frame(width: burst ? 18 : 6, height: burst ? 18 : 6)
                    .offset(
                        x: burst ? CGFloat(cos(Double(i) / 12 * .pi * 2)) * 120 : 0,
                        y: burst ? CGFloat(sin(Double(i) / 12 * .pi * 2)) * 120 : 0
                    )
            }
            VStack(spacing: 8) {
                Text(title)
                    .font(Lucky.black(22))
                    .tracking(3)
                    .foregroundStyle(Lucky.goldSoft)
                if amount > 0 {
                    Text("+\(amount)")
                        .font(Lucky.black(42))
                        .foregroundStyle(Lucky.gold)
                        .shadow(color: Lucky.gold.opacity(0.7), radius: 16)
                }
                Text(subtitle)
                    .font(Lucky.bold(13))
                    .foregroundStyle(Lucky.muted)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 22)
            .background(Lucky.maroon.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Lucky.gold, lineWidth: 3)
            )
            .scaleEffect(burst ? 1 : 0.72)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.62)) { burst = true }
        }
    }
}

struct DailyGiftOverlay: View {
    @EnvironmentObject private var store: GameStore
    var gift: DailyGift
    @State private var burst = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
            VStack(spacing: 8) {
                Text("DAILY GIFT")
                    .font(Lucky.black(22))
                    .tracking(3)
                    .foregroundStyle(Lucky.goldSoft)
                Text("Day \(gift.day) of 7")
                    .font(Lucky.bold(14))
                    .foregroundStyle(Lucky.cream)
                Text("+\(gift.reward)")
                    .font(Lucky.black(42))
                    .foregroundStyle(Lucky.gold)
                    .shadow(color: Lucky.gold.opacity(0.7), radius: 16)
                Text(gift.day == 7 ? "Max gift. Come back tomorrow." : "Come back tomorrow to grow it.")
                    .font(Lucky.bold(13))
                    .foregroundStyle(Lucky.muted)
                    .multilineTextAlignment(.center)
                Button {
                    store.claimDaily()
                } label: {
                    Text("Collect")
                        .font(Lucky.bold(16))
                        .foregroundStyle(Lucky.gold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Lucky.wine, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Lucky.gold.opacity(0.45), lineWidth: 1)
                        )
                }
                .buttonStyle(PressScale())
                .padding(.top, 6)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .frame(width: 314)
            .background(Lucky.maroon.opacity(0.94), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Lucky.gold, lineWidth: 3)
            )
            .scaleEffect(burst ? 1 : 0.84)
        }
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.7)) { burst = true }
        }
    }
}
