import SwiftUI

struct PokerTableView: View {
    @StateObject private var gameState = GameState()
    @State private var showActionSheet = false
    @State private var raiseAmount = 20
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                LinearGradient(
                    colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 游戏信息栏
                    gameInfoBar()
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // 主要游戏区域
                    tableArea(geometry: geometry)
                        .frame(maxHeight: .infinity)
                    
                    // 玩家手牌和操作区域
                    playerActionArea()
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                }
            }
        }
        .onAppear {
            if !gameState.isGameActive {
                gameState.startNewHand()
            }
        }
    }
    
    // MARK: - 游戏信息栏
    @ViewBuilder
    private func gameInfoBar() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("第 \(gameState.handNumber) 手")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(gameState.currentPhase.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    
                // 显示当前行动玩家
                if gameState.isGameActive, let currentPlayer = gameState.currentPlayer {
                    Text("轮到: \(currentPlayer.name)")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("底池: \(gameState.totalPot)")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("当前下注: \(gameState.currentBet)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    
                // 显示最新游戏日志
                if !gameState.gameLog.isEmpty {
                    Text(gameState.gameLog.last?.components(separatedBy: "] ").last ?? "")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - 牌桌区域
    @ViewBuilder
    private func tableArea(geometry: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            // 对手玩家 (顶部)
            opponentPlayersView()
            
            // 公共牌区域
            communityCardsView()
            
            Spacer()
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - 对手玩家视图
    @ViewBuilder
    private func opponentPlayersView() -> some View {
        HStack(spacing: 15) {
            ForEach(Array(gameState.players.enumerated()), id: \.element.id) { index, player in
                if index != 0 { // 第一个是当前玩家，显示在底部
                    PlayerView(player: player, isCurrentPlayer: false)
                }
            }
        }
    }
    
    // MARK: - 公共牌视图
    @ViewBuilder
    private func communityCardsView() -> some View {
        VStack(spacing: 15) {
            Text("公共牌")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 10) {
                ForEach(gameState.communityCards, id: \.description) { card in
                    CardView(card: card, isHidden: false)
                }
                
                // 占位符牌
                ForEach(0..<(5 - gameState.communityCards.count), id: \.self) { _ in
                    CardView(card: nil, isHidden: true)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(15)
    }
    
    // MARK: - 玩家操作区域
    @ViewBuilder
    private func playerActionArea() -> some View {
        VStack(spacing: 15) {
            // 当前玩家手牌
            if let currentPlayer = gameState.players.first {
                PlayerView(player: currentPlayer, isCurrentPlayer: true)
            }
            
            // 操作按钮
            if gameState.isGameActive && gameState.currentPlayer?.type == .human {
                actionButtonsView()
            } else if !gameState.isGameActive {
                newHandButton()
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(15)
    }
    
    // MARK: - 执行玩家操作
    private func performAction(_ action: PlayerAction) {
        gameState.processPlayerAction(action)
    }
    
    // MARK: - 操作按钮
    @ViewBuilder
    private func actionButtonsView() -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 15) {
                Button("弃牌") {
                    performAction(.fold)
                }
                .buttonStyle(PokerButtonStyle(color: .red))
                
                if gameState.currentBet == 0 {
                    Button("看牌") {
                        performAction(.check)
                    }
                    .buttonStyle(PokerButtonStyle(color: .blue))
                } else {
                    let callAmount = gameState.currentBet - (gameState.currentPlayer?.currentBet ?? 0)
                    Button("跟注 \(callAmount)") {
                        performAction(.call)
                    }
                    .buttonStyle(PokerButtonStyle(color: .green))
                    .disabled(callAmount <= 0)
                }
            }
            
            HStack(spacing: 15) {
                Button("加注") {
                    showActionSheet = true
                }
                .buttonStyle(PokerButtonStyle(color: .orange))
                
                Button("全押") {
                    performAction(.allIn)
                }
                .buttonStyle(PokerButtonStyle(color: .purple))
            }
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text("选择加注金额"),
                buttons: [
                    .default(Text("加注到 \(gameState.currentBet + gameState.bigBlindAmount)")) {
                        raiseAmount = gameState.currentBet + gameState.bigBlindAmount
                        performAction(.raise)
                    },
                    .default(Text("加注到 \(gameState.currentBet + gameState.bigBlindAmount * 2)")) {
                        raiseAmount = gameState.currentBet + gameState.bigBlindAmount * 2
                        performAction(.raise)
                    },
                    .default(Text("加注到 \(gameState.currentBet + gameState.bigBlindAmount * 3)")) {
                        raiseAmount = gameState.currentBet + gameState.bigBlindAmount * 3
                        performAction(.raise)
                    },
                    .cancel()
                ]
            )
        }
    }
    
    // MARK: - 新手牌按钮
    @ViewBuilder
    private func newHandButton() -> some View {
        VStack(spacing: 10) {
            if let winner = gameState.winner {
                VStack(spacing: 5) {
                    Text("🎉 \(winner.name) 获胜!")
                        .font(.headline)
                        .foregroundColor(.yellow)
                    
                    if !gameState.gameLog.isEmpty {
                        Text(gameState.gameLog.last ?? "")
                            .font(.caption)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            Button("开始新手牌") {
                gameState.startNewHand()
            }
            .buttonStyle(PokerButtonStyle(color: .blue))
        }
    }
}

// MARK: - 玩家视图
struct PlayerView: View {
    @ObservedObject var player: Player
    let isCurrentPlayer: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // 玩家信息
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: player.type.icon)
                        .foregroundColor(player.status.color)
                    Text(player.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                Text("筹码: \(player.chips)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if player.currentBet > 0 {
                    Text("下注: \(player.currentBet)")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .foregroundColor(.white)
            
            // 手牌
            HStack(spacing: 5) {
                ForEach(player.holeCards, id: \.description) { card in
                    CardView(card: card, isHidden: !isCurrentPlayer)
                }
                
                // 占位符牌
                if player.holeCards.count < 2 {
                    ForEach(0..<(2 - player.holeCards.count), id: \.self) { _ in
                        CardView(card: nil, isHidden: true)
                    }
                }
            }
            
            // 位置标识
            HStack(spacing: 4) {
                if player.isDealer {
                    Image(systemName: "d.circle.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
                if player.isSmallBlind {
                    Text("SB")
                        .font(.caption2)
                        .padding(2)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                if player.isBigBlind {
                    Text("BB")
                        .font(.caption2)
                        .padding(2)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(player.status.color, lineWidth: isCurrentPlayer ? 3 : 1)
                )
        )
    }
}

// MARK: - 卡牌视图
struct CardView: View {
    let card: Card?
    let isHidden: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isHidden ? Color.blue : Color.white)
                .frame(width: 40, height: 56)
                .shadow(radius: 2)
            
            if let card = card, !isHidden {
                VStack(spacing: 2) {
                    Text(card.rank.symbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(card.suit.color)
                    Text(card.suit.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(card.suit.color)
                }
            } else {
                Text("🂠")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - 按钮样式
struct PokerButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1.0))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    PokerTableView()
} 