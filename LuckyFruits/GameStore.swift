import SwiftUI
import UIKit

enum AppRoute {
    case loading, home, modes, stages, game
}

enum PlayMode {
    case classic, stage
}

enum SlotSymbol: String, CaseIterable, Identifiable, Codable {
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
    var matchedSymbols: [SlotSymbol] = []
    var lineCount: Int = 0
}

struct HarvestOrder: Identifiable, Equatable, Codable {
    enum Kind: String, Codable {
        case lineSymbol, multiLine, stars, swapWin
    }

    var id: UUID
    var kind: Kind
    var symbol: SlotSymbol?
    var need: Int
    var have: Int
    var reward: Int
    var title: String
    var detail: String

    var done: Bool { have >= need }
    var progress: String { "\(min(have, need))/\(need)" }
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
    @Published var swapsLeft = 0
    @Published var swapPicked: Int?
    @Published var orders: [HarvestOrder] = []
    @Published var album: Set<String> = []
    @Published var blendCharge = 0
    @Published var blendWild: SlotSymbol?
    @Published var blendSpinsLeft = 0
    @Published var showBlendPick = false
    @Published var showAlbum = false
    @Published var lastOrderClear: String?

    let bets = [10, 50, 100]
    let blendMax = 8
    private let defaults = UserDefaults.standard
    let audio = SoundHub()
    private var savedClassicBet: Int
    private var spinGeneration = 0
    private let jackpotSeed = 200
    private var settleRules = SpinRules(diagonals: false, wildStar: false, payoutScale: 1)
    private var settleMult = 1
    private var pendingBlendPick = false
    private var albumBonusClaimed = false
    private static let dailyRewards = [80, 120, 180, 250, 350, 500, 800]

    var inBonus: Bool { mode == .classic && freeSpinsLeft > 0 }

    var canHold: Bool { !isSpinning && stageEnd == nil && !showWinBurst && !showBlendPick }

    var canSwap: Bool { canHold && swapsLeft > 0 }

    var albumCount: Int { album.count }

