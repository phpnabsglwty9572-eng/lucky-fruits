import SwiftUI

struct LoadingView: View {
    @EnvironmentObject private var store: GameStore
    @State private var pulse = false
    @State private var spin = false

    var body: some View {
        DesignCanvas {
            ZStack {
                Image("imgBg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 375, height: 667)
                    .clipped()
                    .blur(radius: 16)
                    .allowsHitTesting(false)
                Lucky.void.opacity(0.64)
                    .allowsHitTesting(false)

                VStack(spacing: 22) {
                    Spacer(minLength: 70)
                    Image("imgTitle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 260)
                        .shadow(color: Lucky.gold.opacity(0.55), radius: pulse ? 18 : 6)
                    ZStack {
                        Image("symSeven")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 128, height: 108)
                            .rotationEffect(.degrees(spin ? 8 : -8))
                            .scaleEffect(pulse ? 1.06 : 0.94)
                            .shadow(color: Lucky.gold.opacity(0.5), radius: 16)
                    }
                    .frame(width: 160, height: 160)
                    .background(Lucky.maroon.opacity(0.75), in: RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Lucky.gold, lineWidth: 3)
                    )

                    VStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Lucky.maroon)
                                Capsule()
                                    .fill(LinearGradient(colors: [Lucky.wine, Lucky.gold], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: max(10, geo.size.width * store.loadProgress))
                            }
                            .overlay(Capsule().stroke(Lucky.gold.opacity(0.7), lineWidth: 1))
                        }
                        .frame(height: 10)
                        .padding(.horizontal, 48)
                        Text("正在点亮灯牌… \(Int(store.loadProgress * 100))%")
                            .font(Lucky.bold(14))
                            .foregroundStyle(Lucky.cream)
                        Text("LUCKY FRUITS")
                            .font(Lucky.extra(11))
                            .tracking(3)
                            .foregroundStyle(Lucky.gold)
                    }
                    Spacer(minLength: 40)
                }
            }
            .frame(width: 375, height: 667)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { spin = true }
            Task { await store.bootstrap() }
        }
    }
}
