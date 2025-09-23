//
//  DiaryTabView.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/9/23.
//

import SwiftUI

struct DiaryTabView: View {
    var body: some View {
        TabView {
            Text("首頁")
                .tabItem { Label("首頁", systemImage: "house") }
            
            Text("聊天")
                .tabItem { Label("聊天", systemImage: "bubble.left") }
            
            NavigationView {
                MoodDiaryView()
            }
            .tabItem { Label("追蹤", systemImage: "chart.bar") }
            
            NavigationView {
                EmotionAnalysisView()
            }
            .tabItem { Label("放鬆", systemImage: "leaf") }
            
            Text("個人檔案")
                .tabItem { Label("個人檔案", systemImage: "person") }
        }
    }
}

#Preview {
    DiaryTabView()
}
