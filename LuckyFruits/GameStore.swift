import SwiftUI
import UIKit

enum AppRoute: Equatable {
    case loading, home, modes, stages, game, window, crush, chase
}

enum PlayMode {
    case classic, bet, stage
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
            .cherry, .cherry, .cherry, .cherry, .cherry,
            .lemon, .lemon, .lemon, .lemon,
            .orange, .orange, .orange,
            .grape, .grape, .grape,
            .melon, .melon, .bell, .bell,
            .star, .star, .bar, .seven
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
    var rows: Bool = true
    var maxLocks: Int = 5
    var allowSwap: Bool = true
    var onlySymbol: SlotSymbol? = nil

    static let campaign: [StageDef] = [
        StageDef(id: 0, name: "Cherry Warmup", blurb: "Serve 20 on rows in 28 restocks", spins: 28, bet: 10, target: 20, reward: 100, diagonals: false, wildStar: false, payoutScale: 1),
        StageDef(id: 1, name: "Marquee Raise", blurb: "Serve 40 on rows in 24 restocks", spins: 24, bet: 10, target: 40, reward: 120, diagonals: false, wildStar: false, payoutScale: 1),
        StageDef(id: 2, name: "Diagonals On", blurb: "Diagonals count · serve 50 in 18", spins: 18, bet: 10, target: 50, reward: 150, diagonals: true, wildStar: false, payoutScale: 1),
        StageDef(id: 3, name: "Wild Stars", blurb: "Stars are wild · serve 180 in 16", spins: 16, bet: 10, target: 180, reward: 180, diagonals: true, wildStar: true, payoutScale: 1),
        StageDef(id: 4, name: "Double Lights", blurb: "5-line serves ×2 · 80 in 14", spins: 14, bet: 10, target: 80, reward: 220, diagonals: true, wildStar: false, payoutScale: 2),
        StageDef(id: 5, name: "High Heat", blurb: "Richer dishes · serve 150 in 16", spins: 16, bet: 50, target: 150, reward: 300, diagonals: false, wildStar: false, payoutScale: 1),
        StageDef(id: 6, name: "Star Cross", blurb: "Diagonals + wilds · serve 1000 in 14", spins: 14, bet: 50, target: 1000, reward: 450, diagonals: true, wildStar: true, payoutScale: 1),
        StageDef(id: 7, name: "Full House", blurb: "Diagonals + wilds + ×2 · 1800 in 12", spins: 12, bet: 50, target: 1800, reward: 800, diagonals: true, wildStar: true, payoutScale: 2),
        StageDef(id: 8, name: "Cherry Ticket", blurb: "Only Cherry lines score · 80 in 18", spins: 18, bet: 10, target: 80, reward: 260, diagonals: false, wildStar: false, payoutScale: 1, onlySymbol: .cherry),
        StageDef(id: 9, name: "Tight Keep", blurb: "Keep 2 fruits max · serve 120 in 14", spins: 14, bet: 10, target: 120, reward: 300, diagonals: false, wildStar: false, payoutScale: 1, maxLocks: 2),
        StageDef(id: 10, name: "Cross Only", blurb: "Only diagonals score · 80 in 16", spins: 16, bet: 10, target: 80, reward: 340, diagonals: true, wildStar: true, payoutScale: 1, rows: false),
        StageDef(id: 11, name: "No Swap", blurb: "No swapping · serve 100 in 14", spins: 14, bet: 10, target: 100, reward: 400, diagonals: false, wildStar: false, payoutScale: 1, allowSwap: false)
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
        case lineSymbol, multiLine, stars, swapWin, coverShift
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
    var rows: Bool = true
    var diagonals: Bool
    var wildStar: Bool
    var payoutScale: Int
    var onlySymbol: SlotSymbol? = nil

    var lines: [[(Int, Int)]] {
        var value: [[(Int, Int)]] = []
        if rows {
            value.append(contentsOf: [
                [(0, 0), (0, 1), (0, 2)],
                [(1, 0), (1, 1), (1, 2)],
                [(2, 0), (2, 1), (2, 2)]
            ])
        }
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
    @Published var lockedCells: Set<Int> = []
    @Published var swapsLeft = 0
    @Published var swapPicked: Int?
    @Published var swapMode = false
    @Published var canServe = false
    @Published var orders: [HarvestOrder] = []
    @Published var menu: [HarvestOrder] = []
    @Published var shiftNumber = 1
    @Published var album: Set<String> = []
    @Published var blendCharge = 0
    @Published var blendWild: SlotSymbol?
    @Published var blendSpinsLeft = 0
    @Published var showBlendPick = false
    @Published var showAlbum = false
    @Published var showCoach = false
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
    private var swappedThisRound = false
    private var warmRestock = false
    private var coachToken = 0
    private static let dailyRewards = [80, 120, 180, 250, 350, 500, 800]

    var inBonus: Bool { false }

    var canAct: Bool { !isSpinning && stageEnd == nil && !showWinBurst && !showBlendPick }

    var canSwap: Bool { canAct && swapMode && swapsLeft > 0 }

    var maxLocks: Int {
        if mode == .stage, let stage = currentStage { return stage.maxLocks }
        return 5
    }

    private var stageAllowsSwap: Bool {
        if mode == .stage, currentStage?.allowSwap == false { return false }
        return true
    }

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
        let storedShift = defaults.integer(forKey: "lf.shift")
        shiftNumber = max(1, storedShift)
        if let data = defaults.data(forKey: "lf.menu"),
           let saved = try? JSONDecoder().decode([HarvestOrder].self, from: data),
           saved.contains(where: { !$0.done }) {
            menu = saved
        } else {
            menu = makeMenu(for: shiftNumber)
        }
        syncCoverShift()
    }

    var canSpin: Bool {
        if isSpinning || showBlendPick || showWinBurst { return false }
        if lockedCells.count >= 9 { return false }
        if mode == .stage {
            return stageEnd == nil && stageSpinsLeft > 0
        }
        return true
    }

    var isWager: Bool { mode == .bet }

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
        defaults.set(shiftNumber, forKey: "lf.shift")
        if let data = try? JSONEncoder().encode(menu) {
            defaults.set(data, forKey: "lf.menu")
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
        lockedCells = []
        clearSwap()
        swapMode = false
        canServe = false
        lastOrderClear = nil
        refillOrders()
        bet = 10
        grid = Self.starterGrid()
        warmRestock = true
        previewBoard()
        syncCoverShift()
        if orders.contains(where: { $0.kind == .coverShift && !$0.done }) {
            banner = "Score under 100 · serve 2 plates for +120"
        }
        route = .game
        presentCoach()
    }

    func openBet() {
        stopReelMotion()
        mode = .bet
        stageEnd = nil
        showWinBurst = false
        hitCells = []
        freeSpinsLeft = 0
        winStreak = 0
        lockedCells = []
        clearSwap()
        swapMode = false
        canServe = false
        lastOrderClear = nil
        refillOrders()
        bet = savedClassicBet
        grid = Self.starterGrid()
        warmRestock = true
        previewBoard()
        banner = "Bet \(bet) · restock costs \(bet)"
        route = .game
        presentCoach()
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
        lockedCells = []
        clearSwap()
        swapMode = false
        canServe = false
        lastOrderClear = nil
        bet = stage.bet
        grid = GameStore.mockGrid()
        previewBoard()
        refreshStageBanner()
        route = .game
        presentCoach()
    }

    func leaveGame() {
        stopReelMotion()
        showWinBurst = false
        stageEnd = nil
        freeSpinsLeft = 0
        winStreak = 0
        lockedCells = []
        clearSwap()
        swapMode = false
        canServe = false
        showBlendPick = false
        pendingBlendPick = false
        dismissCoach()
        route = mode == .stage ? .stages : .home
    }

    func exitToStageMap() {
        stopReelMotion()
        stageEnd = nil
        showWinBurst = false
        lockedCells = []
        clearSwap()
        swapMode = false
        canServe = false
        showBlendPick = false
        pendingBlendPick = false
        route = .stages
    }

    func presentCoach() {
        coachToken += 1
        let token = coachToken
        showCoach = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            guard coachToken == token else { return }
            showCoach = false
        }
    }

