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
            case .window: WindowView()
            case .crush: CrushView()
            case .chase: ChaseView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.45), value: store.route)
        .sheet(isPresented: $store.showSettings) { SettingsSheet() }
        .sheet(isPresented: $store.showPrivacy) { PrivacySheet() }
        .sheet(isPresented: $store.showRules) { RulesSheet() }
        .sheet(isPresented: $store.showAlbum) { AlbumSheet() }
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
            .frame(width: Lucky.panelWidth)
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

struct CoachOverlay: View {
    @EnvironmentObject private var store: GameStore
    @State private var burst = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(Lucky.black(22))
                    .tracking(2)
                    .foregroundStyle(Lucky.goldSoft)
                    .frame(maxWidth: .infinity)
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    coachLine("\(index + 1)", line)
                }
                Text("Tap to close")
                    .font(Lucky.bold(13))
                    .foregroundStyle(Lucky.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(20)
            .frame(width: Lucky.panelWidth)
            .background(Lucky.maroon.opacity(0.96), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Lucky.gold, lineWidth: 3)
            )
            .scaleEffect(burst ? 1 : 0.86)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            store.audio.click()
            withAnimation { store.dismissCoach() }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) { burst = true }
        }
    }

    private var title: String {
        switch store.mode {
        case .bet: "MARQUEE BET"
        case .stage: "CHALLENGE"
        case .classic: "KITCHEN"
        }
    }

    private var lines: [String] {
        switch store.mode {
        case .bet:
            [
                "Pick BET 10, 50, or 100.",
                "RESTOCK costs that bet from your score.",
                "SERVE a 3-match. Payout uses the bet."
            ]
        case .stage:
            [
                "Restocks are limited. They do not cost score.",
                store.currentStage?.blurb ?? "KEEP fruits, SWAP, then SERVE toward the goal.",
                "Hit the target before the restocks run out."
            ]
        case .classic:
            store.coins < 100
                ? [
                    "The bottom bar is this shift's menu.",
                    "SERVE those fruits for +30. Other lines still pay.",
                    "Clear the menu for a shift bonus.",
                    "Score under 100: serve 2 plates for +120."
                ]
                : [
                    "The bottom bar is this shift's menu.",
                    "SERVE those fruits for +30. Other lines still pay.",
                    "Clear the menu for a shift bonus. The next menu is harder."
                ]
        }
    }

    private func coachLine(_ step: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(step)
                .font(Lucky.black(14))
                .foregroundStyle(Lucky.gold)
                .frame(width: 22, height: 22)
                .background(Lucky.wine, in: Circle())
            Text(text)
                .font(Lucky.bold(14))
                .foregroundStyle(Lucky.cream)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct BlendPickOverlay: View {
    @EnvironmentObject private var store: GameStore
    @State private var burst = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
            VStack(spacing: 10) {
                Text("BLEND READY")
                    .font(Lucky.black(22))
                    .tracking(3)
                    .foregroundStyle(Lucky.goldSoft)
                Text("Pick a fruit. It is wild for the next 3 restocks.")
                    .font(Lucky.bold(13))
                    .foregroundStyle(Lucky.cream)
                    .multilineTextAlignment(.center)
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(SlotSymbol.allCases) { symbol in
                        Button {
                            withAnimation { store.pickBlend(symbol) }
                        } label: {
                            VStack(spacing: 4) {
                                Image(symbol.asset)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 44, height: 44)
                                Text(symbol.title)
                                    .font(Lucky.bold(10))
                                    .foregroundStyle(Lucky.gold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Lucky.wine.opacity(0.95), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Lucky.gold.opacity(0.55), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PressScale())
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .frame(width: Lucky.panelWidth)
            .background(Lucky.maroon.opacity(0.96), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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

struct AlbumSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationStack {
            ZStack {
                Lucky.void.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Serve a 3-match of each fruit to stamp it. Fill the album for a one-time +400 bonus.")
                            .font(Lucky.bold(14))
                            .foregroundStyle(Lucky.cream)
                        Text("\(store.albumCount) / 9 stamped")
                            .font(Lucky.black(18))
                            .foregroundStyle(Lucky.gold)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(SlotSymbol.allCases) { symbol in
                                let owned = store.album.contains(symbol.rawValue)
                                VStack(spacing: 6) {
                                    Image(symbol.asset)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 52)
                                        .grayscale(owned ? 0 : 1)
                                        .opacity(owned ? 1 : 0.38)
                                    Text(owned ? symbol.title : "???")
                                        .font(Lucky.bold(12))
                                        .foregroundStyle(owned ? Lucky.gold : Lucky.muted)
                                }
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(Lucky.maroon, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(owned ? Lucky.gold : Lucky.gold.opacity(0.2), lineWidth: owned ? 2 : 1)
                                )
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Fruit Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Lucky.gold)
                }
            }
        }
        .luckySheetChrome()
    }
}
