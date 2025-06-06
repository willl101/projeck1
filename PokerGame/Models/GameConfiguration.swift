import Foundation

// MARK: - 游戏配置管理器
class GameConfiguration: ObservableObject, Codable {
    static let shared = GameConfiguration()
    
    // MARK: - 游戏设置
    @Published var smallBlind: Int = 10
    @Published var bigBlind: Int = 20
    @Published var startingChips: Int = 1000
    @Published var aiPlayerCount: Int = 3
    @Published var selectedAIDifficulty: AIDifficulty = .medium
    @Published var autoSaveEnabled: Bool = true
    @Published var animationSpeed: Double = 1.0
    @Published var showProbabilities: Bool = true
    @Published var enableAIAnalysis: Bool = true
    
    // MARK: - 界面设置
    @Published var isDarkMode: Bool = false
    @Published var cardBackStyle: String = "classic"
    @Published var tableColor: String = "green"
    @Published var enableHapticFeedback: Bool = true
    
    // MARK: - 统计设置
    @Published var trackStatistics: Bool = true
    @Published var saveHandHistory: Bool = true
    @Published var maxHistoryRecords: Int = 1000
    
    private let userDefaults = UserDefaults.standard
    private let configKey = "GameConfiguration"
    
    private init() {
        loadConfiguration()
    }
    
    // MARK: - Codable 支持
    enum CodingKeys: String, CodingKey {
        case smallBlind, bigBlind, startingChips, aiPlayerCount
        case selectedAIDifficulty, autoSaveEnabled, animationSpeed
        case showProbabilities, enableAIAnalysis, isDarkMode
        case cardBackStyle, tableColor, enableHapticFeedback
        case trackStatistics, saveHandHistory, maxHistoryRecords
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        smallBlind = try container.decode(Int.self, forKey: .smallBlind)
        bigBlind = try container.decode(Int.self, forKey: .bigBlind)
        startingChips = try container.decode(Int.self, forKey: .startingChips)
        aiPlayerCount = try container.decode(Int.self, forKey: .aiPlayerCount)
        selectedAIDifficulty = try container.decode(AIDifficulty.self, forKey: .selectedAIDifficulty)
        autoSaveEnabled = try container.decode(Bool.self, forKey: .autoSaveEnabled)
        animationSpeed = try container.decode(Double.self, forKey: .animationSpeed)
        showProbabilities = try container.decode(Bool.self, forKey: .showProbabilities)
        enableAIAnalysis = try container.decode(Bool.self, forKey: .enableAIAnalysis)
        isDarkMode = try container.decode(Bool.self, forKey: .isDarkMode)
        cardBackStyle = try container.decode(String.self, forKey: .cardBackStyle)
        tableColor = try container.decode(String.self, forKey: .tableColor)
        enableHapticFeedback = try container.decode(Bool.self, forKey: .enableHapticFeedback)
        trackStatistics = try container.decode(Bool.self, forKey: .trackStatistics)
        saveHandHistory = try container.decode(Bool.self, forKey: .saveHandHistory)
        maxHistoryRecords = try container.decode(Int.self, forKey: .maxHistoryRecords)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(smallBlind, forKey: .smallBlind)
        try container.encode(bigBlind, forKey: .bigBlind)
        try container.encode(startingChips, forKey: .startingChips)
        try container.encode(aiPlayerCount, forKey: .aiPlayerCount)
        try container.encode(selectedAIDifficulty, forKey: .selectedAIDifficulty)
        try container.encode(autoSaveEnabled, forKey: .autoSaveEnabled)
        try container.encode(animationSpeed, forKey: .animationSpeed)
        try container.encode(showProbabilities, forKey: .showProbabilities)
        try container.encode(enableAIAnalysis, forKey: .enableAIAnalysis)
        try container.encode(isDarkMode, forKey: .isDarkMode)
        try container.encode(cardBackStyle, forKey: .cardBackStyle)
        try container.encode(tableColor, forKey: .tableColor)
        try container.encode(enableHapticFeedback, forKey: .enableHapticFeedback)
        try container.encode(trackStatistics, forKey: .trackStatistics)
        try container.encode(saveHandHistory, forKey: .saveHandHistory)
        try container.encode(maxHistoryRecords, forKey: .maxHistoryRecords)
    }
    
    // MARK: - 配置管理
    func saveConfiguration() {
        do {
            let data = try JSONEncoder().encode(self)
            userDefaults.set(data, forKey: configKey)
            userDefaults.synchronize()
        } catch {
            print("保存配置失败: \(error)")
        }
    }
    
    private func loadConfiguration() {
        guard let data = userDefaults.data(forKey: configKey) else { return }
        
        do {
            let config = try JSONDecoder().decode(GameConfiguration.self, from: data)
            
            // 复制配置
            self.smallBlind = config.smallBlind
            self.bigBlind = config.bigBlind
            self.startingChips = config.startingChips
            self.aiPlayerCount = config.aiPlayerCount
            self.selectedAIDifficulty = config.selectedAIDifficulty
            self.autoSaveEnabled = config.autoSaveEnabled
            self.animationSpeed = config.animationSpeed
            self.showProbabilities = config.showProbabilities
            self.enableAIAnalysis = config.enableAIAnalysis
            self.isDarkMode = config.isDarkMode
            self.cardBackStyle = config.cardBackStyle
            self.tableColor = config.tableColor
            self.enableHapticFeedback = config.enableHapticFeedback
            self.trackStatistics = config.trackStatistics
            self.saveHandHistory = config.saveHandHistory
            self.maxHistoryRecords = config.maxHistoryRecords
            
        } catch {
            print("加载配置失败: \(error)")
        }
    }
    
    // MARK: - 预设配置
    func resetToDefaults() {
        smallBlind = 10
        bigBlind = 20
        startingChips = 1000
        aiPlayerCount = 3
        selectedAIDifficulty = .medium
        autoSaveEnabled = true
        animationSpeed = 1.0
        showProbabilities = true
        enableAIAnalysis = true
        isDarkMode = false
        cardBackStyle = "classic"
        tableColor = "green"
        enableHapticFeedback = true
        trackStatistics = true
        saveHandHistory = true
        maxHistoryRecords = 1000
        
        saveConfiguration()
    }
    
    func applyTournamentSettings() {
        smallBlind = 25
        bigBlind = 50
        startingChips = 2000
        aiPlayerCount = 5
        selectedAIDifficulty = .hard
        
        saveConfiguration()
    }
    
    func applyCasualSettings() {
        smallBlind = 5
        bigBlind = 10
        startingChips = 500
        aiPlayerCount = 2
        selectedAIDifficulty = .easy
        
        saveConfiguration()
    }
    
    // MARK: - 验证设置
    func validateSettings() -> Bool {
        return smallBlind > 0 && 
               bigBlind > smallBlind && 
               startingChips >= bigBlind * 10 &&
               aiPlayerCount >= 1 && aiPlayerCount <= 7 &&
               animationSpeed > 0 && animationSpeed <= 3.0 &&
               maxHistoryRecords > 0
    }
} 