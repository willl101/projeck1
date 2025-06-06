import Foundation

// MARK: - 手牌评估器
class HandEvaluator {
    
    // 评估七张牌（手牌2张+公共牌5张）的最佳五张牌组合
    static func evaluateHand(cards: [Card]) -> HandEvaluation {
        guard cards.count >= 5 else {
            return HandEvaluation(rank: .highCard, cards: cards, kickers: [])
        }
        
        let sortedCards = cards.sorted { $0.sortValue > $1.sortValue }
        
        // 检查各种牌型
        if let royalFlush = checkRoyalFlush(cards: sortedCards) {
            return royalFlush
        }
        
        if let straightFlush = checkStraightFlush(cards: sortedCards) {
            return straightFlush
        }
        
        if let fourOfAKind = checkFourOfAKind(cards: sortedCards) {
            return fourOfAKind
        }
        
        if let fullHouse = checkFullHouse(cards: sortedCards) {
            return fullHouse
        }
        
        if let flush = checkFlush(cards: sortedCards) {
            return flush
        }
        
        if let straight = checkStraight(cards: sortedCards) {
            return straight
        }
        
        if let threeOfAKind = checkThreeOfAKind(cards: sortedCards) {
            return threeOfAKind
        }
        
        if let twoPair = checkTwoPair(cards: sortedCards) {
            return twoPair
        }
        
        if let onePair = checkOnePair(cards: sortedCards) {
            return onePair
        }
        
        return checkHighCard(cards: sortedCards)
    }
    
    // MARK: - 牌型检查方法
    
    private static func checkRoyalFlush(cards: [Card]) -> HandEvaluation? {
        for suit in Suit.allCases {
            let suitCards = cards.filter { $0.suit == suit }
            if suitCards.count >= 5 {
                let royalRanks: Set<Rank> = [.ten, .jack, .queen, .king, .ace]
                let royalCards = suitCards.filter { royalRanks.contains($0.rank) }
                if royalCards.count == 5 {
                    return HandEvaluation(rank: .royalFlush, cards: royalCards, kickers: [])
                }
            }
        }
        return nil
    }
    
    private static func checkStraightFlush(cards: [Card]) -> HandEvaluation? {
        for suit in Suit.allCases {
            let suitCards = cards.filter { $0.suit == suit }
            if suitCards.count >= 5 {
                if let straight = findStraight(in: suitCards) {
                    return HandEvaluation(rank: .straightFlush, cards: straight, kickers: [])
                }
            }
        }
        return nil
    }
    
    private static func checkFourOfAKind(cards: [Card]) -> HandEvaluation? {
        let rankGroups = Dictionary(grouping: cards, by: { $0.rank })
        
        for (rank, groupCards) in rankGroups {
            if groupCards.count >= 4 {
                let fourCards = Array(groupCards.prefix(4))
                let kickers = cards.filter { $0.rank != rank }.prefix(1)
                return HandEvaluation(rank: .fourOfAKind, cards: fourCards, kickers: Array(kickers))
            }
        }
        return nil
    }
    
    private static func checkFullHouse(cards: [Card]) -> HandEvaluation? {
        let rankGroups = Dictionary(grouping: cards, by: { $0.rank })
        var threeCards: [Card] = []
        var pairCards: [Card] = []
        
        for (_, groupCards) in rankGroups.sorted(by: { $0.value.count > $1.value.count }) {
            if groupCards.count >= 3 && threeCards.isEmpty {
                threeCards = Array(groupCards.prefix(3))
            } else if groupCards.count >= 2 && pairCards.isEmpty {
                pairCards = Array(groupCards.prefix(2))
            }
        }
        
        if !threeCards.isEmpty && !pairCards.isEmpty {
            return HandEvaluation(rank: .fullHouse, cards: threeCards + pairCards, kickers: [])
        }
        return nil
    }
    
