//
//  DiaryMainView.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/9/26.
//
import SwiftUI

struct DiaryMainView: View {
    @State private var selectedTab = 0 // 預設顯示「健康數據」
    
    var body: some View {
        VStack(spacing: 0) {
            // 上方 Segmented Control
            Picker("選項", selection: $selectedTab) {
                Text("健康數據").tag(0)
                Text("心情日記").tag(1)
                Text("量表追蹤").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .background(Color.yellow.opacity(0.1))
            
            // 對應的子頁面
            TabView(selection: $selectedTab) {
                // ✅ 健康數據
                NavigationView {
                    HealthDataView()
                }
                .tag(0)
                
                // ✅ 心情日記
                NavigationView {
                    MoodDiaryView()
                }
                .tag(1)
                
                // ✅ 量表追蹤（先放佔位符）
                NavigationView {
                    EmotionAnalysisView()
                }
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .navigationTitle("健康追蹤")
    }
}
