import SwiftUI

struct ModeSelectView: View {
    @EnvironmentObject private var store: GameStore
    @State private var glow = false

    var body: some View {
        DesignCanvas {
            ZStack {
                screenBackground

                Image("imgHomeLogo")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 250, height: 120)
                    .shadow(color: Lucky.gold.opacity(glow ? 0.4 : 0.12), radius: glow ? 14 : 4)
                    .position(x: 187.5, y: 118)

                Text("选择模式")
                    .font(Lucky.black(22))
                    .tracking(2)
                    .foregroundStyle(Lucky.gold)
                    .position(x: 187.5, y: 210)

                modeCard(
                    title: "经典机台",
                    subtitle: "自由转动，金币一直累计",
                    footnote: "横线三连 · 下注 10 / 50 / 100",
                    y: 330
                ) {
                    store.audio.click()
                    withAnimation { store.openClassic() }
                }

                modeCard(
                    title: "闯关挑战",
                    subtitle: "限定转数，达标进入下一关",
                    footnote: "已通过 \(store.clearedStages)/\(StageDef.campaign.count)",
                    y: 490
                ) {
                    store.audio.click()
                    withAnimation { store.route = .stages }
                }

                homeButton {
                    store.audio.click()
                    withAnimation { store.route = .home }
                }
            }
            .frame(width: 375, height: 667)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) { glow = true }
            store.audio.startMusic()
        }
    }

    private func modeCard(title: String, subtitle: String, footnote: String, y: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(Lucky.black(24))
                    .foregroundStyle(Lucky.gold)
                Text(subtitle)
                    .font(Lucky.bold(14))
                    .foregroundStyle(Lucky.cream)
                Text(footnote)
                    .font(Lucky.bold(12))
                    .foregroundStyle(Lucky.muted)
            }
            .padding(.horizontal, 18)
            .frame(width: 314, height: 118, alignment: .leading)
            .background(Lucky.maroon.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Lucky.gold.opacity(glow ? 0.9 : 0.45), lineWidth: 2)
            )
            .shadow(color: Lucky.gold.opacity(glow ? 0.28 : 0.08), radius: glow ? 10 : 4)
        }
        .buttonStyle(PressScale())
        .position(x: 187.5, y: y)
    }
}

struct StageMapView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        DesignCanvas {
            ZStack(alignment: .top) {
                screenBackground

                VStack(spacing: 6) {
                    Color.clear.frame(height: 64)
                    Text(store.clearedStages >= StageDef.campaign.count
                         ? "八关灯牌已全部点亮，可随时重玩"
                         : "按顺序过关。不扣金币，首次通关才发奖励。")
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

                Text("闯关")
                    .font(Lucky.black(22))
                    .tracking(3)
                    .foregroundStyle(Lucky.gold)
                    .position(x: 187.5, y: 36)

                Text("\(store.clearedStages)/\(StageDef.campaign.count)")
                    .font(Lucky.black(16))
                    .foregroundStyle(Lucky.goldSoft)
                    .position(x: 328, y: 36)

                homeButton {
                    store.audio.click()
                    withAnimation { store.route = .modes }
                }
            }
            .frame(width: 375, height: 667)
        }
        .onAppear { store.audio.startMusic() }
    }

    private func stageRow(_ stage: StageDef) -> some View {
        let locked = stage.id > store.clearedStages
        let cleared = stage.id < store.clearedStages
        let current = stage.id == store.clearedStages
        let badge = locked ? "未解锁" : (cleared ? "已过" : "挑战")

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
                Text(end.cleared ? (end.finale ? "灯牌点亮" : "过关") : "未达标")
                    .font(Lucky.black(26))
                    .tracking(3)
                    .foregroundStyle(Lucky.goldSoft)
                Text("第\(store.stageIndex + 1)关 · \(end.stageName)")
                    .font(Lucky.bold(14))
                    .foregroundStyle(Lucky.cream)
                Text("\(end.got) / \(end.target)")
                    .font(Lucky.black(32))
                    .foregroundStyle(Lucky.gold)
                if end.cleared, end.firstClear {
                    Text("奖励 +\(end.reward) 金币")
                        .font(Lucky.bold(15))
                        .foregroundStyle(Lucky.goldSoft)
                } else if end.cleared {
                    Text("再次通过，奖励已领过")
                        .font(Lucky.bold(14))
                        .foregroundStyle(Lucky.muted)
                } else {
                    Text("转数用尽，还差 \(end.target - end.got)")
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
                    overlayButton("返回关卡") {
                        store.audio.click()
                        withAnimation { store.exitToStageMap() }
                    }
                }
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

    private var primaryTitle: String {
        if end.cleared, end.hasNext { return "下一关" }
        return end.cleared ? "再玩一次" : "再试一次"
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

private var screenBackground: some View {
    Image("imgLoadBg")
        .resizable()
        .scaledToFill()
        .frame(width: 375, height: 667)
        .clipped()
        .allowsHitTesting(false)
}

private func homeButton(action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image("btnHome")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: 50, height: 50)
    }
    .buttonStyle(PressScale())
    .position(x: 12 + 25, y: 10 + 25)
}
