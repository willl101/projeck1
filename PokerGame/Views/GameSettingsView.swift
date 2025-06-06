import SwiftUI

struct GameSettingsView: View {
    @StateObject private var gameState = GameState()
    @StateObject private var gameConfig = GameConfiguration.shared
    @StateObject private var soundManager = SoundManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("盲注设置")) {
                    HStack {
                        Text("小盲注")
                        Spacer()
                        TextField("小盲注", value: $gameConfig.smallBlind, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("大盲注")
                        Spacer()
                        TextField("大盲注", value: $gameConfig.bigBlind, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                    
                    Text("建议比例: 大盲注 = 2 × 小盲注")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("筹码设置")) {
                    HStack {
                        Text("起始筹码")
                        Spacer()
                        TextField("起始筹码", value: $gameConfig.startingChips, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                    }
                    
                    Text("建议: 起始筹码 = 50-100 × 大盲注")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("AI玩家设置")) {
                    HStack {
                        Text("AI玩家数量")
                        Spacer()
                        Picker("AI玩家数量", selection: $gameConfig.aiPlayerCount) {
                            ForEach(1...6, id: \.self) { count in
                                Text("\(count)").tag(count)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI难度")
                        Picker("AI难度", selection: $gameConfig.selectedAIDifficulty) {
                            ForEach(AIDifficulty.allCases, id: \.self) { difficulty in
                                VStack(alignment: .leading) {
                                    Text(difficulty.rawValue)
                                        .fontWeight(.semibold)
                                    Text(difficulty.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(difficulty)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section(header: Text("游戏预设")) {
                    VStack(spacing: 12) {
                        Button("休闲模式") {
                            applyPreset(type: .casual)
                        }
                        .buttonStyle(PresetButtonStyle(color: .green))
                        
                        Button("标准模式") {
                            applyPreset(type: .standard)
                        }
                        .buttonStyle(PresetButtonStyle(color: .blue))
                        
                        Button("竞技模式") {
                            applyPreset(type: .competitive)
                        }
                        .buttonStyle(PresetButtonStyle(color: .red))
                    }
                }
                
                Section(header: Text("音效设置")) {
                    HStack {
                        Text("启用音效")
                        Spacer()
                        Toggle("", isOn: $soundManager.isSoundEnabled)
                    }
                    
                    if soundManager.isSoundEnabled {
                        VStack {
                            HStack {
                                Text("音量")
                                Spacer()
                                Text("\(Int(soundManager.soundVolume * 100))%")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $soundManager.soundVolume, in: 0...1, step: 0.1)
                                .accentColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("快速设置")) {
                    VStack(spacing: 10) {
                        Button("应用设置并开始新游戏") {
                            applySettings()
                        }
                        .buttonStyle(PokerButtonStyle(color: .blue))
                        
                        Button("重置为默认设置") {
                            resetToDefaults()
                        }
                        .buttonStyle(PokerButtonStyle(color: .gray))
                    }
                }
            }
            .navigationTitle("游戏设置")
            .alert("设置已更新", isPresented: $showingAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - 预设配置
    enum PresetType {
        case casual, standard, competitive
    }
    
    private func applyPreset(type: PresetType) {
        switch type {
        case .casual:
            gameConfig.applyCasualSettings()
            alertMessage = "已设置为休闲模式：低盲注，多筹码，简单AI"
            
        case .standard:
            gameConfig.resetToDefaults()
            alertMessage = "已设置为标准模式：平衡的游戏参数"
            
        case .competitive:
            gameConfig.applyTournamentSettings()
            alertMessage = "已设置为竞技模式：高盲注，困难AI，激烈竞争"
        }
        showingAlert = true
    }
    
    private func resetToDefaults() {
        gameConfig.resetToDefaults()
        alertMessage = "已重置为默认设置"
        showingAlert = true
    }
    
    private func applySettings() {
        // 验证设置
        if !gameConfig.validateSettings() {
            alertMessage = "错误：设置无效，请检查盲注和筹码数量"
            showingAlert = true
            return
        }
        
        // 保存配置
        gameConfig.saveConfiguration()
        
        // 应用设置到游戏状态
        gameState.smallBlindAmount = gameConfig.smallBlind
        gameState.bigBlindAmount = gameConfig.bigBlind
        gameState.players.removeAll()
        
        // 添加玩家
        gameState.addPlayer(Player(name: "玩家", chips: gameConfig.startingChips, type: .human))
        
        // 添加AI玩家
        for i in 1...gameConfig.aiPlayerCount {
            let aiName = "AI-\(i)"
            gameState.addPlayer(Player(name: aiName, chips: gameConfig.startingChips, type: .ai, difficulty: gameConfig.selectedAIDifficulty))
        }
        
        alertMessage = "设置已应用！新游戏已准备就绪。"
        showingAlert = true
    }
}

// MARK: - 预设按钮样式
struct PresetButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1.0))
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    GameSettingsView()
} 