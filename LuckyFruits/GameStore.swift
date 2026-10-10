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
        case .cherry: "Cherry"
        case .lemon: "Lemon"
        case .orange: "Orange"
        case .grape: "Grape"
        case .melon: "Melon"
        case .bell: "Bell"
        case .star: "Star"
        case .bar: "BAR"
        case .seven: "Lucky 7"
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
        StageDef(id: 0, name: "Cherry Warmup", blurb: "Win 20 on rows in 28 spins", spins: 28, bet: 10, target: 20, reward: 100, diagonals: false, wildStar: false, payoutScale: 1),
        StageDef(id: 1, name: "Marquee Raise", blurb: "Win 40 on rows in 24 spins", spins: 24, bet: 10, target: 40, reward: 120, diagonals: false, wildStar: false, payoutScale: 1),
        StageDef(id: 2, name: "Diagonals On", blurb: "Diagonals count · win 50 in 18", spins: 18, bet: 10, target: 50, reward: 150, diagonals: true, wildStar: false, payoutScale: 1),
        StageDef(id: 3, name: "Wild Stars", blurb: "Stars are wild · win 180 in 16", spins: 16, bet: 10, target: 180, reward: 180, diagonals: true, wildStar: true, payoutScale: 1),
        StageDef(id: 4, name: "Double Lights", blurb: "5-line pays ×2 · win 80 in 14", spins: 14, bet: 10, target: 80, reward: 220, diagonals: true, wildStar: false, payoutScale: 2),
        StageDef(id: 5, name: "High Stakes", blurb: "Bet locked at 50 · win 150 in 16", spins: 16, bet: 50, target: 150, reward: 300, diagonals: false, wildStar: false, payoutScale: 1),
        StageDef(id: 6, name: "Star Cross", blurb: "Diagonals + wilds · win 1000 in 14", spins: 14, bet: 50, target: 1000, reward: 450, diagonals: true, wildStar: true, payoutScale: 1),
        StageDef(id: 7, name: "Finale Lights", blurb: "Diagonals + wilds + ×2 · win 1800 in 12", spins: 12, bet: 50, target: 1800, reward: 800, diagonals: true, wildStar: true, payoutScale: 2)
    ]
}

struct DailyGift: Equatable {
    var day: Int
    var reward: Int
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

struct SpinResult {
    var amount: Int = 0
    var cells: Set<Int> = []
    var jackpotHit: Bool = false
    var scatterStars: Int = 0
    var freeAwarded: Int = 0
    var extraStageSpins: Int = 0
    var nearMiss: String?
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
    @Published var jackpot: Int
    @Published var winStreak = 0
    @Published var freeSpinsLeft = 0
    @Published var burstTitle = "LUCKY WIN"
    @Published var burstSubtitle = "Tap to continue"
    @Published var coinFlash = false
    @Published var daily: DailyGift?
    @Published var heldColumns: Set<Int> = []
    @Published var nudgesLeft = 0

    let bets = [10, 50, 100]
    private let defaults = UserDefaults.standard
    let audio = SoundHub()
    private var savedClassicBet: Int
    private var spinGeneration = 0
    private let jackpotSeed = 200
    private var settleRules = SpinRules(diagonals: false, wildStar: false, payoutScale: 1)
    private var settleMult = 1
    private static let dailyRewards = [80, 120, 180, 250, 350, 500, 800]

    var inBonus: Bool { mode == .classic && freeSpinsLeft > 0 }

    var canHold: Bool { !isSpinning && stageEnd == nil && !showWinBurst }

    var comboMultiplier: Int {
        switch winStreak {
        case 0: return 1
        case 1: return 2
        case 2: return 3
        default: return 5
        }
    }

