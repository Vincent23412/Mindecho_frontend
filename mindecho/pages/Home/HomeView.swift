import SwiftUI

struct HomeView: View {
    // MARK: - State 屬性
    @State private var selectedTimePeriod = "本週"
    @State private var animationProgress: Double = 0
    @State private var showingDailyCheckIn = false
    @State private var quote = "你的故事還沒有結束，最精彩的章節還在後面"
    
    // MARK: - Observable Objects
    @ObservedObject private var checkInManager = DailyCheckInManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 今日提醒
                    dailyReminderCard
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    
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
            .toolbar {
                // 開發測試按鈕
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("重置今日檢測") {
                            checkInManager.resetTodayData()
                        }
                        
                        Button("清除所有數據", role: .destructive) {
                            checkInManager.clearAllData()
                        }
                        
                        Divider()

                        Button("查看檢測狀態") {
                            print("今日已完成: \(checkInManager.hasCompletedToday)")
                            print("今日分數: \(String(describing: checkInManager.todayScores))")
                            print("週數據筆數: \(checkInManager.weeklyScores.count)")
                        }
                    } label: {
                        Image(systemName: "hammer.fill")
                            .foregroundColor(AppColors.titleColor)
                    }
                }
            }
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
    
    private var dailyReminderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今日提醒")
                .font(.headline)
                .foregroundColor(AppColors.titleColor)
            
            Text("「\(quote)」")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .minimumScaleFactor(0.9)
                .frame(minHeight: 50, alignment: .topLeading)
                .padding(.bottom, 4)
            
            Spacer(minLength: 0)
            
            Button {
                quote = randomQuote()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("換一句")
                }
                .font(.caption)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.orange.opacity(0.15))
                )
            }
            .foregroundColor(AppColors.orange)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.15), radius: 4, x: 0, y: 2)
        )
    }
    
    private func randomQuote() -> String {
        [
            "你的故事還沒有結束，最精彩的章節還在後面。",
            "今天的努力，是明天的底氣。",
            "即使慢，也不要停止前進。",
            "有時候，溫柔比勇敢更強大。"
        ].randomElement()!
    }
    
}

#Preview {
    HomeView()
}
