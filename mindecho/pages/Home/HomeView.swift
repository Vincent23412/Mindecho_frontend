import SwiftUI

struct HomeView: View {
    // MARK: - State 屬性
    @State private var selectedTimePeriod = "本週"
    @State private var animationProgress: Double = 0
    @State private var showingDailyCheckIn = false
    @State private var showingDiary = false
    @State private var hasWrittenDiaryToday: Bool? = nil
    @State private var todayDiaryEntry: DiaryEntry?
    @State private var homeDiaryText: String = ""
    @State private var isSavingHomeDiary = false
    @State private var homeDiaryMessage: String?
    @State private var homeDiaryError: String?
    @State private var homeSelectedMood: String? = "OKAY"
    @State private var diaryRefreshToken = UUID()

    private let homeMoods = [
        ("VERY_BAD", "😫", "很差"),
        ("BAD", "😐", "不好"),
        ("OKAY", "🙂", "一般"),
        ("GOOD", "😃", "良好"),
        ("HAPPY", "🤩", "極佳")
    ]
    
    // MARK: - Observable Objects
    @ObservedObject private var checkInManager = DailyCheckInManager.shared
    @ObservedObject private var authViewModel = AuthViewModel.shared
    @EnvironmentObject private var tabTourState: TabTourState
    @State private var showLogoutConfirm = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 五項指標追蹤
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
                    
                    // 今日提醒
                    DailyReminderCard()
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
                    
                    if hasWrittenDiaryToday == false {
                        DiaryReminderCard(onTap: {
                            showingDiary = true
                        })
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    
                    Spacer().frame(height: 24)
                    
                    // 心理測驗區塊
                    PsychologicalTestsSection()
                        .padding(.top, 20)
                    
                    // 快捷入口
                    QuickAccessSection()
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    
                    // 心理健康資源區塊
                    MentalHealthResourcesSection()
                        .padding(.top, 20)

                    homeDiaryQuickEntry
                        .padding(.top, 20)
                        .padding(.bottom, 20)

                    logoutSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 28)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("功能介紹") {
                        tabTourState.step = .home
                        tabTourState.isActive = true
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
            .alert("登出", isPresented: $showLogoutConfirm) {
                Button("取消", role: .cancel) {}
                Button("登出", role: .destructive) {
                    authViewModel.logout()
                }
            } message: {
                Text("確定要登出嗎？")
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
        .sheet(isPresented: $showingDiary) {
            NavigationView {
                MoodDiaryView(refreshToken: diaryRefreshToken)
            }
        }
    }

    private var homeDiaryQuickEntry: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("寫日記")
                    .font(.headline)
                    .foregroundColor(AppColors.titleColor)
                Spacer()
                if isSavingHomeDiary {
                    Text("儲存中...")
                        .font(.caption)
                        .foregroundColor(AppColors.titleColor.opacity(0.6))
                }
            }

            ZStack(alignment: .topLeading) {
                if homeDiaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("寫下今天的感受與想法…")
                        .font(.subheadline)
                        .foregroundColor(AppColors.titleColor.opacity(0.45))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }
                TextEditor(text: $homeDiaryText)
                    .frame(height: 120)
                    .padding(10)
                    .foregroundColor(AppColors.titleColor)
                    .background(Color.clear)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.lightYellow)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppColors.titleColor.opacity(0.12), lineWidth: 1)
                    )
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("今天的心情")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppColors.titleColor)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(homeMoods, id: \.0) { mood in
                            Button {
                                homeSelectedMood = mood.0
                            } label: {
                                VStack(spacing: 4) {
                                    Text(mood.1)
                                        .font(.title2)
                                    Text(mood.2)
                                        .font(.caption)
                                        .foregroundColor(AppColors.titleColor)
                                }
                                .frame(width: 70, height: 78)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(AppColors.lightYellow)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(
                                                    homeSelectedMood == mood.0
                                                    ? AppColors.orange
                                                    : AppColors.titleColor.opacity(0.12),
                                                    lineWidth: 1.5
                                                )
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Button {
                Task { await saveHomeDiaryEntry() }
            } label: {
                Text(isSavingHomeDiary ? "儲存中..." : "儲存日記")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.orange)
                    .cornerRadius(12)
            }
            .disabled(isSavingHomeDiary)

            if let homeDiaryMessage {
                Text(homeDiaryMessage)
                    .font(.caption)
                    .foregroundColor(.green)
            }
            if let homeDiaryError {
                Text(homeDiaryError)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 16)
    }

    private var logoutSection: some View {
        Button {
            showLogoutConfirm = true
        } label: {
            Text("登出")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.85))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
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
            let latest = entries.max { lhs, rhs in
                let l = parseISODate(lhs.updatedAt) ?? parseISODate(lhs.createdAt)
                let r = parseISODate(rhs.updatedAt) ?? parseISODate(rhs.createdAt)
                return (l ?? .distantPast) < (r ?? .distantPast)
            }
            hasWrittenDiaryToday = !(latest == nil)
            todayDiaryEntry = latest
            if let entry = latest {
                if homeDiaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   let content = entry.content {
                    homeDiaryText = content
                }
                if let mood = entry.mood {
                    homeSelectedMood = mood
                }
            }
        } catch {
            hasWrittenDiaryToday = nil
            todayDiaryEntry = nil
        }
    }

    private func saveHomeDiaryEntry() async {
        let content = homeDiaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else {
            await MainActor.run {
                homeDiaryError = "請先輸入內容"
                homeDiaryMessage = nil
            }
            return
        }

        await MainActor.run {
            isSavingHomeDiary = true
            homeDiaryError = nil
            homeDiaryMessage = nil
        }

        guard let mood = homeSelectedMood else {
            await MainActor.run {
                homeDiaryError = "請先選擇心情"
                homeDiaryMessage = nil
            }
            return
        }
        do {
            if let existing = todayDiaryEntry {
                let updated = try await APIService.shared.updateDiaryEntry(
                    id: existing.id,
                    content: content,
                    mood: mood,
                    entryDate: Date()
                )
                await MainActor.run {
                    todayDiaryEntry = updated
                    hasWrittenDiaryToday = true
                    homeDiaryText = ""
                    homeDiaryMessage = "已更新今日日記"
                    diaryRefreshToken = UUID()
                }
            } else {
                let created = try await APIService.shared.createDiaryEntry(
                    content: content,
                    mood: mood,
                    entryDate: Date()
                )
                await MainActor.run {
                    todayDiaryEntry = created
                    hasWrittenDiaryToday = true
                    homeDiaryText = ""
                    homeDiaryMessage = "已儲存今日日記"
                    diaryRefreshToken = UUID()
                }
            }
        } catch {
            await MainActor.run {
                homeDiaryError = "儲存失敗，請稍後再試"
            }
        }

        await MainActor.run {
            isSavingHomeDiary = false
        }
    }

    private func parseISODate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}

#Preview {
    HomeView()
        .environmentObject(TabTourState.shared)
}
