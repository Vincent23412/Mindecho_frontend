//
//  MoodDiaryView.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/9/26.
//
import SwiftUI

struct MoodDiaryView: View {
    @State private var selectedDate = Date()
    @State private var selectedMood: String? = nil
    @State private var diaryText: String = ""   // 用來存放日記內容
    @State private var isSaving = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var entriesByDay: [Date: DiaryEntryViewData] = [:]
    @State private var loadedMonthStart: Date?
    
    let moods = [
        ("VERY_BAD", "😫", "很差"),
        ("BAD", "😐", "不好"),
        ("OKAY", "🙂", "一般"),
        ("GOOD", "😃", "良好"),
        ("HAPPY", "🤩", "極佳")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // 📅 日曆卡片（內建）
                VStack(alignment: .leading, spacing: 10) {
                    Text("選擇日期")
                        .font(.headline)
                        .foregroundColor(AppColors.titleColor)
                    DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.06), radius: 10, y: 6)
                )
                .padding(.horizontal)

                // 📌 本月紀錄
                if !monthlyEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("本月紀錄")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppColors.titleColor)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(monthlyEntries) { entry in
                                    Button {
                                        selectedDate = entry.entryDate
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(entry.dayText)
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(AppColors.titleColor)
                                            Text(entry.moodEmoji)
                                                .font(.caption)
                                        }
                                        .frame(width: 36, height: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(Color.white)
                                                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 😊 心情選擇
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("今天的心情")
                            .font(.headline)
                            .foregroundColor(AppColors.titleColor)
                        Spacer()
                        if let mood = selectedMood {
                            Text("已選擇：\(displayName(for: mood))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(moods, id: \.0) { mood in
                                Button {
                                    selectedMood = mood.0
                                } label: {
                                    VStack(spacing: 6) {
                                        Text(mood.1).font(.largeTitle)
                                        Text(mood.2)
                                            .font(.caption)
                                            .foregroundColor(AppColors.titleColor)
                                    }
                                    .frame(width: 90, height: 100)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(
                                                        selectedMood == mood.0
                                                        ? AppColors.chatModeColor
                                                        : Color.gray.opacity(0.2),
                                                        lineWidth: 2
                                                    )
                                            )
                                            .shadow(color: .black.opacity(0.05), radius: 6, y: 4)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                
                // 📔 日記
                VStack(alignment: .leading, spacing: 12) {
                    Text("日記")
                        .font(.headline)
                        .foregroundColor(AppColors.titleColor)
                    
                    if isLoading {
                        Text("載入中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    TextEditor(text: $diaryText)
                        .frame(height: 160)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.05), radius: 6, y: 4)
                        )
                }
                .padding(.horizontal)
                
                // 📌 儲存區
                VStack(alignment: .leading, spacing: 12) {
                    Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline)
                        .foregroundColor(AppColors.titleColor)
                    
                    Button {
                        Task { await saveDiaryEntry() }
                    } label: {
                        HStack {
                            Image(systemName: "tray.and.arrow.down.fill")
                            Text(isSaving ? "儲存中..." : "儲存")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isSaving)
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.06), radius: 10, y: 6)
                )
                .padding(.horizontal)
                
                if let successMessage {
                    Text(successMessage)
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal)
                }
                
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Spacer(minLength: 20)
            }
            .padding(.vertical, 12)
        }
        .background(AppColors.lightYellow.ignoresSafeArea())
        .onAppear {
            Task { await loadEntries(for: selectedDate) }
        }
        .onChange(of: selectedDate) { _, newValue in
            applyEntry(for: newValue)
            Task { await loadEntriesIfMonthChanged(for: newValue) }
        }
    }
    
    private struct DiaryEntryViewData: Identifiable {
        let id: String
        let content: String
        let mood: String
        let entryDate: Date
    }

    private struct MonthlyEntryItem: Identifiable {
        let id: String
        let entryDate: Date
        let moodEmoji: String
        let dayText: String
    }

    private var monthlyEntries: [MonthlyEntryItem] {
        let calendar = Calendar.current
        return entriesByDay.values
            .sorted { $0.entryDate < $1.entryDate }
            .map { entry in
                MonthlyEntryItem(
                    id: entry.id,
                    entryDate: entry.entryDate,
                    moodEmoji: moodEmoji(for: entry.mood),
                    dayText: "\(calendar.component(.day, from: entry.entryDate))"
                )
            }
    }
    
    private func displayName(for moodCode: String) -> String {
        moods.first(where: { $0.0 == moodCode })?.2 ?? moodCode
    }

    private func moodEmoji(for moodCode: String) -> String {
        moods.first(where: { $0.0 == moodCode })?.1 ?? "•"
    }
    
    private func normalizeDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    private func applyEntry(for date: Date) {
        let day = normalizeDay(date)
        if let entry = entriesByDay[day] {
            selectedMood = entry.mood
            diaryText = entry.content
        } else {
            selectedMood = nil
            diaryText = ""
        }
    }
    
    private func monthRange(for date: Date) -> (Date, Date) {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        let nextMonth = calendar.date(byAdding: DateComponents(month: 1), to: start) ?? date
        let end = calendar.date(byAdding: DateComponents(second: -1), to: nextMonth) ?? date
        return (start, end)
    }

    private func loadEntriesIfMonthChanged(for date: Date) async {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        if loadedMonthStart != monthStart {
            await loadEntries(for: date)
        }
    }
    
    private func parseEntryDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
    
    private func loadEntries(for date: Date) async {
        isLoading = true
        errorMessage = nil
        let range = monthRange(for: date)
        do {
            let entries = try await APIService.shared.getDiaryEntries(
                startDate: range.0,
                endDate: range.1
            )
            var updated: [Date: DiaryEntryViewData] = [:]
            for entry in entries {
                guard let entryDate = parseEntryDate(entry.entryDate),
                      let mood = entry.mood,
                      let content = entry.content else { continue }
                let day = normalizeDay(entryDate)
                updated[day] = DiaryEntryViewData(
                    id: entry.id,
                    content: content,
                    mood: mood,
                    entryDate: entryDate
                )
            }
            entriesByDay = updated
            loadedMonthStart = Calendar.current.startOfDay(for: range.0)
            applyEntry(for: selectedDate)
        } catch {
            errorMessage = "載入日記失敗，請稍後再試"
        }
        isLoading = false
    }
    
    private func saveDiaryEntry() async {
        errorMessage = nil
        successMessage = nil
        
        guard let mood = selectedMood else {
            errorMessage = "請選擇心情"
            return
        }
        let content = diaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else {
            errorMessage = "請輸入日記內容"
            return
        }
        
        isSaving = true
        do {
            let day = normalizeDay(selectedDate)
            if let existing = entriesByDay[day] {
                let updated = try await APIService.shared.updateDiaryEntry(
                    id: existing.id,
                    content: content,
                    mood: mood,
                    entryDate: selectedDate
                )
                let entryDate = parseEntryDate(updated.entryDate) ?? selectedDate
                entriesByDay[day] = DiaryEntryViewData(
                    id: updated.id,
                    content: content,
                    mood: mood,
                    entryDate: entryDate
                )
            } else {
                let created = try await APIService.shared.createDiaryEntry(
                    content: content,
                    mood: mood,
                    entryDate: selectedDate
                )
                let entryDate = parseEntryDate(created.entryDate) ?? selectedDate
                entriesByDay[day] = DiaryEntryViewData(
                    id: created.id,
                    content: content,
                    mood: mood,
                    entryDate: entryDate
                )
            }
            successMessage = "已儲存日記"
        } catch {
            errorMessage = "儲存失敗，請稍後再試"
        }
        isSaving = false
    }
}

#Preview {
    MoodDiaryView()
}
