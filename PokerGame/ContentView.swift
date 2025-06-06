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
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("个人")
                }
                .tag(3)
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
    var body: some View {
        NavigationView {
            Text("个人资料开发中...")
                .navigationTitle("个人资料")
        }
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