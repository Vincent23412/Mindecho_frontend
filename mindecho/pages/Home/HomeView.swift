import SwiftUI

struct HomeView: View {
    // MARK: - State 屬性
    @State private var currentDate = Date()
    @State private var birthDate = Calendar.current.date(from: DateComponents(year: 1990, month: 1, day: 1)) ?? Date()
    @State private var showingBiorhythmSettings = false
    @State private var selectedTimePeriod = "本週"
    @State private var animationProgress: Double = 0
    @State private var currentPage = 0
    @State private var showingDailyCheckIn = false
    @State private var quote = "你的故事還沒有結束，最精彩的章節還在後面"
    
    // MARK: - Observable Objects
    @ObservedObject private var checkInManager = DailyCheckInManager.shared
    
    // MARK: - Computed Properties
    private var standardBiorhythmData: BiorhythmData {
        return BiorhythmCalculator.calculateStandardBiorhythm(
            birthDate: birthDate,
            currentDate: currentDate
        )
    }
    
    private var personalBiorhythmData: BiorhythmData {
        return BiorhythmCalculator.calculatePersonalBiorhythm(
            weeklyScores: checkInManager.weeklyScores,
            currentDate: currentDate
        ) ?? BiorhythmData(
            physical: 0,
            emotional: 0,
            intellectual: 0,
            sleep: 0,
            appetite: 0,
            mode: .personal
        )
    }
    
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
                    
                    // 水平滑動視圖
                    TabView(selection: $currentPage) {
                        // 第一頁：五項指標追蹤卡片
                        VStack {
                            
                            FiveIndicatorsCard(selectedTimePeriod: $selectedTimePeriod)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                                .frame(height: 350)
                            Spacer()
                        }
                        .tag(0)
                        
                        // 第二頁：個人生理節律卡片
                        VStack {
                            Spacer().frame(height: 6)  // 調回與標準卡片相同的間距
                            PersonalBiorhythmCard(
                                animationProgress: animationProgress,
                                onDetailTapped: {
                                    showingDailyCheckIn = true
                                }
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .frame(height: 350)
                            Spacer()
                        }
                        .tag(1)
                        
                        // 第三頁：標準生理節律卡片
                        VStack {
                            Spacer().frame(height: 16)
                            BiorhythmCard(
                                biorhythmData: standardBiorhythmData,
                                currentDate: currentDate,
                                birthDate: birthDate,
                                animationProgress: animationProgress,
                                onEditTapped: {
                                    showingBiorhythmSettings = true
                                }
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .frame(height: 350)
                            Spacer()
                        }
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .indexViewStyle(.page(backgroundDisplayMode: .never))
                    .frame(height: 380)
                    
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
                        
                        Button("生成測試節律數據") {
                            PersonalRhythmManager.shared.generateTestData()
                        }
                        
                        Button("清除節律數據", role: .destructive) {
                            PersonalRhythmManager.shared.clearStoredData()
                        }
                        
                        Button("查看節律狀態") {
                            print(PersonalRhythmManager.shared.getDebugInfo())
                        }
                        
                        Button("查看檢測狀態") {
                            print("今日已完成: \(checkInManager.hasCompletedToday)")
                            print("今日分數: \(String(describing: checkInManager.todayScores))")
                            print("週數據筆數: \(checkInManager.weeklyScores.count)")
                        }
                        
                        Divider()
                        
                        Button("跳到個人模式") {
                            currentPage = 1
                        }
                        
                        Button("跳到標準模式") {
                            currentPage = 2
                        }
                    } label: {
                        Image(systemName: "hammer.fill")
                            .foregroundColor(AppColors.titleColor)
                    }
                }
            }
            .onAppear {
                loadStoredSettings()
                
                // 觸發動畫
                withAnimation(.easeInOut(duration: HomeConstants.Animation.biorhythmAnimationDuration)) {
                    animationProgress = 1.0
                }
            }
        }
        .sheet(isPresented: $showingBiorhythmSettings) {
            BiorhythmSettingsView(
                currentDate: $currentDate,
                birthDate: $birthDate,
                isPresented: $showingBiorhythmSettings
            )
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
    
    /// 載入存儲的設定
    private func loadStoredSettings() {
        // 載入出生日期
        if let storedBirthDate = UserDefaults.standard.object(forKey: HomeConstants.UserDefaultsKeys.birthDate) as? Date {
            birthDate = storedBirthDate
        }
    }
    
    /// 保存設定
    private func saveSettings() {
        UserDefaults.standard.set(birthDate, forKey: HomeConstants.UserDefaultsKeys.birthDate)
    }
}

#Preview {
    HomeView()
}
