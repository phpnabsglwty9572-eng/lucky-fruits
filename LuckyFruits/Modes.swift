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
        ZStack {
            Image("imgHomeLogo")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 250, height: 120)
                .shadow(color: Lucky.gold.opacity(glow ? 0.4 : 0.12), radius: glow ? 14 : 4)
                .position(x: 187.5, y: 118)

            Text("SELECT MODE")
                .font(Lucky.black(22))
                .tracking(2)
                .foregroundStyle(Lucky.gold)
                .position(x: 187.5, y: 210)

            modeCard(
                title: "Classic",
                subtitle: "Orders, swap, blend wilds",
                footnote: "Harvest jobs · bet 10 / 50 / 100",
                width: 314,
                height: 118
            ) {
                store.audio.click()
                withAnimation { store.openClassic() }
            }
            .position(x: 187.5, y: 330)

            modeCard(
                title: "Challenge",
                subtitle: "Limited spins · swap to hit the goal",
                footnote: "Cleared \(store.clearedStages)/\(StageDef.campaign.count)",
                width: 314,
                height: 118
            ) {
                store.audio.click()
                withAnimation { store.route = .stages }
            }
            .position(x: 187.5, y: 490)

            navHomeButton {
                store.audio.click()
                withAnimation { store.route = .home }
            }
            .position(x: 12 + 25, y: 10 + 25)
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

            if Lucky.isPad { Spacer(minLength: 12) }

            HStack(spacing: Lucky.isPad ? 28 : 22) {
                modeCard(
                    title: "Classic",
                    subtitle: "Orders, swap, blend wilds",
                    footnote: "Harvest jobs · bet 10 / 50 / 100",
                    width: min(Lucky.isPad ? 460 : 420, size.width * 0.42),
                    height: min(Lucky.isPad ? 260 : 220, size.height * 0.48)
                ) {
                    store.audio.click()
                    withAnimation { store.openClassic() }
                }
                modeCard(
                    title: "Challenge",
                    subtitle: "Limited spins · swap to hit the goal",
                    footnote: "Cleared \(store.clearedStages)/\(StageDef.campaign.count)",
                    width: min(Lucky.isPad ? 460 : 420, size.width * 0.42),
                    height: min(Lucky.isPad ? 260 : 220, size.height * 0.48)
                ) {
                    store.audio.click()
                    withAnimation { store.route = .stages }
                }
            }
            .padding(.horizontal, Lucky.isPad ? 40 : 28)
            Spacer(minLength: 0)
        }
        .frame(width: size.width, height: size.height)
    }

    private func modeCard(title: String, subtitle: String, footnote: String, width: CGFloat, height: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(Lucky.black(28))
                    .foregroundStyle(Lucky.gold)
                Text(subtitle)
                    .font(Lucky.bold(15))
                    .foregroundStyle(Lucky.cream)
                Spacer(minLength: 0)
                Text(footnote)
                    .font(Lucky.bold(13))
                    .foregroundStyle(Lucky.muted)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
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
                     ? "All 8 stages lit. Replay any time."
                     : "Clear in order. No coin cost. First clear pays.")
                    .font(Lucky.bold(12))
                    .foregroundStyle(Lucky.muted)
                    .multilineTextAlignment(.center)
                    .frame(width: 320)
                    .padding(.bottom, 2)

                ForEach(StageDef.campaign) { stage in
                    stageRow(stage)
                }
                Spacer(minLength: 0)
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
                 ? "All 8 stages lit. Replay any time."
                 : "Clear in order. No coin cost. First clear pays.")
                .font(Lucky.bold(13))
                .foregroundStyle(Lucky.muted)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 12
            ) {
                ForEach(StageDef.campaign) { stage in
                    stageRow(stage)
                }
            }
            .padding(.horizontal, Lucky.isPad ? 36 : 24)
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
                    Text("Cleared again. Reward already claimed.")
                        .font(Lucky.bold(14))
                        .foregroundStyle(Lucky.muted)
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
