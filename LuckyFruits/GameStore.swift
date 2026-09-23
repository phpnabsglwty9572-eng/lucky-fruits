import SwiftUI
import UIKit

enum AppRoute {
    case loading, home, game
}

enum SlotSymbol: String, CaseIterable, Identifiable {
    case cherry, lemon, orange, grape, melon, bell, star, bar, seven

    var id: String { rawValue }

    var asset: String {
        switch self {
        case .cherry: "symCherry"
        case .lemon: "symLemon"
        case .orange: "symOrange"
        case .grape: "symGrape"
        case .melon: "symMelon"
        case .bell: "symBell"
        case .star: "symStar"
        case .bar: "symBar"
        case .seven: "symSeven"
        }
    }

    var title: String {
        switch self {
        case .cherry: "樱桃"
        case .lemon: "柠檬"
        case .orange: "橙子"
        case .grape: "葡萄"
        case .melon: "西瓜"
        case .bell: "金铃"
        case .star: "金星"
        case .bar: "BAR"
        case .seven: "幸运7"
        }
    }

    var lineMultiplier: Int {
        switch self {
        case .seven: 20
        case .bar: 12
        case .star: 10
        case .bell: 8
        case .melon: 6
        case .grape: 5
        case .orange: 4
        case .lemon: 3
        case .cherry: 2
        }
    }

    static func randomSpin() -> SlotSymbol {
        let bag: [SlotSymbol] = [
            .cherry, .cherry, .cherry,
            .lemon, .lemon, .orange, .orange,
            .grape, .grape, .melon, .bell, .star, .bar, .seven
        ]
        return bag.randomElement() ?? .cherry
    }
}

@MainActor
final class GameStore: ObservableObject {
    @Published var route: AppRoute = .loading
    @Published var loadProgress: Double = 0
    @Published var coins: Int
    @Published var bet: Int
    @Published var grid: [[SlotSymbol]]
    @Published var isSpinning = false
    @Published var lastWin = 0
    @Published var banner = ""
    @Published var hitRows: Set<Int> = []
    @Published var showWinBurst = false
    @Published var showSettings = false
    @Published var showPrivacy = false
    @Published var showRules = false
    @Published var soundEnabled: Bool
    @Published var musicEnabled: Bool
    @Published var hapticEnabled: Bool
    @Published var reelBlur: CGFloat = 0
    @Published var spinningColumn = -1

    let bets = [10, 50, 100]
    private let defaults = UserDefaults.standard
    let audio = SoundHub()

    init() {
        coins = defaults.object(forKey: "lf.coins") as? Int ?? 1_000
        bet = defaults.object(forKey: "lf.bet") as? Int ?? 10
        soundEnabled = defaults.object(forKey: "lf.sound") as? Bool ?? true
        musicEnabled = defaults.object(forKey: "lf.music") as? Bool ?? true
        hapticEnabled = defaults.object(forKey: "lf.haptic") as? Bool ?? true
        grid = GameStore.mockGrid()
    }

    var canSpin: Bool { !isSpinning && coins >= bet }

    func persist() {
        defaults.set(coins, forKey: "lf.coins")
        defaults.set(bet, forKey: "lf.bet")
        defaults.set(soundEnabled, forKey: "lf.sound")
        defaults.set(musicEnabled, forKey: "lf.music")
        defaults.set(hapticEnabled, forKey: "lf.haptic")
    }

    func bootstrap() async {
        audio.soundEnabled = soundEnabled
        audio.musicEnabled = musicEnabled
        audio.startMusic()
        for step in 1...100 {
            loadProgress = Double(step) / 100
            try? await Task.sleep(nanoseconds: 18_000_000)
        }
        withAnimation(.easeInOut(duration: 0.45)) { route = .home }
    }

    func setBet(_ value: Int) {
        guard !isSpinning else { return }
        if value == 100 {
            bet = min(100, max(10, coins))
            if coins >= 100 { bet = 100 }
        } else {
            bet = value
        }
        persist()
        audio.click()
        haptic(.light)
    }

    func resetProgress() {
        coins = 1_000
        bet = 10
        lastWin = 0
        banner = "三连成行 · 赢取金币"
        hitRows = []
        grid = GameStore.mockGrid()
        persist()
    }

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func spin() async {
        guard canSpin else {
            if coins < bet { banner = "金币不足" }
            return
        }

        isSpinning = true
        hitRows = []
        showWinBurst = false
        lastWin = 0
        coins -= bet
        persist()
        audio.spin()
        haptic(.rigid)
        withAnimation(.easeIn(duration: 0.12)) { reelBlur = 7 }

        for tick in 0..<24 {
            spinningColumn = tick % 3
            grid = GameStore.freshGrid()
            if tick % 2 == 0 { audio.tick() }
            try? await Task.sleep(nanoseconds: UInt64(26_000_000 + tick * 8_000_000))
        }

        withAnimation(.easeOut(duration: 0.22)) { reelBlur = 0 }
        spinningColumn = -1
        grid = GameStore.freshGrid()
        audio.stopReel()

        var payout = 0
        var rows = Set<Int>()
        for r in 0..<3 {
            let a = grid[r][0], b = grid[r][1], c = grid[r][2]
            if a == b, b == c {
                payout += bet * a.lineMultiplier
                rows.insert(r)
            }
        }
        if payout > 0 {
            hitRows = rows
            lastWin = payout
            coins += payout
            banner = "赢得 \(payout) 金币"
            showWinBurst = true
            audio.win()
            haptic(.heavy)
        } else {
            banner = "再转一次，大奖在灯火里"
            haptic(.light)
        }
        persist()
        isSpinning = false
    }

    func applyAudioFlags() {
        audio.soundEnabled = soundEnabled
        audio.musicEnabled = musicEnabled
        persist()
        if musicEnabled { audio.startMusic() } else { audio.stopMusic() }
    }

    private static func freshGrid() -> [[SlotSymbol]] {
        (0..<3).map { _ in (0..<3).map { _ in SlotSymbol.randomSpin() } }
    }

    static func mockGrid() -> [[SlotSymbol]] {
        [
            [.cherry, .lemon, .orange],
            [.grape, .melon, .bell],
            [.star, .bar, .seven]
        ]
    }
}
