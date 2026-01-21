//
//  ContentView.swift
//  mindecho
//
//  Created by 鄧巧婕 on 2025/7/20.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel.shared
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // 已登錄
                mainTabView
            } else {
                // 未登錄 
                WelcomePage()
            }
        }
        .task {
            authViewModel.attemptAutoLoginOnLaunch()
        }
        .fullScreenCover(isPresented: $authViewModel.shouldShowDailyCheckIn) {
            DailyCheckInView(isPresented: $authViewModel.shouldShowDailyCheckIn)
        }
    }
    
    // MARK: - TabView
    private var mainTabView: some View {
        MainTabView()
    }
}

private struct MainTabView: View {
    @State private var selectedTab: MainTab = .home
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                ForEach(MainTab.allCases) { tab in
                    NavigationView {
                        tab.view
                    }
                    .tag(tab)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            CustomTabBar(selectedTab: $selectedTab)
        }
        .accentColor(.orange)
    }
}

// MARK: - Tabs
private enum MainTab: String, CaseIterable, Identifiable {
    case home, chat, diary, relax, profile
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .home: return "首頁"
        case .chat: return "聊天"
        case .diary: return "追蹤"
        case .relax: return "放鬆"
        case .profile: return "個人檔案"
        }
    }
    
    var systemImage: String {
        switch self {
        case .home: return "house"
        case .chat: return "bubble.left"
        case .diary: return "chart.bar"
        case .relax: return "leaf"
        case .profile: return "person"
        }
    }
    
    @ViewBuilder
    var view: some View {
        switch self {
        case .home: HomeView()
        case .chat: ChatListPage()
        case .diary: DiaryMainView()
        case .relax: RelaxTimerView()
        case .profile: ProfileView()
        }
    }
}

// MARK: - Custom Tab Bar
private struct CustomTabBar: View {
    @Binding var selectedTab: MainTab
    
    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 12
            let padding: CGFloat = 12
            let count = CGFloat(MainTab.allCases.count)
            let totalSpacing = spacing * (count - 1)
            let itemWidth = (geo.size.width - totalSpacing - padding * 2) / count
            
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: spacing) {
                    ForEach(MainTab.allCases) { tab in
                        TabButton(
                            tab: tab,
                            isSelected: tab == selectedTab,
                            fixedWidth: itemWidth
                        ) {
                            selectedTab = tab
                        }
                    }
                }
                .padding(.horizontal, padding)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(.ultraThinMaterial)
        }
        .frame(height: 70)
    }
}

private struct TabButton: View {
    let tab: MainTab
    let isSelected: Bool
    let fixedWidth: CGFloat?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                Text(tab.title)
                    .font(.footnote)
            }
            .frame(width: fixedWidth ?? 60)
            .padding(.vertical, 6)
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 開發中頁面
struct DevelopingView: View {
    let pageName: String
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 圖標
            Image(systemName: "hammer.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            // 標題
            Text("\(pageName)功能")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // 副標題
            Text("正在開發中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 描述
            VStack(spacing: 8) {
                Text("我們正在努力為您打造更好的體驗")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("敬請期待 🚀")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 底部提示
            VStack(spacing: 4) {
                Text("目前可使用聊天功能")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("請點擊下方「聊天」頁籤")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // 🎯 臨時測試：長按 5 秒直接登出
                Text("長按此處 5 秒可登出")
                    .font(.caption2)
                    .foregroundColor(.red.opacity(0.7))
                    .onLongPressGesture(minimumDuration: 5.0) {
                        AuthService.shared.logout()
                    }
            }
            .padding(.bottom, 40)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ContentView()
}

#Preview("MainTabView") {
    MainTabView()
}

#Preview("開發中頁面") {
    DevelopingView(pageName: "測試")
}
