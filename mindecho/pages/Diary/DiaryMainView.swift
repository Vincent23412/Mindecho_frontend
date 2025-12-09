//
//  DiaryMainView.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/9/26.
//
import SwiftUI

struct DiaryMainView: View {
    @State private var selectedTab = 0 // 預設顯示「健康數據」
    @State private var selectedTimePeriod = "本週"
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 頁面標題
            VStack(spacing: 4) {
                Text("追蹤")
                    .font(.title2.bold())
                    .foregroundColor(.brown)
                Text("查看你的健康數據與情緒變化")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            // 上方 Segmented Control
            Picker("選項", selection: $selectedTab) {
                Text("健康數據").tag(0)
                Text("心情日記").tag(1)
                Text("量表追蹤").tag(2)
                Text("AI情緒分析").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // 對應的子頁面
            TabView(selection: $selectedTab) {
                NavigationView { HealthDataView() }.tag(0)
                NavigationView { MoodDiaryView() }.tag(1)
                NavigationView {
                    ScrollView {
                        FiveIndicatorsCard(
                            selectedTimePeriod: $selectedTimePeriod,
                            indicatorOrder: [.physical, .emotional, .sleep, .mental],
                            customDisplayNames: [
                                .physical: "PHQ-9",
                                .emotional: "GAD-7",
                                .sleep: "BSRS-5",
                                .mental: "RFQ-8"
                            ]
                        )
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .frame(height: 350)
                        Spacer(minLength: 20)
                    }
                    .background(AppColors.lightYellow)
                }
                .tag(2)
                NavigationView { EmotionAnalysisView() }.tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
        }
        .background(AppColors.lightYellow)
    }
}

#Preview {
    DiaryMainView()
}
