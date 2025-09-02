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
                    // 每日檢測提醒（如果還沒完成）
                    if !checkInManager.hasCompletedToday {
                        DailyCheckInReminderCard(onTap: {
                            showingDailyCheckIn = true
                        })
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    
                    // 頁面指示器（3個頁面）
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? AppColors.titleColor : AppColors.titleColor.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, 8)
                    
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
