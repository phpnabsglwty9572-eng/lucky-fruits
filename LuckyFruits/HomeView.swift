import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: GameStore
    @State private var glow = false
    @State private var showStart = false
    @State private var showSettings = false
    @State private var showPrivacy = false

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
                if Lucky.isPad, !Lucky.isLandscape(size) {
                    padHome(size: size)
                } else if Lucky.isLandscape(size) {
                    landscapeHome(size: size)
                } else {
                    phoneHome
                        .frame(width: Lucky.canvas.width, height: Lucky.canvas.height)
                        .scaleEffect(
                            x: Lucky.canvasScale(for: size).width,
                            y: Lucky.canvasScale(for: size).height,
                            anchor: .center
                        )
                        .frame(width: size.width, height: size.height)
                }
                if let gift = store.daily {
                    DailyGiftOverlay(gift: gift)
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) { glow = true }
            withAnimation(.spring(response: 0.62, dampingFraction: 0.68).delay(0.08)) { showStart = true }
            withAnimation(.spring(response: 0.62, dampingFraction: 0.7).delay(0.24)) { showSettings = true }
            withAnimation(.spring(response: 0.62, dampingFraction: 0.72).delay(0.38)) { showPrivacy = true }
            store.prepareDailyGift()
            store.audio.startMusic()
        }
    }

    private var phoneHome: some View {
        ZStack {
            Image("imgHomeLogo")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 326, height: 175)
                .shadow(color: Lucky.gold.opacity(glow ? 0.55 : 0.16), radius: glow ? 20 : 6)
                .offset(y: glow ? -5 : 4)
                .position(x: 26 + 326 / 2, y: 66 + 175 / 2)

            startButton
                .scaleEffect(showStart ? 1 : 0.82)
                .opacity(showStart ? 1 : 0)
                .offset(y: showStart ? 0 : 26)
                .position(x: 39 + 298 / 2, y: 269 + 114 / 2)

            settingsButton
                .scaleEffect(showSettings ? 1 : 0.86)
                .opacity(showSettings ? 1 : 0)
                .offset(y: showSettings ? 0 : 20)
                .position(x: 58 + 261 / 2, y: 410 + 78 / 2)

            privacyButton
                .scaleEffect(showPrivacy ? 1 : 0.88)
                .opacity(showPrivacy ? 1 : 0)
                .offset(y: showPrivacy ? 0 : 18)
                .position(x: 69 + 241 / 2, y: 519 + 70 / 2)
        }
        .frame(width: 375, height: 667)
    }

    private func padHome(size: CGSize) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            Image("imgHomeLogo")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: min(520, size.width * 0.62), height: min(260, size.height * 0.28))
                .shadow(color: Lucky.gold.opacity(glow ? 0.55 : 0.16), radius: glow ? 20 : 6)
                .offset(y: glow ? -4 : 4)
            Text("HARVEST · SWAP · BLEND")
                .font(Lucky.black(16))
                .tracking(3)
                .foregroundStyle(Lucky.goldSoft.opacity(0.9))
                .padding(.top, 8)
            Spacer(minLength: 20)
            VStack(spacing: 18) {
                startButton
                    .scaleEffect(showStart ? 1 : 0.82)
                    .opacity(showStart ? 1 : 0)
                settingsButton
                    .scaleEffect(showSettings ? 1 : 0.86)
                    .opacity(showSettings ? 1 : 0)
                privacyButton
                    .scaleEffect(showPrivacy ? 1 : 0.88)
                    .opacity(showPrivacy ? 1 : 0)
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 20)
            .frame(maxWidth: 440)
            .background(Lucky.maroon.opacity(0.42), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Lucky.gold.opacity(0.35), lineWidth: 1.5)
            }
            Spacer(minLength: 28)
        }
        .padding(.horizontal, 40)
        .frame(width: size.width, height: size.height)
    }

    private func landscapeHome(size: CGSize) -> some View {
        HStack(alignment: .center, spacing: 28) {
            VStack(spacing: 12) {
                Image("imgHomeLogo")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(
                        width: min(Lucky.isPad ? 520 : 440, size.width * 0.44),
                        height: min(Lucky.isPad ? 280 : 236, size.height * 0.46)
                    )
                    .shadow(color: Lucky.gold.opacity(glow ? 0.55 : 0.16), radius: glow ? 20 : 6)
                    .offset(y: glow ? -4 : 4)
                Text("HARVEST · SWAP · BLEND")
                    .font(Lucky.black(14))
                    .tracking(3)
                    .foregroundStyle(Lucky.goldSoft.opacity(0.9))
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 16) {
                startButton
                    .scaleEffect(showStart ? 1 : 0.82)
                    .opacity(showStart ? 1 : 0)
                settingsButton
                    .scaleEffect(showSettings ? 1 : 0.86)
                    .opacity(showSettings ? 1 : 0)
                privacyButton
                    .scaleEffect(showPrivacy ? 1 : 0.88)
                    .opacity(showPrivacy ? 1 : 0)
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 18)
            .background(Lucky.maroon.opacity(0.42), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Lucky.gold.opacity(0.35), lineWidth: 1.5)
                EdgeLights(width: min(360, size.width * 0.4), height: min(size.height - 80, 360), corner: 28, count: 18, speed: 0.28)
                    .opacity(0.7)
            }
            .frame(width: min(Lucky.isPad ? 400 : 360, size.width * 0.4))
        }
        .padding(.horizontal, max(32, size.width * 0.05))
        .padding(.vertical, 28)
        .frame(width: size.width, height: size.height)
    }

    private var startButton: some View {
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
    }

    private var settingsButton: some View {
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
    }

    private var privacyButton: some View {
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
    }
}
