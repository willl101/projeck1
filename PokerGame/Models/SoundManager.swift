import Foundation
import AVFoundation

// MARK: - 声音管理器
class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    @Published var isSoundEnabled = true
    @Published var soundVolume: Float = 1.0
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("设置音频会话失败: \(error)")
        }
    }
    
    // MARK: - 音效枚举
    enum SoundEffect: String, CaseIterable {
        case dealCard = "deal_card"
        case chipsBet = "chips_bet"
        case cardFlip = "card_flip"
        case win = "win"
        case lose = "lose"
        case call = "call"
        case raise = "raise"
        case fold = "fold"
        case allIn = "all_in"
        case newGame = "new_game"
        case buttonClick = "button_click"
        
        var fileName: String {
            return self.rawValue + ".mp3"
        }
    }
    
    // MARK: - 播放音效
    func playSound(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }
        
        if let player = audioPlayers[effect.rawValue] {
            player.volume = soundVolume
            player.currentTime = 0
            player.play()
        } else {
            // 如果有实际的音频文件，可以在这里加载
            // loadSound(effect)
            print("播放音效: \(effect.rawValue)")
        }
    }
    
    private func loadSound(_ effect: SoundEffect) {
        guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "mp3") else {
            print("找不到音频文件: \(effect.fileName)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = soundVolume
            audioPlayers[effect.rawValue] = player
        } catch {
            print("加载音频文件失败: \(error)")
        }
    }
    
    // MARK: - 音效控制
    func enableSound(_ enabled: Bool) {
        isSoundEnabled = enabled
    }
    
    func setVolume(_ volume: Float) {
        soundVolume = max(0.0, min(1.0, volume))
        for player in audioPlayers.values {
            player.volume = soundVolume
        }
    }
    
    func stopAllSounds() {
        for player in audioPlayers.values {
            player.stop()
        }
    }
} 