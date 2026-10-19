import SwiftUI

private struct CrushBurst: Identifiable, Equatable {
    let id = UUID()
    var index: Int
    var combo: Int
}

private struct CrushLevel {
    var target: Int
    var moves: Int
    var kinds: Int

    static let campaign: [CrushLevel] = [
        CrushLevel(target: 220, moves: 20, kinds: 4),
        CrushLevel(target: 300, moves: 19, kinds: 4),
        CrushLevel(target: 380, moves: 18, kinds: 5),
        CrushLevel(target: 480, moves: 17, kinds: 5),
        CrushLevel(target: 580, moves: 16, kinds: 5),
        CrushLevel(target: 700, moves: 16, kinds: 6),
        CrushLevel(target: 840, moves: 15, kinds: 6),
        CrushLevel(target: 1000, moves: 15, kinds: 6),
        CrushLevel(target: 1180, moves: 14, kinds: 7),
        CrushLevel(target: 1380, moves: 14, kinds: 7),
        CrushLevel(target: 1600, moves: 13, kinds: 8),
        CrushLevel(target: 1860, moves: 13, kinds: 8)
    ]
}

@MainActor
private final class CrushTable: ObservableObject {
    let size = 7
    @Published var cells: [SlotSymbol] = []
    @Published var picked: Int?
    @Published var clearing: Set<Int> = []
    @Published var bursts: [CrushBurst] = []
    @Published var flashLine: Set<Int> = []
    @Published var comboFlash = 0
    @Published var lastBank = 0
    @Published var busy = false
    @Published var level = 1
    @Published var score = 0
    @Published var movesLeft = 20
    @Published var banner = "Swap two neighbors"
    @Published var showCoach = true
    @Published var showResult = false
    @Published var resultCleared = false

    private var coachToken = 0
    private let defaults = UserDefaults.standard
    private let palette: [SlotSymbol] = [.cherry, .lemon, .orange, .grape, .melon, .bell, .star, .bar]

    var levelCount: Int { CrushLevel.campaign.count }
    var current: CrushLevel {
        CrushLevel.campaign[min(max(level, 1), CrushLevel.campaign.count) - 1]
    }

    init() {
        let saved = defaults.integer(forKey: "lf.crush.level")
        if saved >= 1, saved <= CrushLevel.campaign.count {
            level = saved
        }
    }

