import SwiftUI

private struct WindowPiece: Identifiable, Equatable {
    let id: UUID
    var symbol: SlotSymbol
    var selected: Bool
}

private struct WindowLevel {
    var orders: Int
    var plate: Int
    var counter: Int
    var pool: [SlotSymbol]
    var wildChance: Int
    var lives: Int

    static let campaign: [WindowLevel] = [
        WindowLevel(orders: 4, plate: 2, counter: 12, pool: [.cherry, .lemon, .orange, .grape], wildChance: 50, lives: 3),
        WindowLevel(orders: 4, plate: 2, counter: 12, pool: [.cherry, .lemon, .orange, .grape, .melon], wildChance: 40, lives: 3),
        WindowLevel(orders: 5, plate: 3, counter: 12, pool: [.cherry, .lemon, .orange, .grape, .melon, .bell], wildChance: 30, lives: 3),
        WindowLevel(orders: 5, plate: 3, counter: 14, pool: [.lemon, .orange, .grape, .melon, .bell, .bar], wildChance: 22, lives: 3),
        WindowLevel(orders: 5, plate: 3, counter: 14, pool: [.orange, .grape, .melon, .bell, .star, .bar], wildChance: 16, lives: 3),
        WindowLevel(orders: 6, plate: 3, counter: 16, pool: [.grape, .melon, .bell, .star, .bar, .seven], wildChance: 12, lives: 3),
        WindowLevel(orders: 6, plate: 4, counter: 16, pool: [.cherry, .lemon, .orange, .grape, .melon, .bell], wildChance: 14, lives: 3),
        WindowLevel(orders: 6, plate: 4, counter: 16, pool: [.orange, .grape, .melon, .bell, .bar, .seven], wildChance: 8, lives: 2),
        WindowLevel(orders: 7, plate: 4, counter: 16, pool: [.grape, .melon, .bell, .star, .bar, .seven], wildChance: 6, lives: 2),
        WindowLevel(orders: 7, plate: 4, counter: 16, pool: [.bell, .star, .bar, .seven, .melon, .grape], wildChance: 4, lives: 2),
        WindowLevel(orders: 8, plate: 4, counter: 16, pool: [.star, .bar, .seven, .bell, .melon, .orange], wildChance: 0, lives: 2),
        WindowLevel(orders: 8, plate: 4, counter: 16, pool: [.seven, .bar, .star, .bell, .grape, .cherry, .lemon], wildChance: 0, lives: 2)
    ]
}

@MainActor
private final class WindowTable: ObservableObject {
    @Published var order: [SlotSymbol] = []
    @Published var counter: [WindowPiece] = []
    @Published var starsLeft = 3
    @Published var served = 0
    @Published var service = 1
    @Published var banner = "Plate the fruits on the order"
    @Published var showCoach = true
    @Published var showResult = false
    @Published var resultCleared = false
    @Published var resultPay = 0

    private var coachToken = 0
    private var serviceEarned = 0
    private let defaults = UserDefaults.standard

    var levelCount: Int { WindowLevel.campaign.count }
    var ordersInService: Int { current.orders }
    var lives: Int { current.lives }
    private var current: WindowLevel {
        let index = min(max(service, 1), WindowLevel.campaign.count) - 1
        return WindowLevel.campaign[index]
    }

    init() {
        let saved = UserDefaults.standard.integer(forKey: "lf.window.level")
        if saved >= 1, saved <= WindowLevel.campaign.count {
            service = saved
        }
    }

    func begin(showHowTo: Bool) {
        starsLeft = current.lives
        served = 0
        serviceEarned = 0
        showResult = false
        openOrder()
        if showHowTo {
            presentCoach()
        } else {
            dismissCoach()
        }
    }

