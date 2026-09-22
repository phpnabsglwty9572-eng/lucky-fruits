import SwiftUI

struct GameView: View {
    @EnvironmentObject private var store: GameStore
    @State private var pulse = false

    var body: some View {
        DesignCanvas {
            ZStack {
                Image("imgLoadBg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 375, height: 667)
                    .clipped()
                    .allowsHitTesting(false)

                artTap("btnHome", w: 51, h: 51, x: 12, y: 5) {
                    store.audio.click()
                    withAnimation { store.route = .home }
                }
                coinsHud
                    .position(x: 119 + 68, y: 6 + 25.5)
                artTap("btnSettings", w: 51, h: 51, x: 311, y: 5) {
                    store.audio.click()
                    store.showSettings = true
                }

                Image("imgTitle")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 206, height: 39)
                    .position(x: 84 + 103, y: 114 + 19.5)
                    .allowsHitTesting(false)

                reelBoard
                    .position(x: 19 + 168, y: 133 + 161.5)

                if !store.banner.isEmpty {
                    Text(store.banner)
                        .font(Lucky.bold(11))
                        .foregroundStyle(Lucky.goldSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Lucky.maroon.opacity(0.88), in: Capsule())
                        .overlay(Capsule().stroke(Lucky.gold.opacity(0.55), lineWidth: 1))
                        .frame(width: 220)
                        .position(x: 187.5, y: 62)
                        .allowsHitTesting(false)
                }

                betButton("btnBet10", w: 74, h: 70, x: 19, y: 478, selected: store.bet == 10) { store.setBet(10) }
                betButton("btnBet50", w: 74, h: 70, x: 99, y: 478, selected: store.bet == 50) { store.setBet(50) }
                betButton("btnMaxBet", w: 72, h: 70, x: 178, y: 478, selected: store.bet == 100) { store.setBet(100) }

                Button {
                    Task { await store.spin() }
                } label: {
                    Image("btnSpin")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 112, height: 112)
                        .shadow(color: Lucky.gold.opacity(store.isSpinning ? 0.2 : (pulse ? 0.55 : 0.2)), radius: pulse ? 12 : 4)
                        .opacity(store.canSpin || store.isSpinning ? 1 : 0.55)
                }
                .buttonStyle(PressScale())
                .disabled(!store.canSpin)
                .position(x: 254 + 56, y: 456 + 56)

                if store.showWinBurst {
                    WinBurstOverlay(amount: store.lastWin)
                        .frame(width: 375, height: 667)
                        .onTapGesture { withAnimation { store.showWinBurst = false } }
                }
            }
            .frame(width: 375, height: 667)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) { pulse = true }
            store.audio.startMusic()
        }
    }

    private var coinsHud: some View {
        ZStack {
            Image("hudCoins")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 136, height: 51)
            Text("\(store.coins)")
                .font(Lucky.black(16))
                .foregroundStyle(Lucky.gold)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(width: 100, height: 18)
                .background(Color(red: 0.36, green: 0.06, blue: 0.09))
                .offset(y: 10)
        }
        .frame(width: 136, height: 51)
        .allowsHitTesting(false)
    }

    private var reelBoard: some View {
        let padL: CGFloat = 28
        let padT: CGFloat = 54
        let padR: CGFloat = 28
        let padB: CGFloat = 30
        let gap: CGFloat = 7
        let cellW = (336 - padL - padR - gap * 2) / 3
        let cellH = (323 - padT - padB - gap * 2) / 3

        return ZStack(alignment: .topLeading) {
            Image("imgReel")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 336, height: 323)

            if store.isSpinning {
                MarqueeRing(pulse: pulse, width: 336, height: 323)
                    .blendMode(.plusLighter)
                    .opacity(0.45)
            }

            ForEach(0..<3, id: \.self) { r in
                ForEach(0..<3, id: \.self) { c in
                    let hit = store.hitRows.contains(r)
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black)
                        Image(store.grid[r][c].asset)
                            .resizable()
                            .scaledToFit()
                            .padding(3)
                            .blur(radius: store.reelBlur)
                            .offset(y: store.spinningColumn == c ? 8 : 0)
                            .animation(.easeInOut(duration: 0.07), value: store.spinningColumn)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(hit && !store.isSpinning ? Lucky.gold : Color.clear, lineWidth: 2.5)
                            .shadow(color: hit && !store.isSpinning ? Lucky.gold.opacity(0.9) : .clear, radius: pulse ? 10 : 4)
                    )
                    .scaleEffect(hit && !store.isSpinning ? (pulse ? 1.04 : 1.0) : 1)
                    .frame(width: cellW, height: cellH)
                    .offset(
                        x: padL + CGFloat(c) * (cellW + gap),
                        y: padT + CGFloat(r) * (cellH + gap)
                    )
                }
            }
        }
        .frame(width: 336, height: 323)
        .clipped()
        .allowsHitTesting(false)
    }

    private func artTap(_ image: String, w: CGFloat, h: CGFloat, x: CGFloat, y: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: w, height: h)
        }
        .buttonStyle(PressScale())
        .position(x: x + w / 2, y: y + h / 2)
    }

    private func betButton(_ image: String, w: CGFloat, h: CGFloat, x: CGFloat, y: CGFloat, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: w, height: h)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selected ? Lucky.gold : Color.clear, lineWidth: 3)
                )
                .shadow(color: selected ? Lucky.gold.opacity(0.7) : .clear, radius: selected ? 8 : 0)
        }
        .buttonStyle(PressScale())
        .disabled(store.isSpinning)
        .position(x: x + w / 2, y: y + h / 2)
    }
}
