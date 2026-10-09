import SwiftUI
import UIKit

enum AppRoute {
    case loading, home, modes, stages, game
}

enum PlayMode {
    case classic, stage
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

struct StageDef: Identifiable, Equatable {
    let id: Int
    let name: String
    let blurb: String
    let spins: Int
    let bet: Int
    let target: Int
    let reward: Int
    let diagonals: Bool
    let wildStar: Bool
    let payoutScale: Int

    static let campaign: [StageDef] = [
        StageDef(id: 0, name: "樱桃试手", blurb: "28 转内，横线赢得 20", spins: 28, bet: 10, target: 20, reward: 100, diagonals: false, wildStar: false, payoutScale: 1),
        StageDef(id: 1, name: "灯排加码", blurb: "24 转内，横线赢得 40", spins: 24, bet: 10, target: 40, reward: 120, diagonals: false, wildStar: false, payoutScale: 1),
        StageDef(id: 2, name: "斜线入局", blurb: "斜线也算 · 18 转赢得 50", spins: 18, bet: 10, target: 50, reward: 150, diagonals: true, wildStar: false, payoutScale: 1),
        StageDef(id: 3, name: "金星替牌", blurb: "金星万能 · 16 转赢得 180", spins: 16, bet: 10, target: 180, reward: 180, diagonals: true, wildStar: true, payoutScale: 1),
        StageDef(id: 4, name: "双倍灯夜", blurb: "五线赔付翻倍 · 14 转赢得 80", spins: 14, bet: 10, target: 80, reward: 220, diagonals: true, wildStar: false, payoutScale: 2),
        StageDef(id: 5, name: "高注试炼", blurb: "下注锁定 50 · 16 转赢得 150", spins: 16, bet: 50, target: 150, reward: 300, diagonals: false, wildStar: false, payoutScale: 1),
        StageDef(id: 6, name: "星斜交织", blurb: "斜线加金星 · 14 转赢得 1000", spins: 14, bet: 50, target: 1000, reward: 450, diagonals: true, wildStar: true, payoutScale: 1),
        StageDef(id: 7, name: "灯牌终章", blurb: "斜线+万能+双倍 · 12 转赢得 1800", spins: 12, bet: 50, target: 1800, reward: 800, diagonals: true, wildStar: true, payoutScale: 2)
    ]
}

struct StageEnd: Equatable {
    var cleared: Bool
    var reward: Int
    var firstClear: Bool
    var finale: Bool
    var got: Int
    var target: Int
    var stageName: String
    var hasNext: Bool
}

private struct SpinRules {
    var diagonals: Bool
    var wildStar: Bool
    var payoutScale: Int

