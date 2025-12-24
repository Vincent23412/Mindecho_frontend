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
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    let moods = [
        ("VERY_BAD", "😫", "很差"),
        ("BAD", "😐", "不好"),
        ("OKAY", "🙂", "一般"),
        ("GOOD", "😃", "良好"),
        ("HAPPY", "🤩", "極佳")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // 📅 日曆卡片
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
    }
    
    private func displayName(for moodCode: String) -> String {
        moods.first(where: { $0.0 == moodCode })?.2 ?? moodCode
    }
    
    private func saveDiaryEntry() async {
        errorMessage = nil
        successMessage = nil
        
        guard let userId = AuthService.shared.currentUser?.primaryId, !userId.isEmpty else {
            errorMessage = "找不到使用者資訊"
            return
        }
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
            _ = try await APIService.shared.submitDiaryEntry(
                userId: userId,
                mood: mood,
                content: content,
                entryDate: selectedDate
            )
            successMessage = "已儲存日記"
            diaryText = ""
        } catch {
            errorMessage = "儲存失敗，請稍後再試"
        }
        isSaving = false
    }
}

#Preview {
    MoodDiaryView()
}
