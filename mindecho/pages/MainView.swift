//
//  MainView.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/10/24.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            NavigationView {
                HomeView()
            }
                .tabItem { Label("首頁", systemImage: "house") }
            
            NavigationView {
                ChatListPage()
            }
            .tabItem { Label("聊天", systemImage: "bubble.left") }
            
            NavigationView {
                DiaryMainView()
            }
            .tabItem { Label("追蹤", systemImage: "chart.bar") }
            
            NavigationView {
                RelaxTimerView()
            }
            .tabItem { Label("放鬆", systemImage: "leaf") }
            
            NavigationView {
                ProfileView()
            }
            .tabItem { Label("個人檔案", systemImage: "person") }
        
        
            NavigationView {
                RPGSceneView()
            }
            .tabItem { Label("遊戲", systemImage: "gamecontroller")
            }
    }
    }
}

#Preview {
    MainView()
}
