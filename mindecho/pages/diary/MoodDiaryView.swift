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
    
    let moods = [
        ("很差", "😫"),
        ("不好", "😐"),
        ("一般", "🙂"),
        ("良好", "😃"),
        ("極佳", "🤩")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            DatePicker("選擇日期", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)
            
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
            
            VStack {
                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                Button("儲存") {
                    print("已儲存心情: \(selectedMood ?? "未選擇")")
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("健康追蹤")
    }
}
