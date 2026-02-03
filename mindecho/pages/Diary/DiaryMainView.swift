//
//  DiaryMainView.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/9/26.
//
import SwiftUI

struct DiaryMainView: View {
    @State private var selectedTab = 0 // 預設顯示「五項指標追蹤」
    @State private var selectedTimePeriod = "本週"
    @StateObject private var scaleSessionManager = ScaleSessionManager.shared
    @ObservedObject private var checkInManager = DailyCheckInManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 頁面標題
            VStack(spacing: 4) {
                Text("追蹤")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.titleColor)
                Text("查看你的健康數據與情緒變化")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            // 上方 Segmented Control
            Picker("選項", selection: $selectedTab) {
                Text("心情日記").tag(1)
                Text("量表追蹤").tag(2)
                Text("五項指標追蹤").tag(0)
            }
            .pickerStyle(SegmentedPickerStyle())
            .tint(AppColors.titleColor)
            .padding()
            
            // 對應的子頁面
            TabView(selection: $selectedTab) {
                NavigationView {
                    ScrollView {
                        VStack {
                            FiveIndicatorsCard(selectedTimePeriod: $selectedTimePeriod)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            
                            DailyScoresTableCard(
                                scores: checkInManager.weeklyScores,
                                selectedTimePeriod: selectedTimePeriod
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            
                            Spacer(minLength: 20)
                        }
                    }
                    .background(AppColors.lightYellow)
                }
                .tag(0)
                NavigationView { MoodDiaryView() }.tag(1)
                NavigationView {
                    ScrollView {
                        ScaleTrackingCard(manager: scaleSessionManager)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        Spacer(minLength: 20)
                    }
                    .background(AppColors.lightYellow)
                }
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
            .onChange(of: selectedTab) { _, value in
                if value == 2 {
                    scaleSessionManager.loadSessions()
                }
            }
        }
        .background(AppColors.lightYellow)
        .onAppear {
            scaleSessionManager.loadSessions()
            checkInManager.loadDataFromAPI()
        }
    }
}

#Preview {
    DiaryMainView()
}
