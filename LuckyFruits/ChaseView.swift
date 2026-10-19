import SwiftUI
import UIKit

private struct ChaseCell: Identifiable {
    let id: Int
    let symbol: SlotSymbol
    let asset: String
    let multiplier: Int
    let art: CGSize
}

private struct ChaseBulb {
    var x: CGFloat
    var y: CGFloat
    var asset: String
}

private enum ChaseInk {
    static let page = Color(red: 24 / 255, green: 8 / 255, blue: 15 / 255)
    static let veil = Color(red: 24 / 255, green: 5 / 255, blue: 12 / 255).opacity(0.31)
    static let goldLine = Color(red: 231 / 255, green: 185 / 255, blue: 81 / 255)
    static let cream = Color(red: 255 / 255, green: 241 / 255, blue: 198 / 255)
    static let creamBright = Color(red: 255 / 255, green: 241 / 255, blue: 184 / 255)
    static let muted = Color(red: 197 / 255, green: 169 / 255, blue: 143 / 255)
    static let rule = Color(red: 142 / 255, green: 91 / 255, blue: 43 / 255)
    static let cell = Color(red: 16 / 255, green: 11 / 255, blue: 14 / 255)
    static let cellEdge = Color(red: 128 / 255, green: 86 / 255, blue: 46 / 255)
    static let hotFill = Color(red: 100 / 255, green: 50 / 255, blue: 21 / 255)
    static let hotEdge = Color(red: 255 / 255, green: 241 / 255, blue: 166 / 255)
    static let ink = Color(red: 53 / 255, green: 13 / 255, blue: 28 / 255)
    static let wishIdle = Color(red: 23 / 255, green: 13 / 255, blue: 19 / 255)
    static let wishEdge = Color(red: 88 / 255, green: 54 / 255, blue: 36 / 255)
    static let wishOn = Color(red: 88 / 255, green: 44 / 255, blue: 23 / 255)
    static let track = Color(red: 13 / 255, green: 8 / 255, blue: 13 / 255)
    static let boardInner = Color(red: 16 / 255, green: 9 / 255, blue: 12 / 255)
    static let boardLip = Color(red: 53 / 255, green: 13 / 255, blue: 28 / 255)

