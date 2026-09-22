import SwiftUI

struct LoadingView: View {
    @EnvironmentObject private var store: GameStore
    @State private var glow = false

    var body: some View {
        DesignCanvas {
            ZStack(alignment: .topLeading) {
                Image("imgLoadBg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 375, height: 667)
                    .clipped()
                    .allowsHitTesting(false)

                Image("imgLoadLogo")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 336, height: 126)
                    .shadow(color: Lucky.gold.opacity(glow ? 0.4 : 0.12), radius: glow ? 14 : 4)
                    .position(x: 19 + 336 / 2, y: 172 + 126 / 2)

                progressBoard
                    .position(x: 21 + 333 / 2, y: 335 + 106 / 2)
            }
            .frame(width: 375, height: 667)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) { glow = true }
            Task { await store.bootstrap() }
        }
    }

    private var progressBoard: some View {
        let trackX: CGFloat = 24
        let trackY: CGFloat = 26
        let trackH: CGFloat = 36
        let trackW: CGFloat = 285
        let fill = max(0.035, min(1, store.loadProgress))
        let fillW = max(14, trackW * fill)

        return ZStack(alignment: .topLeading) {
            Image("imgLoadBar")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 333, height: 106)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1, green: 226 / 255, blue: 110 / 255),
                                Color(red: 232 / 255, green: 176 / 255, blue: 42 / 255),
                                Color(red: 168 / 255, green: 108 / 255, blue: 16 / 255)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.45), Color.white.opacity(0)],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(height: trackH * 0.45)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(width: fillW, height: trackH)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color(red: 1, green: 236 / 255, blue: 170 / 255).opacity(0.35), lineWidth: 1)
            )
            .offset(x: trackX, y: trackY)
            .animation(.easeOut(duration: 0.12), value: store.loadProgress)

            Text("LOADING \(Int(store.loadProgress * 100))%")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(Lucky.goldSoft)
                .shadow(color: .black.opacity(0.7), radius: 1, y: 1)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .frame(width: 128, height: 26)
                .position(x: 166.5, y: 88)
        }
        .frame(width: 333, height: 106)
        .allowsHitTesting(false)
    }
}
