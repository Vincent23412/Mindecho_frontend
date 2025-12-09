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
