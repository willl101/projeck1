import Foundation
import SwiftUI

// MARK: - 游戏阶段
enum GamePhase: String, CaseIterable, Codable {
    case preflop = "翻牌前"
    case flop = "翻牌"
    case turn = "转牌"
    case river = "河牌"
    case showdown = "摊牌"
    case finished = "结束"
    
    var description: String {
        switch self {
        case .preflop: return "发底牌阶段"
        case .flop: return "发前三张公共牌"
        case .turn: return "发第四张公共牌"
        case .river: return "发第五张公共牌"
        case .showdown: return "比牌阶段"
        case .finished: return "游戏结束"
        }
    }
    
    var communityCardsCount: Int {
        switch self {
        case .preflop: return 0
        case .flop: return 3
        case .turn: return 4
        case .river: return 5
        case .showdown, .finished: return 5
        }
    }
}

// MARK: - 手牌类型
enum HandRank: Int, CaseIterable, Codable, Comparable {
    case highCard = 1
    case onePair = 2
    case twoPair = 3
    case threeOfAKind = 4
    case straight = 5
    case flush = 6
    case fullHouse = 7
    case fourOfAKind = 8
    case straightFlush = 9
    case royalFlush = 10
    
    var name: String {
        switch self {
        case .highCard: return "高牌"
        case .onePair: return "一对"
        case .twoPair: return "两对"
        case .threeOfAKind: return "三条"
        case .straight: return "顺子"
        case .flush: return "同花"
        case .fullHouse: return "葫芦"
        case .fourOfAKind: return "四条"
        case .straightFlush: return "同花顺"
        case .royalFlush: return "皇家同花顺"
        }
    }
    
    var description: String {
        switch self {
        case .highCard: return "最大的单张牌"
        case .onePair: return "两张相同点数的牌"
        case .twoPair: return "两个不同的对子"
        case .threeOfAKind: return "三张相同点数的牌"
        case .straight: return "五张连续的牌"
        case .flush: return "五张同花色的牌"
        case .fullHouse: return "三条加一对"
        case .fourOfAKind: return "四张相同点数的牌"
        case .straightFlush: return "同花色的顺子"
        case .royalFlush: return "10、J、Q、K、A的同花顺"
        }
    }
    
    static func < (lhs: HandRank, rhs: HandRank) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - 手牌评估结果
struct HandEvaluation: Codable, Comparable {
    let rank: HandRank
    let cards: [Card]
    let kickers: [Card] // 用于比较的踢脚牌
    
    static func < (lhs: HandEvaluation, rhs: HandEvaluation) -> Bool {
        if lhs.rank != rhs.rank {
            return lhs.rank < rhs.rank
        }
        
        // 同样手牌类型，比较关键牌和踢脚牌
        let lhsValues = lhs.cards.map { $0.sortValue } + lhs.kickers.map { $0.sortValue }
        let rhsValues = rhs.cards.map { $0.sortValue } + rhs.kickers.map { $0.sortValue }
        
        for (l, r) in zip(lhsValues, rhsValues) {
            if l != r {
                return l < r
            }
        }
        
        return false // 完全相等
    }
    
    static func == (lhs: HandEvaluation, rhs: HandEvaluation) -> Bool {
        return !(lhs < rhs) && !(rhs < lhs)
    }
}

// MARK: - 底池
struct Pot: Codable {
    var amount: Int = 0
    var contributors: [UUID] = [] // 参与者ID
    var isMainPot: Bool = true
    
    mutating func addChips(_ chips: Int, from playerId: UUID) {
        amount += chips
        if !contributors.contains(playerId) {
            contributors.append(playerId)
        }
    }
    
