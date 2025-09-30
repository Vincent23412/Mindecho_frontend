import SwiftUI

struct DiaryTabView: View {
    var body: some View {
        TabView {
            Text("首頁")
                .tabItem { Label("首頁", systemImage: "house") }
            
            NavigationView {
                ChatListPage()
            }
            .tabItem { Label("聊天", systemImage: "bubble.left") }
            
            NavigationView {
                DiaryMainView()
            }
            .tabItem { Label("追蹤", systemImage: "chart.bar") }
            
            Text("放鬆")
                .tabItem { Label("放鬆", systemImage: "leaf") }
            
            Text("個人檔案")
                .tabItem { Label("個人檔案", systemImage: "person") }
        }
    }
}

#Preview {
    DiaryTabView()
}