    func dismissCoach() {
        coachToken += 1
        showCoach = false
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
        guard isWager, !isSpinning else { return }
        bet = value
        savedClassicBet = bet
        persist()
        audio.click()
        haptic(.light)
        banner = "Bet \(bet) · restock costs \(bet)"
    }

    func toggleSwapMode() {
        guard canAct else { return }
        if mode == .stage, currentStage?.allowSwap == false {
            banner = "No swaps this stage"
            audio.click()
            return
        }
        if swapsLeft <= 0 {
            banner = "Restock to earn a swap"
            audio.click()
            return
        }
        swapMode.toggle()
        swapPicked = nil
        audio.click()
        haptic(.light)
        banner = swapMode ? "Tap two fruits to swap" : "Swap off · lock fruits or serve"
    }

    func clearLocks() {
        guard canAct else { return }
        lockedCells = []
        audio.click()
        haptic(.light)
        banner = "Locks cleared"
    }

    func serve() {
        guard canAct, canServe else {
            banner = "Make a 3-match, then SERVE"
            audio.click()
            return
        }
        let rules = activeRules
        let result = payout(for: grid, multiplier: comboMultiplier, rules: rules)
        guard result.lineCount > 0 else {
            canServe = false
            audio.click()
            return
        }
        applyServe(result)
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
        lockedCells = []
        clearSwap()
        swapMode = false
        canServe = false
        orders = []
        shiftNumber = 1
        menu = makeMenu(for: 1)
        blendCharge = 0
        blendWild = nil
        blendSpinsLeft = 0
        showBlendPick = false
        pendingBlendPick = false
        lastOrderClear = nil
        refillOrders()
        syncCoverShift()
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
        syncCoverShift()
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

    func tapCell(_ index: Int) {
        guard canAct, (0..<9).contains(index) else { return }
        if swapMode, swapsLeft > 0 {
            performSwap(index)
            return
        }
        toggleLock(index)
    }

    private func toggleLock(_ index: Int) {
        if lockedCells.contains(index) {
            lockedCells.remove(index)
        } else if lockedCells.count >= maxLocks {
            banner = "Keep \(maxLocks) fruits max"
            audio.click()
            return
        } else {
            lockedCells.insert(index)
        }
        audio.click()
        haptic(.light)
        banner = lockedCells.isEmpty
            ? "Tap fruits to keep them"
            : "Keeping \(lockedCells.count) · RESTOCK the rest"
    }

    private func performSwap(_ index: Int) {
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
        swapMode = false
        swappedThisRound = true
        audio.tick()
        haptic(.rigid)
        previewBoard()
        if mode == .stage, stageSpinsLeft <= 0, !canServe {
            resolveStageEnd()
        } else {
            banner = canServe ? "Line ready · SERVE it" : "No line yet · lock and restock"
        }
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
        banner = "Chef wild \(symbol.title) · next 3 restocks"
    }

    private func clearSwap() {
        swapsLeft = 0
        swapPicked = nil
        swapMode = false
    }

    func spin() async {
        guard canSpin else {
            if lockedCells.count >= 9 {
                banner = "Unlock a fruit to restock"
            }
            return
        }
        if isWager, coins < bet {
            banner = "Not enough score · bet \(bet)"
            audio.click()
            return
        }

        spinGeneration += 1
        let generation = spinGeneration
        let playingStage = mode == .stage
        let stageAtStart = stageIndex
        let locks = lockedCells
        let snapshot = grid
        var refundStage = playingStage
        var chargedBet = false

        func abortIfStale() -> Bool {
            guard generation != spinGeneration else { return false }
            if chargedBet {
                coins += bet
                chargedBet = false
                persist()
            }
            if refundStage, mode == .stage, stageIndex == stageAtStart {
                stageSpinsLeft += 1
                refundStage = false
            }
            isSpinning = false
            reelBlur = 0
            spinningColumn = -1
            return true
        }

        let wastedLine = canServe
        isSpinning = true
        canServe = false
        hitCells = []
        showWinBurst = false
        swapPicked = nil
        swapMode = false
        swapsLeft = 0
        swappedThisRound = false
        lastOrderClear = nil
        if wastedLine { winStreak = 0 }

        if playingStage {
            stageSpinsLeft -= 1
        } else if isWager {
            coins -= bet
            chargedBet = true
            persist()
        }

        let landing = landingGrid(locking: locks, snapshot: snapshot)
        audio.spin()
        haptic(.rigid)
        withAnimation(.easeIn(duration: 0.12)) { reelBlur = locks.count >= 9 ? 0 : 7 }

        let moving = (0..<3).filter { col in
            (0..<3).contains { row in !locks.contains(row * 3 + col) }
        }
        for tick in 0..<22 {
            if abortIfStale() { return }
            spinningColumn = moving.isEmpty ? -1 : moving[tick % moving.count]
            grid = GameStore.mixedGrid(locking: locks, snapshot: snapshot)
            if tick % 2 == 0 { audio.tick() }
            try? await Task.sleep(nanoseconds: UInt64(26_000_000 + tick * 8_000_000))
        }

        if abortIfStale() { return }

        withAnimation(.easeOut(duration: 0.22)) { reelBlur = 0 }
        spinningColumn = -1
        grid = landing
        audio.stopReel()
        refundStage = false
        chargedBet = false
        if blendWild != nil {
            blendSpinsLeft -= 1
            if blendSpinsLeft <= 0 {
                blendWild = nil
                blendSpinsLeft = 0
            }
        }
        swapsLeft = stageAllowsSwap ? 1 : 0
        previewBoard()
        isSpinning = false
        persist()
    }

    private func landingGrid(locking: Set<Int>, snapshot: [[SlotSymbol]]) -> [[SlotSymbol]] {
        var grid = GameStore.mixedGrid(locking: locking, snapshot: snapshot)
        let wanted: [SlotSymbol] = mode == .classic
            ? menu.compactMap { $0.done ? nil : $0.symbol }
            : orders.compactMap { $0.kind == .lineSymbol ? $0.symbol : nil }
        var helped = false
        for row in 0..<3 {
            let indexes = [row * 3, row * 3 + 1, row * 3 + 2]
            let symbols = indexes.map { snapshot[$0 / 3][$0 % 3] }
            guard let pair = Self.pairSymbol(symbols),
                  let miss = symbols.indices.first(where: { symbols[$0] != pair }) else { continue }
            let index = indexes[miss]
            guard !locking.contains(index) else { continue }
            let chance = warmRestock && !helped ? 100 : 76
            if Int.random(in: 0..<100) < chance {
                grid[row][index % 3] = pair
                helped = true
            }
        }
        if !helped, Int.random(in: 0..<100) < 42 {
            let row = (0..<3).first { row in
                (0..<3).contains { col in !locking.contains(row * 3 + col) }
            } ?? 0
            let symbol = wanted.randomElement() ?? [.cherry, .lemon, .orange].randomElement() ?? .cherry
            for col in 0..<3 where !locking.contains(row * 3 + col) {
                grid[row][col] = symbol
            }
        }
        warmRestock = false
        return grid
    }

    private static func pairSymbol(_ symbols: [SlotSymbol]) -> SlotSymbol? {
        guard symbols.count == 3 else { return nil }
        if symbols[0] == symbols[1], symbols[0] != symbols[2] { return symbols[0] }
        if symbols[1] == symbols[2], symbols[0] != symbols[1] { return symbols[1] }
        if symbols[0] == symbols[2], symbols[0] != symbols[1] { return symbols[0] }
        return nil
    }

    private func previewBoard() {
        let result = payout(for: grid, multiplier: comboMultiplier, rules: activeRules)
        hitCells = result.cells
        canServe = result.lineCount > 0
        if canServe {
            banner = mode == .classic ? menuServeBanner(result) : "Line ready · SERVE, or swap for a better fruit"
        } else if let ignored = ignoredLineBanner() {
            banner = ignored
        } else if let miss = result.nearMiss {
            banner = "\(miss) · swap or restock"
        } else if mode == .stage {
            refreshStageBanner()
        } else {
            refreshClassicBanner()
        }
    }

    private func menuServeBanner(_ result: SpinResult) -> String {
        let open = menu.filter { !$0.done }
        let waiting = open.first?.title ?? "the menu"
        let onMenu = result.matchedSymbols.contains { symbol in
            open.contains { $0.symbol == symbol }
        }
        if onMenu { return "On the menu · SERVE" }
        let name = result.matchedSymbols.first?.title ?? "This line"
        return "\(name) is off the menu · wants \(waiting)"
    }

    private func ignoredLineBanner() -> String? {
        guard mode == .stage, let stage = currentStage else { return nil }
        if let only = stage.onlySymbol {
            let any = payout(
                for: grid,
                multiplier: 1,
                rules: SpinRules(diagonals: stage.diagonals, wildStar: stage.wildStar, payoutScale: 1)
            )
            if any.lineCount > 0 { return "Only \(only.title) lines score" }
        }
        if !stage.rows {
            let rows = payout(
                for: grid,
                multiplier: 1,
                rules: SpinRules(rows: true, diagonals: false, wildStar: stage.wildStar, payoutScale: 1)
            )
            if rows.lineCount > 0 { return "Rows do not count · serve a diagonal" }
        }
        return nil
    }

    private func applyServe(_ result: SpinResult) {
        lastWin = result.amount
        hitCells = result.cells
        let albumComplete = stampAlbum(result.matchedSymbols)
        chargeBlend(result.lineCount)
        creditOrders(result, usedSwap: swappedThisRound)
        let menuCredit = creditMenu(result)
        let covered = creditCoverShift()
        swappedThisRound = false
        let servedMult = comboMultiplier
        if mode == .stage {
            stageWon += result.amount
            celebrate(result, multiplier: servedMult, albumComplete: albumComplete)
        } else {
            coins += result.amount + menuCredit.bonus
            celebrate(result, multiplier: servedMult, albumComplete: albumComplete)
        }
        winStreak += 1
        if mode == .stage {
            resolveStageEnd()
        }

        var next = grid
        for cell in result.cells {
            next[cell / 3][cell % 3] = SlotSymbol.randomSpin()
            lockedCells.remove(cell)
        }
        grid = next
        swapsLeft = stageAllowsSwap ? 1 : 0
        swapMode = false
        swapPicked = nil
        if stageEnd == nil {
            previewBoard()
        }
        syncCoverShift()
        if covered {
            banner = "Cover shift · +120"
        } else if mode == .classic, let note = menuCredit.note {
            banner = note
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
            let tip = max(40, (stage.reward * 3) / 10)
            if first {
                clearedStages = stageIndex + 1
                coins += stage.reward
            } else {
                coins += tip
            }
            persist()
            let lastIndex = StageDef.campaign.count - 1
            stageEnd = StageEnd(
                cleared: true,
                reward: first ? stage.reward : tip,
                firstClear: first,
                finale: first && stageIndex == lastIndex,
                got: stageWon,
                target: stage.target,
                stageName: stage.name,
                hasNext: first && stageIndex < lastIndex
            )
            banner = first ? "Cleared · +\(stage.reward)" : "Replay tip · +\(tip)"
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

    private func refreshStageBanner() {
        guard let stage = currentStage else { return }
        var text = "Stage \(stageIndex + 1) \(stage.name) · \(stageSpinsLeft) restocks"
        if let only = stage.onlySymbol {
            text = "Only \(only.title) · \(stageSpinsLeft) restocks"
        } else if !stage.rows {
            text = "Diagonals only · \(stageSpinsLeft) restocks"
        } else if !stage.allowSwap {
            text = "No swap · \(stageSpinsLeft) restocks"
        } else if stage.maxLocks < 5 {
            text = "Keep \(stage.maxLocks) max · \(stageSpinsLeft) restocks"
        }
        if let wild = blendWild, blendSpinsLeft > 0 {
            text += " · wild \(wild.title)"
        } else if canServe {
            text += " · SERVE a line"
        } else if winStreak >= 1 {
            text += " · Combo ×\(comboMultiplier)"
        }
        banner = text
    }

    private func refreshClassicBanner() {
        if let note = lastOrderClear {
            banner = note
            return
        }
        if let wild = blendWild, blendSpinsLeft > 0 {
            banner = "Chef wild \(wild.title) · \(blendSpinsLeft) restocks"
            return
        }
        if canServe {
            banner = "Serve the line · fill kitchen orders"
            return
        }
        if !lockedCells.isEmpty {
            banner = "Keeping \(lockedCells.count) · RESTOCK the rest"
            return
        }
        banner = "Shift \(shiftNumber) · serve the menu · \(blendLabel)"
    }

    private func isFeaturedWin(_ result: SpinResult) -> Bool {
        result.lineCount >= 2 || result.amount >= 80
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
        if result.lineCount >= 2 {
            burstTitle = "DOUBLE SERVE"
            burstSubtitle = "Two dishes out"
        } else if multiplier > 1 {
            burstTitle = "COMBO ×\(multiplier)"
            burstSubtitle = "Keep serving"
        } else {
            burstTitle = "SERVED"
            burstSubtitle = result.matchedSymbols.first.map { "\($0.title) is out" } ?? "Tap to continue"
        }
        banner = "Served +\(result.amount)"
    }

    private var activeRules: SpinRules {
        if mode == .stage, let stage = currentStage {
            return SpinRules(
                rows: stage.rows,
                diagonals: stage.diagonals,
                wildStar: stage.wildStar,
                payoutScale: stage.payoutScale,
                onlySymbol: stage.onlySymbol
            )
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
                if let only = rules.onlySymbol, symbol != only { continue }
                let unit = (mode == .stage || mode == .bet) ? bet : 10
                result.amount += unit * symbol.lineMultiplier * rules.payoutScale * multiplier
                result.lineCount += 1
                result.matchedSymbols.append(symbol)
                for (row, col) in line {
                    result.cells.insert(row * 3 + col)
                }
            } else if near == nil, let hint = nearMissHint(symbols) {
                near = hint
            }
        }

        result.scatterStars = grid.flatMap { $0 }.filter { $0 == .star }.count
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

    private func creditMenu(_ result: SpinResult) -> (bonus: Int, note: String?) {
        guard mode == .classic else { return (0, nil) }
        var bonus = 0
        var plated: [String] = []
        for index in menu.indices {
            guard !menu[index].done, let symbol = menu[index].symbol else { continue }
            let add = result.matchedSymbols.filter { $0 == symbol }.count
            guard add > 0 else { continue }
            menu[index].have = min(menu[index].need, menu[index].have + add)
            bonus += 30 * add
            plated.append(symbol.title)
        }
        if !menu.isEmpty, menu.allSatisfy(\.done) {
            let clearPay = min(400, 60 + shiftNumber * 40)
            bonus += clearPay
            let finished = shiftNumber
            shiftNumber += 1
            menu = makeMenu(for: shiftNumber)
            return (bonus, "Shift \(finished) cleared · +\(bonus)")
        }
        if plated.isEmpty {
            let waiting = menu.first { !$0.done }?.title ?? "the menu"
            return (0, "Off the menu · shift wants \(waiting)")
        }
        if let waiting = menu.first(where: { !$0.done })?.title {
            return (bonus, "\(plated[0]) plated · +\(bonus) · next \(waiting)")
        }
        return (bonus, "On the menu · +\(bonus)")
    }

    private func makeMenu(for shift: Int) -> [HarvestOrder] {
        let plan: [(SlotSymbol, Int)]
        switch shift {
        case 1:
            plan = [(.cherry, 1), (.lemon, 1), (.orange, 1)]
        case 2:
            plan = [(.cherry, 2), (.lemon, 1), (.orange, 1)]
        case 3:
            plan = [(.lemon, 1), (.orange, 1), (.grape, 1)]
        case 4:
            plan = [(.orange, 2), (.grape, 1), (.melon, 1)]
        case 5:
            plan = [(.grape, 1), (.melon, 1), (.bell, 1)]
        default:
            let pool: [SlotSymbol] = [.cherry, .lemon, .orange, .grape, .melon, .bell, .star, .bar, .seven]
            let start = (shift * 2) % pool.count
            var picks: [SlotSymbol] = []
            var step = 0
            while picks.count < 3 {
                let symbol = pool[(start + step) % pool.count]
                if !picks.contains(symbol) { picks.append(symbol) }
                step += 1
            }
            let need = min(3, 1 + (shift - 5) / 2)
            plan = [(picks[0], need), (picks[1], max(1, need - 1)), (picks[2], 1)]
        }
        return plan.map { symbol, need in
            HarvestOrder(
                id: UUID(),
                kind: .lineSymbol,
                symbol: symbol,
                need: need,
                have: 0,
                reward: 30,
                title: symbol.title,
                detail: "Serve \(need)"
            )
        }
    }

    private func creditOrders(_ result: SpinResult, usedSwap: Bool) {
        guard mode == .bet else { return }
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
            case .coverShift:
                add = 0
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

    private func creditCoverShift() -> Bool {
        guard mode == .classic else { return false }
        guard let index = orders.firstIndex(where: { $0.kind == .coverShift && !$0.done }) else { return false }
        orders[index].have = min(orders[index].need, orders[index].have + 1)
        guard orders[index].done else { return false }
        coins += orders[index].reward
        orders.removeAll { $0.kind == .coverShift }
        coinFlash = true
        return true
    }

    private func syncCoverShift() {
        if let index = orders.firstIndex(where: { $0.kind == .coverShift && $0.have == 0 }), coins >= 100 {
            orders.remove(at: index)
        }
        let active = orders.contains { $0.kind == .coverShift && !$0.done }
        guard coins < 100, !active else { return }
        orders.insert(
            HarvestOrder(
                id: UUID(),
                kind: .coverShift,
                symbol: nil,
                need: 2,
                have: 0,
                reward: 120,
                title: "Cover",
                detail: "Serve 2 plates"
            ),
            at: 0
        )
    }

    private func refillOrders() {
        var guardCount = 0
        while orders.filter({ $0.kind != .coverShift }).count < 3, guardCount < 12 {
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

    private static func mixedGrid(locking: Set<Int>, snapshot: [[SlotSymbol]]) -> [[SlotSymbol]] {
        var grid = freshGrid()
        for index in locking {
            let row = index / 3
            let col = index % 3
            grid[row][col] = snapshot[row][col]
        }
        return grid
    }

    private static func dayKey(offset: Int = 0) -> String {
        let cal = Calendar.current
        let date = cal.date(byAdding: .day, value: offset, to: Date()) ?? Date()
        let parts = cal.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }

    static func starterGrid() -> [[SlotSymbol]] {
        [
            [.cherry, .cherry, .lemon],
            [.orange, .grape, .orange],
            [.lemon, .bell, .star]
        ]
    }

    static func mockGrid() -> [[SlotSymbol]] {
        starterGrid()
    }
}
