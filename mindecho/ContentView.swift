//
//  ContentView.swift
//  mindecho
//
//  Created by 鄧巧婕 on 2025/7/20.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                // 已登錄
                mainTabView
            } else {
                // 未登錄 
                WelcomePage()
            }
        }
    }
    
    // MARK: - TabView
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            // 首頁 - 改用 HomeView
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首頁")
                }
                .tag(0)
            
            //.onAppear {
                    // 清除所有認證資料（僅用於測試）
                   //AuthService.shared.logout()
            // }
            // 聊天
            ChatListPage()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("聊天")
                }
                .tag(1)
            
            // 追蹤
            DevelopingView(pageName: "追蹤")
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("追蹤")
                }
                .tag(2)
            
            // 放鬆
            DevelopingView(pageName: "放鬆")
                .tabItem {
                    Image(systemName: "leaf.fill")
                    Text("放鬆")
                }
                .tag(3)
            
            // 個人檔案
            DevelopingView(pageName: "個人檔案")
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("個人檔案")
                }
                .tag(4)
        }
        .accentColor(.orange)
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

#Preview("開發中頁面") {
    DevelopingView(pageName: "測試")
}
