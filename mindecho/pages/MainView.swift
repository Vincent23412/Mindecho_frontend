//
//  MainView.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/10/24.
//

import SwiftUI

struct MainView: View {
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
    }
}

#Preview {
    MainView()
}

// MARK: - Tabs
private enum MainTab: String, CaseIterable, Identifiable {
    case home, chat, diary, relax, profile, game
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .home: return "首頁"
        case .chat: return "聊天"
        case .diary: return "追蹤"
        case .relax: return "放鬆"
        case .profile: return "個人檔案"
        case .game: return "遊戲"
        }
    }
    
    var systemImage: String {
        switch self {
        case .home: return "house"
        case .chat: return "bubble.left"
        case .diary: return "chart.bar"
        case .relax: return "leaf"
        case .profile: return "person"
        case .game: return "gamecontroller"
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
        case .game: RPGSceneView()
        }
    }
}

// MARK: - Custom Tab Bar
private struct CustomTabBar: View {
    @Binding var selectedTab: MainTab
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(MainTab.allCases) { tab in
                        TabButton(tab: tab, isSelected: tab == selectedTab) {
                            selectedTab = tab
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .background(.ultraThinMaterial)
        }
    }
}

private struct TabButton: View {
    let tab: MainTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                Text(tab.title)
                    .font(.footnote)
            }
            .frame(minWidth: 52)
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