    private static func checkFlush(cards: [Card]) -> HandEvaluation? {
        for suit in Suit.allCases {
            let suitCards = cards.filter { $0.suit == suit }
            if suitCards.count >= 5 {
                let bestFive = Array(suitCards.prefix(5))
                return HandEvaluation(rank: .flush, cards: bestFive, kickers: [])
            }
        }
        return nil
    }
    
    private static func checkStraight(cards: [Card]) -> HandEvaluation? {
        if let straight = findStraight(in: cards) {
            return HandEvaluation(rank: .straight, cards: straight, kickers: [])
        }
        return nil
    }
    
    private static func checkThreeOfAKind(cards: [Card]) -> HandEvaluation? {
        let rankGroups = Dictionary(grouping: cards, by: { $0.rank })
        
        for (rank, groupCards) in rankGroups {
            if groupCards.count >= 3 {
                let threeCards = Array(groupCards.prefix(3))
                let kickers = cards.filter { $0.rank != rank }.prefix(2)
                return HandEvaluation(rank: .threeOfAKind, cards: threeCards, kickers: Array(kickers))
            }
        }
        return nil
    }
    
    private static func checkTwoPair(cards: [Card]) -> HandEvaluation? {
        let rankGroups = Dictionary(grouping: cards, by: { $0.rank })
        var pairs: [Card] = []
        var pairRanks: [Rank] = []
        
        for (rank, groupCards) in rankGroups.sorted(by: { $0.key.sortValue > $1.key.sortValue }) {
            if groupCards.count >= 2 && pairs.count < 4 {
                pairs.append(contentsOf: Array(groupCards.prefix(2)))
                pairRanks.append(rank)
            }
        }
        
        if pairs.count >= 4 {
            let kickers = cards.filter { !pairRanks.contains($0.rank) }.prefix(1)
            return HandEvaluation(rank: .twoPair, cards: Array(pairs.prefix(4)), kickers: Array(kickers))
        }
        return nil
    }
    
    private static func checkOnePair(cards: [Card]) -> HandEvaluation? {
        let rankGroups = Dictionary(grouping: cards, by: { $0.rank })
        
        for (rank, groupCards) in rankGroups.sorted(by: { $0.key.sortValue > $1.key.sortValue }) {
            if groupCards.count >= 2 {
                let pairCards = Array(groupCards.prefix(2))
                let kickers = cards.filter { $0.rank != rank }.prefix(3)
                return HandEvaluation(rank: .onePair, cards: pairCards, kickers: Array(kickers))
            }
        }
        return nil
    }
    
    private static func checkHighCard(cards: [Card]) -> HandEvaluation {
        let bestFive = Array(cards.prefix(5))
        return HandEvaluation(rank: .highCard, cards: [], kickers: bestFive)
    }
    
    private static func findStraight(in cards: [Card]) -> [Card]? {
        let uniqueRanks = Array(Set(cards.map { $0.rank })).sorted { $0.sortValue > $1.sortValue }
        
        // 检查是否有足够的牌形成顺子
        guard uniqueRanks.count >= 5 else { return nil }
        
        // 检查A-2-3-4-5顺子
        let wheelRanks: [Rank] = [.ace, .five, .four, .three, .two]
        let wheelCards = wheelRanks.compactMap { rank in
            cards.first { $0.rank == rank }
        }
        if wheelCards.count == 5 {
            return wheelCards
        }
        
        // 检查常规顺子
        let maxIndex = uniqueRanks.count - 5
        guard maxIndex >= 0 else { return nil }
        
        for i in 0...maxIndex {
            let endIndex = i + 5
            guard endIndex <= uniqueRanks.count else { continue }
            
            let straightRanks = Array(uniqueRanks[i..<endIndex])
            if isConsecutive(ranks: straightRanks) {
                let straightCards = straightRanks.compactMap { rank in
                    cards.first { $0.rank == rank }
                }
                if straightCards.count == 5 {
                    return straightCards
                }
            }
        }
        
        return nil
    }
    
