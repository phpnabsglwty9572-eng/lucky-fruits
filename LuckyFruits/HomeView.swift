import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: GameStore
    @State private var glow = false

    var body: some View {
        DesignCanvas {
            ZStack {
                Image("imgLoadBg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 375, height: 667)
                    .clipped()
                    .allowsHitTesting(false)

                Image("imgHomeLogo")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 326, height: 175)
                    .shadow(color: Lucky.gold.opacity(glow ? 0.45 : 0.15), radius: glow ? 16 : 5)
                    .position(x: 26 + 326 / 2, y: 66 + 175 / 2)

                Button {
                    store.audio.click()
                    withAnimation { store.route = .game }
                } label: {
                    Image("btnStartGame")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 298, height: 114)
                        .shadow(color: Lucky.gold.opacity(glow ? 0.55 : 0.18), radius: glow ? 14 : 5)
                }
                .buttonStyle(PressScale())
                .position(x: 39 + 298 / 2, y: 269 + 114 / 2)

                Button {
                    store.audio.click()
                    store.showSettings = true
                } label: {
                    Image("btnGameSettings")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 258, height: 80)
                }
                .buttonStyle(PressScale())
                .position(x: 58 + 261 / 2, y: 410 + 78 / 2)

                Button {
                    store.audio.click()
                    store.showPrivacy = true
                } label: {
                    Image("btnPrivacy")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 241, height: 70)
                }
                .buttonStyle(PressScale())
                .position(x: 69 + 241 / 2, y: 519 + 70 / 2)
            }
            .frame(width: 375, height: 667)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) { glow = true }
            store.audio.startMusic()
        }
    }
}
