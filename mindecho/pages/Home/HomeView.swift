import SwiftUI

struct HomeView: View {
    // MARK: - State 屬性
    @State private var selectedTimePeriod = "本週"
    @State private var animationProgress: Double = 0
    @State private var showingDailyCheckIn = false
    
    // MARK: - Observable Objects
    @ObservedObject private var checkInManager = DailyCheckInManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 今日提醒
                    DailyReminderCard()
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    // 每日檢測提醒（如果還沒完成）
                    if !checkInManager.hasCompletedToday {
                        DailyCheckInReminderCard(onTap: {
                            showingDailyCheckIn = true
                        })
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    
                    Spacer().frame(height: 24)
                    
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
                        
                        Spacer()
                    }
                    
                    // 心理健康資源區塊
                    MentalHealthResourcesSection()
                        .padding(.top, 20)
                    
                    // 心理測驗區塊
                    PsychologicalTestsSection()
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                }
            }
            .background(AppColors.lightYellow)
            .onAppear {
                checkInManager.loadDataFromAPI()
            }
            .navigationTitle("首頁")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.cardBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                // 觸發動畫
                withAnimation(.easeInOut(duration: HomeConstants.Animation.biorhythmAnimationDuration)) {
                    animationProgress = 1.0
                }
            }
        }
        .sheet(isPresented: $showingDailyCheckIn) {
            DailyCheckInView(isPresented: $showingDailyCheckIn)
        }
    }
    
    // MARK: - 私有方法
    
}

#Preview {
    HomeView()
}
