import SwiftUI
import WebKit

struct SettingsSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    toggle("Music", isOn: $store.musicEnabled)
                    toggle("Sound FX", isOn: $store.soundEnabled)
                    toggle("Haptics", isOn: $store.hapticEnabled)
                    sheetButton("Fruit Album") {
                        store.audio.click()
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            store.showAlbum = true
                        }
                    }
                    sheetButton("Rules") {
                        store.audio.click()
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            store.showRules = true
                        }
                    }
                    sheetButton("Reset coins & stages", fill: Lucky.wine) {
                        store.resetProgress()
                        store.audio.click()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(Lucky.void.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Lucky.void, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Lucky.gold)
                }
            }
            .onChange(of: store.musicEnabled) { _, _ in store.applyAudioFlags() }
            .onChange(of: store.soundEnabled) { _, _ in store.applyAudioFlags() }
        }
        .luckySheetChrome(phoneDetents: [.large])
    }

    private func sheetButton(_ title: String, fill: Color = Lucky.maroon, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(Lucky.bold(16))
            .foregroundStyle(Lucky.gold)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(fill, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Lucky.gold.opacity(0.45), lineWidth: 1))
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
                .background(Color.white)
                .navigationTitle("Privacy")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.white, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.light, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                            .foregroundStyle(Color.black)
                    }
                }
        }
        .luckySheetChrome(phoneDetents: nil, colorScheme: .light, background: .white)
    }
}

struct PrivacyWebView: UIViewRepresentable {
    var url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let web = WKWebView(frame: .zero, configuration: config)
        web.backgroundColor = .white
        web.isOpaque = true
        web.underPageBackgroundColor = .white
        web.scrollView.backgroundColor = .white
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
                        Text("Lucky Fruits is a kitchen puzzle. You keep fruits, restock the others, then SERVE a 3-match. Score is not a wager. There is no cash-out.")
                            .foregroundStyle(Lucky.goldSoft)
                        Text("Marquee")
                            .foregroundStyle(Lucky.gold)
                        Text("Same board as Kitchen. Choose BET 10, 50, or MAX 100. Each restock costs that bet from your score. Serving pays the symbol odds times that bet. You cannot restock if the score is below the bet. Bottom orders pay extra when you serve what they ask.")
                            .foregroundStyle(Lucky.cream)
                        Text("Kitchen")
                            .foregroundStyle(Lucky.gold)
                        Text("Tap fruits to KEEP them (max 5). RESTOCK fills the unlocked cells. SWAP two fruits once after a restock. When a row (or a hot diagonal) matches, tap SERVE. Serving is the only way to score. There is no bet.")
                            .foregroundStyle(Lucky.cream)
                        Text("Each Kitchen visit has a shift menu on the bottom bar. Serving a menu fruit pays an extra +30 and fills that dish. Other lines still pay, but the shift does not move. Clear all three dishes for a shift bonus, then a harder menu starts. If your score is under 100, a Cover shift also appears: serve 2 plates for +120.")
                            .foregroundStyle(Lucky.cream)
                        Text("Chef blend: served lines fill the meter. When it is full, pick a fruit to make wild for the next 3 restocks.")
                            .foregroundStyle(Lucky.cream)
                        Text("Album: stamp each fruit the first time you serve it. Stamp all 9 for a one-time +400 bonus.")
                            .foregroundStyle(Lucky.cream)
                        Text("Combo: consecutive serves stack to ×2 / ×3 / ×5 and light the diagonals. Restocking a ready line drops the combo.")
                            .foregroundStyle(Lucky.cream)
                        Text("Daily gift: open the app each day to collect score. The gift grows through 7 days.")
                            .foregroundStyle(Lucky.cream)
                        Text("7 ×20   BAR ×12   Star ×10   Bell ×8")
                            .foregroundStyle(Lucky.gold)
                        Text("Melon ×6   Grape ×5   Orange ×4   Lemon ×3   Cherry ×2")
                            .foregroundStyle(Lucky.gold)
                        Text("Challenge")
                            .foregroundStyle(Lucky.gold)
                            .padding(.top, 4)
                        Text("Kitchen score is not charged. Each stage limits restocks. Serve enough dishes to clear. First clear pays into kitchen score. Replaying a cleared stage pays a smaller tip. Stages unlock in order.")
                            .foregroundStyle(Lucky.cream)
                        Text("Later stages change the rules: diagonals, wild stars, Cherry-only lines, two keeps, diagonals only, or no swap.")
                            .foregroundStyle(Lucky.muted)
                        Text("Window")
                            .foregroundStyle(Lucky.gold)
                            .padding(.top, 4)
                        Text("No reels. A ticket lists the fruits. Tap matching fruits on the counter, then SEND. Extra fruits are decoys. A star can stand in for a missing fruit. Twelve levels. Later levels use a fuller counter, a bigger plate, fewer spare stars, and only two misses.")
                            .foregroundStyle(Lucky.cream)
                        Text("Crush")
                            .foregroundStyle(Lucky.gold)
                            .padding(.top, 4)
                        Text("Swap two neighboring fruits on a 7×7 board. Three in a line crush. Four clear the whole row or column. Five clear every fruit of that kind. Crush score is local. About one eighth banks into your kitchen score, plus a small tip when you clear a level.")
                            .foregroundStyle(Lucky.cream)
                        Text("Ring Chase")
                            .foregroundStyle(Lucky.gold)
                            .padding(.top, 4)
                        Text("A ring of fruit cells. Pick a wish fruit and a bet of 10, 50, or 100. Start Chase runs the light clockwise. Tap again to stop. The cell you land on pays that bet times its multiplier into your score. Each stop on the wish fruit fills its set. Three fills pay +500, then the set starts over.")
                            .foregroundStyle(Lucky.cream)
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
        .luckySheetChrome()
    }
}
