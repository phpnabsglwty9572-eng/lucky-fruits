import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: GameStore
    @State private var glow = false
    @State private var showStart = false
    @State private var showSettings = false
    @State private var showPrivacy = false

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
                    .shadow(color: Lucky.gold.opacity(glow ? 0.55 : 0.16), radius: glow ? 20 : 6)
                    .offset(y: glow ? -5 : 4)
                    .position(x: 26 + 326 / 2, y: 66 + 175 / 2)

                Button {
                    store.audio.click()
                    withAnimation { store.route = .modes }
                } label: {
                    ZStack {
                        Image("btnStartGame")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 298, height: 114)
                        EdgeLights(width: 302, height: 118, corner: 59, count: 24, speed: 0.42)
                    }
                    .shadow(color: Lucky.gold.opacity(glow ? 0.7 : 0.22), radius: glow ? 16 : 6)
                    .scaleEffect(glow ? 1.04 : 1.0)
                }
                .buttonStyle(PressScale())
                .scaleEffect(showStart ? 1 : 0.82)
                .opacity(showStart ? 1 : 0)
                .offset(y: showStart ? 0 : 26)
                .position(x: 39 + 298 / 2, y: 269 + 114 / 2)

                Button {
                    store.audio.click()
                    store.showSettings = true
                } label: {
                    ZStack {
                        Image("btnGameSettings")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 258, height: 80)
                        EdgeLights(width: 262, height: 84, corner: 12, count: 16, speed: 0.28)
                            .opacity(0.85)
                    }
                    .shadow(color: Lucky.gold.opacity(glow ? 0.35 : 0.08), radius: glow ? 10 : 3)
                }
                .buttonStyle(PressScale())
                .scaleEffect(showSettings ? 1 : 0.86)
                .opacity(showSettings ? 1 : 0)
                .offset(y: showSettings ? 0 : 20)
                .position(x: 58 + 261 / 2, y: 410 + 78 / 2)

                Button {
                    store.audio.click()
                    store.showPrivacy = true
                } label: {
                    ZStack {
                        Image("btnPrivacy")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 241, height: 70)
                        EdgeLights(width: 245, height: 74, corner: 10, count: 14, speed: 0.24)
                            .opacity(0.75)
                    }
                    .shadow(color: Lucky.gold.opacity(glow ? 0.28 : 0.06), radius: glow ? 8 : 2)
                }
                .buttonStyle(PressScale())
                .scaleEffect(showPrivacy ? 1 : 0.88)
                .opacity(showPrivacy ? 1 : 0)
                .offset(y: showPrivacy ? 0 : 18)
                .position(x: 69 + 241 / 2, y: 519 + 70 / 2)

                if let gift = store.daily {
                    DailyGiftOverlay(gift: gift)
                        .frame(width: 375, height: 667)
                }
            }
            .frame(width: 375, height: 667)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) { glow = true }
            withAnimation(.spring(response: 0.62, dampingFraction: 0.68).delay(0.08)) { showStart = true }
            withAnimation(.spring(response: 0.62, dampingFraction: 0.7).delay(0.24)) { showSettings = true }
            withAnimation(.spring(response: 0.62, dampingFraction: 0.72).delay(0.38)) { showPrivacy = true }
            store.prepareDailyGift()
            store.audio.startMusic()
        }
    }
}
