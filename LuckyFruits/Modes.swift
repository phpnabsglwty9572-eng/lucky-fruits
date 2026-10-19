import SwiftUI

struct ModeSelectView: View {
    @EnvironmentObject private var store: GameStore
    @State private var glow = false

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
                if Lucky.isLandscape(size) || Lucky.isPad {
                    landscapeModes(size: size)
                } else {
                    phoneModes
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
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) { glow = true }
            store.audio.startMusic()
        }
    }

    private var phoneModes: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 6) {
                Color.clear.frame(height: 36)
                Image("imgHomeLogo")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 150, height: 58)
                    .shadow(color: Lucky.gold.opacity(glow ? 0.4 : 0.12), radius: glow ? 14 : 4)

                Text("SELECT MODE")
                    .font(Lucky.black(16))
                    .tracking(2)
                    .foregroundStyle(Lucky.gold)

                ScrollView {
                    VStack(spacing: 8) {
                        modeCard(
                            title: "Kitchen",
                            subtitle: "Serve the shift menu",
                            footnote: "No bet · score only when you serve",
                            width: 314,
                            height: 86
                        ) {
                            store.audio.click()
                            withAnimation { store.openClassic() }
                        }
                        modeCard(
                            title: "Challenge",
                            subtitle: "Limited restocks · serve to the goal",
                            footnote: "Cleared \(store.clearedStages)/\(StageDef.campaign.count)",
                            width: 314,
                            height: 86
                        ) {
                            store.audio.click()
                            withAnimation { store.route = .stages }
                        }
                        modeCard(
                            title: "Window",
                            subtitle: "Plate the order from the counter",
                            footnote: "12 levels · fuller counter",
                            width: 314,
                            height: 86
                        ) {
                            store.audio.click()
                            withAnimation { store.route = .window }
                        }
                        modeCard(
                            title: "Crush",
                            subtitle: "Swap fruits to match three",
                            footnote: "7×7 · banks a little score",
                            width: 314,
                            height: 86
                        ) {
                            store.audio.click()
                            withAnimation { store.route = .crush }
                        }
                        modeCard(
                            title: "Marquee",
                            subtitle: "Same board, restock costs a bet",
                            footnote: "Bet 10 / 50 / 100 · serve pays the bet",
                            width: 314,
                            height: 86
                        ) {
                            store.audio.click()
                            withAnimation { store.openBet() }
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
            .frame(width: 375, height: 667, alignment: .top)

            navHomeButton {
                store.audio.click()
                withAnimation { store.route = .home }
            }
            .padding(.leading, 12)
            .padding(.top, 10)
        }
        .frame(width: 375, height: 667)
    }

    private func landscapeModes(size: CGSize) -> some View {
        VStack(spacing: 18) {
            HStack {
                navHomeButton {
                    store.audio.click()
                    withAnimation { store.route = .home }
                }
                Spacer()
                Text("SELECT MODE")
                    .font(Lucky.black(26))
                    .tracking(3)
                    .foregroundStyle(Lucky.gold)
                Spacer()
                Color.clear.frame(width: 50, height: 50)
            }
            .padding(.horizontal, Lucky.isPad ? 40 : 28)
            .padding(.top, Lucky.isPad ? 20 : 12)

            if Lucky.isPad { Spacer(minLength: 20) }

            VStack(spacing: Lucky.isPad ? 18 : 12) {
                HStack(spacing: Lucky.isPad ? 18 : 12) {
                    modeCard(
                        title: "Kitchen",
                        subtitle: "Serve the shift menu",
                        footnote: "No bet",
                        width: cardWidth(size),
                        height: cardHeight(size)
                    ) {
                        store.audio.click()
                        withAnimation { store.openClassic() }
                    }
                    modeCard(
                        title: "Challenge",
                        subtitle: "Limited restocks",
                        footnote: "\(store.clearedStages)/\(StageDef.campaign.count) cleared",
                        width: cardWidth(size),
                        height: cardHeight(size)
                    ) {
                        store.audio.click()
                        withAnimation { store.route = .stages }
                    }
                }
                HStack(spacing: Lucky.isPad ? 18 : 12) {
                    modeCard(
                        title: "Window",
                        subtitle: "Plate the order",
                        footnote: "12 levels",
                        width: cardWidth(size),
                        height: cardHeight(size)
                    ) {
                        store.audio.click()
                        withAnimation { store.route = .window }
                    }
                    modeCard(
                        title: "Crush",
                        subtitle: "Match three",
                        footnote: "12 levels",
                        width: cardWidth(size),
                        height: cardHeight(size)
                    ) {
                        store.audio.click()
                        withAnimation { store.route = .crush }
                    }
                }
                modeCard(
                    title: "Marquee",
                    subtitle: "Restock costs a bet",
                    footnote: "10 / 50 / 100",
                    width: min(cardWidth(size) * 2 + (Lucky.isPad ? 18 : 12), size.width - 56),
                    height: min(108, cardHeight(size))
                ) {
                    store.audio.click()
                    withAnimation { store.openBet() }
                }
            }
            .padding(.horizontal, Lucky.isPad ? 56 : 28)
            Spacer(minLength: Lucky.isPad ? 24 : 0)
        }
        .frame(width: size.width, height: size.height)
    }

    private func cardWidth(_ size: CGSize) -> CGFloat {
        min(Lucky.isPad ? 420 : 300, size.width * (Lucky.isPad ? 0.4 : 0.44))
    }

    private func cardHeight(_ size: CGSize) -> CGFloat {
        min(Lucky.isPad ? 188 : 118, max(96, (size.height - (Lucky.isPad ? 220 : 180)) / 3))
    }

    private func modeCard(title: String, subtitle: String, footnote: String, width: CGFloat, height: CGFloat, action: @escaping () -> Void) -> some View {
        let compact = height < 150
        return Button(action: action) {
            VStack(alignment: .leading, spacing: compact ? 4 : 8) {
                Text(title)
                    .font(Lucky.black(compact ? 22 : 28))
                    .foregroundStyle(Lucky.gold)
                Text(subtitle)
                    .font(Lucky.bold(compact ? 13 : 15))
                    .foregroundStyle(Lucky.cream)
                    .lineLimit(2)
                Spacer(minLength: 0)
                Text(footnote)
                    .font(Lucky.bold(compact ? 11 : 13))
                    .foregroundStyle(Lucky.muted)
                    .lineLimit(2)
            }
            .padding(.horizontal, compact ? 16 : 22)
            .padding(.vertical, compact ? 10 : 18)
            .frame(width: width, height: height, alignment: .leading)
            .background(Lucky.maroon.opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Lucky.gold.opacity(glow ? 0.95 : 0.4), lineWidth: 2)
                EdgeLights(width: width, height: height, corner: 22, count: 18, speed: 0.32)
            }
            .shadow(color: Lucky.gold.opacity(glow ? 0.4 : 0.1), radius: glow ? 12 : 4)
            .scaleEffect(glow ? 1.015 : 1)
        }
        .buttonStyle(PressScale())
    }
}

