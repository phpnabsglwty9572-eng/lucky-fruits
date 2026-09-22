import SwiftUI

struct SettingsSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Lucky.void.ignoresSafeArea()
                VStack(spacing: 16) {
                    toggle("背景音乐", isOn: $store.musicEnabled)
                    toggle("游戏音效", isOn: $store.soundEnabled)
                    toggle("震动反馈", isOn: $store.hapticEnabled)
                    Button("重置本地金币") {
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
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }.foregroundStyle(Lucky.gold)
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
            ZStack {
                Lucky.void.ignoresSafeArea()
                ScrollView {
                    Text("Lucky Fruits 为单机水果机。金币、下注仅保存在本机，不联网、不上报账号。背景音乐与音效为原创合成，风格贴合金红赌场灯牌。")
                        .font(.system(size: 15))
                        .foregroundStyle(Lucky.muted)
                        .padding(20)
                }
            }
            .navigationTitle("隐私政策")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }.foregroundStyle(Lucky.gold)
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }
}

struct RulesSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Lucky.void.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 12) {
                    Text("任意一行三枚相同即中奖，可同时中多行。倍率按符号结算。")
                        .foregroundStyle(Lucky.cream)
                    Text("7 ×20   BAR ×12   星 ×10   铃 ×8")
                        .foregroundStyle(Lucky.gold)
                    Text("西瓜 ×6   葡萄 ×5   橙 ×4   柠檬 ×3   樱桃 ×2")
                        .foregroundStyle(Lucky.gold)
                    Text("BET 10 / 50 / MAX(100)。余额不足时无法开转。")
                        .foregroundStyle(Lucky.muted)
                    Spacer()
                }
                .font(Lucky.bold(15))
                .padding(20)
            }
            .navigationTitle("规则")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }.foregroundStyle(Lucky.gold)
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }
}