    init() {
        coins = defaults.object(forKey: "lf.coins") as? Int ?? 1_000
        let storedBet = defaults.object(forKey: "lf.bet") as? Int ?? 10
        bet = storedBet
        soundEnabled = defaults.object(forKey: "lf.sound") as? Bool ?? true
        musicEnabled = defaults.object(forKey: "lf.music") as? Bool ?? true
        hapticEnabled = defaults.object(forKey: "lf.haptic") as? Bool ?? true
        let storedClears = defaults.object(forKey: "lf.cleared") as? Int ?? 0
        clearedStages = min(max(0, storedClears), StageDef.campaign.count)
        jackpot = max(jackpotSeed, defaults.object(forKey: "lf.jackpot") as? Int ?? jackpotSeed)
        savedClassicBet = storedBet
        grid = GameStore.mockGrid()
    }

    var canSpin: Bool {
        if isSpinning { return false }
        if mode == .stage {
            return stageEnd == nil && stageSpinsLeft > 0
        }
        if freeSpinsLeft > 0 { return true }
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
        defaults.set(jackpot, forKey: "lf.jackpot")
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
        prepareDailyGift()
    }

    func openClassic() {
        stopReelMotion()
        mode = .classic
        stageEnd = nil
        showWinBurst = false
        hitCells = []
        freeSpinsLeft = 0
        winStreak = 0
        heldColumns = []
        nudgesLeft = 0
        bet = savedClassicBet
        refreshClassicBanner()
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
        freeSpinsLeft = 0
        winStreak = 0
        heldColumns = []
        nudgesLeft = 0
        bet = stage.bet
        grid = GameStore.mockGrid()
        refreshStageBanner()
        route = .game
    }

    func leaveGame() {
        stopReelMotion()
        showWinBurst = false
        stageEnd = nil
        freeSpinsLeft = 0
        winStreak = 0
        heldColumns = []
        nudgesLeft = 0
        route = mode == .stage ? .stages : .home
    }

    func exitToStageMap() {
        stopReelMotion()
        stageEnd = nil
        showWinBurst = false
        heldColumns = []
        nudgesLeft = 0
        route = .stages
    }

    func dismissWinBurst() {
        showWinBurst = false
        coinFlash = false
        if mode == .stage, stageEnd == nil {
            refreshStageBanner()
        } else if mode == .classic {
            refreshClassicBanner()
        }
    }

