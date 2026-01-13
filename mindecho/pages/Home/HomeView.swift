import SwiftUI

struct HomeView: View {
    // MARK: - State 屬性
    @State private var selectedTimePeriod = "本週"
    @State private var animationProgress: Double = 0
    @State private var showingDailyCheckIn = false
    @State private var showingDiary = false
    @State private var hasWrittenDiaryToday: Bool? = nil
    
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
                    
                    if hasWrittenDiaryToday == false {
                        DiaryReminderCard(onTap: {
                            showingDiary = true
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
                    
                    // 快捷入口
                    QuickAccessSection()
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                }
            }
            .background(AppColors.lightYellow)
            .onAppear {
                checkInManager.loadDataFromAPI()
                Task { await loadDiaryStatus() }
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
        .sheet(isPresented: $showingDiary) {
            NavigationView {
                MoodDiaryView()
            }
        }
    }
    
    // MARK: - 私有方法
    private func loadDiaryStatus() async {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let nextDay = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let end = calendar.date(byAdding: .second, value: -1, to: nextDay) ?? start
        
        do {
            let entries = try await APIService.shared.getDiaryEntries(
                startDate: start,
                endDate: end
            )
            hasWrittenDiaryToday = !entries.isEmpty
        } catch {
            hasWrittenDiaryToday = nil
        }
    }
}

#Preview {
    HomeView()
}