    private static func isConsecutive(ranks: [Rank]) -> Bool {
        guard ranks.count >= 2 else { return false }
        
        for i in 0..<(ranks.count - 1) {
            if ranks[i].sortValue - ranks[i+1].sortValue != 1 {
                return false
            }
        }
        return true
    }
}

// MARK: - 胜率计算器
class WinRateCalculator {
    
    // 蒙特卡洛模拟计算胜率
    static func calculateWinRate(
        playerHoleCards: [Card],
        communityCards: [Card],
        opponentCount: Int,
        iterations: Int = 5000  // 减少迭代次数以提高性能
    ) -> Double {
        
        guard !playerHoleCards.isEmpty else { return 0.0 }
        guard opponentCount > 0 else { return 1.0 }
        
        var wins = 0
        var ties = 0
        let usedCards = Set(playerHoleCards + communityCards)
        
        // 根据已知牌的数量调整迭代次数
        let adjustedIterations = communityCards.count >= 3 ? iterations / 2 : iterations
        
        for _ in 0..<adjustedIterations {
            var deck = createDeck(excluding: usedCards)
            deck.shuffle()
            
            // 完成公共牌
            var fullCommunityCards = communityCards
            let cardsNeeded = 5 - fullCommunityCards.count
            for _ in 0..<cardsNeeded {
                if !deck.isEmpty {
                    fullCommunityCards.append(deck.removeFirst())
                }
            }
            
            // 为对手发牌
            var opponentHands: [[Card]] = []
            let maxOpponents = min(opponentCount, deck.count / 2)
            guard maxOpponents > 0 else { continue }
            
            for _ in 0..<maxOpponents {
                if deck.count >= 2 {
                    let opponentCards = [deck.removeFirst(), deck.removeFirst()]
                    opponentHands.append(opponentCards)
                } else {
                    break
                }
            }
            
            guard !opponentHands.isEmpty else { continue }
            
            // 评估所有手牌
            let playerEvaluation = HandEvaluator.evaluateHand(cards: playerHoleCards + fullCommunityCards)
            let opponentEvaluations = opponentHands.map { hand in
                HandEvaluator.evaluateHand(cards: hand + fullCommunityCards)
            }
            
            // 检查是否获胜或平局
            let betterHands = opponentEvaluations.filter { $0 > playerEvaluation }.count
            let equalHands = opponentEvaluations.filter { $0 == playerEvaluation }.count
            
            if betterHands == 0 && equalHands == 0 {
                wins += 1
            } else if betterHands == 0 && equalHands > 0 {
                ties += 1
            }
        }
        
        // 平局计算为0.5胜
        return (Double(wins) + Double(ties) * 0.5) / Double(adjustedIterations)
    }
    
    private static func createDeck(excluding usedCards: Set<Card>) -> [Card] {
        var deck: [Card] = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                let card = Card(suit: suit, rank: rank)
                if !usedCards.contains(card) {
                    deck.append(card)
                }
            }
        }
        return deck
    }
}

// MARK: - AI决策引擎
class PokerAI {
    
    // 计算底池赔率
    static func calculatePotOdds(potSize: Int, betToCall: Int) -> Double {
        guard betToCall > 0 else { return 0 }
        return Double(betToCall) / Double(potSize + betToCall)
    }
    
