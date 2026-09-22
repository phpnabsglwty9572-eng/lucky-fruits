import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: GameStore
    @State private var bob = false
    @State private var glow = false

    var body: some View {
        DesignCanvas {
            ZStack(alignment: .topLeading) {
                Image("imgBg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 375, height: 667)
                    .clipped()
                    .blur(radius: 14)
                    .allowsHitTesting(false)
                Lucky.void.opacity(0.62)
                    .allowsHitTesting(false)

                VStack(spacing: 18) {
                    Spacer(minLength: 86)
                    Image("imgTitle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280)
                        .shadow(color: Lucky.gold.opacity(glow ? 0.85 : 0.25), radius: glow ? 20 : 6)

                    HStack(spacing: 14) {
                        homeIcon("symCherry")
                        homeIcon("symSeven")
                        homeIcon("symStar")
                    }
                    .offset(y: bob ? -6 : 6)

                    Text("转动金框滚轮，点亮三连好运")
                        .font(Lucky.bold(14))
                        .foregroundStyle(Lucky.cream)
                        .shadow(color: .black.opacity(0.7), radius: 4)

                    Button {
                        store.audio.click()
                        withAnimation { store.route = .game }
                    } label: {
                        Image("btnSpin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 128, height: 128)
                            .shadow(color: Lucky.gold.opacity(glow ? 0.8 : 0.25), radius: glow ? 22 : 8)
                    }
                    .buttonStyle(PressScale())

                    HStack(spacing: 12) {
                        homeChip("规则") { store.showRules = true }
                        homeChip("隐私") { store.showPrivacy = true }
                    }
                    .padding(.horizontal, 28)

                    Spacer(minLength: 24)
                }
                .frame(width: 375, height: 667)

                Button {
                    store.audio.click()
                    store.showSettings = true
                } label: {
                    Image("btnSettings")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 51, height: 51)
                }
                .buttonStyle(PressScale())
                .zIndex(2)
                .position(x: 311 + 25.5, y: 5 + 25.5)
            }
            .frame(width: 375, height: 667)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { bob = true }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { glow = true }
            store.audio.startMusic()
        }
    }

    private func homeIcon(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: 72, height: 64)
            .background(Lucky.maroon.opacity(0.7), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Lucky.gold, lineWidth: 2))
    }

    private func homeChip(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            store.audio.click()
            action()
        } label: {
            Text(title)
                .font(Lucky.bold(14))
                .foregroundStyle(Lucky.gold)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Lucky.maroon.opacity(0.88), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Lucky.gold.opacity(0.7), lineWidth: 1.5))
        }
        .buttonStyle(PressScale())
    }
}
