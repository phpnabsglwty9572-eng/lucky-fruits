import SwiftUI

struct GameView: View {
    @EnvironmentObject private var store: GameStore
    @State private var pulse = false

    var body: some View {
        DesignCanvas {
            ZStack(alignment: .topLeading) {
                Image("imgBg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 375, height: 667)
                    .clipped()
                    .allowsHitTesting(false)

                coinsHud
                    .position(x: 119 + 68, y: 6 + 25.5)

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
                        .position(x: 187.5, y: 72)
                        .allowsHitTesting(false)
                }

                hotSpot(x: 12, y: 5, w: 51, h: 51, circle: true) {
                    store.audio.click()
                    withAnimation { store.route = .home }
                }
                hotSpot(x: 311, y: 5, w: 51, h: 51, circle: true) {
                    store.audio.click()
                    store.showSettings = true
                }
                hotSpot(x: 19, y: 478, w: 74, h: 70, circle: false) { store.setBet(10) }
                hotSpot(x: 99, y: 478, w: 74, h: 70, circle: false) { store.setBet(50) }
                hotSpot(x: 178, y: 478, w: 72, h: 70, circle: false) { store.setBet(100) }
                hotSpot(x: 254, y: 456, w: 112, h: 112, circle: true) {
                    Task { await store.spin() }
                }

                betGlow(x: 19, y: 478, w: 74, h: 70, on: store.bet == 10)
                betGlow(x: 99, y: 478, w: 74, h: 70, on: store.bet == 50)
                betGlow(x: 178, y: 478, w: 72, h: 70, on: store.bet == 100)

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
        Text("\(store.coins)")
            .font(Lucky.black(16))
            .foregroundStyle(Lucky.gold)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .frame(width: 100, height: 18)
            .background(Color(red: 0.36, green: 0.06, blue: 0.09))
            .offset(y: 10)
            .frame(width: 136, height: 51, alignment: .center)
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
            if store.isSpinning {
                MarqueeRing(pulse: pulse, width: 336, height: 323)
                    .blendMode(.plusLighter)
                    .opacity(0.55)
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

    private func betGlow(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, on: Bool) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(Lucky.gold, lineWidth: on ? 3 : 0)
            .shadow(color: on ? Lucky.gold.opacity(0.75) : .clear, radius: on ? 8 : 0)
            .frame(width: w, height: h)
            .position(x: x + w / 2, y: y + h / 2)
            .allowsHitTesting(false)
    }

    private func hotSpot(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, circle: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Rectangle()
                .fill(Color.white.opacity(0.001))
                .frame(width: w, height: h)
                .contentShape(circle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 10)))
        }
        .buttonStyle(.plain)
        .position(x: x + w / 2, y: y + h / 2)
    }
}

private struct AnyShape: Shape {
    private let builder: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        builder = { rect in shape.path(in: rect) }
    }

    func path(in rect: CGRect) -> Path { builder(rect) }
}