    static let metal = LinearGradient(
        stops: [
            .init(color: Color(red: 1, green: 240 / 255, blue: 180 / 255), location: 0),
            .init(color: Color(red: 221 / 255, green: 168 / 255, blue: 67 / 255), location: 0.2),
            .init(color: Color(red: 144 / 255, green: 96 / 255, blue: 33 / 255), location: 0.48),
            .init(color: Color(red: 248 / 255, green: 212 / 255, blue: 123 / 255), location: 0.62),
            .init(color: Color(red: 140 / 255, green: 79 / 255, blue: 27 / 255), location: 1)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let wine = LinearGradient(
        stops: [
            .init(color: Color(red: 75 / 255, green: 23 / 255, blue: 40 / 255), location: 0),
            .init(color: Color(red: 33 / 255, green: 13 / 255, blue: 23 / 255), location: 0.5),
            .init(color: Color(red: 55 / 255, green: 17 / 255, blue: 34 / 255), location: 1)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let startFill = LinearGradient(
        stops: [
            .init(color: Color(red: 215 / 255, green: 57 / 255, blue: 72 / 255), location: 0),
            .init(color: Color(red: 157 / 255, green: 19 / 255, blue: 42 / 255), location: 0.5),
            .init(color: Color(red: 87 / 255, green: 11 / 255, blue: 26 / 255), location: 1)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

@MainActor
private final class ChaseTable: ObservableObject {
    static let wishes: [SlotSymbol] = [.cherry, .lemon, .orange, .grape, .melon]
    static let setNeed = 3
    static let setBonus = 500
    static let bets = [10, 50, 100]

    static let ring: [ChaseCell] = [
        ChaseCell(id: 0, symbol: .cherry, asset: "chaseCherry", multiplier: 5, art: CGSize(width: 55, height: 55)),
        ChaseCell(id: 1, symbol: .lemon, asset: "chaseLemon", multiplier: 5, art: CGSize(width: 55, height: 55)),
        ChaseCell(id: 2, symbol: .orange, asset: "chaseOrange", multiplier: 5, art: CGSize(width: 55, height: 55)),
        ChaseCell(id: 3, symbol: .grape, asset: "chaseGrape", multiplier: 10, art: CGSize(width: 55, height: 55)),
        ChaseCell(id: 4, symbol: .bell, asset: "chaseBell", multiplier: 20, art: CGSize(width: 55, height: 55)),
        ChaseCell(id: 5, symbol: .seven, asset: "chaseSeven", multiplier: 50, art: CGSize(width: 55, height: 50)),
        ChaseCell(id: 6, symbol: .star, asset: "chaseStar", multiplier: 30, art: CGSize(width: 55, height: 55)),
        ChaseCell(id: 7, symbol: .melon, asset: "chaseMelon", multiplier: 10, art: CGSize(width: 55, height: 55)),
        ChaseCell(id: 8, symbol: .bar, asset: "chaseBar", multiplier: 40, art: CGSize(width: 55, height: 50)),
        ChaseCell(id: 9, symbol: .orange, asset: "chaseOrange", multiplier: 5, art: CGSize(width: 55, height: 55)),
        ChaseCell(id: 10, symbol: .lemon, asset: "chaseLemon", multiplier: 5, art: CGSize(width: 55, height: 55)),
        ChaseCell(id: 11, symbol: .grape, asset: "chaseGrape", multiplier: 10, art: CGSize(width: 55, height: 55))
    ]

    static let frames: [CGRect] = [
        CGRect(x: 25, y: 25, width: 81, height: 81),
        CGRect(x: 114, y: 25, width: 81, height: 81),
        CGRect(x: 203, y: 25, width: 81, height: 81),
        CGRect(x: 292, y: 25, width: 81, height: 81),
        CGRect(x: 292, y: 114, width: 81, height: 81),
        CGRect(x: 292, y: 203, width: 81, height: 81),
        CGRect(x: 292, y: 292, width: 81, height: 81),
        CGRect(x: 203, y: 292, width: 81, height: 81),
        CGRect(x: 114, y: 292, width: 81, height: 81),
        CGRect(x: 25, y: 292, width: 81, height: 81),
        CGRect(x: 25, y: 203, width: 81, height: 81),
        CGRect(x: 25, y: 114, width: 81, height: 81)
    ]

    @Published var index = 0
    @Published var bet = 50
    @Published var wish: SlotSymbol = .cherry
    @Published var collected: [String: Int] = [:]
    @Published var running = false
    @Published var stopping = false
    @Published var note: String?

    private var ready = false
    private var stakeTaken = false
    private var task: Task<Void, Never>?
    private var noteToken = UUID()
    private let defaults = UserDefaults.standard

    var wishMultiplier: Int {
        Self.ring.first { $0.symbol == wish }?.multiplier ?? 5
    }

    var preview: Int { bet * wishMultiplier }

    var have: Int { min(Self.setNeed, collected[wish.rawValue] ?? 0) }

    func prepare() {
        guard !ready else { return }
        ready = true
        let storedBet = defaults.object(forKey: "lf.chase.bet") as? Int ?? 50
        bet = Self.bets.contains(storedBet) ? storedBet : 50
        if let raw = defaults.string(forKey: "lf.chase.wish"),
           let symbol = SlotSymbol(rawValue: raw),
           Self.wishes.contains(symbol) {
            wish = symbol
        }
        for symbol in Self.wishes {
            collected[symbol.rawValue] = min(Self.setNeed - 1, max(0, defaults.integer(forKey: "lf.chase.have.\(symbol.rawValue)")))
        }
        index = Self.ring.firstIndex { $0.symbol == wish } ?? 0
    }

    func pickWish(_ symbol: SlotSymbol, store: GameStore) {
        guard !running, Self.wishes.contains(symbol) else { return }
        store.audio.click()
        wish = symbol
        index = Self.ring.firstIndex { $0.symbol == symbol } ?? index
        save()
    }

    func pickBet(_ value: Int, store: GameStore) {
        guard !running, Self.bets.contains(value) else { return }
        store.audio.click()
        bet = value
        save()
    }

    func toggle(_ store: GameStore) {
        if running {
            guard !stopping else { return }
            stopping = true
            store.audio.click()
            return
        }
        guard store.coins >= bet else {
            show("Not enough coins for this bet.")
            store.audio.click()
            return
        }
        store.coins -= bet
        store.persist()
        stakeTaken = true
        running = true
        stopping = false
        note = nil
        store.audio.spin()
        task = Task { await loop(store) }
    }

    func settleIfNeeded(_ store: GameStore) {
        guard stakeTaken else { return }
        task?.cancel()
        task = nil
        if stopping {
            finish(store)
        } else {
            store.coins += bet
            store.persist()
            stakeTaken = false
            running = false
            stopping = false
        }
    }

    private func loop(_ store: GameStore) async {
        var delay: UInt64 = 55_000_000
        var steps = 0
        var stopAfter: Int?
        while !Task.isCancelled {
            index = (index + 1) % Self.ring.count
            if steps % 2 == 0 { store.audio.tick() }
            steps += 1
            if stopping, stopAfter == nil {
                stopAfter = steps + Int.random(in: 10...18)
            }
            if let stopAfter, steps >= stopAfter { break }
            try? await Task.sleep(nanoseconds: delay)
            if Task.isCancelled { break }
            if stopping { delay = min(delay + 22_000_000, 240_000_000) }
        }
        finish(store)
    }

    private func finish(_ store: GameStore) {
        guard stakeTaken else {
            running = false
            stopping = false
            return
        }
        stakeTaken = false
        running = false
        stopping = false
        task = nil
        let cell = Self.ring[index]
        let win = bet * cell.multiplier
        store.coins += win
        var lines = ["\(cell.symbol.title) ×\(cell.multiplier) · +\(win)"]
        if cell.symbol == wish {
            let next = (collected[wish.rawValue] ?? 0) + 1
            if next >= Self.setNeed {
                collected[wish.rawValue] = 0
                store.coins += Self.setBonus
                lines.append("\(wish.title) set complete · +\(Self.setBonus)")
            } else {
                collected[wish.rawValue] = next
            }
        }
        store.persist()
        save()
        store.audio.stopReel()
        store.audio.win()
        if store.hapticEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        show(lines.joined(separator: "   "))
    }

    private func show(_ text: String) {
        let token = UUID()
        noteToken = token
        note = text
        Task {
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            if noteToken == token { note = nil }
        }
    }

    private func save() {
        defaults.set(bet, forKey: "lf.chase.bet")
        defaults.set(wish.rawValue, forKey: "lf.chase.wish")
        for symbol in Self.wishes {
            defaults.set(collected[symbol.rawValue] ?? 0, forKey: "lf.chase.have.\(symbol.rawValue)")
        }
    }

    static var bulbs: [ChaseBulb] {
        let xs: [CGFloat] = [18.5, 45.7, 72.9, 100.1, 127.3, 154.5, 181.7, 208.9, 236.1, 263.3, 290.5, 317.7, 344.9, 372.1]
        let ys: [CGFloat] = [45.7, 72.9, 100.1, 127.3, 154.5, 181.7, 208.9, 236.1, 263.3, 290.5, 317.7, 344.9]
        var items: [ChaseBulb] = []
        for (i, x) in xs.enumerated() {
            items.append(ChaseBulb(x: x, y: 8, asset: i % 3 == 0 ? "chaseBulbA" : "chaseBulbB"))
        }
        for (i, x) in xs.enumerated() {
            items.append(ChaseBulb(x: x, y: 383, asset: i % 3 == 0 ? "chaseBulbC" : "chaseBulbD"))
        }
        for (i, y) in ys.enumerated() {
            items.append(ChaseBulb(x: 8, y: y, asset: i % 3 == 0 ? "chaseBulbC" : "chaseBulbD"))
        }
        for (i, y) in ys.enumerated() {
            items.append(ChaseBulb(x: 383, y: y, asset: i % 3 == 0 ? "chaseBulbC" : "chaseBulbD"))
        }
        return items
    }
}

struct ChaseView: View {
    @EnvironmentObject private var store: GameStore
    @StateObject private var table = ChaseTable()

    private let design = CGSize(width: 430, height: 984)

    var body: some View {
        GeometryReader { geo in
            let inset = geo.safeAreaInsets
            let play = CGSize(
                width: max(1, geo.size.width - inset.leading - inset.trailing),
                height: max(1, geo.size.height - inset.top - inset.bottom)
            )
            let scale = min(play.width / design.width, play.height / design.height)
            ZStack {
                Image("chaseBg")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .allowsHitTesting(false)
                ChaseInk.veil
                    .allowsHitTesting(false)
                screen
                    .frame(width: design.width, height: design.height)
                    .scaleEffect(scale, anchor: .center)
                    .frame(width: design.width * scale, height: design.height * scale)
                    .position(
                        x: inset.leading + play.width / 2,
                        y: inset.top + play.height / 2
                    )
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(ChaseInk.page)
        .ignoresSafeArea()
        .onAppear {
            table.prepare()
            store.audio.startMusic()
        }
        .onDisappear {
            table.settleIfNeeded(store)
        }
    }

    private var screen: some View {
        VStack(spacing: 14) {
            header
            board
            controls
        }
        .padding(.top, 18)
        .padding(.bottom, 24)
        .frame(width: design.width, height: design.height, alignment: .top)
    }

    private var header: some View {
        VStack(spacing: 4) {
            HStack {
                iconButton("chaseHouse", slashed: false) {
                    store.audio.click()
                    table.settleIfNeeded(store)
                    withAnimation { store.route = .modes }
                }
                Spacer()
                ZStack {
                    Image("hudCoins")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 136, height: 51)
                    VStack(spacing: 0) {
                        Text("COINS")
                            .font(Lucky.bold(9))
                            .tracking(1.4)
                            .foregroundStyle(ChaseInk.goldLine)
                        Text("\(store.coins)")
                            .font(Lucky.black(18))
                            .foregroundStyle(ChaseInk.cream)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .frame(width: 108)
                    }
                }
                Spacer()
                iconButton("chaseVolume", slashed: !store.soundEnabled) {
                    store.audio.click()
                    store.soundEnabled.toggle()
                    store.applyAudioFlags()
                }
            }
            .frame(width: 398, height: 51)

            logo
                .padding(.top, 0)

            HStack(spacing: 10) {
                Capsule().fill(ChaseInk.rule).frame(width: 40, height: 1)
                Text("Ring Chase")
                    .font(Lucky.bold(17))
                    .foregroundStyle(ChaseInk.cream)
                Capsule().fill(ChaseInk.rule).frame(width: 40, height: 1)
            }
            .frame(height: 20)
        }
        .frame(width: 398)
    }

    private var logo: some View {
        Color.clear
            .frame(width: 256, height: 96)
            .overlay(alignment: .topLeading) {
                Image("chaseLogo")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 256 * 1.1166, height: 96 * 5.2938)
                    .offset(x: 256 * -0.0568, y: 96 * -1.3653)
            }
            .clipped()
    }

    private var board: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(ChaseInk.metal)
            RoundedRectangle(cornerRadius: 27, style: .continuous)
                .fill(ChaseInk.boardLip)
                .overlay(
                    RoundedRectangle(cornerRadius: 27, style: .continuous)
                        .stroke(Color(red: 1, green: 219 / 255, blue: 131 / 255), lineWidth: 1)
                )
                .frame(width: 390, height: 390)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ChaseInk.boardInner)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(ChaseInk.goldLine, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.85), radius: 8, y: 2)
                .frame(width: 362, height: 362)

            ForEach(Array(ChaseTable.bulbs.enumerated()), id: \.offset) { offset, bulb in
                Image(bulb.asset)
                    .resizable()
                    .frame(width: 17, height: 17)
                    .scaleEffect(bulbHot(offset) ? 1.28 : 1)
                    .position(x: bulb.x + 3.5, y: bulb.y + 3.5)
            }
            .allowsHitTesting(false)

            ForEach(ChaseTable.ring) { cell in
                cellView(cell)
                    .position(
                        x: ChaseTable.frames[cell.id].midX,
                        y: ChaseTable.frames[cell.id].midY
                    )
            }

            centerScreen
                .position(x: 199, y: 199)
        }
        .frame(width: 398, height: 398)
        .shadow(color: Color(red: 226 / 255, green: 163 / 255, blue: 69 / 255).opacity(0.21), radius: 20)
        .shadow(color: .black.opacity(0.69), radius: 12, y: 10)
    }

    private func bulbHot(_ offset: Int) -> Bool {
        guard table.running else { return false }
        let count = ChaseTable.bulbs.count
        let head = (table.index * count / ChaseTable.ring.count) % count
        let delta = min((offset - head + count) % count, (head - offset + count) % count)
        return delta <= 1
    }

    private func cellView(_ cell: ChaseCell) -> some View {
        let active = cell.id == table.index
        return VStack(spacing: 0) {
            Image(cell.asset)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: cell.art.width, height: cell.art.height)
            Text("×\(cell.multiplier)")
                .font(Lucky.bold(13))
                .foregroundStyle(active ? ChaseInk.cream : ChaseInk.goldLine)
        }
        .padding(.top, 4)
        .padding(.bottom, 3)
        .frame(width: 81, height: 81)
        .background(active ? ChaseInk.hotFill : ChaseInk.cell, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(active ? ChaseInk.hotEdge : ChaseInk.cellEdge, lineWidth: active ? 3 : 1)
        )
        .shadow(color: active ? Color(red: 1, green: 210 / 255, blue: 78 / 255).opacity(0.69) : .clear, radius: active ? 12 : 0)
    }

    private var centerScreen: some View {
        VStack(spacing: 5) {
            Text("LUCKY CHASE")
                .font(Lucky.bold(9))
                .tracking(0.6)
                .foregroundStyle(ChaseInk.goldLine)
            Text("Hit \(table.wish.title) to win")
                .font(Lucky.bold(13))
                .foregroundStyle(ChaseInk.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("\(table.preview)")
                .font(.system(size: 48, weight: .heavy))
                .foregroundStyle(ChaseInk.metal)
                .shadow(color: Color(red: 203 / 255, green: 101 / 255, blue: 26 / 255).opacity(0.33), radius: 8, y: 2)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("\(table.bet) coins × \(table.wishMultiplier)")
                .font(Lucky.bold(11))
                .foregroundStyle(ChaseInk.muted)
            Text("Clockwise chase ↻")
                .font(Lucky.bold(10))
                .foregroundStyle(ChaseInk.goldLine)
                .padding(.top, 5)
        }
        .padding(.horizontal, 10)
        .frame(width: 170, height: 170)
        .background(ChaseInk.wine, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ChaseInk.rule, lineWidth: 1)
        )
    }

    private var controls: some View {
        VStack(spacing: 10) {
            collection
            wishes
            bets
            launch
            Text(table.note ?? "Tap to start · tap again to stop · the cell you land on pays.")
                .font(Lucky.bold(11))
                .foregroundStyle(table.note == nil ? ChaseInk.muted : ChaseInk.cream)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
        }
        .frame(width: 398)
    }

    private var collection: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(ChaseTable.ring.first { $0.symbol == table.wish }?.asset ?? "chaseCherry")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 29, height: 29)
                Text("\(table.wish.title) set")
                    .font(Lucky.bold(14))
                    .foregroundStyle(ChaseInk.cream)
                Text("\(table.have) / \(ChaseTable.setNeed)")
                    .font(Lucky.bold(12))
                    .foregroundStyle(ChaseInk.goldLine)
                Spacer(minLength: 6)
                Text("Full set +\(ChaseTable.setBonus)")
                    .font(Lucky.bold(12))
                    .foregroundStyle(ChaseInk.goldLine)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            GeometryReader { geo in
                let fill = geo.size.width * CGFloat(table.have) / CGFloat(ChaseTable.setNeed)
                ZStack(alignment: .leading) {
                    Capsule().fill(ChaseInk.track)
                    Capsule()
                        .fill(ChaseInk.metal)
                        .frame(width: max(table.have == 0 ? 0 : 8, fill))
                        .padding(1)
                }
            }
            .frame(height: 7)
            Text("Each stop on \(table.wish.title) adds +1. Resets when full.")
                .font(Lucky.bold(10))
                .foregroundStyle(ChaseInk.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ChaseInk.wine, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ChaseInk.rule, lineWidth: 1)
        )
    }

    private var wishes: some View {
        VStack(spacing: 5) {
            HStack {
                Text("Wish fruit")
                    .font(Lucky.bold(12))
                    .foregroundStyle(ChaseInk.cream)
                Spacer()
                Text("\(table.wish.title) · hit pays \(table.preview)")
                    .font(Lucky.bold(11))
                    .foregroundStyle(ChaseInk.goldLine)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            HStack(spacing: 8) {
                ForEach(ChaseTable.wishes) { symbol in
                    wishButton(symbol)
                }
            }
        }
    }

    private func wishButton(_ symbol: SlotSymbol) -> some View {
        let selected = table.wish == symbol
        let asset = ChaseTable.ring.first { $0.symbol == symbol }?.asset ?? "chaseCherry"
        return Button {
            table.pickWish(symbol, store: store)
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Image(asset)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 41, height: 41)
                if selected {
                    Text("✓")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(ChaseInk.ink)
                        .frame(width: 14, height: 14)
                        .background(ChaseInk.goldLine, in: Circle())
                        .offset(x: 4, y: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 49)
            .background(selected ? ChaseInk.wishOn : ChaseInk.wishIdle, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(selected ? ChaseInk.goldLine : ChaseInk.wishEdge, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(PressScale())
        .disabled(table.running)
    }

    private var bets: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Bet")
                    .font(Lucky.bold(10))
                    .foregroundStyle(ChaseInk.muted)
                Text("\(table.bet)")
                    .font(Lucky.bold(20))
                    .foregroundStyle(ChaseInk.cream)
            }
            .frame(width: 52, alignment: .leading)
            Spacer(minLength: 8)
            ForEach(ChaseTable.bets, id: \.self) { value in
                betButton(value)
                if value != ChaseTable.bets.last { Spacer(minLength: 8) }
            }
        }
        .frame(height: 46)
    }

    private func betButton(_ value: Int) -> some View {
        let selected = table.bet == value
        return Button {
            table.pickBet(value, store: store)
        } label: {
            Text("\(value) coins")
                .font(Lucky.bold(value == 100 ? 12 : 13))
                .foregroundStyle(selected ? ChaseInk.ink : ChaseInk.creamBright)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 86, height: 46)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(ChaseInk.metal)
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(ChaseInk.wine)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(selected ? ChaseInk.cream : ChaseInk.rule, lineWidth: 1)
                )
        }
        .buttonStyle(PressScale())
        .disabled(table.running)
    }

    private var launch: some View {
        HStack {
            VStack(spacing: 4) {
                Text("Direction")
                    .font(Lucky.bold(10))
                    .foregroundStyle(ChaseInk.muted)
                Text("Clockwise ↻")
                    .font(Lucky.bold(13))
                    .foregroundStyle(ChaseInk.goldLine)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 80)
            Spacer(minLength: 8)
            Button {
                table.toggle(store)
            } label: {
                Text(table.stopping ? "Stopping" : (table.running ? "Stop" : "Start Chase"))
                    .font(Lucky.bold(24))
                    .foregroundStyle(ChaseInk.creamBright)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: 210, height: 90)
                    .background(ChaseInk.startFill, in: Capsule())
                    .overlay(Capsule().stroke(Color(red: 1, green: 240 / 255, blue: 180 / 255), lineWidth: 3))
                    .shadow(color: .black.opacity(0.56), radius: 4, y: 5)
            }
            .buttonStyle(PressScale())
            Spacer(minLength: 8)
            VStack(spacing: 4) {
                Text("Wish hit")
                    .font(Lucky.bold(10))
                    .foregroundStyle(ChaseInk.muted)
                Text("×\(table.wishMultiplier) pay")
                    .font(Lucky.bold(13))
                    .foregroundStyle(ChaseInk.goldLine)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 80)
        }
        .padding(.top, 2)
    }

    private func iconButton(_ asset: String, slashed: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle().fill(ChaseInk.wine)
                Circle().stroke(ChaseInk.goldLine, lineWidth: 1.5)
                Image(asset)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                if slashed {
                    Rectangle()
                        .fill(ChaseInk.cream)
                        .frame(width: 1.6, height: 22)
                        .rotationEffect(.degrees(-35))
                }
            }
            .frame(width: 40, height: 40)
        }
        .buttonStyle(PressScale())
    }
}
