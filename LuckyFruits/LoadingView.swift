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
                    .frame(width: 335, height: 126)
                    .shadow(color: Lucky.gold.opacity(glow ? 0.55 : 0.2), radius: glow ? 16 : 6)
                    .position(x: 19 + 335 / 2, y: 172 + 126 / 2)

                progressBoard
                    .position(x: 21 + 333 / 2, y: 335 + 106 / 2)
            }
            .frame(width: 375, height: 667)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { glow = true }
            Task { await store.bootstrap() }
        }
    }

    private var progressBoard: some View {
        let trackInsetX: CGFloat = 30
        let trackY: CGFloat = 29
        let trackH: CGFloat = 30
        let trackW: CGFloat = 333 - trackInsetX * 2
        let fill = max(0.04, min(1, store.loadProgress))

        return ZStack(alignment: .topLeading) {
            Image("imgLoadBar")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 333, height: 106)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.92))
                .frame(width: trackW, height: trackH)
                .offset(x: trackInsetX, y: trackY)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1, green: 214 / 255, blue: 90 / 255),
                            Color(red: 210 / 255, green: 140 / 255, blue: 28 / 255)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: max(12, trackW * fill), height: trackH)
                .offset(x: trackInsetX, y: trackY)
                .shadow(color: Lucky.gold.opacity(0.45), radius: 6)
                .animation(.easeOut(duration: 0.12), value: store.loadProgress)

            Text("LOADING \(Int(store.loadProgress * 100))%")
                .font(Lucky.extra(13))
                .tracking(0.6)
                .foregroundStyle(Lucky.gold)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .frame(width: 148, height: 22)
                .background(Color(red: 16 / 255, green: 8 / 255, blue: 8 / 255))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .position(x: 166.5, y: 90)
        }
        .frame(width: 333, height: 106)
        .allowsHitTesting(false)
    }
}
