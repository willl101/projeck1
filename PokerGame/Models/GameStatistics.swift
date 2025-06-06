import Foundation

// MARK: - 游戏统计数据
class GameStatistics: ObservableObject, Codable {
    @Published var totalHands: Int = 0
    @Published var handsWon: Int = 0
    @Published var totalChipsWon: Int = 0
    @Published var totalChipsLost: Int = 0
    @Published var biggestWin: Int = 0
    @Published var biggestLoss: Int = 0
    @Published var gamesSessions: Int = 0
    @Published var totalPlayTime: TimeInterval = 0
    @Published var handHistory: [HandResult] = []
    @Published var sessionHistory: [GameSession] = []
    
    // MARK: - 编码支持
    enum CodingKeys: String, CodingKey {
        case totalHands, handsWon, totalChipsWon, totalChipsLost
        case biggestWin, biggestLoss, gamesSessions, totalPlayTime
        case handHistory, sessionHistory
    }
    
    init() {}
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalHands = try container.decode(Int.self, forKey: .totalHands)
        handsWon = try container.decode(Int.self, forKey: .handsWon)
        totalChipsWon = try container.decode(Int.self, forKey: .totalChipsWon)
        totalChipsLost = try container.decode(Int.self, forKey: .totalChipsLost)
        biggestWin = try container.decode(Int.self, forKey: .biggestWin)
        biggestLoss = try container.decode(Int.self, forKey: .biggestLoss)
        gamesSessions = try container.decode(Int.self, forKey: .gamesSessions)
        totalPlayTime = try container.decode(TimeInterval.self, forKey: .totalPlayTime)
        handHistory = try container.decode([HandResult].self, forKey: .handHistory)
        sessionHistory = try container.decode([GameSession].self, forKey: .sessionHistory)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(totalHands, forKey: .totalHands)
        try container.encode(handsWon, forKey: .handsWon)
        try container.encode(totalChipsWon, forKey: .totalChipsWon)
        try container.encode(totalChipsLost, forKey: .totalChipsLost)
        try container.encode(biggestWin, forKey: .biggestWin)
        try container.encode(biggestLoss, forKey: .biggestLoss)
        try container.encode(gamesSessions, forKey: .gamesSessions)
        try container.encode(totalPlayTime, forKey: .totalPlayTime)
        try container.encode(handHistory, forKey: .handHistory)
        try container.encode(sessionHistory, forKey: .sessionHistory)
    }
    
    // MARK: - 记录手牌结果
    func recordHand(result: HandResult) {
        totalHands += 1
        
        if result.won {
            handsWon += 1
        }
        
        let chipsChange = result.chipsChange
        if chipsChange > 0 {
            totalChipsWon += chipsChange
            if chipsChange > biggestWin {
                biggestWin = chipsChange
            }
        } else if chipsChange < 0 {
            let loss = abs(chipsChange)
            totalChipsLost += loss
            if loss > biggestLoss {
                biggestLoss = loss
            }
        }
        
        handHistory.append(result)
        
        // 只保留最近1000手的记录
        if handHistory.count > 1000 {
            handHistory.removeFirst()
        }
    }
    
    // MARK: - 记录游戏会话
    func startSession() -> GameSession {
        let session = GameSession(startTime: Date())
        gamesSessions += 1
        return session
    }
    
    func endSession(_ session: GameSession, finalChips: Int) {
        session.endSession(finalChips: finalChips)
        totalPlayTime += session.duration
        sessionHistory.append(session)
        
        // 只保留最近100个会话
        if sessionHistory.count > 100 {
            sessionHistory.removeFirst()
        }
    }
    
    // MARK: - 计算属性
    var winRate: Double {
        guard totalHands > 0 else { return 0.0 }
        return Double(handsWon) / Double(totalHands)
    }
    
    var netChips: Int {
        return totalChipsWon - totalChipsLost
    }
    
    var averageWin: Double {
        guard handsWon > 0 else { return 0.0 }
        return Double(totalChipsWon) / Double(handsWon)
    }
    
    var averageLoss: Double {
        let handsLost = totalHands - handsWon
        guard handsLost > 0 else { return 0.0 }
        return Double(totalChipsLost) / Double(handsLost)
    }
    
    var averageSessionTime: TimeInterval {
        guard sessionHistory.count > 0 else { return 0.0 }
        return totalPlayTime / TimeInterval(sessionHistory.count)
    }
    
    // MARK: - 重置统计数据
    func resetStatistics() {
        totalHands = 0
        handsWon = 0
        totalChipsWon = 0
        totalChipsLost = 0
        biggestWin = 0
        biggestLoss = 0
        gamesSessions = 0
        totalPlayTime = 0
        handHistory.removeAll()
        sessionHistory.removeAll()
    }
}

// MARK: - 手牌结果
struct HandResult: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let holeCards: [Card]
    let communityCards: [Card]
    let handRank: HandRank
    let chipsChange: Int
    let won: Bool
    let opponentCount: Int
    
    enum CodingKeys: String, CodingKey {
        case timestamp, holeCards, communityCards, handRank, chipsChange, won, opponentCount
    }
    
    init(holeCards: [Card], communityCards: [Card], handRank: HandRank, chipsChange: Int, won: Bool, opponentCount: Int) {
        self.timestamp = Date()
        self.holeCards = holeCards
        self.communityCards = communityCards
        self.handRank = handRank
        self.chipsChange = chipsChange
        self.won = won
        self.opponentCount = opponentCount
    }
}

// MARK: - 游戏会话
class GameSession: ObservableObject, Codable, Identifiable {
    let id = UUID()
    let startTime: Date
    let startingChips: Int
    @Published var endTime: Date?
    @Published var finalChips: Int = 0
    @Published var handsPlayed: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case startTime, startingChips, endTime, finalChips, handsPlayed
    }
    
    init(startTime: Date, startingChips: Int = 1000) {
        self.startTime = startTime
        self.startingChips = startingChips
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        startTime = try container.decode(Date.self, forKey: .startTime)
        startingChips = try container.decode(Int.self, forKey: .startingChips)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        finalChips = try container.decode(Int.self, forKey: .finalChips)
        handsPlayed = try container.decode(Int.self, forKey: .handsPlayed)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(startingChips, forKey: .startingChips)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(finalChips, forKey: .finalChips)
        try container.encode(handsPlayed, forKey: .handsPlayed)
    }
    
    func endSession(finalChips: Int) {
        self.endTime = Date()
        self.finalChips = finalChips
    }
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    var chipsChange: Int {
        return finalChips - startingChips
    }
    
    var isWinningSession: Bool {
        return chipsChange > 0
    }
} 