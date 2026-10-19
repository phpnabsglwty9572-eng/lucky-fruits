import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.displayScale) private var displayScale
    @State private var glow = false
    @State private var showStart = false
    @State private var showSettings = false
    @State private var showPrivacy = false

    private let logoPixels = CGSize(width: 648, height: 356)
    private let startPixels = CGSize(width: 598, height: 226)
    private let settingsPixels = CGSize(width: 258, height: 80)
    private let privacyPixels = CGSize(width: 241, height: 70)

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                Image("imgLoadBg")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .allowsHitTesting(false)
                if Lucky.isPad, !Lucky.isLandscape(size) {
                    padHome(size: size)
                } else if Lucky.isLandscape(size) {
                    landscapeHome(size: size)
                } else {
                    phoneHome(size: size)
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

    private func phoneHome(size: CGSize) -> some View {
        let logo = homeArt(logoPixels, maxWidth: size.width * 0.84, maxUpscale: 1.15)
        let start = homeArt(startPixels, maxWidth: size.width * 0.8, maxUpscale: 1.2)
        let settings = homeArt(settingsPixels, maxWidth: size.width * 0.72, maxUpscale: 1.65)
        let privacy = homeArt(privacyPixels, maxWidth: size.width * 0.68, maxUpscale: 1.85)
        return VStack(spacing: 0) {
            Spacer(minLength: size.height * 0.05)
            logoImage(logo)
            Text("KEEP · RESTOCK · SERVE")
                .font(Lucky.black(13))
                .tracking(2.4)
                .foregroundStyle(Lucky.goldSoft.opacity(0.9))
                .padding(.top, 10)
            Spacer(minLength: 18)
            VStack(spacing: 14) {
                startButton(start)
                    .scaleEffect(showStart ? 1 : 0.82)
                    .opacity(showStart ? 1 : 0)
                settingsButton(settings)
                    .scaleEffect(showSettings ? 1 : 0.86)
                    .opacity(showSettings ? 1 : 0)
                privacyButton(privacy)
                    .scaleEffect(showPrivacy ? 1 : 0.88)
                    .opacity(showPrivacy ? 1 : 0)
            }
            Spacer(minLength: size.height * 0.07)
        }
        .frame(width: size.width, height: size.height)
    }

    private func padHome(size: CGSize) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            logoImage(homeArt(logoPixels, maxWidth: min(420, size.width * 0.56), maxUpscale: 1.15))
            Text("KEEP · RESTOCK · SERVE")
                .font(Lucky.black(16))
                .tracking(3)
                .foregroundStyle(Lucky.goldSoft.opacity(0.9))
                .padding(.top, 8)
            Spacer(minLength: 20)
            VStack(spacing: 18) {
                startButton(homeArt(startPixels, maxWidth: 340, maxUpscale: 1.15))
                    .scaleEffect(showStart ? 1 : 0.82)
                    .opacity(showStart ? 1 : 0)
                settingsButton(homeArt(settingsPixels, maxWidth: 300, maxUpscale: 1.65))
                    .scaleEffect(showSettings ? 1 : 0.86)
                    .opacity(showSettings ? 1 : 0)
                privacyButton(homeArt(privacyPixels, maxWidth: 280, maxUpscale: 1.85))
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
                logoImage(homeArt(logoPixels, maxWidth: min(Lucky.isPad ? 420 : 300, size.width * 0.4), maxUpscale: 1.15))
                Text("KEEP · RESTOCK · SERVE")
                    .font(Lucky.black(14))
                    .tracking(3)
                    .foregroundStyle(Lucky.goldSoft.opacity(0.9))
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 16) {
                startButton(homeArt(startPixels, maxWidth: min(320, size.width * 0.34), maxUpscale: 1.15))
                    .scaleEffect(showStart ? 1 : 0.82)
                    .opacity(showStart ? 1 : 0)
                settingsButton(homeArt(settingsPixels, maxWidth: min(280, size.width * 0.3), maxUpscale: 1.65))
                    .scaleEffect(showSettings ? 1 : 0.86)
                    .opacity(showSettings ? 1 : 0)
                privacyButton(homeArt(privacyPixels, maxWidth: min(260, size.width * 0.28), maxUpscale: 1.85))
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

    private func homeArt(_ pixels: CGSize, maxWidth: CGFloat, maxUpscale: CGFloat) -> CGSize {
        let sharp = pixels.width / max(displayScale, 1)
        let width = min(maxWidth, sharp * maxUpscale)
        return CGSize(width: width, height: width * pixels.height / pixels.width)
    }

    private func logoImage(_ size: CGSize) -> some View {
        Image("imgHomeLogo")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size.width, height: size.height)
            .shadow(color: Lucky.gold.opacity(glow ? 0.45 : 0.14), radius: glow ? 14 : 5)
            .offset(y: glow ? -4 : 3)
    }

    private func startButton(_ size: CGSize) -> some View {
        Button {
            store.audio.click()
            withAnimation { store.route = .modes }
        } label: {
            ZStack {
                Image("btnStartGame")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                EdgeLights(width: size.width + 4, height: size.height + 4, corner: (size.height + 4) / 2, count: 22, speed: 0.42)
            }
            .shadow(color: Lucky.gold.opacity(glow ? 0.55 : 0.18), radius: glow ? 12 : 5)
        }
        .buttonStyle(PressScale())
    }

    private func settingsButton(_ size: CGSize) -> some View {
        Button {
            store.audio.click()
            store.showSettings = true
        } label: {
            ZStack {
                Image("btnGameSettings")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                EdgeLights(width: size.width + 4, height: size.height + 4, corner: 10, count: 16, speed: 0.28)
                    .opacity(0.85)
            }
            .shadow(color: Lucky.gold.opacity(glow ? 0.28 : 0.08), radius: glow ? 8 : 3)
        }
        .buttonStyle(PressScale())
    }

    private func privacyButton(_ size: CGSize) -> some View {
        Button {
            store.audio.click()
            store.showPrivacy = true
        } label: {
            ZStack {
                Image("btnPrivacy")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                EdgeLights(width: size.width + 4, height: size.height + 4, corner: 8, count: 14, speed: 0.24)
                    .opacity(0.75)
            }
            .shadow(color: Lucky.gold.opacity(glow ? 0.22 : 0.06), radius: glow ? 6 : 2)
        }
        .buttonStyle(PressScale())
    }
}