struct StageMapView: View {
    @EnvironmentObject private var store: GameStore

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
                if Lucky.isLandscape(size) || Lucky.isPad {
                    landscapeStages(size: size)
                } else {
                    phoneStages
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
        .onAppear { store.audio.startMusic() }
    }

    private var phoneStages: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 6) {
                Color.clear.frame(height: 64)
                Text(store.clearedStages >= StageDef.campaign.count
                     ? "All stages lit. Replay pays a tip."
                     : "Clear in order. Restocks are free. First clear pays.")
                    .font(Lucky.bold(12))
                    .foregroundStyle(Lucky.muted)
                    .multilineTextAlignment(.center)
                    .frame(width: 320)
                    .padding(.bottom, 2)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(StageDef.campaign) { stage in
                            stageRow(stage)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .frame(width: 375, height: 667)

            Text("STAGES")
                .font(Lucky.black(22))
                .tracking(3)
                .foregroundStyle(Lucky.gold)
                .position(x: 187.5, y: 36)

            Text("\(store.clearedStages)/\(StageDef.campaign.count)")
                .font(Lucky.black(16))
                .foregroundStyle(Lucky.goldSoft)
                .position(x: 328, y: 36)

            navHomeButton {
                store.audio.click()
                withAnimation { store.route = .modes }
            }
            .position(x: 12 + 25, y: 10 + 25)
        }
        .frame(width: 375, height: 667)
    }

    private func landscapeStages(size: CGSize) -> some View {
        VStack(spacing: 10) {
            HStack {
                navHomeButton {
                    store.audio.click()
                    withAnimation { store.route = .modes }
                }
                Spacer()
                Text("STAGES")
                    .font(Lucky.black(24))
                    .tracking(3)
                    .foregroundStyle(Lucky.gold)
                Spacer()
                Text("\(store.clearedStages)/\(StageDef.campaign.count)")
                    .font(Lucky.black(18))
                    .foregroundStyle(Lucky.goldSoft)
                    .frame(minWidth: 50, alignment: .trailing)
            }
            .padding(.horizontal, Lucky.isPad ? 40 : 28)
            .padding(.top, Lucky.isPad ? 18 : 10)

            Text(store.clearedStages >= StageDef.campaign.count
                 ? "All stages lit. Replay pays a tip."
                 : "Clear in order. Restocks are free. First clear pays.")
                .font(Lucky.bold(13))
                .foregroundStyle(Lucky.muted)

            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: Lucky.isPad ? 16 : 14), count: Lucky.isPad && size.width > 900 ? 3 : 2),
                    spacing: Lucky.isPad ? 14 : 12
                ) {
                    ForEach(StageDef.campaign) { stage in
                        stageRow(stage)
                    }
                }
                .padding(.horizontal, Lucky.isPad ? 48 : 24)
            }
            Spacer(minLength: 0)
        }
        .frame(width: size.width, height: size.height)
    }

    private func stageRow(_ stage: StageDef) -> some View {
        let locked = stage.id > store.clearedStages
        let cleared = stage.id < store.clearedStages
        let current = stage.id == store.clearedStages
        let badge = locked ? "Locked" : (cleared ? "Cleared" : "Play")

        return Button {
            store.audio.click()
            withAnimation { store.beginStage(stage.id) }
        } label: {
            HStack(spacing: 10) {
                Text("\(stage.id + 1)")
                    .font(Lucky.black(18))
                    .foregroundStyle(locked ? Lucky.muted : Lucky.gold)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(stage.name)
                        .font(Lucky.bold(16))
                        .foregroundStyle(locked ? Lucky.muted : Lucky.cream)
                    Text(stage.blurb)
                        .font(Lucky.bold(11))
                        .foregroundStyle(Lucky.muted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 6)
                Text(badge)
                    .font(Lucky.bold(12))
                    .foregroundStyle(current ? Lucky.gold : Lucky.goldSoft.opacity(locked ? 0.45 : 0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Lucky.maroon.opacity(locked ? 0.55 : 0.92), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(current ? Lucky.gold : Lucky.gold.opacity(0.28), lineWidth: current ? 2 : 1)
            )
        }
        .buttonStyle(PressScale())
        .disabled(locked)
    }
}

struct StageEndOverlay: View {
    @EnvironmentObject private var store: GameStore
    var end: StageEnd
    @State private var burst = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
            VStack(spacing: 8) {
                Text(end.cleared ? (end.finale ? "LIGHTS ON" : "CLEARED") : "FAILED")
                    .font(Lucky.black(26))
                    .tracking(3)
                    .foregroundStyle(Lucky.goldSoft)
                Text("Stage \(store.stageIndex + 1) · \(end.stageName)")
                    .font(Lucky.bold(14))
                    .foregroundStyle(Lucky.cream)
                Text("\(end.got) / \(end.target)")
                    .font(Lucky.black(32))
                    .foregroundStyle(Lucky.gold)
                if end.cleared, end.firstClear {
                    Text("Reward +\(end.reward) coins")
                        .font(Lucky.bold(15))
                        .foregroundStyle(Lucky.goldSoft)
                } else if end.cleared {
                    Text("Replay tip +\(end.reward)")
                        .font(Lucky.bold(14))
                        .foregroundStyle(Lucky.goldSoft)
                } else {
                    Text("Out of spins. Need \(end.target - end.got) more")
                        .font(Lucky.bold(14))
                        .foregroundStyle(Lucky.muted)
                }

                HStack(spacing: 10) {
                    overlayButton(primaryTitle) {
                        store.audio.click()
                        withAnimation {
                            if end.cleared, end.hasNext {
                                store.beginStage(store.stageIndex + 1)
                            } else {
                                store.beginStage(store.stageIndex)
                            }
                        }
                    }
                    overlayButton("Stages") {
                        store.audio.click()
                        withAnimation { store.exitToStageMap() }
                    }
                }
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

    private var primaryTitle: String {
        if end.cleared, end.hasNext { return "Next" }
        return end.cleared ? "Play again" : "Retry"
    }

    private func overlayButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Lucky.bold(15))
                .foregroundStyle(Lucky.gold)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Lucky.wine, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Lucky.gold.opacity(0.45), lineWidth: 1)
                )
        }
        .buttonStyle(PressScale())
    }
}

private func navHomeButton(action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image("btnHome")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: 50, height: 50)
    }
    .buttonStyle(PressScale())
}