    func presentCoach() {
        coachToken += 1
        let token = coachToken
        showCoach = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            guard self.coachToken == token else { return }
            self.showCoach = false
        }
    }

    func dismissCoach() {
        coachToken += 1
        showCoach = false
    }

    func toggle(_ id: UUID) {
        guard !showResult, !showCoach, let index = counter.firstIndex(where: { $0.id == id }) else { return }
        counter[index].selected.toggle()
    }

    func send(into store: GameStore) {
        guard !showResult, !showCoach else { return }
        let picked = counter.filter(\.selected).map(\.symbol)
        guard !picked.isEmpty else {
            banner = "Tap fruits, then SEND"
            store.audio.click()
            return
        }
        guard plateMatches(order, picked) else {
            starsLeft -= 1
            clearSelection()
            store.audio.click()
            store.haptic(.rigid)
            if starsLeft <= 0 {
                banner = "Window closed"
                resultCleared = false
                resultPay = serviceEarned
                showResult = true
            } else {
                banner = "Not this plate · \(starsLeft) left"
            }
            return
        }

        let pay = order.reduce(0) { $0 + $1.lineMultiplier * 10 }
        store.coins += pay
        serviceEarned += pay
        store.persist()
        store.audio.win()
        store.haptic(.medium)
        served += 1
        if served >= ordersInService {
            let tip = 70 + service * 35
            store.coins += tip
            serviceEarned += tip
            store.persist()
            resultCleared = true
            resultPay = tip
            banner = "Level \(service) clear · +\(tip)"
            let next = service >= levelCount ? 1 : service + 1
            defaults.set(next, forKey: "lf.window.level")
            showResult = true
            return
        }
        banner = "Sent · +\(pay)"
        openOrder()
    }

    func nextService() {
        service = service >= levelCount ? 1 : service + 1
        defaults.set(service, forKey: "lf.window.level")
        begin(showHowTo: false)
    }

    func retry() {
        begin(showHowTo: false)
    }

    private func openOrder() {
        order = makeOrder()
        counter = dealCounter(order)
    }

    private func clearSelection() {
        for index in counter.indices {
            counter[index].selected = false
        }
    }

    private func makeOrder() -> [SlotSymbol] {
        let level = current
        var order = (0..<level.plate).map { _ in level.pool.randomElement() ?? .cherry }
        if level.plate >= 2, Int.random(in: 0..<100) < (level.plate >= 4 ? 85 : 60) {
            order[order.count - 1] = order[0]
        }
        return order
    }

    private func dealCounter(_ order: [SlotSymbol]) -> [WindowPiece] {
        let level = current
        var symbols = order
        let fillers = level.pool
        while symbols.count < level.counter - 1 {
            symbols.append(fillers.randomElement() ?? .cherry)
        }
        if !order.contains(.star), Int.random(in: 0..<100) < level.wildChance {
            symbols.append(.star)
        } else {
            symbols.append(fillers.randomElement() ?? .lemon)
        }
        while symbols.count < level.counter {
            symbols.append(fillers.randomElement() ?? .cherry)
        }
        symbols.shuffle()
        return symbols.map { WindowPiece(id: UUID(), symbol: $0, selected: false) }
    }

    private func plateMatches(_ order: [SlotSymbol], _ picked: [SlotSymbol]) -> Bool {
        var remaining = order
        var stars = picked.filter { $0 == .star }.count
        for symbol in picked where symbol != .star {
            guard let index = remaining.firstIndex(of: symbol) else { return false }
            remaining.remove(at: index)
        }
        let starNeed = remaining.filter { $0 == .star }.count
        guard stars >= starNeed else { return false }
        stars -= starNeed
        return stars == remaining.count - starNeed
    }
}