    mutating func reset() {
        amount = 0
        contributors.removeAll()
    }
}

// MARK: - 游戏状态
class GameState: ObservableObject, Codable {
    @Published var players: [Player] = []
    @Published var deck = Deck()
    @Published var communityCards: [Card] = []
    @Published var currentPhase: GamePhase = .preflop
    @Published var currentPlayerIndex: Int = 0
    @Published var dealerIndex: Int = 0
    @Published var smallBlindIndex: Int = 1
    @Published var bigBlindIndex: Int = 2
    @Published var pot = Pot()
    @Published var sidePots: [Pot] = []
    @Published var currentBet: Int = 0
    @Published var minRaise: Int = 0
    @Published var smallBlindAmount: Int = 10
    @Published var bigBlindAmount: Int = 20
    @Published var handNumber: Int = 1
    @Published var isGameActive: Bool = false
    @Published var winner: Player?
    @Published var gameLog: [String] = []
    
    // MARK: - 管理器
    private let soundManager = SoundManager.shared
    private let gameConfig = GameConfiguration.shared
    
    // MARK: - 编码支持
    enum CodingKeys: String, CodingKey {
        case players, communityCards, currentPhase, currentPlayerIndex
        case dealerIndex, smallBlindIndex, bigBlindIndex, pot, sidePots
        case currentBet, minRaise, smallBlindAmount, bigBlindAmount
        case handNumber, isGameActive, gameLog
    }
    
    init() {
        setupGame()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.players = try container.decode([Player].self, forKey: .players)
        self.communityCards = try container.decode([Card].self, forKey: .communityCards)
        self.currentPhase = try container.decode(GamePhase.self, forKey: .currentPhase)
        self.currentPlayerIndex = try container.decode(Int.self, forKey: .currentPlayerIndex)
        self.dealerIndex = try container.decode(Int.self, forKey: .dealerIndex)
        self.smallBlindIndex = try container.decode(Int.self, forKey: .smallBlindIndex)
        self.bigBlindIndex = try container.decode(Int.self, forKey: .bigBlindIndex)
        self.pot = try container.decode(Pot.self, forKey: .pot)
        self.sidePots = try container.decode([Pot].self, forKey: .sidePots)
        self.currentBet = try container.decode(Int.self, forKey: .currentBet)
        self.minRaise = try container.decode(Int.self, forKey: .minRaise)
        self.smallBlindAmount = try container.decode(Int.self, forKey: .smallBlindAmount)
        self.bigBlindAmount = try container.decode(Int.self, forKey: .bigBlindAmount)
        self.handNumber = try container.decode(Int.self, forKey: .handNumber)
        self.isGameActive = try container.decode(Bool.self, forKey: .isGameActive)
        self.gameLog = try container.decode([String].self, forKey: .gameLog)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(players, forKey: .players)
        try container.encode(communityCards, forKey: .communityCards)
        try container.encode(currentPhase, forKey: .currentPhase)
        try container.encode(currentPlayerIndex, forKey: .currentPlayerIndex)
        try container.encode(dealerIndex, forKey: .dealerIndex)
        try container.encode(smallBlindIndex, forKey: .smallBlindIndex)
        try container.encode(bigBlindIndex, forKey: .bigBlindIndex)
        try container.encode(pot, forKey: .pot)
        try container.encode(sidePots, forKey: .sidePots)
        try container.encode(currentBet, forKey: .currentBet)
        try container.encode(minRaise, forKey: .minRaise)
        try container.encode(smallBlindAmount, forKey: .smallBlindAmount)
        try container.encode(bigBlindAmount, forKey: .bigBlindAmount)
        try container.encode(handNumber, forKey: .handNumber)
        try container.encode(isGameActive, forKey: .isGameActive)
        try container.encode(gameLog, forKey: .gameLog)
    }
    
    // MARK: - 游戏初始化
    func setupGame() {
        // 创建默认玩家
        addPlayer(Player(name: "玩家", chips: 1000, type: .human))
        addPlayer(Player(name: "AI-简单", chips: 1000, type: .ai, difficulty: .easy))
        addPlayer(Player(name: "AI-中等", chips: 1000, type: .ai, difficulty: .medium))
        addPlayer(Player(name: "AI-困难", chips: 1000, type: .ai, difficulty: .hard))
        
        updatePositions()
    }
    