    var blendLabel: String {
        if let wild = blendWild, blendSpinsLeft > 0 {
            return "Wild \(wild.title) · \(blendSpinsLeft)"
        }
        return "Blend \(blendCharge)/\(blendMax)"
    }

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
        album = Set(defaults.stringArray(forKey: "lf.album") ?? [])
        albumBonusClaimed = defaults.bool(forKey: "lf.album.bonus")
        blendCharge = min(blendMax, max(0, defaults.integer(forKey: "lf.blend.charge")))
        if let raw = defaults.string(forKey: "lf.blend.wild"), let wild = SlotSymbol(rawValue: raw) {
            blendWild = wild
            blendSpinsLeft = max(0, defaults.integer(forKey: "lf.blend.spins"))
        }
        if let data = defaults.data(forKey: "lf.orders"),
           let saved = try? JSONDecoder().decode([HarvestOrder].self, from: data) {
            orders = saved.filter { !$0.done }
        }
        refillOrders()
    }

    var canSpin: Bool {
        if isSpinning || showBlendPick || showWinBurst { return false }
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
        defaults.set(Array(album), forKey: "lf.album")
        defaults.set(albumBonusClaimed, forKey: "lf.album.bonus")
        defaults.set(blendCharge, forKey: "lf.blend.charge")
        defaults.set(blendWild?.rawValue, forKey: "lf.blend.wild")
        defaults.set(blendSpinsLeft, forKey: "lf.blend.spins")
        if let data = try? JSONEncoder().encode(orders) {
            defaults.set(data, forKey: "lf.orders")
        }
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
        clearSwap()
        lastOrderClear = nil
        refillOrders()
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
        clearSwap()
        lastOrderClear = nil
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
        clearSwap()
        showBlendPick = false
        pendingBlendPick = false
        route = mode == .stage ? .stages : .home
    }

    func exitToStageMap() {
        stopReelMotion()
        stageEnd = nil
        showWinBurst = false
        heldColumns = []
        clearSwap()
        showBlendPick = false
        pendingBlendPick = false
        route = .stages
    }

    func dismissWinBurst() {
        showWinBurst = false
        coinFlash = false
        if pendingBlendPick {
            pendingBlendPick = false
            showBlendPick = true
        } else if mode == .stage, stageEnd == nil {
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
        clearSwap()
        orders = []
        blendCharge = 0
        blendWild = nil
        blendSpinsLeft = 0
        showBlendPick = false
        pendingBlendPick = false
        lastOrderClear = nil
        refillOrders()
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

    func tapCell(_ index: Int) {
        guard canSwap, (0..<9).contains(index) else { return }
        if swapPicked == index {
            swapPicked = nil
            audio.click()
            return
        }
        guard let first = swapPicked else {
            swapPicked = index
            banner = "Swap with another fruit"
            audio.click()
            haptic(.light)
            return
        }
        let ra = first / 3
        let ca = first % 3
        let rb = index / 3
        let cb = index % 3
        var next = grid
        let saved = next[ra][ca]
        next[ra][ca] = next[rb][cb]
        next[rb][cb] = saved
        grid = next
        swapsLeft = 0
        swapPicked = nil
        audio.tick()
        haptic(.rigid)
        settleLandedGrid(
            playingStage: mode == .stage,
            stageAtStart: stageIndex,
            consumeHolds: false,
            grantSwap: false,
            usedSwap: true
        )
    }

    func pickBlend(_ symbol: SlotSymbol) {
        guard showBlendPick else { return }
        blendWild = symbol
        blendSpinsLeft = 3
        blendCharge = 0
        showBlendPick = false
        pendingBlendPick = false
        persist()
        audio.win()
        haptic(.heavy)
        banner = "Blend wild \(symbol.title) · next 3 spins"
    }

    private func clearSwap() {
        swapsLeft = 0
        swapPicked = nil
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
        swapPicked = nil
        swapsLeft = 0
        lastOrderClear = nil

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
        settleLandedGrid(playingStage: playingStage, stageAtStart: stageAtStart, consumeHolds: true, grantSwap: true, usedSwap: false)
        isSpinning = false
    }

    private func settleLandedGrid(playingStage: Bool, stageAtStart: Int, consumeHolds: Bool, grantSwap: Bool, usedSwap: Bool) {
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
        } else if grantSwap {
            winStreak = 0
        }

        let albumComplete = stampAlbum(result.matchedSymbols)
        chargeBlend(result.lineCount)
        if !playingStage {
            creditOrders(result, usedSwap: usedSwap)
        }

        if playingStage {
            guard mode == .stage, stageIndex == stageAtStart else { return }
            stageWon += result.amount
            if result.amount > 0 || result.extraStageSpins > 0 || albumComplete {
                celebrate(result, multiplier: settleMult, albumComplete: albumComplete)
            }
            resolveStageEnd()
            if stageEnd == nil, result.amount == 0, result.extraStageSpins == 0 {
                if let miss = result.nearMiss {
                    banner = grantSwap ? "\(miss) · SWAP two fruits" : miss
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
                celebrate(result, multiplier: settleMult, albumComplete: albumComplete)
            } else if result.freeAwarded > 0 || albumComplete {
                celebrate(result, multiplier: settleMult, albumComplete: albumComplete)
            } else if let miss = result.nearMiss {
                banner = grantSwap ? "\(miss) · SWAP two fruits" : miss
                haptic(.light)
            } else {
                refreshClassicBanner()
                haptic(.light)
            }
            persist()
        }

        if consumeHolds { heldColumns = [] }
        if grantSwap {
            swapsLeft = (result.amount == 0 && result.freeAwarded == 0 && result.extraStageSpins == 0 && stageEnd == nil) ? 1 : 0
        } else if result.amount > 0 {
            swapsLeft = 0
        }
        if result.amount > 0 { heldColumns = [] }
        if grantSwap, blendWild != nil {
            blendSpinsLeft -= 1
            if blendSpinsLeft <= 0 {
                blendWild = nil
                blendSpinsLeft = 0
            }
        }
        presentBlendPickIfReady()
        persist()
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
        } else if swapsLeft > 0 {
            banner = "SWAP two fruits or HOLD a reel"
        } else if mode == .stage {
            refreshStageBanner()
        } else {
            refreshClassicBanner()
        }
    }

    private func refreshStageBanner() {
        guard let stage = currentStage else { return }
        var text = "Stage \(stageIndex + 1) \(stage.name) · \(stageSpinsLeft) left"
        if let wild = blendWild, blendSpinsLeft > 0 {
            text += " · wild \(wild.title)"
        } else if winStreak >= 1 {
            text += " · Streak ×\(comboMultiplier)"
        } else if swapsLeft > 0 {
            text += " · SWAP / HOLD"
        }
        banner = text
    }

    private func refreshClassicBanner() {
        if let note = lastOrderClear {
            banner = note
            return
        }
        if freeSpinsLeft > 0 {
            banner = "Free spins \(freeSpinsLeft) · wild stars · diagonals"
            return
        }
        if let wild = blendWild, blendSpinsLeft > 0 {
            banner = "Blend wild \(wild.title) · \(blendSpinsLeft) left"
            return
        }
        if !heldColumns.isEmpty {
            banner = "Holding \(heldColumns.count) · SPIN respin the rest"
            return
        }
        var text = "Jackpot \(jackpot) · \(blendLabel)"
        if winStreak >= 1 {
            text += " · Streak ×\(comboMultiplier)"
        } else if swapsLeft > 0 {
            text += " · SWAP two fruits"
        }
        banner = text
    }

    private func isFeaturedWin(_ result: SpinResult) -> Bool {
        result.jackpotHit || result.freeAwarded > 0 || result.extraStageSpins > 0 || result.amount >= bet * 10
    }

    private func celebrate(_ result: SpinResult, multiplier: Int, albumComplete: Bool = false) {
        presentBurst(result, multiplier: multiplier, albumComplete: albumComplete)
        audio.win()
        haptic(.heavy)
        if albumComplete || isFeaturedWin(result) {
            showWinBurst = true
            coinFlash = false
        } else {
            showWinBurst = false
            coinFlash = true
        }
    }

    private func presentBurst(_ result: SpinResult, multiplier: Int, albumComplete: Bool) {
        if albumComplete {
            burstTitle = "ALBUM"
            burstSubtitle = "Every fruit harvested · +400"
            banner = "Album complete · +400"
            return
        }
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
        var wilds = Set<SlotSymbol>()
        if rules.wildStar { wilds.insert(.star) }
        if let extra = blendWild { wilds.insert(extra) }

        for line in rules.lines {
            let symbols = line.map { grid[$0.0][$0.1] }
            if let symbol = matchedSymbol(symbols, wilds: wilds) {
                result.amount += bet * symbol.lineMultiplier * rules.payoutScale * multiplier
                result.lineCount += 1
                result.matchedSymbols.append(symbol)
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

    private func matchedSymbol(_ symbols: [SlotSymbol], wilds: Set<SlotSymbol>) -> SlotSymbol? {
        if !wilds.isEmpty {
            let concrete = symbols.filter { !wilds.contains($0) }
            if concrete.isEmpty { return symbols.first { !wilds.contains($0) } ?? symbols[0] }
            let first = concrete[0]
            guard concrete.allSatisfy({ $0 == first }) else { return nil }
            return first
        }
        guard symbols.count == 3, symbols[0] == symbols[1], symbols[1] == symbols[2] else { return nil }
        return symbols[0]
    }

    @discardableResult
    private func stampAlbum(_ symbols: [SlotSymbol]) -> Bool {
        var unlocked = false
        for symbol in symbols where album.insert(symbol.rawValue).inserted {
            unlocked = true
        }
        guard unlocked else { return false }
        var completed = false
        if album.count == SlotSymbol.allCases.count, !albumBonusClaimed {
            albumBonusClaimed = true
            coins += 400
            lastWin = max(lastWin, 400)
            completed = true
        }
        persist()
        return completed
    }

    private func chargeBlend(_ lines: Int) {
        guard lines > 0, blendSpinsLeft == 0, blendWild == nil else { return }
        blendCharge = min(blendMax, blendCharge + lines)
    }

    private func presentBlendPickIfReady() {
        guard blendCharge >= blendMax, blendSpinsLeft == 0, blendWild == nil, stageEnd == nil else { return }
        if showWinBurst {
            pendingBlendPick = true
        } else {
            showBlendPick = true
        }
    }

    private func creditOrders(_ result: SpinResult, usedSwap: Bool) {
        guard mode == .classic else { return }
        var payout = 0
        var names: [String] = []
        for index in orders.indices {
            guard !orders[index].done else { continue }
            var add = 0
            switch orders[index].kind {
            case .lineSymbol:
                if let symbol = orders[index].symbol {
                    add = result.matchedSymbols.filter { $0 == symbol }.count
                }
            case .multiLine:
                if result.lineCount >= 2 { add = 1 }
            case .stars:
                if result.scatterStars >= 3 { add = 1 }
            case .swapWin:
                if usedSwap, result.amount > 0 { add = 1 }
            }
            guard add > 0 else { continue }
            orders[index].have = min(orders[index].need, orders[index].have + add)
            if orders[index].done {
                payout += orders[index].reward
                names.append(orders[index].title)
            }
        }
        if payout > 0 {
            coins += payout
            lastOrderClear = names.count == 1
                ? "Order \(names[0]) · +\(payout)"
                : "Orders cleared · +\(payout)"
            coinFlash = true
        }
        orders.removeAll { $0.done }
        refillOrders()
        persist()
    }

    private func refillOrders() {
        var guardCount = 0
        while orders.count < 3, guardCount < 12 {
            guardCount += 1
            if let next = spawnOrder() {
                orders.append(next)
            } else {
                break
            }
        }
    }

    private func spawnOrder() -> HarvestOrder? {
        var pool: [HarvestOrder] = []
        for symbol in SlotSymbol.allCases {
            if orders.contains(where: { $0.kind == .lineSymbol && $0.symbol == symbol }) { continue }
            let need = (symbol == .cherry || symbol == .lemon || symbol == .orange) ? 2 : 1
            pool.append(
                HarvestOrder(
                    id: UUID(),
                    kind: .lineSymbol,
                    symbol: symbol,
                    need: need,
                    have: 0,
                    reward: 40 + symbol.lineMultiplier * 12,
                    title: symbol.title,
                    detail: need > 1 ? "Match \(need) \(symbol.title) lines" : "Match a \(symbol.title) line"
                )
            )
        }
        if !orders.contains(where: { $0.kind == .multiLine }) {
            pool.append(
                HarvestOrder(
                    id: UUID(), kind: .multiLine, symbol: nil, need: 1, have: 0, reward: 110,
                    title: "Twin lines", detail: "Pay 2 lines in one spin"
                )
            )
        }
        if !orders.contains(where: { $0.kind == .stars }) {
            pool.append(
                HarvestOrder(
                    id: UUID(), kind: .stars, symbol: .star, need: 1, have: 0, reward: 90,
                    title: "Star party", detail: "Land 3 stars anywhere"
                )
            )
        }
        if !orders.contains(where: { $0.kind == .swapWin }) {
            pool.append(
                HarvestOrder(
                    id: UUID(), kind: .swapWin, symbol: nil, need: 1, have: 0, reward: 120,
                    title: "Puzzle pay", detail: "Complete a line with a SWAP"
                )
            )
        }
        return pool.randomElement()
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