    // 获取智能建议
    static func getRecommendation(
        gameState: GameState,
        playerIndex: Int
    ) -> AIRecommendation {
        
        guard playerIndex < gameState.players.count else {
            return AIRecommendation(action: .fold, confidence: 1.0, reasoning: "无效玩家")
        }
        
        let player = gameState.players[playerIndex]
        let winRate = WinRateCalculator.calculateWinRate(
            playerHoleCards: player.holeCards,
            communityCards: gameState.communityCards,
            opponentCount: gameState.activePlayers.count - 1
        )
        
        let potOdds = calculatePotOdds(
            potSize: gameState.totalPot,
            betToCall: gameState.currentBet - player.currentBet
        )
        
        // 基于胜率和赔率的决策逻辑
        if winRate > 0.7 {
            return AIRecommendation(
                action: .raise,
                confidence: winRate,
                reasoning: "手牌强度很高（胜率 \(Int(winRate * 100))%），建议加注施压"
            )
        } else if winRate > 0.5 && winRate > potOdds {
            return AIRecommendation(
                action: .call,
                confidence: winRate,
                reasoning: "胜率（\(Int(winRate * 100))%）超过底池赔率（\(Int(potOdds * 100))%），建议跟注"
            )
        } else if winRate > 0.3 && gameState.currentBet == 0 {
            return AIRecommendation(
                action: .check,
                confidence: winRate,
                reasoning: "中等手牌，可以免费看牌"
            )
        } else {
            return AIRecommendation(
                action: .fold,
                confidence: 1.0 - winRate,
                reasoning: "胜率过低（\(Int(winRate * 100))%），建议弃牌"
            )
        }
    }
    
    // AI玩家决策
    static func makeAIDecision(
        gameState: GameState,
        aiPlayer: Player
    ) -> PlayerAction {
        
        guard let playerIndex = gameState.players.firstIndex(where: { $0.id == aiPlayer.id }) else {
            return .fold
        }
        
        let recommendation = getRecommendation(gameState: gameState, playerIndex: playerIndex)
        let callAmount = gameState.currentBet - aiPlayer.currentBet
        
        // 检查特殊情况
        if callAmount >= aiPlayer.chips {
            // 如果跟注需要全押，基于胜率决定
            let winRate = WinRateCalculator.calculateWinRate(
                playerHoleCards: aiPlayer.holeCards,
                communityCards: gameState.communityCards,
                opponentCount: gameState.activePlayers.count - 1
            )
            return winRate > 0.4 ? .allIn : .fold
        }
        
        if gameState.currentBet == 0 && recommendation.action == .call {
            return .check // 没有下注时选择看牌而不是跟注
        }
        
        // 根据AI难度调整决策
        switch aiPlayer.difficulty {
        case .easy:
            // 简单AI：更保守，降低激进度
            if recommendation.action == .raise && recommendation.confidence < 0.8 {
                return callAmount == 0 ? .check : .call
            }
            if recommendation.action == .call && recommendation.confidence < 0.3 {
                return .fold
            }
        case .medium:
            // 中等AI：按推荐执行，但加入一些随机性
            if recommendation.action == .raise && recommendation.confidence < 0.6 && Bool.random() {
                return callAmount == 0 ? .check : .call
            }
        case .hard:
            // 困难AI：更激进，适当虚张声势
            if recommendation.action == .call && recommendation.confidence > 0.6 {
                return .raise
            }
            if recommendation.action == .fold && recommendation.confidence > 0.2 && Bool.random() {
                return callAmount == 0 ? .check : .call
            }
        case .expert:
            // 专家AI：加入混合策略和位置考虑
            let isLatePosition = playerIndex >= gameState.players.count / 2
            if isLatePosition && recommendation.action == .call && recommendation.confidence > 0.5 {
                return .raise
            }
            if !isLatePosition && recommendation.action == .raise && recommendation.confidence < 0.7 {
                return callAmount == 0 ? .check : .call
            }
            // 25% 概率的虚张声势
            if recommendation.confidence > 0.3 {
                let randomValue = Int.random(in: 0..<4)
                if randomValue == 0 {
                    return recommendation.action == .fold ? (callAmount == 0 ? .check : .call) : .raise
                }
            }
        case .none:
            break
        }
        
        return recommendation.action
    }
}

// MARK: - AI推荐结构
struct AIRecommendation {
    let action: PlayerAction
    let confidence: Double
    let reasoning: String
    
    var confidenceLevel: String {
        switch confidence {
        case 0.8...1.0: return "非常确信"
        case 0.6..<0.8: return "比较确信"
        case 0.4..<0.6: return "一般确信"
        case 0.2..<0.4: return "不太确信"
        default: return "不确信"
        }
    }
} 