    func addPlayer(_ player: Player) {
        players.append(player)
        player.position = players.count - 1
        updatePositions()
    }
    
    func removePlayer(at index: Int) {
        guard index < players.count else { return }
        players.remove(at: index)
        updatePositions()
    }
    
    // MARK: - 位置管理
    func updatePositions() {
        guard players.count >= 2 else { 
            dealerIndex = 0
            smallBlindIndex = 0
            bigBlindIndex = 0
            return 
        }
        
        // 确保索引在有效范围内
        dealerIndex = min(dealerIndex, players.count - 1)
        smallBlindIndex = (dealerIndex + 1) % players.count
        bigBlindIndex = (dealerIndex + 2) % players.count
        
        // 如果只有2个玩家，大盲注等于庄家
        if players.count == 2 {
            bigBlindIndex = dealerIndex
        }
        
        for (index, player) in players.enumerated() {
            player.position = index
            player.isDealer = index == dealerIndex
            player.isSmallBlind = index == smallBlindIndex
            player.isBigBlind = index == bigBlindIndex
        }
    }
    
    func moveDealer() {
        guard players.count >= 2 else { return }
        dealerIndex = (dealerIndex + 1) % players.count
        updatePositions()
    }
    
    // MARK: - 游戏控制
    func startNewHand() {
        // 重置游戏状态
        deck.reset()
        communityCards.removeAll()
        currentPhase = .preflop
        pot.reset()
        sidePots.removeAll()
        currentBet = 0
        minRaise = bigBlindAmount
        winner = nil
        
        // 重置玩家状态
        for player in players {
            player.resetForNewHand()
        }
        
        // 发底牌
        dealHoleCards()
        
        // 收盲注
        collectBlinds()
        
        // 设置第一个行动玩家（大盲注后的玩家）
        guard players.count > 0 else { return }
        currentPlayerIndex = (bigBlindIndex + 1) % players.count
        
        isGameActive = true
        
        addToLog("开始第 \(handNumber) 手牌")
        
        // 如果当前玩家是AI，自动执行行动
        processCurrentPlayerAction()
    }
    
    func dealHoleCards() {
        for player in players where player.status != .busted {
            let cards = deck.dealCards(count: 2)
            player.dealHoleCards(cards)
        }
        soundManager.playSound(.dealCard)
        addToLog("发放底牌")
    }
    
    func collectBlinds() {
        guard smallBlindIndex >= 0 && smallBlindIndex < players.count,
              bigBlindIndex >= 0 && bigBlindIndex < players.count else {
            addToLog("盲注索引错误，跳过盲注收取")
            return
        }
        
        let smallBlindPlayer = players[smallBlindIndex]
        let bigBlindPlayer = players[bigBlindIndex]
        
        smallBlindPlayer.placeBet(smallBlindAmount)
        pot.addChips(smallBlindAmount, from: smallBlindPlayer.id)
        addToLog("\(smallBlindPlayer.name) 支付小盲注 \(smallBlindAmount)")
        
        bigBlindPlayer.placeBet(bigBlindAmount)
        pot.addChips(bigBlindAmount, from: bigBlindPlayer.id)
        currentBet = bigBlindAmount
        addToLog("\(bigBlindPlayer.name) 支付大盲注 \(bigBlindAmount)")
    }
    
