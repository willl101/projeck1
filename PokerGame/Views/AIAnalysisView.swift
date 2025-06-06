import SwiftUI

struct AIAnalysisView: View {
    @StateObject private var gameState = GameState()
    @State private var currentAnalysis: AIRecommendation?
    @State private var winRate: Double = 0.0
    @State private var potOdds: Double = 0.0
    @State private var isAnalyzing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 当前手牌显示
                    currentHandSection()
                    
                    // 胜率分析
                    winRateAnalysisSection()
                    
                    // 赔率分析
                    oddsAnalysisSection()
                    
                    // AI建议
                    aiRecommendationSection()
                    
                    // 手牌强度分析
                    handStrengthSection()
                    
                    // 分析控制按钮
                    analysisControlSection()
                }
                .padding()
            }
            .navigationTitle("AI分析")
            .onAppear {
                if !gameState.isGameActive {
                    gameState.startNewHand()
                }
                performAnalysis()
            }
        }
    }
    
    // MARK: - 当前手牌区域
    @ViewBuilder
    private func currentHandSection() -> some View {
        VStack(spacing: 15) {
            Text("当前手牌分析")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let player = gameState.players.first {
                HStack(spacing: 20) {
                    // 手牌
                    VStack {
                        Text("手牌")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 8) {
                            ForEach(player.holeCards, id: \.description) { card in
                                CardView(card: card, isHidden: false)
                            }
                        }
                    }
                    
                    // 公共牌
                    VStack {
                        Text("公共牌")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 6) {
                            ForEach(gameState.communityCards, id: \.description) { card in
                                CardView(card: card, isHidden: false)
                                    .scaleEffect(0.8)
                            }
                            // 占位符
                            ForEach(0..<(5 - gameState.communityCards.count), id: \.self) { _ in
                                CardView(card: nil, isHidden: true)
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                }
                
                // 当前手牌类型
                if !player.holeCards.isEmpty {
                    let allCards = player.holeCards + gameState.communityCards
                    if allCards.count >= 2 {
                        let evaluation = HandEvaluator.evaluateHand(cards: allCards)
                        Text("当前牌型: \(evaluation.rank.name)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.top, 5)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 胜率分析区域
    @ViewBuilder
    private func winRateAnalysisSection() -> some View {
        VStack(spacing: 15) {
            Text("胜率分析")
                .font(.headline)
                .foregroundColor(.primary)
            
            // 胜率圆环图
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: CGFloat(winRate))
                    .stroke(
                        LinearGradient(
                            colors: winRateColor(),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: winRate)
                
                VStack {
                    Text("\(Int(winRate * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("胜率")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 胜率详情
            VStack(spacing: 8) {
                HStack {
                    Text("对手数量:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(gameState.activePlayers.count - 1)")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("游戏阶段:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(gameState.currentPhase.description)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("胜率等级:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(winRateLevel())
                        .fontWeight(.semibold)
                        .foregroundColor(winRateLevelColor())
                }
            }
            .font(.caption)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 赔率分析区域
    @ViewBuilder
    private func oddsAnalysisSection() -> some View {
        VStack(spacing: 15) {
            Text("赔率分析")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // 底池赔率
                HStack {
                    VStack(alignment: .leading) {
                        Text("底池赔率")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("跟注成本 vs 底池大小")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(String(format: "%.1f", potOdds * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                Divider()
                
                // 底池信息
                VStack(spacing: 8) {
                    HStack {
                        Text("底池大小:")
                        Spacer()
                        Text("\(gameState.totalPot)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("跟注成本:")
                        Spacer()
                        let callCost = max(0, gameState.currentBet - (gameState.players.first?.currentBet ?? 0))
                        Text("\(callCost)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("盈亏平衡点:")
                        Spacer()
                        Text("\(String(format: "%.1f", potOdds * 100))%")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                .font(.caption)
                
                // 赔率建议
                HStack {
                    Image(systemName: winRate > potOdds ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(winRate > potOdds ? .green : .red)
                    
                    Text(winRate > potOdds ? "胜率超过赔率，建议跟注" : "胜率低于赔率，建议弃牌")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(winRate > potOdds ? .green : .red)
                }
                .padding(.top, 5)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - AI建议区域
    @ViewBuilder
    private func aiRecommendationSection() -> some View {
        VStack(spacing: 15) {
            Text("AI智能建议")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let analysis = currentAnalysis {
                VStack(spacing: 12) {
                    // 推荐行动
                    HStack {
                        Image(systemName: analysis.action.systemImage)
                            .font(.title2)
                            .foregroundColor(actionColor(analysis.action))
                        
                        VStack(alignment: .leading) {
                            Text("推荐行动: \(analysis.action.rawValue)")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Text("置信度: \(analysis.confidenceLevel)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(analysis.confidence * 100))%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(actionColor(analysis.action))
                    }
                    
                    // 分析原因
                    Text(analysis.reasoning)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            } else {
                Text("正在分析中...")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 手牌强度分析
    @ViewBuilder
    private func handStrengthSection() -> some View {
        VStack(spacing: 15) {
            Text("手牌强度分析")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let player = gameState.players.first, !player.holeCards.isEmpty {
                let allCards = player.holeCards + gameState.communityCards
                if allCards.count >= 2 {
                    let evaluation = HandEvaluator.evaluateHand(cards: allCards)
                
                VStack(spacing: 10) {
                    // 当前牌型
                    HStack {
                        Text("当前牌型:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(evaluation.rank.name)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    // 牌型说明
                    Text(evaluation.rank.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // 改进可能性
                    if gameState.communityCards.count < 5 {
                        Divider()
                        
                        Text("改进可能性")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        // 这里可以添加更详细的改进分析
                        let remainingCards = 5 - gameState.communityCards.count
                        Text("还有 \(remainingCards) 张公共牌未发，手牌仍有改进空间")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    }
                } else {
                    Text("手牌不足")
                        .foregroundColor(.secondary)
                }
            } else {
                Text("等待发牌...")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 分析控制区域
    @ViewBuilder
    private func analysisControlSection() -> some View {
        VStack(spacing: 15) {
            Button(action: {
                performAnalysis()
            }) {
                HStack {
                    if isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "brain.head.profile")
                    }
                    Text(isAnalyzing ? "分析中..." : "重新分析")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isAnalyzing)
            
            Button("开始新手牌") {
                gameState.startNewHand()
                performAnalysis()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
    
    // MARK: - 分析方法
    private func performAnalysis() {
        guard let player = gameState.players.first,
              !player.holeCards.isEmpty else { return }
        
        isAnalyzing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 计算胜率
            let calculatedWinRate = WinRateCalculator.calculateWinRate(
                playerHoleCards: player.holeCards,
                communityCards: gameState.communityCards,
                opponentCount: gameState.activePlayers.count - 1,
                iterations: 5000 // 减少迭代次数以提高性能
            )
            
            // 计算赔率
            let callCost = max(0, gameState.currentBet - player.currentBet)
            let calculatedPotOdds = PokerAI.calculatePotOdds(
                potSize: gameState.totalPot,
                betToCall: callCost
            )
            
            // 获取AI建议
            let recommendation = PokerAI.getRecommendation(
                gameState: gameState,
                playerIndex: 0
            )
            
            DispatchQueue.main.async {
                self.winRate = calculatedWinRate
                self.potOdds = calculatedPotOdds
                self.currentAnalysis = recommendation
                self.isAnalyzing = false
            }
        }
    }
    
    // MARK: - 辅助方法
    private func winRateColor() -> [Color] {
        switch winRate {
        case 0.7...1.0: return [.green, .green.opacity(0.7)]
        case 0.5..<0.7: return [.yellow, .orange]
        case 0.3..<0.5: return [.orange, .red.opacity(0.7)]
        default: return [.red, .red.opacity(0.7)]
        }
    }
    
    private func winRateLevel() -> String {
        switch winRate {
        case 0.8...1.0: return "极强"
        case 0.7..<0.8: return "很强"
        case 0.6..<0.7: return "较强"
        case 0.4..<0.6: return "中等"
        case 0.2..<0.4: return "较弱"
        default: return "很弱"
        }
    }
    
    private func winRateLevelColor() -> Color {
        switch winRate {
        case 0.7...1.0: return .green
        case 0.5..<0.7: return .yellow
        case 0.3..<0.5: return .orange
        default: return .red
        }
    }
    
    private func actionColor(_ action: PlayerAction) -> Color {
        switch action {
        case .fold: return .red
        case .check: return .blue
        case .call: return .green
        case .raise: return .orange
        case .allIn: return .purple
        }
    }
}

#Preview {
    AIAnalysisView()
} 