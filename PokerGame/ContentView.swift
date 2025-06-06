import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("主页")
                }
                .tag(0)
            
            GameView()
                .tabItem {
                    Image(systemName: "suit.club.fill")
                    Text("游戏")
                }
                .tag(1)
            
            AIAnalysisView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI分析")
                }
                .tag(2)
            
            GameSettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("设置")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("个人")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 顶部欢迎区域
                VStack(spacing: 20) {
                    Image(systemName: "suit.spade.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("专业德州扑克")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("AI智能分析，提升您的技战术水平")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // 快速开始按钮
                VStack(spacing: 20) {
                    NavigationLink(destination: QuickGameView()) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("快速开始")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    NavigationLink(destination: RoomListView()) {
                        HStack {
                            Image(systemName: "person.3.fill")
                            Text("加入房间")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    NavigationLink(destination: CreateRoomView()) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("创建房间")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationTitle("德州扑克")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// 游戏视图
struct GameView: View {
    var body: some View {
        NavigationView {
            PokerTableView()
                .navigationTitle("游戏桌")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ProfileView: View {
    @StateObject private var statistics = GameStatistics()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 用户头像和基本信息
                    userProfileSection()
                    
                    // 总体统计
                    overallStatsSection()
                    
                    // 胜率和表现
                    performanceSection()
                    
                    // 近期表现
                    recentPerformanceSection()
                    
                    // 管理选项
                    managementSection()
                }
                .padding()
            }
            .navigationTitle("个人资料")
        }
    }
    
    @ViewBuilder
    private func userProfileSection() -> some View {
        VStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                )
            
            Text("德州扑克玩家")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("加入时间: \(Date().formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    @ViewBuilder
    private func overallStatsSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("总体统计")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(title: "总手数", value: "\(statistics.totalHands)", icon: "suit.club.fill", color: .blue)
                StatCard(title: "获胜手数", value: "\(statistics.handsWon)", icon: "trophy.fill", color: .yellow)
                StatCard(title: "游戏会话", value: "\(statistics.gamesSessions)", icon: "gamecontroller.fill", color: .green)
                StatCard(title: "游戏时长", value: formatTime(statistics.totalPlayTime), icon: "clock.fill", color: .orange)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    @ViewBuilder
    private func performanceSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("表现分析")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("胜率")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(String(format: "%.1f", statistics.winRate * 100))%")
                        .fontWeight(.semibold)
                        .foregroundColor(statistics.winRate > 0.5 ? .green : .red)
                }
                
                HStack {
                    Text("净收益")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(statistics.netChips > 0 ? "+" : "")\(statistics.netChips)")
                        .fontWeight(.semibold)
                        .foregroundColor(statistics.netChips > 0 ? .green : .red)
                }
                
                HStack {
                    Text("最大单次收益")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(statistics.biggestWin)")
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("最大单次损失")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(statistics.biggestLoss)")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    @ViewBuilder
    private func recentPerformanceSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("近期表现")
                .font(.headline)
                .fontWeight(.bold)
            
            if statistics.handHistory.isEmpty {
                Text("暂无游戏记录")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(statistics.handHistory.suffix(5).reversed(), id: \.id) { hand in
                        HStack {
                            Image(systemName: hand.won ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(hand.won ? .green : .red)
                            
                            Text(hand.handRank.name)
                                .font(.caption)
                            
                            Spacer()
                            
                            Text("\(hand.chipsChange > 0 ? "+" : "")\(hand.chipsChange)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(hand.chipsChange > 0 ? .green : .red)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    @ViewBuilder
    private func managementSection() -> some View {
        VStack(spacing: 12) {
            Button("重置统计数据") {
                statistics.resetStatistics()
            }
            .buttonStyle(PokerButtonStyle(color: .red))
            
            Button("导出数据") {
                // TODO: 实现数据导出功能
            }
            .buttonStyle(PokerButtonStyle(color: .blue))
        }
        .padding()
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// 临时占位视图
struct QuickGameView: View {
    var body: some View {
        Text("快速游戏开发中...")
            .navigationTitle("快速游戏")
    }
}

struct RoomListView: View {
    var body: some View {
        Text("房间列表开发中...")
            .navigationTitle("房间列表")
    }
}

struct CreateRoomView: View {
    var body: some View {
        Text("创建房间开发中...")
            .navigationTitle("创建房间")
    }
}

#Preview {
    ContentView()
} 