    // MARK: - 玩家行动处理
    func processPlayerAction(_ action: PlayerAction, player: Player? = nil) {
        let actionPlayer = player ?? currentPlayer
        guard let actionPlayer = actionPlayer else { return }
        
        // 执行玩家行动
        switch action {
        case .fold:
            actionPlayer.fold()
            soundManager.playSound(.fold)
            addToLog("\(actionPlayer.name) 弃牌")
            
        case .check:
            actionPlayer.check()
            addToLog("\(actionPlayer.name) 看牌")
            
        case .call:
            let callAmount = currentBet - actionPlayer.currentBet
            actionPlayer.call(callAmount)
            pot.addChips(callAmount, from: actionPlayer.id)
            soundManager.playSound(.call)
            addToLog("\(actionPlayer.name) 跟注 \(callAmount)")
            
        case .raise:
            let raiseAmount = max(currentBet + minRaise, actionPlayer.currentBet + minRaise)
            let raiseAmountToAdd = raiseAmount - actionPlayer.currentBet
            actionPlayer.raise(to: raiseAmountToAdd)
            pot.addChips(raiseAmountToAdd, from: actionPlayer.id)
            currentBet = raiseAmount
            soundManager.playSound(.raise)
            addToLog("\(actionPlayer.name) 加注到 \(raiseAmount)")
            
        case .allIn:
            let allInAmount = actionPlayer.chips
            actionPlayer.allIn()
            pot.addChips(allInAmount, from: actionPlayer.id)
            if actionPlayer.totalBetInRound > currentBet {
                currentBet = actionPlayer.totalBetInRound
            }
            soundManager.playSound(.allIn)
            addToLog("\(actionPlayer.name) 全押 \(allInAmount)")
        }
        
        // 移动到下一个玩家
        moveToNextPlayer()
    }
    
    private func moveToNextPlayer() {
        // 检查是否回合结束
        if isBettingRoundComplete() {
            nextPhase()
            return
        }
        
        guard players.count > 0 else { return }
        
        // 移动到下一个有效玩家
        var attempts = 0
        repeat {
            currentPlayerIndex = (currentPlayerIndex + 1) % players.count
            attempts += 1
        } while !(currentPlayer?.canAct ?? false) && activePlayers.count > 1 && attempts < players.count
        
        // 处理当前玩家行动
        processCurrentPlayerAction()
    }
    
    private func processCurrentPlayerAction() {
        guard let player = currentPlayer else { return }
        
        // 如果是AI玩家，自动执行行动
        if player.type == .ai {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let aiAction = PokerAI.makeAIDecision(gameState: self, aiPlayer: player)
                self.processPlayerAction(aiAction, player: player)
            }
        }
        // 如果是人类玩家，等待用户操作
    }
    
    private func isBettingRoundComplete() -> Bool {
        let activePlayers = players.filter { $0.canAct || $0.status == .allIn }
        
        // 如果只有一个或零个活跃玩家，回合结束
        if activePlayers.count <= 1 {
            return true
        }
        
        // 检查所有活跃玩家是否都行动过且下注相等
        let playersWhoCanBet = activePlayers.filter { $0.canAct }
        if playersWhoCanBet.isEmpty {
            return true
        }
        
        // 检查所有能下注的玩家是否都有相同的下注额或已行动过
        let maxBet = playersWhoCanBet.map { $0.currentBet }.max() ?? 0
        let allPlayersEqualBet = playersWhoCanBet.allSatisfy { player in
            player.currentBet == maxBet || player.lastAction != nil
        }
        
        return allPlayersEqualBet && playersWhoCanBet.allSatisfy { $0.lastAction != nil }
    }
    
    // MARK: - 游戏阶段推进
    func nextPhase() {
        switch currentPhase {
        case .preflop:
            dealFlop()
        case .flop:
            dealTurn()
        case .turn:
            dealRiver()
        case .river:
            showdown()
        case .showdown:
            endHand()
        case .finished:
            break
        }
    }
    
    func dealFlop() {
        let flopCards = deck.dealCards(count: 3)
        communityCards.append(contentsOf: flopCards)
        currentPhase = .flop
        resetBetting()
        soundManager.playSound(.cardFlip)
        addToLog("发放翻牌: \(flopCards.map { $0.description }.joined(separator: " "))")
        processCurrentPlayerAction()
    }
    
