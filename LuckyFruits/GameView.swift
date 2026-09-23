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

                Image("imgHudBar")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: 375, height: 69)
                    .clipped()
                    .position(x: 187.5, y: 34.5)
                    .allowsHitTesting(false)

                artTap("btnHome", w: 50, h: 50, x: 12, y: 10) {
                    store.audio.click()
                    withAnimation { store.route = .home }
                }

                coinsHud
                    .position(x: 187.5, y: 35.5)

                artTap("btnSettings", w: 50, h: 50, x: 313, y: 10) {
                    store.audio.click()
                    store.showSettings = true
                }

                reelBoard
                    .position(x: 20 + 335 / 2, y: 108 + 341 / 2)

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
                        .position(x: 187.5, y: 90)
                        .allowsHitTesting(false)
                }

                betPlate(top: "BET", bottom: "10", x: 19, y: 468, selected: store.bet == 10) {
                    store.setBet(10)
                }
                betPlate(top: "BET", bottom: "50", x: 99, y: 468, selected: store.bet == 50) {
                    store.setBet(50)
                }
                betPlate(top: "MAX", bottom: "BET", x: 178, y: 468, selected: store.bet != 10 && store.bet != 50) {
                    store.setBet(100)
                }

                Button {
                    Task { await store.spin() }
                } label: {
                    Image("btnSpin")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 111, height: 111)
                        .shadow(
                            color: Lucky.gold.opacity(store.isSpinning ? 0.2 : (pulse ? 0.55 : 0.2)),
                            radius: pulse ? 12 : 4
                        )
                        .opacity(store.canSpin || store.isSpinning ? 1 : 0.55)
                }
                .buttonStyle(PressScale())
                .disabled(!store.canSpin)
                .position(x: 254 + 55.5, y: 448 + 55.5)

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
                .frame(width: 135, height: 55)
            VStack(spacing: 0) {
                Text("COINS")
                    .font(Lucky.bold(8))
                    .tracking(1.6)
                    .foregroundStyle(Lucky.goldSoft.opacity(0.92))
                Text("\(store.coins)")
                    .font(Lucky.black(18))
                    .foregroundStyle(Lucky.gold)
                    .minimumScaleFactor(0.45)
                    .lineLimit(1)
                    .frame(width: 108)
            }
            .offset(y: 1)
        }
        .frame(width: 135, height: 55)
        .allowsHitTesting(false)
    }

    private var reelBoard: some View {
        let cols: [CGFloat] = [26, 123, 219]
        let rows: [CGFloat] = [42, 146, 238]
        let cellW: CGFloat = 88
        let cellH: [CGFloat] = [92, 80, 80]

        return ZStack(alignment: .topLeading) {
            Image("imgReel")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 335, height: 341)

            Image("imgTitle")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 188, height: 34)
                .position(x: 167.5, y: 20)

            if store.isSpinning {
                MarqueeRing(pulse: pulse, width: 335, height: 341)
                    .blendMode(.plusLighter)
                    .opacity(0.45)
            }

            ForEach(0..<3, id: \.self) { r in
                ForEach(0..<3, id: \.self) { c in
                    let hit = store.hitRows.contains(r)
                    ZStack {
                        Image(store.grid[r][c].asset)
                            .resizable()
                            .scaledToFit()
                            .padding(4)
                            .blur(radius: store.reelBlur)
                            .offset(y: store.spinningColumn == c ? 8 : 0)
                            .animation(.easeInOut(duration: 0.07), value: store.spinningColumn)
                    }
                    .frame(width: cellW, height: cellH[r])
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(hit && !store.isSpinning ? Lucky.gold : Color.clear, lineWidth: 2.5)
                            .shadow(color: hit && !store.isSpinning ? Lucky.gold.opacity(0.9) : .clear, radius: pulse ? 10 : 4)
                    )
                    .scaleEffect(hit && !store.isSpinning ? (pulse ? 1.04 : 1.0) : 1)
                    .offset(x: cols[c], y: rows[r])
                }
            }
        }
        .frame(width: 335, height: 341)
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

    private func betPlate(top: String, bottom: String, x: CGFloat, y: CGFloat, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Image("btnBetPlate")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 72, height: 63)
                VStack(spacing: -1) {
                    Text(top)
                        .font(Lucky.black(11))
                        .tracking(0.6)
                    Text(bottom)
                        .font(Lucky.black(15))
                }
                .foregroundStyle(Lucky.gold)
                .shadow(color: .black.opacity(0.45), radius: 1, y: 1)
                .offset(y: 1)
            }
            .frame(width: 74, height: 70)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selected ? Lucky.gold : Color.clear, lineWidth: 3)
            )
            .shadow(color: selected ? Lucky.gold.opacity(0.7) : .clear, radius: selected ? 8 : 0)
            .brightness(selected ? 0.06 : 0)
        }
        .buttonStyle(PressScale())
        .disabled(store.isSpinning)
        .position(x: x + 37, y: y + 35)
    }
}