struct WindowView: View {
    @EnvironmentObject private var store: GameStore
    @StateObject private var table = WindowTable()

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let pad = Lucky.isPad
            let wide = Lucky.isLandscape(size) || pad
            ZStack {
                Image("imgLoadBg")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .allowsHitTesting(false)

                VStack(spacing: pad ? 18 : 12) {
                    hud
                    if wide {
                        HStack(alignment: .center, spacing: pad ? 40 : 28) {
                            ticket
                                .frame(maxWidth: pad ? 520 : 460)
                            VStack(spacing: 16) {
                                counterGrid(
                                    width: min(pad ? 640 : 520, size.width * (pad ? 0.5 : 0.46)),
                                    maxHeight: size.height * (pad ? 0.58 : 0.62)
                                )
                                footer
                            }
                            .frame(maxWidth: pad ? 680 : 560)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ticket
                            .frame(maxWidth: pad ? 640 : .infinity)
                        counterGrid(
                            width: min(pad ? 640 : 560, size.width - (pad ? 80 : 36)),
                            maxHeight: size.height * (pad ? 0.52 : 0.5)
                        )
                        Spacer(minLength: 0)
                        footer
                            .frame(maxWidth: pad ? 640 : .infinity)
                    }
                }
                .padding(.horizontal, pad ? 48 : 18)
                .padding(.top, pad ? 20 : 8)
                .padding(.bottom, pad ? 28 : 18)
                .frame(width: size.width, height: size.height)

                if table.showCoach {
                    coach
                } else if table.showResult {
                    resultCard
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .ignoresSafeArea()
        .onAppear {
            store.audio.startMusic()
            if table.order.isEmpty { table.begin(showHowTo: true) }
        }
    }

    private var hud: some View {
        HStack {
            Button {
                store.audio.click()
                withAnimation { store.route = .modes }
            } label: {
                Image("btnHome")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: Lucky.isPad ? 62 : 50, height: Lucky.isPad ? 62 : 50)
            }
            .buttonStyle(PressScale())
            Spacer()
            ZStack {
                Image("hudCoins")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: Lucky.isPad ? 168 : 135, height: Lucky.isPad ? 68 : 55)
                VStack(spacing: 0) {
                    Text("SCORE")
                        .font(Lucky.bold(Lucky.isPad ? 10 : 8))
                        .tracking(1.6)
                        .foregroundStyle(Lucky.goldSoft.opacity(0.92))
                    Text("\(store.coins)")
                        .font(Lucky.black(Lucky.isPad ? 22 : 18))
                        .foregroundStyle(Lucky.gold)
                        .minimumScaleFactor(0.45)
                        .lineLimit(1)
                        .frame(width: Lucky.isPad ? 132 : 108)
                }
            }
            Spacer()
            Button {
                store.audio.click()
                store.showSettings = true
            } label: {
                Image("btnSettings")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: Lucky.isPad ? 62 : 50, height: Lucky.isPad ? 62 : 50)
            }
            .buttonStyle(PressScale())
        }
    }

    private var ticket: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ORDER")
                    .font(Lucky.black(14))
                    .tracking(2)
                    .foregroundStyle(Lucky.gold)
                Spacer()
                Text("\(table.served)/\(table.ordersInService)")
                    .font(Lucky.black(16))
                    .foregroundStyle(Lucky.goldSoft)
                Text("Level \(table.service)/\(table.levelCount)")
                    .font(Lucky.bold(12))
                    .foregroundStyle(Lucky.muted)
            }
            HStack(spacing: 16) {
                ForEach(grouped(table.order), id: \.0.rawValue) { symbol, count in
                    HStack(spacing: 6) {
                        Image(symbol.asset)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: table.order.count > 3 ? 42 : 50, height: table.order.count > 3 ? 42 : 50)
                        if count > 1 {
                            Text("×\(count)")
                                .font(Lucky.black(18))
                                .foregroundStyle(Lucky.gold)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            Text(table.banner)
                .font(Lucky.bold(13))
                .foregroundStyle(Lucky.cream)
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Lucky.maroon.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Lucky.gold.opacity(0.55), lineWidth: 1.5)
        )
    }

    private func counterGrid(width: CGFloat, maxHeight: CGFloat) -> some View {
        let columns = 4
        let rows = max(1, Int(ceil(Double(max(table.counter.count, 1)) / Double(columns))))
        let spacing: CGFloat = 8
        let sideByWidth = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        let sideByHeight = (maxHeight - spacing * CGFloat(rows - 1)) / CGFloat(rows)
        let side = min(Lucky.isPad ? 118 : 96, sideByWidth, sideByHeight)
        return LazyVGrid(columns: Array(repeating: GridItem(.fixed(side), spacing: spacing), count: columns), spacing: spacing) {
            ForEach(table.counter) { piece in
                Button {
                    table.toggle(piece.id)
                    store.audio.click()
                } label: {
                    Image(piece.symbol.asset)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .padding(side > 90 ? 10 : 6)
                        .frame(width: side, height: side)
                        .background(
                            Lucky.maroon.opacity(piece.selected ? 0.96 : 0.7),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Lucky.gold.opacity(piece.selected ? 1 : 0.28), lineWidth: piece.selected ? 3 : 1)
                        )
                }
                .buttonStyle(PressScale())
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var footer: some View {
        HStack(spacing: 14) {
            HStack(spacing: 6) {
                ForEach(0..<table.lives, id: \.self) { index in
                    Image("symStar")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .opacity(index < table.starsLeft ? 1 : 0.22)
                }
            }
            Button {
                table.send(into: store)
            } label: {
                Text(sendTitle)
                    .font(Lucky.black(Lucky.isPad ? 22 : 18))
                    .tracking(1.4)
                    .foregroundStyle(Lucky.gold)
                    .frame(maxWidth: .infinity)
                    .frame(height: Lucky.isPad ? 64 : 54)
                    .background(Lucky.wine, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Lucky.gold, lineWidth: 1.5)
                    )
            }
            .buttonStyle(PressScale())
        }
    }

    private var sendTitle: String {
        let picked = table.counter.filter(\.selected).count
        if picked == 0 { return "SEND" }
        return "SEND \(picked)/\(table.order.count)"
    }

    private var coach: some View {
        ZStack {
            Color.black.opacity(0.55)
            VStack(alignment: .leading, spacing: 12) {
                Text("WINDOW")
                    .font(Lucky.black(22))
                    .tracking(2)
                    .foregroundStyle(Lucky.goldSoft)
                    .frame(maxWidth: .infinity)
                coachLine("1", "Tap only the fruits on the order. Extras are decoys.")
                coachLine("2", "A star can stand in for any missing fruit. Later levels rarely have one.")
                coachLine("3", "SEND the plate. Use up the stars and the level closes.")
                Text("Tap to close")
                    .font(Lucky.bold(13))
                    .foregroundStyle(Lucky.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(20)
            .frame(width: Lucky.panelWidth)
            .background(Lucky.maroon.opacity(0.96), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Lucky.gold, lineWidth: 3)
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            store.audio.click()
            table.dismissCoach()
        }
    }

    private func coachLine(_ step: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(step)
                .font(Lucky.black(14))
                .foregroundStyle(Lucky.gold)
                .frame(width: 22, height: 22)
                .background(Lucky.wine, in: Circle())
            Text(text)
                .font(Lucky.bold(14))
                .foregroundStyle(Lucky.cream)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var resultCard: some View {
        ZStack {
            Color.black.opacity(0.5)
            VStack(spacing: 8) {
                Text(resultHeadline)
                    .font(Lucky.black(24))
                    .tracking(2)
                    .foregroundStyle(Lucky.goldSoft)
                Text(resultDetail)
                    .font(Lucky.bold(15))
                    .foregroundStyle(Lucky.cream)
                    .multilineTextAlignment(.center)
                HStack(spacing: 10) {
                    resultButton(table.resultCleared ? (table.service >= table.levelCount ? "Again" : "Next") : "Retry") {
                        store.audio.click()
                        if table.resultCleared {
                            table.nextService()
                        } else {
                            table.retry()
                        }
                    }
                    resultButton("Modes") {
                        store.audio.click()
                        withAnimation { store.route = .modes }
                    }
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .frame(width: Lucky.panelWidth)
            .background(Lucky.maroon.opacity(0.94), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Lucky.gold, lineWidth: 3)
            )
        }
    }

    private var resultHeadline: String {
        if table.resultCleared, table.service >= table.levelCount { return "ALL LIT" }
        return table.resultCleared ? "LEVEL CLEAR" : "WINDOW CLOSED"
    }

    private var resultDetail: String {
        if table.resultCleared, table.service >= table.levelCount {
            return "Level \(table.levelCount) tip +\(table.resultPay)"
        }
        if table.resultCleared {
            return "Level \(table.service) tip +\(table.resultPay)"
        }
        return "Sent \(table.served)/\(table.ordersInService)"
    }

    private func resultButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Lucky.bold(15))
                .foregroundStyle(Lucky.gold)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Lucky.wine, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Lucky.gold.opacity(0.45), lineWidth: 1)
                )
        }
        .buttonStyle(PressScale())
    }

    private func grouped(_ symbols: [SlotSymbol]) -> [(SlotSymbol, Int)] {
        var rows: [(SlotSymbol, Int)] = []
        for symbol in symbols {
            if let index = rows.firstIndex(where: { $0.0 == symbol }) {
                rows[index].1 += 1
            } else {
                rows.append((symbol, 1))
            }
        }
        return rows
    }
}
