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
                if Lucky.isPad {
                    if Lucky.isLandscape(size) {
                        padLandscape(size: size)
                    } else {
                        padPortrait(size: size)
                    }
                } else if Lucky.isLandscape(size) {
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

            controlRow(spacing: 6)
                .position(x: 136, y: 503)

            if store.isWager, store.canServe {
                servePill
                    .position(x: 187.5, y: 452)
            }

            spinButton
                .position(x: 254 + 55.5, y: 448 + 55.5)

            harvestBar
                .frame(width: 351)
                .position(x: 187.5, y: 614)

            overlays
                .frame(width: 375, height: 667)
        }
        .frame(width: 375, height: 667)
    }

    private func padPortrait(size: CGSize) -> some View {
        let chrome: CGFloat = 96 + 40 + 156 + 96
        let reelScale = min((size.width - 72) / 335, max(280, size.height - chrome) / 341, 2.05)
        return VStack(spacing: 0) {
            padHUD(width: size.width)
            if !store.banner.isEmpty {
                bannerChip
                    .padding(.top, 10)
            }
            Spacer(minLength: 12)
            reelBoard
                .scaleEffect(reelScale)
                .frame(width: 335 * reelScale, height: 341 * reelScale)
            Spacer(minLength: 10)
            padBetRow
                .padding(.bottom, 10)
            harvestBar
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
        }
        .overlay { overlays }
        .frame(width: size.width, height: size.height)
    }

    private func padLandscape(size: CGSize) -> some View {
        let reelScale = min(
            (size.height - 220) / 341,
            (size.width * 0.54) / 335,
            1.85
        )
        return VStack(spacing: 0) {
            padHUD(width: size.width)
            if !store.banner.isEmpty {
                bannerChip
                    .padding(.top, 8)
            }
            HStack(alignment: .center, spacing: 36) {
                reelBoard
                    .scaleEffect(reelScale)
                    .frame(width: 335 * reelScale, height: 341 * reelScale)
                padBetRow
            }
            .padding(.horizontal, 36)
            .frame(maxHeight: .infinity)
            harvestBar
                .padding(.horizontal, 36)
                .padding(.bottom, 20)
        }
        .overlay { overlays }
        .frame(width: size.width, height: size.height)
    }

    private func padHUD(width: CGFloat) -> some View {
        ZStack {
            Image("imgHudBar")
                .resizable()
                .scaledToFill()
                .frame(width: width, height: 88)
                .clipped()
                .allowsHitTesting(false)
            HStack {
                hudIcon("btnHome", size: 58, disabled: store.isSpinning) {
                    store.audio.click()
                    withAnimation { store.leaveGame() }
                }
                Spacer()
                coinsHud
                    .scaleEffect(1.18)
                    .frame(width: 160, height: 65)
                Spacer()
                hudIcon("btnSettings", size: 58, disabled: store.isSpinning) {
                    store.audio.click()
                    store.showSettings = true
                }
            }
            .padding(.horizontal, 28)
        }
        .frame(height: 88)
    }

    private var padBetRow: some View {
        VStack(spacing: 14) {
            if store.isWager, store.canServe {
                servePill
            }
            controlRow(spacing: 16)
                .scaleEffect(1.12)
            spinButton
                .scaleEffect(1.28)
                .frame(width: 148, height: 148)
        }
    }

    private func landscapeMachine(size: CGSize) -> some View {
        let reelH = min(size.height - 168, size.width * 0.58)
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
                VStack(spacing: 16) {
                    if store.isWager, store.canServe {
                        servePill
                    }
                    controlRow(spacing: 12)
                    spinButton
                }
            }
            .padding(.horizontal, 28)
            .frame(maxHeight: .infinity)

            harvestBar
                .padding(.horizontal, 24)
                .padding(.bottom, 14)
        }
        .overlay {
            overlays
        }
        .frame(width: size.width, height: size.height)
    }

    @ViewBuilder
    private var overlays: some View {
        if store.showCoach {
            CoachOverlay()
        } else if store.showWinBurst {
            WinBurstOverlay(amount: store.lastWin, title: store.burstTitle, subtitle: store.burstSubtitle)
                .onTapGesture { withAnimation { store.dismissWinBurst() } }
        } else if store.showBlendPick {
            BlendPickOverlay()
        } else if let end = store.stageEnd {
            StageEndOverlay(end: end)
        }
    }

    private var harvestBar: some View {
        HStack(spacing: 8) {
            if store.mode == .stage {
                Text(store.currentStage?.blurb ?? "Keep fruits, restock the rest, then SERVE a line")
                    .font(Lucky.bold(Lucky.isPad ? 14 : 11))
                    .foregroundStyle(Lucky.goldSoft)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: Lucky.isPad ? 54 : 44, alignment: .leading)
                    .padding(.horizontal, 10)
            } else {
                if store.mode == .classic {
                    VStack(spacing: 1) {
                        Text("SHIFT")
                            .font(Lucky.bold(Lucky.isPad ? 10 : 8))
                            .foregroundStyle(Lucky.goldSoft)
                        Text("\(store.shiftNumber)")
                            .font(Lucky.black(Lucky.isPad ? 16 : 13))
                            .foregroundStyle(Lucky.gold)
                    }
                    .frame(width: Lucky.isPad ? 54 : 40, height: Lucky.isPad ? 54 : 44)
                    .background(Lucky.wine.opacity(0.95), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                ForEach(visibleOrders) { order in
                    orderChip(order)
                }
            }
            Button {
                store.audio.click()
                store.showAlbum = true
            } label: {
                VStack(spacing: Lucky.isPad ? 3 : 2) {
                    Text("\(store.albumCount)/9")
                        .font(Lucky.black(Lucky.isPad ? 16 : 13))
                        .foregroundStyle(Lucky.gold)
                    Text("ALBUM")
                        .font(Lucky.bold(Lucky.isPad ? 10 : 8))
                        .tracking(0.6)
                        .foregroundStyle(Lucky.goldSoft)
                }
                .frame(width: Lucky.isPad ? 70 : 52, height: Lucky.isPad ? 54 : 44)
                .background(Lucky.wine.opacity(0.95), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Lucky.gold.opacity(0.55), lineWidth: 1)
                )
            }
            .buttonStyle(PressScale())
        }
        .padding(.horizontal, Lucky.isPad ? 12 : 8)
        .padding(.vertical, Lucky.isPad ? 10 : 7)
        .frame(maxWidth: .infinity)
        .background(Lucky.maroon.opacity(0.94), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Lucky.gold.opacity(0.4), lineWidth: 1)
        )
    }

    private var visibleOrders: [HarvestOrder] {
        if store.mode == .classic {
            let cover = store.orders.filter { $0.kind == .coverShift && !$0.done }
            let plates = store.menu.filter { !$0.done }
            if cover.isEmpty { return plates }
            return cover + Array(plates.prefix(2))
        }
        return store.orders.filter { $0.kind != .coverShift }
    }

    private func orderChip(_ order: HarvestOrder) -> some View {
        let cover = order.kind == .coverShift
        return HStack(spacing: 5) {
            if let symbol = order.symbol {
                Image(symbol.asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Lucky.isPad ? 28 : 22, height: Lucky.isPad ? 28 : 22)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(order.title)
                    .font(Lucky.black(Lucky.isPad ? 13 : 10))
                    .foregroundStyle(Lucky.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(cover ? "\(order.progress) · +\(order.reward)" : order.progress)
                    .font(Lucky.bold(Lucky.isPad ? 11 : 9))
                    .foregroundStyle(Lucky.goldSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.horizontal, Lucky.isPad ? 10 : 7)
        .frame(maxWidth: .infinity, minHeight: Lucky.isPad ? 54 : 44, maxHeight: Lucky.isPad ? 54 : 44, alignment: .leading)
        .background(Lucky.wine.opacity(cover ? 0.95 : 0.72), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Lucky.gold.opacity(cover ? 0.9 : 0.28), lineWidth: cover ? 1.5 : 1)
        )
    }

    private func controlRow(spacing: CGFloat) -> some View {
        HStack(spacing: spacing) {
            if store.isWager {
            actionChip(top: "BET", bottom: "10", selected: store.bet == 10) { store.setBet(10) }
            actionChip(top: "BET", bottom: "50", selected: store.bet == 50) { store.setBet(50) }
            actionChip(top: "MAX", bottom: "BET", selected: store.bet == 100) { store.setBet(100) }
        } else {
            actionChip(top: "SERVE", bottom: store.canServe ? "READY" : "LINE", selected: store.canServe) {
                store.serve()
            }
            actionChip(top: "SWAP", bottom: store.swapsLeft > 0 ? "\(store.swapsLeft)" : "0", selected: store.swapMode) {
                store.toggleSwapMode()
            }
            actionChip(top: "CLEAR", bottom: "KEEP", selected: !store.lockedCells.isEmpty) {
                store.clearLocks()
            }
            }
        }
    }

    private var servePill: some View {
        Button {
            store.serve()
        } label: {
            Text("SERVE")
                .font(Lucky.black(13))
                .tracking(1.2)
                .foregroundStyle(Lucky.gold)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Lucky.wine.opacity(0.95), in: Capsule())
                .overlay(Capsule().stroke(Lucky.gold, lineWidth: 1.5))
                .shadow(color: Lucky.gold.opacity(0.45), radius: 6)
        }
        .buttonStyle(PressScale())
    }

    private var bannerChip: some View {
        Text(store.banner)
            .font(Lucky.bold(Lucky.isPad ? 14 : 11))
            .foregroundStyle(Lucky.goldSoft)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, Lucky.isPad ? 16 : 10)
            .padding(.vertical, Lucky.isPad ? 7 : 4)
            .background(Lucky.maroon.opacity(0.88), in: Capsule())
            .overlay(Capsule().stroke(Lucky.gold.opacity(0.55), lineWidth: 1))
            .frame(width: Lucky.isPad ? 420 : 280)
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
                Text("STOCK")
                    .font(Lucky.black(11))
                    .tracking(1)
                    .foregroundStyle(Lucky.goldSoft)
                    .shadow(color: .black.opacity(0.7), radius: 2, y: 1)
                    .offset(y: 28)
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

    private func hudIcon(_ image: String, size: CGFloat = 50, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size, height: size)
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
                Text(store.mode == .stage ? "GOAL" : (store.isWager ? "BET \(store.bet)" : "SCORE"))
                    .font(Lucky.bold(8))
                    .tracking(1.6)
                    .foregroundStyle(Lucky.goldSoft.opacity(0.92))
                Text(store.mode == .stage ? "\(store.stageWon)/\(store.stageTarget)" : "\(store.coins)")
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
                    let index = r * 3 + c
                    let hit = store.hitCells.contains(index)
                    let kept = store.lockedCells.contains(index)
                    let picked = store.swapPicked == index
                    Button {
                        store.tapCell(index)
                    } label: {
                        ZStack {
                            Image(store.grid[r][c].asset)
                                .resizable()
                                .scaledToFit()
                                .padding(4)
                                .blur(radius: kept ? 0 : store.reelBlur)
                                .offset(y: kept ? 0 : (store.spinningColumn == c ? 8 : 0))
                                .animation(.easeInOut(duration: 0.07), value: store.spinningColumn)
                            if kept, !store.isSpinning {
                                Text("KEEP")
                                    .font(Lucky.black(8))
                                    .tracking(0.6)
                                    .foregroundStyle(Lucky.gold)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Lucky.wine.opacity(0.92), in: Capsule())
                                    .offset(y: cellH[r] / 2 - 14)
                            }
                        }
                        .frame(width: cellW, height: cellH[r])
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    picked ? Lucky.goldSoft : (kept ? Lucky.gold : (hit && !store.isSpinning ? Lucky.gold : Color.clear)),
                                    lineWidth: picked || kept || hit ? 2.5 : 0
                                )
                                .shadow(
                                    color: (picked || kept || hit) && !store.isSpinning ? Lucky.gold.opacity(0.9) : .clear,
                                    radius: pulse ? 10 : 4
                                )
                        )
                        .scaleEffect(picked ? 1.06 : (hit && !store.isSpinning ? (pulse ? 1.04 : 1.0) : 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(!store.canAct)
                    .offset(x: cols[c], y: rows[r])
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

    private func actionChip(top: String, bottom: String, selected: Bool, action: @escaping () -> Void) -> some View {
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
                        .font(Lucky.black(13))
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
        .disabled(!store.canAct)
        .opacity(store.canAct ? 1 : 0.45)
    }
}