    func begin(showHowTo: Bool) {
        score = 0
        movesLeft = current.moves
        picked = nil
        clearing = []
        bursts = []
        flashLine = []
        comboFlash = 0
        lastBank = 0
        busy = false
        showResult = false
        banner = "Swap neighbors · \(current.target) crush"
        fillBoard()
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

    func tap(_ index: Int, store: GameStore) {
        guard !busy, !showCoach, !showResult, (0..<cells.count).contains(index) else { return }
        if let first = picked {
            if first == index {
                picked = nil
                store.audio.click()
                return
            }
            if adjacent(first, index) {
                Task { await swap(first, index, store: store) }
            } else {
                picked = index
                store.audio.click()
            }
            return
        }
        picked = index
        store.audio.click()
    }

    func nextLevel() {
        level = level >= levelCount ? 1 : level + 1
        defaults.set(level, forKey: "lf.crush.level")
        begin(showHowTo: false)
    }

    func retry() {
        begin(showHowTo: false)
    }

    private func fillBoard() {
        var next = Array(repeating: SlotSymbol.cherry, count: size * size)
        for index in next.indices {
            next[index] = randomTile(avoiding: next, at: index)
        }
        if findMatches(in: next).isEmpty, !hasMove(in: next) {
            fillBoard()
            return
        }
        cells = next
    }

    private func randomTile(avoiding board: [SlotSymbol], at index: Int) -> SlotSymbol {
        let kinds = Array(palette.prefix(current.kinds))
        for _ in 0..<12 {
            let pick = kinds.randomElement() ?? .cherry
            var trial = board
            if (0..<trial.count).contains(index) {
                trial[index] = pick
            }
            if !makesImmediateMatch(trial, index: index, symbol: pick) {
                return pick
            }
        }
        return kinds.randomElement() ?? .cherry
    }

    private func makesImmediateMatch(_ board: [SlotSymbol], index: Int, symbol: SlotSymbol) -> Bool {
        let row = index / size
        let col = index % size
        if col >= 2, board[index - 1] == symbol, board[index - 2] == symbol { return true }
        if row >= 2, board[index - size] == symbol, board[index - size * 2] == symbol { return true }
        return false
    }

    private func adjacent(_ a: Int, _ b: Int) -> Bool {
        let ra = a / size, ca = a % size
        let rb = b / size, cb = b % size
        return abs(ra - rb) + abs(ca - cb) == 1
    }

    private func swap(_ a: Int, _ b: Int, store: GameStore) async {
        busy = true
        picked = nil
        var next = cells
        next.swapAt(a, b)
        cells = next
        store.audio.tick()
        try? await Task.sleep(nanoseconds: 160_000_000)
        if findMatches(in: cells).isEmpty {
            next.swapAt(a, b)
            cells = next
            banner = "Need 3 in a row"
            store.audio.click()
            busy = false
            return
        }
        movesLeft -= 1
        await resolve(store: store)
        if score >= current.target {
            finish(cleared: true, store: store)
            return
        }
        if movesLeft <= 0 {
            finish(cleared: false, store: store)
            return
        }
        if !hasMove(in: cells) {
            banner = "No moves · board shuffled"
            shuffleUntilPlayable()
        }
        busy = false
    }

    private func resolve(store: GameStore) async {
        var combo = 1
        while true {
            let hits = findMatches(in: cells)
            guard !hits.isEmpty else { break }
            let extra = specialHits(from: hits, in: cells)
            let all = hits.union(extra)
            clearing = all
            flashLine = extra
            bursts = all.map { CrushBurst(index: $0, combo: combo) }
            comboFlash = combo
            let crush = all.count * 10 * combo
            let bank = max(1, crush / 8)
            score += crush
            lastBank = bank
            store.coins += bank
            store.coinFlash = true
            store.persist()
            store.audio.win()
            store.haptic(combo >= 3 ? .heavy : .medium)
            if extra.count >= size {
                banner = combo > 1 ? "LINE ×\(combo) · +\(bank) score" : "LINE BLAST · +\(bank) score"
            } else {
                banner = combo > 1 ? "Combo ×\(combo) · +\(bank) score" : "Match · +\(bank) score"
            }
            try? await Task.sleep(nanoseconds: 420_000_000)
            drop(clearing: all)
            clearing = []
            flashLine = []
            bursts = []
            combo += 1
            try? await Task.sleep(nanoseconds: 120_000_000)
        }
        comboFlash = 0
    }

    private func specialHits(from hits: Set<Int>, in board: [SlotSymbol]) -> Set<Int> {
        var extra: Set<Int> = []
        for row in 0..<size {
            let cells = (0..<size).map { row * size + $0 }.filter { hits.contains($0) }
            if cells.count >= 5, let symbol = cells.first.map({ board[$0] }) {
                for index in board.indices where board[index] == symbol {
                    extra.insert(index)
                }
            } else if cells.count >= 4 {
                for col in 0..<size { extra.insert(row * size + col) }
            }
        }
        for col in 0..<size {
            let cells = (0..<size).map { $0 * size + col }.filter { hits.contains($0) }
            if cells.count >= 5, let symbol = cells.first.map({ board[$0] }) {
                for index in board.indices where board[index] == symbol {
                    extra.insert(index)
                }
            } else if cells.count >= 4 {
                for row in 0..<size { extra.insert(row * size + col) }
            }
        }
        extra.subtract(hits)
        return extra
    }

    private func drop(clearing hits: Set<Int>) {
        var board = cells
        for col in 0..<size {
            var stack: [SlotSymbol] = []
            for row in stride(from: size - 1, through: 0, by: -1) {
                let index = row * size + col
                if !hits.contains(index) {
                    stack.append(board[index])
                }
            }
            for row in stride(from: size - 1, through: 0, by: -1) {
                let index = row * size + col
                if stack.isEmpty {
                    board[index] = randomTile(avoiding: board, at: index)
                } else {
                    board[index] = stack.removeFirst()
                }
            }
        }
        cells = board
    }

    private func findMatches(in board: [SlotSymbol]) -> Set<Int> {
        var hits: Set<Int> = []
        for row in 0..<size {
            var run = 1
            for col in 1..<size {
                let index = row * size + col
                if board[index] == board[index - 1] {
                    run += 1
                } else {
                    if run >= 3 {
                        for k in 0..<run { hits.insert(index - 1 - k) }
                    }
                    run = 1
                }
            }
            if run >= 3 {
                let last = row * size + size - 1
                for k in 0..<run { hits.insert(last - k) }
            }
        }
        for col in 0..<size {
            var run = 1
            for row in 1..<size {
                let index = row * size + col
                if board[index] == board[index - size] {
                    run += 1
                } else {
                    if run >= 3 {
                        for k in 0..<run { hits.insert(index - size * (k + 1)) }
                    }
                    run = 1
                }
            }
            if run >= 3 {
                let last = (size - 1) * size + col
                for k in 0..<run { hits.insert(last - size * k) }
            }
        }
        return hits
    }

    private func hasMove(in board: [SlotSymbol]) -> Bool {
        for index in board.indices {
            let neighbors = [index + 1, index + size].filter { next in
                (0..<board.count).contains(next) && adjacent(index, next)
            }
            for next in neighbors {
                var trial = board
                trial.swapAt(index, next)
                if !findMatches(in: trial).isEmpty { return true }
            }
        }
        return false
    }

    private func shuffleUntilPlayable() {
        for _ in 0..<20 {
            fillBoard()
            if findMatches(in: cells).isEmpty, hasMove(in: cells) { return }
        }
    }

    private func finish(cleared: Bool, store: GameStore) {
        busy = false
        resultCleared = cleared
        if cleared {
            let tip = 12 + level * 4
            lastBank = tip
            store.coins += tip
            store.coinFlash = true
            store.persist()
            banner = "Level \(level) clear · +\(tip) score"
            let next = level >= levelCount ? 1 : level + 1
            defaults.set(next, forKey: "lf.crush.level")
        } else {
            banner = "Out of moves"
        }
        showResult = true
        store.audio.win()
    }
}

struct CrushView: View {
    @EnvironmentObject private var store: GameStore
    @StateObject private var table = CrushTable()

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let pad = Lucky.isPad
            let wide = Lucky.isLandscape(size) && size.width > 700
            ZStack {
                Image("imgLoadBg")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    hud
                        .padding(.horizontal, pad ? 36 : 14)
                        .padding(.top, pad ? 18 : 6)
                    status
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, pad ? 48 : 14)
                        .padding(.top, pad ? 14 : 8)
                    Spacer(minLength: pad ? 16 : 8)
                    board(maxSide: boardSide(size: size, pad: pad, wide: wide))
                        .frame(maxWidth: .infinity)
                    Spacer(minLength: pad ? 20 : 8)
                }
                .frame(width: size.width, height: size.height, alignment: .top)

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
            if table.cells.isEmpty { table.begin(showHowTo: true) }
        }
    }

    private func boardSide(size: CGSize, pad: Bool, wide: Bool) -> CGFloat {
        if pad {
            if wide {
                return min(size.height - 210, size.width * 0.62)
            }
            return min(size.width * 0.78, size.height - 250)
        }
        if wide {
            return min(size.height - 150, size.width * 0.58)
        }
        return min(size.width - 16, size.height - 164)
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

    private var status: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("LEVEL \(table.level)/\(table.levelCount)")
                    .font(Lucky.black(Lucky.isPad ? 16 : 13))
                    .foregroundStyle(Lucky.gold)
                Text(table.banner)
                    .font(Lucky.bold(Lucky.isPad ? 14 : 12))
                    .foregroundStyle(Lucky.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(table.score)/\(table.current.target)")
                    .font(Lucky.black(Lucky.isPad ? 20 : 16))
                    .foregroundStyle(Lucky.goldSoft)
                Text("\(table.movesLeft) moves")
                    .font(Lucky.bold(Lucky.isPad ? 14 : 12))
                    .foregroundStyle(Lucky.muted)
                if table.lastBank > 0 {
                    Text("+\(table.lastBank) SCORE")
                        .font(Lucky.black(Lucky.isPad ? 13 : 11))
                        .foregroundStyle(Lucky.gold)
                }
            }
        }
        .padding(.horizontal, Lucky.isPad ? 18 : 12)
        .padding(.vertical, Lucky.isPad ? 12 : 8)
        .frame(maxWidth: Lucky.isPad ? 720 : .infinity)
        .background(Lucky.maroon.opacity(0.92), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Lucky.gold.opacity(0.4), lineWidth: 1)
        )
    }

    private func board(maxSide: CGFloat) -> some View {
        let cell = floor(maxSide / CGFloat(table.size))
        let side = cell * CGFloat(table.size)
        return ZStack {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cell), spacing: 0), count: table.size), spacing: 0) {
                ForEach(table.cells.indices, id: \.self) { index in
                    Button {
                        table.tap(index, store: store)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Lucky.maroon.opacity(table.picked == index ? 0.96 : 0.72))
                            if table.flashLine.contains(index) {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(Lucky.gold.opacity(0.38))
                            }
                            Image(table.cells[index].asset)
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                                .padding(cell * 0.08)
                                .opacity(table.clearing.contains(index) ? 0.15 : 1)
                                .scaleEffect(table.clearing.contains(index) ? 1.28 : 1)
                                .rotationEffect(.degrees(table.clearing.contains(index) ? 12 : 0))
                            if table.clearing.contains(index) {
                                Circle()
                                    .stroke(Lucky.goldSoft, lineWidth: 2)
                                    .frame(width: cell * 0.72, height: cell * 0.72)
                                    .scaleEffect(1.15)
                                    .opacity(0.9)
                                Circle()
                                    .fill(Lucky.gold.opacity(0.55))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .frame(width: cell - 3, height: cell - 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(
                                    Lucky.gold.opacity(table.picked == index ? 1 : (table.clearing.contains(index) ? 0.95 : 0.22)),
                                    lineWidth: table.picked == index || table.clearing.contains(index) ? 2.4 : 1
                                )
                        )
                        .shadow(
                            color: Lucky.gold.opacity(table.clearing.contains(index) ? 0.85 : 0),
                            radius: table.clearing.contains(index) ? 10 : 0
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(table.busy)
                }
            }
            if table.comboFlash >= 2 {
                Text(table.comboFlash >= 4 ? "MEGA" : "COMBO ×\(table.comboFlash)")
                    .font(Lucky.black(table.comboFlash >= 4 ? 34 : 28))
                    .tracking(2)
                    .foregroundStyle(Lucky.goldSoft)
                    .shadow(color: Lucky.gold.opacity(0.9), radius: 12)
                    .scaleEffect(1.08)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: side, height: side)
        .padding(6)
        .background(Lucky.wine.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Lucky.gold.opacity(0.45), lineWidth: 1.5)
        )
        .animation(.easeOut(duration: 0.18), value: table.clearing)
        .animation(.easeInOut(duration: 0.12), value: table.picked)
        .animation(.spring(response: 0.28, dampingFraction: 0.62), value: table.comboFlash)
    }

    private var coach: some View {
        ZStack {
            Color.black.opacity(0.55)
            VStack(alignment: .leading, spacing: 12) {
                Text("CRUSH")
                    .font(Lucky.black(22))
                    .tracking(2)
                    .foregroundStyle(Lucky.goldSoft)
                    .frame(maxWidth: .infinity)
                coachLine("1", "Tap two neighboring fruits to swap.")
                coachLine("2", "Match 3. Four clears a line. Five clears that fruit.")
                coachLine("3", "A little of the crush score banks into your coins.")
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
                if table.resultCleared, table.lastBank > 0 {
                    Text("Banked +\(table.lastBank) score")
                        .font(Lucky.bold(14))
                        .foregroundStyle(Lucky.goldSoft)
                }
                HStack(spacing: 10) {
                    resultButton(table.resultCleared ? (table.level >= table.levelCount ? "Again" : "Next") : "Retry") {
                        store.audio.click()
                        if table.resultCleared {
                            table.nextLevel()
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
        if table.resultCleared, table.level >= table.levelCount { return "ALL LIT" }
        return table.resultCleared ? "LEVEL CLEAR" : "OUT OF MOVES"
    }

    private var resultDetail: String {
        if table.resultCleared {
            return "\(table.score) / \(table.current.target)"
        }
        return "Need \(max(0, table.current.target - table.score)) more"
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
}
