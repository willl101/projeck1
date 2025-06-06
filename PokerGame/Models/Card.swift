import Foundation
import SwiftUI

// MARK: - 花色枚举
enum Suit: String, CaseIterable, Codable {
    case spades = "♠"
    case hearts = "♥"
    case diamonds = "♦"
    case clubs = "♣"
    
    var color: Color {
        switch self {
        case .spades, .clubs:
            return .black
        case .hearts, .diamonds:
            return .red
        }
    }
    
    var name: String {
        switch self {
        case .spades: return "黑桃"
        case .hearts: return "红桃"
        case .diamonds: return "方块"
        case .clubs: return "梅花"
        }
    }
}

// MARK: - 牌面值枚举
enum Rank: Int, CaseIterable, Codable, Comparable {
    case two = 2, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace
    
    var symbol: String {
        switch self {
        case .two, .three, .four, .five, .six, .seven, .eight, .nine, .ten: return "\(rawValue)"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        case .ace: return "A"
        }
    }
    
    var name: String {
        switch self {
        case .two, .three, .four, .five, .six, .seven, .eight, .nine, .ten: return "\(rawValue)"
        case .jack: return "杰克"
        case .queen: return "皇后"
        case .king: return "国王"
        case .ace: return "A"
        }
    }
    
    // 用于排序的值（A=14）
    var sortValue: Int {
        return self == .ace ? 14 : rawValue
    }
    
    static func < (lhs: Rank, rhs: Rank) -> Bool {
        // 特殊处理A的比较：在比大小时，A可以是1也可以是14
        if lhs == .ace && rhs != .ace {
            return false // A通常比其他牌大
        }
        if rhs == .ace && lhs != .ace {
            return true
        }
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - 牌类
struct Card: Codable, Equatable, Hashable {
    let suit: Suit
    let rank: Rank
    
    init(suit: Suit, rank: Rank) {
        self.suit = suit
        self.rank = rank
    }
    
    var description: String {
        return "\(suit.rawValue)\(rank.symbol)"
    }
    
    var fullName: String {
        return "\(suit.name)\(rank.name)"
    }
    
    // 用于排序的值（A=14）
    var sortValue: Int {
        return rank == .ace ? 14 : rank.rawValue
    }
}

// MARK: - 牌组
class Deck: ObservableObject {
    @Published var cards: [Card] = []
    
    init() {
        reset()
    }
    
    func reset() {
        cards = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                cards.append(Card(suit: suit, rank: rank))
            }
        }
        shuffle()
    }
    
    func shuffle() {
        cards.shuffle()
    }
    
    func deal() -> Card? {
        return cards.popLast()
    }
    
    func dealCards(count: Int) -> [Card] {
        var dealtCards: [Card] = []
        for _ in 0..<min(count, cards.count) {
            if let card = deal() {
                dealtCards.append(card)
            }
        }
        return dealtCards
    }
    
    var remainingCards: Int {
        return cards.count
    }
} 