    var lines: [[(Int, Int)]] {
        var value: [[(Int, Int)]] = [
            [(0, 0), (0, 1), (0, 2)],
            [(1, 0), (1, 1), (1, 2)],
            [(2, 0), (2, 1), (2, 2)]
        ]
        if diagonals {
            value.append([(0, 0), (1, 1), (2, 2)])
            value.append([(0, 2), (1, 1), (2, 0)])
        }
        return value
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
    @Published var hitCells: Set<Int> = []
    @Published var showWinBurst = false
    @Published var showSettings = false
    @Published var showPrivacy = false
    @Published var showRules = false
    @Published var soundEnabled: Bool
    @Published var musicEnabled: Bool
    @Published var hapticEnabled: Bool
    @Published var reelBlur: CGFloat = 0
    @Published var spinningColumn = -1
    @Published var mode: PlayMode = .classic
    @Published var clearedStages: Int
    @Published var stageIndex = 0
    @Published var stageSpinsLeft = 0
    @Published var stageWon = 0
    @Published var stageEnd: StageEnd?

    let bets = [10, 50, 100]
    private let defaults = UserDefaults.standard
    let audio = SoundHub()
    private var savedClassicBet: Int
    private var spinGeneration = 0

    init() {
        coins = defaults.object(forKey: "lf.coins") as? Int ?? 1_000
        bet = defaults.object(forKey: "lf.bet") as? Int ?? 10
        soundEnabled = defaults.object(forKey: "lf.sound") as? Bool ?? true
        musicEnabled = defaults.object(forKey: "lf.music") as? Bool ?? true
        hapticEnabled = defaults.object(forKey: "lf.haptic") as? Bool ?? true
        let storedClears = defaults.object(forKey: "lf.cleared") as? Int ?? 0
        clearedStages = min(max(0, storedClears), StageDef.campaign.count)
        savedClassicBet = bet
        grid = GameStore.mockGrid()
    }

    var canSpin: Bool {
        if isSpinning { return false }
        if mode == .stage {
            return stageEnd == nil && stageSpinsLeft > 0
        }
        return coins >= bet
    }

    var currentStage: StageDef? {
        guard stageIndex >= 0, stageIndex < StageDef.campaign.count else { return nil }
        return StageDef.campaign[stageIndex]
    }

    var stageTarget: Int {
        mode == .stage ? (currentStage?.target ?? 0) : 0
    }

    func persist() {
        defaults.set(coins, forKey: "lf.coins")
        defaults.set(savedClassicBet, forKey: "lf.bet")
        defaults.set(soundEnabled, forKey: "lf.sound")
        defaults.set(musicEnabled, forKey: "lf.music")
        defaults.set(hapticEnabled, forKey: "lf.haptic")
        defaults.set(clearedStages, forKey: "lf.cleared")
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

    func openClassic() {
        stopReelMotion()
        mode = .classic
        stageEnd = nil
        showWinBurst = false
        hitCells = []
        bet = savedClassicBet
        banner = "三连成行 · 赢取金币"
        route = .game
    }

    func beginStage(_ index: Int) {
        guard index >= 0, index < StageDef.campaign.count, index <= clearedStages else { return }
        if mode != .stage {
            savedClassicBet = bet
        }
        stopReelMotion()
        let stage = StageDef.campaign[index]
        mode = .stage
        stageIndex = index
        stageSpinsLeft = stage.spins
        stageWon = 0
        stageEnd = nil
        showWinBurst = false
        hitCells = []
        lastWin = 0
        bet = stage.bet
        grid = GameStore.mockGrid()
        refreshStageBanner()
        route = .game
    }

    func leaveGame() {
        stopReelMotion()
        showWinBurst = false
        stageEnd = nil
        route = mode == .stage ? .stages : .home
    }

    func exitToStageMap() {
        stopReelMotion()
        stageEnd = nil
        showWinBurst = false
        route = .stages
    }

    func dismissWinBurst() {
        showWinBurst = false
        if mode == .stage, stageEnd == nil {
            refreshStageBanner()
        }
    }

    func setBet(_ value: Int) {
        guard !isSpinning else { return }
        if mode == .stage {
            banner = "本关注定 \(bet) · 剩\(stageSpinsLeft)转"
            audio.click()
            return
        }
        if value == 100 {
            bet = min(100, max(10, coins))
            if coins >= 100 { bet = 100 }
        } else {
            bet = value
        }
        savedClassicBet = bet
        persist()
        audio.click()
        haptic(.light)
    }

    func resetProgress() {
        stopReelMotion()
        coins = 1_000
        bet = 10
        savedClassicBet = 10
        lastWin = 0
        banner = "三连成行 · 赢取金币"
        hitCells = []
        grid = GameStore.mockGrid()
        clearedStages = 0
        stageWon = 0
        stageSpinsLeft = 0
        stageEnd = nil
        mode = .classic
        persist()
    }

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func spin() async {
        guard canSpin else {
            if mode == .classic, coins < bet { banner = "金币不足" }
            return
        }

        spinGeneration += 1
        let generation = spinGeneration
        let playingStage = mode == .stage
        let stageAtStart = stageIndex
        var chargedClassic = false
        var refundStageSpin = playingStage

        func abortIfStale() -> Bool {
            guard generation != spinGeneration else { return false }
            if chargedClassic {
                coins += bet
                chargedClassic = false
                persist()
            } else if refundStageSpin, mode == .stage, stageIndex == stageAtStart {
                stageSpinsLeft += 1
                refundStageSpin = false
            }
            isSpinning = false
            reelBlur = 0
            spinningColumn = -1
            return true
        }

        isSpinning = true
        hitCells = []
        showWinBurst = false
        lastWin = 0

        if playingStage {
            stageSpinsLeft -= 1
        } else {
            coins -= bet
            chargedClassic = true
            persist()
        }

        audio.spin()
        haptic(.rigid)
        withAnimation(.easeIn(duration: 0.12)) { reelBlur = 7 }

        for tick in 0..<24 {
            if abortIfStale() { return }
            spinningColumn = tick % 3
            grid = GameStore.freshGrid()
            if tick % 2 == 0 { audio.tick() }
            try? await Task.sleep(nanoseconds: UInt64(26_000_000 + tick * 8_000_000))
        }

        if abortIfStale() { return }

        withAnimation(.easeOut(duration: 0.22)) { reelBlur = 0 }
        spinningColumn = -1
        grid = GameStore.freshGrid()
        audio.stopReel()

        let result = payout(for: grid)
        hitCells = result.cells
        lastWin = result.amount
        chargedClassic = false
        refundStageSpin = false

        if playingStage {
            guard mode == .stage, stageIndex == stageAtStart else {
                isSpinning = false
                return
            }
            stageWon += result.amount
            if result.amount > 0 {
                banner = "赢得 \(result.amount) 金币"
                showWinBurst = true
                audio.win()
                haptic(.heavy)
            }
            resolveStageEnd()
            if stageEnd == nil, result.amount == 0 {
                refreshStageBanner()
                haptic(.light)
            } else if stageEnd?.cleared == false, result.amount == 0 {
                haptic(.light)
            }
        } else {
            guard mode == .classic else {
                isSpinning = false
                return
            }
            if result.amount > 0 {
                coins += result.amount
                banner = "赢得 \(result.amount) 金币"
                showWinBurst = true
                audio.win()
                haptic(.heavy)
            } else {
                banner = "再转一次，大奖在灯火里"
                haptic(.light)
            }
            persist()
        }
        isSpinning = false
    }

    func applyAudioFlags() {
        audio.soundEnabled = soundEnabled
        audio.musicEnabled = musicEnabled
        persist()
        if musicEnabled { audio.startMusic() } else { audio.stopMusic() }
    }

    private func resolveStageEnd() {
        guard let stage = currentStage else { return }
        let cleared = stageWon >= stage.target
        let failed = !cleared && stageSpinsLeft <= 0
        guard cleared || failed else { return }

        if cleared {
            let first = stageIndex == clearedStages
            if first {
                clearedStages = stageIndex + 1
                coins += stage.reward
                persist()
            }
            let lastIndex = StageDef.campaign.count - 1
            stageEnd = StageEnd(
                cleared: true,
                reward: first ? stage.reward : 0,
                firstClear: first,
                finale: first && stageIndex == lastIndex,
                got: stageWon,
                target: stage.target,
                stageName: stage.name,
                hasNext: first && stageIndex < lastIndex
            )
            banner = first ? "过关 · 奖励 \(stage.reward)" : "再次通过"
        } else {
            stageEnd = StageEnd(
                cleared: false,
                reward: 0,
                firstClear: false,
                finale: false,
                got: stageWon,
                target: stage.target,
                stageName: stage.name,
                hasNext: false
            )
            banner = "还差 \(stage.target - stageWon) 金币"
        }
    }

    private func refreshStageBanner() {
        guard let stage = currentStage else { return }
        banner = "第\(stageIndex + 1)关 \(stage.name) · 剩\(stageSpinsLeft)转"
    }

    private var activeRules: SpinRules {
        if mode == .stage, let stage = currentStage {
            return SpinRules(diagonals: stage.diagonals, wildStar: stage.wildStar, payoutScale: stage.payoutScale)
        }
        return SpinRules(diagonals: false, wildStar: false, payoutScale: 1)
    }

    private func payout(for grid: [[SlotSymbol]]) -> (amount: Int, cells: Set<Int>) {
        let rules = activeRules
        var amount = 0
        var cells = Set<Int>()
        for line in rules.lines {
            let symbols = line.map { grid[$0.0][$0.1] }
            guard let symbol = matchedSymbol(symbols, wildStar: rules.wildStar) else { continue }
            amount += bet * symbol.lineMultiplier * rules.payoutScale
            for (row, col) in line {
                cells.insert(row * 3 + col)
            }
        }
        return (amount, cells)
    }

    private func matchedSymbol(_ symbols: [SlotSymbol], wildStar: Bool) -> SlotSymbol? {
        if wildStar {
            let concrete = symbols.filter { $0 != .star }
            if concrete.isEmpty { return .star }
            let first = concrete[0]
            guard concrete.allSatisfy({ $0 == first }) else { return nil }
            return first
        }
        guard symbols.count == 3, symbols[0] == symbols[1], symbols[1] == symbols[2] else { return nil }
        return symbols[0]
    }

    private func stopReelMotion() {
        spinGeneration += 1
        isSpinning = false
        reelBlur = 0
        spinningColumn = -1
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