    func dealTurn() {
        if let turnCard = deck.deal() {
            communityCards.append(turnCard)
            currentPhase = .turn
            resetBetting()
            soundManager.playSound(.cardFlip)
            addToLog("发放转牌: \(turnCard.description)")
            processCurrentPlayerAction()
        }
    }
    
    func dealRiver() {
        if let riverCard = deck.deal() {
            communityCards.append(riverCard)
            currentPhase = .river
            resetBetting()
            soundManager.playSound(.cardFlip)
            addToLog("发放河牌: \(riverCard.description)")
            processCurrentPlayerAction()
        }
    }
    
    func showdown() {
        currentPhase = .showdown
        addToLog("进入摊牌阶段")
        determineWinner()
    }
    
    func endHand() {
        currentPhase = .finished
        handNumber += 1
        moveDealer()
        isGameActive = false
        addToLog("手牌结束\n")
    }
    
    func resetBetting() {
        currentBet = 0
        guard players.count > 0 else { return }
        
        currentPlayerIndex = (dealerIndex + 1) % players.count
        
        for player in players {
            player.resetForNewRound()
        }
        
        // 跳过已经弃牌或出局的玩家
        var attempts = 0
        while !(currentPlayer?.canAct ?? false) && activePlayers.count > 1 && attempts < players.count {
            currentPlayerIndex = (currentPlayerIndex + 1) % players.count
            attempts += 1
        }
    }
    
    // MARK: - 获胜者判定
    func determineWinner() {
        let activePlayers = players.filter { $0.isActive }
        
        if activePlayers.count == 1 {
            // 只有一个玩家，直接获胜
            winner = activePlayers.first
            winner?.chips += pot.amount
            addToLog("\(winner?.name ?? "") 获胜，赢得 \(pot.amount) 筹码")
        } else {
            // 多个玩家，比较手牌
            let playerEvaluations: [(player: Player, evaluation: HandEvaluation)] = activePlayers.compactMap { player in
                let allCards = player.holeCards + communityCards
                guard allCards.count >= 2 else { return nil }
                let evaluation = HandEvaluator.evaluateHand(cards: allCards)
                return (player: player, evaluation: evaluation)
            }
            
            // 确保有可比较的手牌
            guard !playerEvaluations.isEmpty else {
                addToLog("无法评估手牌，游戏结束")
                return
            }
            
            // 找到最强的手牌
            let sortedEvaluations = playerEvaluations.sorted { $0.evaluation > $1.evaluation }
            guard let bestEvaluation = sortedEvaluations.first?.evaluation else { return }
            let winners = sortedEvaluations.filter { $0.evaluation == bestEvaluation }
            
            if winners.count == 1 {
                // 单独获胜者
                winner = winners.first!.player
                winner?.chips += pot.amount
                addToLog("\(winner?.name ?? "") 以 \(bestEvaluation.rank.name) 获胜，赢得 \(pot.amount) 筹码")
            } else {
                // 平分底池
                let winningAmount = pot.amount / winners.count
                for winnerData in winners {
                    winnerData.player.chips += winningAmount
                }
                let winnerNames = winners.map { $0.player.name }.joined(separator: ", ")
                addToLog("\(winnerNames) 平分底池，各得 \(winningAmount) 筹码")
            }
        }
    }
    
    // MARK: - 日志管理
    func addToLog(_ message: String) {
        let timestamp = DateFormatter().string(from: Date())
        gameLog.append("[\(timestamp)] \(message)")
    }
    
    // MARK: - 计算属性
    var activePlayers: [Player] {
        return players.filter { $0.isActive }
    }
    
    var currentPlayer: Player? {
        guard currentPlayerIndex >= 0 && currentPlayerIndex < players.count else { return nil }
        return players[currentPlayerIndex]
    }
    
    var totalPot: Int {
        return pot.amount + sidePots.reduce(0) { $0 + $1.amount }
    }
} 