    func setBet(_ value: Int) {
        guard !isSpinning else { return }
        if inBonus {
            banner = "Free spins · bet locked at \(bet)"
            audio.click()
            return
        }
        if mode == .stage {
            banner = "Stage bet \(bet) · \(stageSpinsLeft) spins left"
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
        refreshClassicBanner()
    }

    func resetProgress() {
        stopReelMotion()
        coins = 1_000
        bet = 10
        savedClassicBet = 10
        lastWin = 0
        hitCells = []
        grid = GameStore.mockGrid()
        clearedStages = 0
        stageWon = 0
        stageSpinsLeft = 0
        stageEnd = nil
        jackpot = jackpotSeed
        winStreak = 0
        freeSpinsLeft = 0
        heldColumns = []
        nudgesLeft = 0
        mode = .classic
        persist()
        refreshClassicBanner()
    }

    func prepareDailyGift() {
        let today = Self.dayKey()
        let last = defaults.string(forKey: "lf.daily.last") ?? ""
        if last == today {
            daily = nil
            return
        }
        let streak = defaults.integer(forKey: "lf.daily.streak")
        let kept = last == Self.dayKey(offset: -1)
        let day = kept ? min(7, max(1, streak) + 1) : 1
        daily = DailyGift(day: day, reward: Self.dailyRewards[day - 1])
    }

    func claimDaily() {
        guard let gift = daily else { return }
        coins += gift.reward
        defaults.set(Self.dayKey(), forKey: "lf.daily.last")
        defaults.set(gift.day, forKey: "lf.daily.streak")
        persist()
        daily = nil
        audio.win()
        haptic(.heavy)
        coinFlash = true
    }

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func toggleHold(_ col: Int) {
        guard canHold, (0..<3).contains(col) else { return }
        if heldColumns.contains(col) {
            heldColumns.remove(col)
        } else if heldColumns.count >= 2 {
            banner = "Hold 2 reels max"
            audio.click()
            return
        } else {
            heldColumns.insert(col)
        }
        audio.click()
        haptic(.light)
        refreshHoldHint()
    }

    func nudge(_ col: Int) {
        guard canHold, nudgesLeft > 0, (0..<3).contains(col) else { return }
        if heldColumns.contains(col) {
            banner = "Nudge a free reel"
            audio.click()
            return
        }
        var next = grid
        next[2][col] = next[1][col]
        next[1][col] = next[0][col]
        next[0][col] = SlotSymbol.randomSpin()
        grid = next
        nudgesLeft = 0
        audio.tick()
        haptic(.rigid)
        settleLandedGrid(playingStage: mode == .stage, stageAtStart: stageIndex, consumeHolds: false, grantNudge: false)
    }

    func spin() async {
        guard canSpin else {
            if mode == .classic, freeSpinsLeft == 0, coins < bet { banner = "Not enough coins" }
            return
        }

        spinGeneration += 1
        let generation = spinGeneration
        let playingStage = mode == .stage
        let stageAtStart = stageIndex
        let bonusSpin = !playingStage && freeSpinsLeft > 0
        let appliedMult = comboMultiplier
        let rules = activeRules
        let holds = heldColumns
        let heldSnapshot = grid
        settleRules = rules
        settleMult = appliedMult
        var chargedClassic = false
        var refundStageSpin = playingStage
        var refundFreeSpin = bonusSpin

        func abortIfStale() -> Bool {
            guard generation != spinGeneration else { return false }
            if chargedClassic {
                coins += bet
                chargedClassic = false
                persist()
            } else if refundStageSpin, mode == .stage, stageIndex == stageAtStart {
                stageSpinsLeft += 1
                refundStageSpin = false
            } else if refundFreeSpin, mode == .classic {
                freeSpinsLeft += 1
                refundFreeSpin = false
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
        } else if bonusSpin {
            freeSpinsLeft -= 1
        } else {
            coins -= bet
            jackpot += max(1, bet / 5)
            chargedClassic = true
            persist()
        }

        audio.spin()
        haptic(.rigid)
        withAnimation(.easeIn(duration: 0.12)) { reelBlur = holds.count == 3 ? 0 : 7 }

        let moving = (0..<3).filter { !holds.contains($0) }
        for tick in 0..<24 {
            if abortIfStale() { return }
            spinningColumn = moving.isEmpty ? -1 : moving[tick % moving.count]
            grid = GameStore.mixedGrid(holding: holds, snapshot: heldSnapshot)
            if tick % 2 == 0 { audio.tick() }
            try? await Task.sleep(nanoseconds: UInt64(26_000_000 + tick * 8_000_000))
        }

        if abortIfStale() { return }

        withAnimation(.easeOut(duration: 0.22)) { reelBlur = 0 }
        spinningColumn = -1
        grid = GameStore.mixedGrid(holding: holds, snapshot: heldSnapshot)
        audio.stopReel()
        chargedClassic = false
        refundStageSpin = false
        refundFreeSpin = false
        settleLandedGrid(playingStage: playingStage, stageAtStart: stageAtStart, consumeHolds: true, grantNudge: true)
        isSpinning = false
    }

    private func settleLandedGrid(playingStage: Bool, stageAtStart: Int, consumeHolds: Bool, grantNudge: Bool) {
        var result = payout(for: grid, multiplier: settleMult, rules: settleRules)
        if result.jackpotHit, mode == .classic {
            result.amount += jackpot
            lastWin = result.amount
            jackpot = jackpotSeed
        } else {
            lastWin = result.amount
        }

        hitCells = result.cells
        if result.freeAwarded > 0, mode == .classic {
            freeSpinsLeft += result.freeAwarded
        }
        if result.extraStageSpins > 0, mode == .stage, stageIndex == stageAtStart {
            stageSpinsLeft += result.extraStageSpins
        }

        if result.amount > 0 {
            winStreak += 1
        } else if !grantNudge {
            // nudge miss keeps the miss streak already applied
        } else {
            winStreak = 0
        }

        if playingStage {
            guard mode == .stage, stageIndex == stageAtStart else { return }
            stageWon += result.amount
            if result.amount > 0 || result.extraStageSpins > 0 {
                celebrate(result, multiplier: settleMult)
            }
            resolveStageEnd()
            if stageEnd == nil, result.amount == 0, result.extraStageSpins == 0 {
                if let miss = result.nearMiss {
                    banner = "\(miss) · HOLD or NUDGE"
                } else {
                    refreshStageBanner()
                }
                haptic(.light)
            } else if stageEnd?.cleared == false, result.amount == 0 {
                haptic(.light)
            }
        } else {
            guard mode == .classic else { return }
            if result.amount > 0 {
                coins += result.amount
                celebrate(result, multiplier: settleMult)
            } else if result.freeAwarded > 0 {
                celebrate(result, multiplier: settleMult)
            } else if let miss = result.nearMiss {
                banner = "\(miss) · HOLD or NUDGE"
                haptic(.light)
            } else {
                refreshClassicBanner()
                haptic(.light)
            }
            persist()
        }

        if consumeHolds { heldColumns = [] }
        if grantNudge {
            nudgesLeft = (result.amount == 0 && result.freeAwarded == 0 && result.extraStageSpins == 0 && stageEnd == nil) ? 1 : 0
        } else if result.amount > 0 {
            nudgesLeft = 0
        }
        if result.amount > 0 { heldColumns = [] }
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
            banner = first ? "Cleared · +\(stage.reward)" : "Cleared again"
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
            banner = "Need \(stage.target - stageWon) more"
        }
    }

    private func refreshHoldHint() {
        if !heldColumns.isEmpty {
            banner = "Holding \(heldColumns.count) · SPIN respin the rest"
        } else if nudgesLeft > 0 {
            banner = "NUDGE a reel or HOLD then spin"
        } else if mode == .stage {
            refreshStageBanner()
        } else {
            refreshClassicBanner()
        }
    }

    private func refreshStageBanner() {
        guard let stage = currentStage else { return }
        var text = "Stage \(stageIndex + 1) \(stage.name) · \(stageSpinsLeft) left"
        if winStreak >= 1 {
            text += " · Streak ×\(comboMultiplier)"
        } else if nudgesLeft > 0 {
            text += " · HOLD / NUDGE"
        }
        banner = text
    }

    private func refreshClassicBanner() {
        if freeSpinsLeft > 0 {
            banner = "Free spins \(freeSpinsLeft) · wild stars · diagonals"
            return
        }
        if !heldColumns.isEmpty {
            banner = "Holding \(heldColumns.count) · SPIN respin the rest"
            return
        }
        var text = "Jackpot \(jackpot)"
        if winStreak >= 1 {
            text += " · Streak ×\(comboMultiplier) · hot diagonals"
        } else if nudgesLeft > 0 {
            text += " · HOLD or NUDGE"
        } else {
            text += " · match 3 in a row"
        }
        banner = text
    }

    private func isFeaturedWin(_ result: SpinResult) -> Bool {
        result.jackpotHit || result.freeAwarded > 0 || result.extraStageSpins > 0 || result.amount >= bet * 10
    }

    private func celebrate(_ result: SpinResult, multiplier: Int) {
        presentBurst(result, multiplier: multiplier)
        audio.win()
        haptic(.heavy)
        if isFeaturedWin(result) {
            showWinBurst = true
            coinFlash = false
        } else {
            showWinBurst = false
            coinFlash = true
        }
    }

    private func presentBurst(_ result: SpinResult, multiplier: Int) {
        if result.jackpotHit {
            burstTitle = "JACKPOT"
            burstSubtitle = result.freeAwarded > 0 ? "Free spins +\(result.freeAwarded)" : "Lucky 7s take the pot"
        } else if result.freeAwarded > 0, result.amount == 0 {
            burstTitle = "FREE SPINS"
            burstSubtitle = "Stars scatter · free +\(result.freeAwarded)"
        } else if result.freeAwarded > 0 {
            burstTitle = "LUCKY WIN"
            burstSubtitle = "Free spins +\(result.freeAwarded)"
        } else if result.extraStageSpins > 0 {
            burstTitle = "EXTRA SPINS"
            burstSubtitle = "Marquee extra +\(result.extraStageSpins)"
        } else if multiplier > 1 {
            burstTitle = "STREAK ×\(multiplier)"
            burstSubtitle = "Tap to continue"
        } else {
            burstTitle = "LUCKY WIN"
            burstSubtitle = "Tap to continue"
        }
        banner = result.jackpotHit ? "Jackpot hit \(result.amount)" : "Won \(result.amount)"
        if result.amount == 0, result.freeAwarded > 0 {
            banner = "Free spins +\(result.freeAwarded)"
        }
    }

    private var activeRules: SpinRules {
        if mode == .stage, let stage = currentStage {
            return SpinRules(diagonals: stage.diagonals, wildStar: stage.wildStar, payoutScale: stage.payoutScale)
        }
        if freeSpinsLeft > 0 {
            return SpinRules(diagonals: true, wildStar: true, payoutScale: 1)
        }
        if winStreak >= 1 {
            return SpinRules(diagonals: true, wildStar: false, payoutScale: 1)
        }
        return SpinRules(diagonals: false, wildStar: false, payoutScale: 1)
    }

    private func payout(for grid: [[SlotSymbol]], multiplier: Int, rules: SpinRules) -> SpinResult {
        var result = SpinResult()
        var near: String?

        for line in rules.lines {
            let symbols = line.map { grid[$0.0][$0.1] }
            if let symbol = matchedSymbol(symbols, wildStar: rules.wildStar) {
                result.amount += bet * symbol.lineMultiplier * rules.payoutScale * multiplier
                if mode == .classic, symbols.allSatisfy({ $0 == .seven }) {
                    result.jackpotHit = true
                }
                for (row, col) in line {
                    result.cells.insert(row * 3 + col)
                }
            } else if near == nil, let hint = nearMissHint(symbols) {
                near = hint
            }
        }

        result.scatterStars = grid.flatMap { $0 }.filter { $0 == .star }.count
        if result.scatterStars >= 3 {
            if mode == .classic {
                switch result.scatterStars {
                case 3: result.freeAwarded = 5
                case 4: result.freeAwarded = 8
                default: result.freeAwarded = 12
                }
            } else {
                result.extraStageSpins = result.scatterStars >= 5 ? 3 : 2
            }
        }
        if result.amount == 0 {
            result.nearMiss = near
        }
        return result
    }

    private func nearMissHint(_ symbols: [SlotSymbol]) -> String? {
        guard symbols.count == 3 else { return nil }
        if symbols[0] == symbols[1], symbols[1] != symbols[2] {
            return "So close · one more \(symbols[0].title)"
        }
        if symbols[1] == symbols[2], symbols[0] != symbols[1] {
            return "So close · one more \(symbols[1].title)"
        }
        return nil
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

    private static func mixedGrid(holding: Set<Int>, snapshot: [[SlotSymbol]]) -> [[SlotSymbol]] {
        var grid = freshGrid()
        for c in holding {
            for r in 0..<3 {
                grid[r][c] = snapshot[r][c]
            }
        }
        return grid
    }

    private static func dayKey(offset: Int = 0) -> String {
        let cal = Calendar.current
        let date = cal.date(byAdding: .day, value: offset, to: Date()) ?? Date()
        let parts = cal.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }

    static func mockGrid() -> [[SlotSymbol]] {
        [
            [.cherry, .lemon, .orange],
            [.grape, .melon, .bell],
            [.star, .bar, .seven]
        ]
    }
}
