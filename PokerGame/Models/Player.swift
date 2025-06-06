import Foundation
import SwiftUI

// MARK: - 玩家行动类型
enum PlayerAction: String, CaseIterable, Codable {
    case fold = "弃牌"
    case check = "看牌"
    case call = "跟注"
    case raise = "加注"
    case allIn = "全押"
    
    var systemImage: String {
        switch self {
        case .fold: return "xmark.circle"
        case .check: return "checkmark.circle"
        case .call: return "equal.circle"
        case .raise: return "plus.circle"
        case .allIn: return "exclamationmark.triangle"
        }
    }
}

// MARK: - 玩家状态
enum PlayerStatus: String, Codable {
    case waiting = "等待中"
    case playing = "游戏中"
    case folded = "已弃牌"
    case allIn = "全押"
    case busted = "出局"
    
    var color: Color {
        switch self {
        case .waiting: return .gray
        case .playing: return .green
        case .folded: return .red
        case .allIn: return .orange
        case .busted: return .black
        }
    }
}

// MARK: - 玩家类型
enum PlayerType: String, Codable {
    case human = "真人玩家"
    case ai = "AI玩家"
    
    var icon: String {
        switch self {
        case .human: return "person.fill"
        case .ai: return "brain.head.profile"
        }
    }
}

// MARK: - AI难度级别
enum AIDifficulty: String, CaseIterable, Codable {
    case easy = "简单"
    case medium = "中等"
    case hard = "困难"
    case expert = "专家"
    
    var description: String {
        switch self {
        case .easy: return "保守型，容易预测"
        case .medium: return "平衡型，中等难度"
        case .hard: return "激进型，较难对付"
        case .expert: return "专业级，高度智能"
        }
    }
}

// MARK: - 玩家模型
class Player: ObservableObject, Identifiable, Codable {
    let id = UUID()
    @Published var name: String
    @Published var chips: Int
    @Published var holeCards: [Card] = []
    @Published var currentBet: Int = 0
    @Published var totalBetInRound: Int = 0
    @Published var status: PlayerStatus = .waiting
    @Published var lastAction: PlayerAction?
    @Published var position: Int = 0
    @Published var isDealer: Bool = false
    @Published var isSmallBlind: Bool = false
    @Published var isBigBlind: Bool = false
    
    let type: PlayerType
    let difficulty: AIDifficulty?
    
    // MARK: - 编码相关
    enum CodingKeys: String, CodingKey {
        case name, chips, holeCards, currentBet, totalBetInRound
        case status, lastAction, position, isDealer, isSmallBlind, isBigBlind
        case type, difficulty
    }
    
    init(name: String, chips: Int, type: PlayerType = .human, difficulty: AIDifficulty? = nil) {
        self.name = name
        self.chips = chips
        self.type = type
        self.difficulty = difficulty
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.chips = try container.decode(Int.self, forKey: .chips)
        self.holeCards = try container.decode([Card].self, forKey: .holeCards)
        self.currentBet = try container.decode(Int.self, forKey: .currentBet)
        self.totalBetInRound = try container.decode(Int.self, forKey: .totalBetInRound)
        self.status = try container.decode(PlayerStatus.self, forKey: .status)
        self.lastAction = try container.decodeIfPresent(PlayerAction.self, forKey: .lastAction)
        self.position = try container.decode(Int.self, forKey: .position)
        self.isDealer = try container.decode(Bool.self, forKey: .isDealer)
        self.isSmallBlind = try container.decode(Bool.self, forKey: .isSmallBlind)
        self.isBigBlind = try container.decode(Bool.self, forKey: .isBigBlind)
        self.type = try container.decode(PlayerType.self, forKey: .type)
        self.difficulty = try container.decodeIfPresent(AIDifficulty.self, forKey: .difficulty)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(chips, forKey: .chips)
        try container.encode(holeCards, forKey: .holeCards)
        try container.encode(currentBet, forKey: .currentBet)
        try container.encode(totalBetInRound, forKey: .totalBetInRound)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(lastAction, forKey: .lastAction)
        try container.encode(position, forKey: .position)
        try container.encode(isDealer, forKey: .isDealer)
        try container.encode(isSmallBlind, forKey: .isSmallBlind)
        try container.encode(isBigBlind, forKey: .isBigBlind)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(difficulty, forKey: .difficulty)
    }
    
    // MARK: - 游戏行为方法
    func dealHoleCards(_ cards: [Card]) {
        self.holeCards = cards
        self.status = .playing
    }
    
    func placeBet(_ amount: Int) {
        let actualBet = min(amount, chips)
        chips -= actualBet
        currentBet += actualBet
        totalBetInRound += actualBet
        
        if chips == 0 {
            status = .allIn
        }
    }
    
    func fold() {
        status = .folded
        lastAction = .fold
    }
    
    func check() {
        lastAction = .check
    }
    
    func call(_ amount: Int) {
        placeBet(amount)
        lastAction = .call
    }
    
    func raise(to amount: Int) {
        placeBet(amount)
        lastAction = .raise
    }
    
    func allIn() {
        placeBet(chips)
        lastAction = .allIn
    }
    
    func resetForNewRound() {
        currentBet = 0
        totalBetInRound = 0
        lastAction = nil
        if status != .busted {
            status = chips > 0 ? .playing : .busted
        }
    }
    
    func resetForNewHand() {
        holeCards = []
        resetForNewRound()
        isDealer = false
        isSmallBlind = false
        isBigBlind = false
    }
    
    // MARK: - 计算属性
    var canAct: Bool {
        return status == .playing && chips > 0
    }
    
    var isActive: Bool {
        return status == .playing || status == .allIn
    }
    
    var displayName: String {
        var name = self.name
        if type == .ai, let difficulty = difficulty {
            name += " (\(difficulty.rawValue))"
        }
        return name
    }
} 