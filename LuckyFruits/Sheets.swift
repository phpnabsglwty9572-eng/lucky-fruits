import SwiftUI
import WebKit

struct SettingsSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Lucky.void.ignoresSafeArea()
                VStack(spacing: 16) {
                    toggle("Music", isOn: $store.musicEnabled)
                    toggle("Sound FX", isOn: $store.soundEnabled)
                    toggle("Haptics", isOn: $store.hapticEnabled)
                    Button("Rules") {
                        store.audio.click()
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            store.showRules = true
                        }
                    }
                    .font(Lucky.bold(16))
                    .foregroundStyle(Lucky.gold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Lucky.maroon, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Lucky.gold.opacity(0.45), lineWidth: 1))

                    Button("Reset coins & stages") {
                        store.resetProgress()
                        store.audio.click()
                    }
                    .font(Lucky.bold(16))
                    .foregroundStyle(Lucky.gold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Lucky.wine, in: RoundedRectangle(cornerRadius: 16))
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Lucky.gold)
                }
            }
            .onChange(of: store.musicEnabled) { _, _ in store.applyAudioFlags() }
            .onChange(of: store.soundEnabled) { _, _ in store.applyAudioFlags() }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }

    private func toggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .tint(Lucky.wine)
            .foregroundStyle(Lucky.cream)
            .padding()
            .background(Lucky.maroon, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct PrivacySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PrivacyWebView(url: Lucky.privacyURL)
                .ignoresSafeArea(edges: .bottom)
                .background(Lucky.void)
                .navigationTitle("Privacy")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }.foregroundStyle(Lucky.gold)
                    }
                }
        }
        .preferredColorScheme(.dark)
    }
}

struct PrivacyWebView: UIViewRepresentable {
    var url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let web = WKWebView(frame: .zero, configuration: config)
        web.backgroundColor = UIColor(Lucky.void)
        web.isOpaque = false
        web.scrollView.backgroundColor = UIColor(Lucky.void)
        web.load(URLRequest(url: url))
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct RulesSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Lucky.void.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Classic")
                            .foregroundStyle(Lucky.gold)
                        Text("Match three identical symbols on any row. Multiple rows can pay in one spin. Payouts follow the symbol odds. BET 10 / 50 / MAX(100). You cannot spin if you cannot afford the bet.")
                            .foregroundStyle(Lucky.cream)
                        Text("Streak: consecutive wins stack payouts to ×2 / ×3 / ×5 and light the diagonals. A miss drops you back to rows only.")
                            .foregroundStyle(Lucky.cream)
                        Text("Jackpot: each paid spin feeds the pot. Three true Lucky 7s on a row or diagonal take the jackpot.")
                            .foregroundStyle(Lucky.cream)
                        Text("Free spins: 3 / 4 / 5 stars on the reels award 5 / 8 / 12 free spins. Stars are wild, diagonals are live, and coins are not charged.")
                            .foregroundStyle(Lucky.cream)
                        Text("Daily gift: open the app each day to collect coins. The gift grows through 7 days. Small wins do not stop the reels — only jackpots, free spins, and big hits pause for a celebration.")
                            .foregroundStyle(Lucky.cream)
                        Text("Hold & nudge: tap a reel to HOLD it (max 2). SPIN then respin the others. After a miss you get one NUDGE — shift that reel down one stop without paying again.")
                            .foregroundStyle(Lucky.cream)
                        Text("7 ×20   BAR ×12   Star ×10   Bell ×8")
                            .foregroundStyle(Lucky.gold)
                        Text("Melon ×6   Grape ×5   Orange ×4   Lemon ×3   Cherry ×2")
                            .foregroundStyle(Lucky.gold)
                        Text("Challenge")
                            .foregroundStyle(Lucky.gold)
                            .padding(.top, 4)
                        Text("Classic coins are not charged. Each stage locks the bet and spin count. Hit the win goal to clear. First clear pays into classic coins. Fail and retry. Stages unlock in order.")
                            .foregroundStyle(Lucky.cream)
                        Text("Later stages add diagonals, wild stars, or double payouts. Three stars pay as the star odds. 3+ stars on the reels add extra spins. Streak multipliers still apply.")
                            .foregroundStyle(Lucky.muted)
                    }
                    .font(Lucky.bold(15))
                    .padding(20)
                }
            }
            .navigationTitle("Rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Lucky.gold)
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }
}
