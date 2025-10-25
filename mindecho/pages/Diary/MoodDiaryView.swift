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
    @State private var diaryText: String = ""   // 👈 用來存放日記內容
    
    let moods = [
        ("很差", "😫"),
        ("不好", "😐"),
        ("一般", "🙂"),
        ("良好", "😃"),
        ("極佳", "🤩")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 👇 上方留一點空白
            Spacer(minLength: 20)
            
            // 📅 日曆卡片
            DatePicker("選擇日期", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
            
            // 😊 心情選擇
            VStack(alignment: .leading, spacing: 12) {
                Text("今天的心情").font(.headline)
                HStack {
                    ForEach(moods, id: \.0) { mood in
                        Button {
                            selectedMood = mood.0
                        } label: {
                            VStack {
                                Text(mood.1).font(.largeTitle)
                                Text(mood.0).font(.caption)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedMood == mood.0 ? .orange : .gray, lineWidth: 2)
                            )
                        }
                    }
                }
            }
            .padding()
            
            // 📔 日記
            VStack(alignment: .leading, spacing: 12) {
                Text("日記").font(.headline)
                TextEditor(text: $diaryText)   // 👈 日記輸入框
                    .frame(height: 120)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5))
                    )
            }
            .padding(.horizontal)
            
            // 📌 儲存區
            VStack {
                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                
                Button("儲存") {
                    print("已儲存心情: \(selectedMood ?? "未選擇")")
                    print("日記內容: \(diaryText)")
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.yellow.opacity(0.05).ignoresSafeArea()) // 👈 更柔和背景
    }
}

#Preview {
    MoodDiaryView()
}
