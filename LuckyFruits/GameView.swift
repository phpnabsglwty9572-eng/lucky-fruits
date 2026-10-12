import SwiftUI

struct GameView: View {
    @EnvironmentObject private var store: GameStore
    @State private var pulse = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                Image("imgLoadBg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .allowsHitTesting(false)
                if Lucky.isLandscape(size) {
                    landscapeMachine(size: size)
                } else {
                    phoneMachine
                        .frame(width: Lucky.canvas.width, height: Lucky.canvas.height)
                        .scaleEffect(
                            x: Lucky.canvasScale(for: size).width,
                            y: Lucky.canvasScale(for: size).height,
                            anchor: .center
                        )
                        .frame(width: size.width, height: size.height)
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) { pulse = true }
            store.audio.startMusic()
        }
    }

    private var phoneMachine: some View {
        ZStack {
            Image("imgHudBar")
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .frame(width: 375, height: 69)
                .clipped()
                .position(x: 187.5, y: 34.5)
                .allowsHitTesting(false)

            artTap("btnHome", w: 50, h: 50, x: 12, y: 10, disabled: store.isSpinning, pulse: pulse) {
                store.audio.click()
                withAnimation { store.leaveGame() }
            }

            coinsHud
                .position(x: 187.5, y: 35.5)

            artTap("btnSettings", w: 50, h: 50, x: 313, y: 10, disabled: store.isSpinning, pulse: pulse) {
                store.audio.click()
                store.showSettings = true
            }

            reelBoard
                .position(x: 20 + 335 / 2, y: 108 + 341 / 2)

            if !store.banner.isEmpty {
                bannerChip
                    .position(x: 187.5, y: 90)
            }

            betChip(top: "BET", bottom: "10", selected: store.bet == 10) { store.setBet(10) }
                .position(x: 19 + 37, y: 468 + 35)
            betChip(top: "BET", bottom: "50", selected: store.bet == 50) { store.setBet(50) }
                .position(x: 99 + 37, y: 468 + 35)
            betChip(top: "MAX", bottom: "BET", selected: store.bet != 10 && store.bet != 50) { store.setBet(100) }
                .position(x: 178 + 37, y: 468 + 35)

            spinButton
                .position(x: 254 + 55.5, y: 448 + 55.5)

            overlays
                .frame(width: 375, height: 667)
        }
        .frame(width: 375, height: 667)
    }

    private func landscapeMachine(size: CGSize) -> some View {
        let reelH = min(size.height - 96, size.width * 0.58)
        let reelScale = min(reelH / 341, (size.width * 0.58) / 335)
        return VStack(spacing: 0) {
            ZStack {
                Image("imgHudBar")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: 72)
                    .clipped()
                    .allowsHitTesting(false)
                HStack {
                    hudIcon("btnHome", disabled: store.isSpinning) {
                        store.audio.click()
                        withAnimation { store.leaveGame() }
                    }
                    Spacer()
                    coinsHud
                    Spacer()
                    hudIcon("btnSettings", disabled: store.isSpinning) {
                        store.audio.click()
                        store.showSettings = true
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(height: 72)

            if !store.banner.isEmpty {
                bannerChip
                    .padding(.top, 6)
            }

            HStack(alignment: .center, spacing: 28) {
                reelBoard
                    .scaleEffect(reelScale)
                    .frame(width: 335 * reelScale, height: 341 * reelScale)
                VStack(spacing: 22) {
                    HStack(spacing: 12) {
                        betChip(top: "BET", bottom: "10", selected: store.bet == 10) { store.setBet(10) }
                        betChip(top: "BET", bottom: "50", selected: store.bet == 50) { store.setBet(50) }
                        betChip(top: "MAX", bottom: "BET", selected: store.bet != 10 && store.bet != 50) { store.setBet(100) }
                    }
                    spinButton
                }
            }
            .padding(.horizontal, 28)
            .frame(maxHeight: .infinity)
        }
        .overlay {
            overlays
        }
        .frame(width: size.width, height: size.height)
    }

    @ViewBuilder
    private var overlays: some View {
        if store.showWinBurst {
            WinBurstOverlay(amount: store.lastWin, title: store.burstTitle, subtitle: store.burstSubtitle)
                .onTapGesture { withAnimation { store.dismissWinBurst() } }
        } else if let end = store.stageEnd {
            StageEndOverlay(end: end)
        }
    }

    private var bannerChip: some View {
        Text(store.banner)
            .font(Lucky.bold(11))
            .foregroundStyle(Lucky.goldSoft)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Lucky.maroon.opacity(0.88), in: Capsule())
            .overlay(Capsule().stroke(Lucky.gold.opacity(0.55), lineWidth: 1))
            .frame(width: 280)
            .allowsHitTesting(false)
    }

    private var spinButton: some View {
        Button {
            Task { await store.spin() }
        } label: {
            ZStack {
                CircleLights(
                    diameter: 111,
                    spinning: store.isSpinning,
                    armed: store.canSpin
                )
                Image("btnSpin")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 111, height: 111)
                    .rotationEffect(.degrees(store.isSpinning ? 0 : (store.canSpin ? (pulse ? -6 : 5) : 0)))
            }
            .shadow(
                color: Lucky.gold.opacity(store.isSpinning ? 0.85 : (store.canSpin ? (pulse ? 0.75 : 0.28) : 0.08)),
                radius: store.isSpinning ? 18 : (pulse ? 14 : 5)
            )
            .scaleEffect(store.isSpinning ? 0.96 : (store.canSpin && pulse ? 1.06 : 1))
            .opacity(store.canSpin || store.isSpinning ? 1 : 0.55)
        }
        .buttonStyle(PressScale())
        .disabled(!store.canSpin)
    }

    private func hudIcon(_ image: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 50, height: 50)
        }
        .buttonStyle(PressScale())
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
    }

    private var coinsHud: some View {
        ZStack {
            Image("hudCoins")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 135, height: 55)
            VStack(spacing: 0) {
                Text(store.mode == .stage ? "GOAL" : (store.inBonus ? "FREE" : "COINS"))
                    .font(Lucky.bold(8))
                    .tracking(1.6)
                    .foregroundStyle(Lucky.goldSoft.opacity(0.92))
                Text(store.mode == .stage ? "\(store.stageWon)/\(store.stageTarget)" : (store.inBonus ? "\(store.freeSpinsLeft)" : "\(store.coins)"))
                    .font(Lucky.black(18))
                    .foregroundStyle(Lucky.gold)
                    .minimumScaleFactor(0.45)
                    .lineLimit(1)
                    .frame(width: 108)
            }
            .offset(y: 1)
        }
        .frame(width: 135, height: 55)
        .scaleEffect(store.coinFlash ? 1.12 : 1)
        .shadow(color: Lucky.gold.opacity(store.coinFlash ? 0.85 : 0), radius: store.coinFlash ? 10 : 0)
        .animation(.spring(response: 0.32, dampingFraction: 0.55), value: store.coinFlash)
        .allowsHitTesting(false)
        .onChange(of: store.coinFlash) { _, flashing in
            guard flashing else { return }
            Task {
                try? await Task.sleep(nanoseconds: 700_000_000)
                await MainActor.run { store.coinFlash = false }
            }
        }
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
                    let hit = store.hitCells.contains(r * 3 + c)
                    let held = store.heldColumns.contains(c)
                    ZStack {
                        Image(store.grid[r][c].asset)
                            .resizable()
                            .scaledToFit()
                            .padding(4)
                            .blur(radius: held ? 0 : store.reelBlur)
                            .offset(y: held ? 0 : (store.spinningColumn == c ? 8 : 0))
                            .animation(.easeInOut(duration: 0.07), value: store.spinningColumn)
                    }
                    .frame(width: cellW, height: cellH[r])
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                held ? Lucky.gold : (hit && !store.isSpinning ? Lucky.gold : Color.clear),
                                lineWidth: held || hit ? 2.5 : 0
                            )
                            .shadow(color: (held || hit) && !store.isSpinning ? Lucky.gold.opacity(0.9) : .clear, radius: pulse ? 10 : 4)
                    )
                    .scaleEffect(hit && !store.isSpinning ? (pulse ? 1.04 : 1.0) : 1)
                    .offset(x: cols[c], y: rows[r])
                    .allowsHitTesting(false)
                }
            }

            ForEach(0..<3, id: \.self) { c in
                let held = store.heldColumns.contains(c)
                Button {
                    store.toggleHold(c)
                } label: {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(held ? Lucky.gold.opacity(0.12) : Color.white.opacity(0.001))
                        .overlay(alignment: .bottom) {
                            Text("HOLD")
                                .font(Lucky.black(10))
                                .tracking(1)
                                .foregroundStyle(held ? Lucky.gold : Lucky.goldSoft.opacity(store.canHold ? 0.45 : 0))
                                .padding(.bottom, 6)
                        }
                }
                .buttonStyle(.plain)
                .disabled(!store.canHold)
                .frame(width: cellW, height: 252)
                .offset(x: cols[c], y: rows[0])

                if store.canHold, store.nudgesLeft > 0, !held {
                    Button {
                        store.nudge(c)
                    } label: {
                        Text("NUDGE")
                            .font(Lucky.black(9))
                            .tracking(0.6)
                            .foregroundStyle(Lucky.gold)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Lucky.wine.opacity(0.94), in: Capsule())
                            .overlay(Capsule().stroke(Lucky.gold, lineWidth: 1))
                            .shadow(color: Lucky.gold.opacity(0.45), radius: 4)
                    }
                    .buttonStyle(PressScale())
                    .offset(x: cols[c] + 16, y: rows[0] + 4)
                }
            }
        }
        .frame(width: 335, height: 341)
        .clipped()
    }

    private func artTap(_ image: String, w: CGFloat, h: CGFloat, x: CGFloat, y: CGFloat, disabled: Bool = false, pulse: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Lucky.gold.opacity(disabled ? 0 : (pulse ? 0.7 : 0.18)), lineWidth: 1.6)
                    .frame(width: w + 8, height: h + 8)
                    .scaleEffect(pulse && !disabled ? 1.1 : 1)
                    .opacity(disabled ? 0 : 1)
                Image(image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: w, height: h)
            }
        }
        .buttonStyle(PressScale())
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
        .position(x: x + w / 2, y: y + h / 2)
    }

    private func betChip(top: String, bottom: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Image("btnBetPlate")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 72, height: 63)
                if selected {
                    EdgeLights(width: 76, height: 68, corner: 12, count: 12, speed: 0.7)
                }
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
                    .stroke(selected ? Lucky.gold : Lucky.gold.opacity(0.18), lineWidth: selected ? 3 : 1)
            )
            .shadow(color: selected ? Lucky.gold.opacity(pulse ? 0.95 : 0.4) : .clear, radius: selected ? (pulse ? 12 : 6) : 0)
            .brightness(selected ? 0.08 : 0)
            .scaleEffect(selected ? (pulse ? 1.08 : 1.03) : 1)
        }
        .buttonStyle(PressScale())
        .disabled(store.isSpinning || store.inBonus)
        .opacity(store.inBonus ? 0.45 : 1)
    }
}
