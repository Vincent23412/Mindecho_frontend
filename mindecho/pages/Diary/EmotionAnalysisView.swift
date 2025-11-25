//
//  EmotionAnalysisView.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/9/26.
//

import SwiftUI

struct EmotionAnalysisView: View {
    let emotions = [
        ("平靜", 0.45, Color.blue),
        ("開心", 0.30, Color.yellow),
        ("疲倦", 0.15, Color.orange),
        ("難過", 0.07, Color.purple),
        ("生氣", 0.03, Color.red)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("AI 情緒分析")
                    .font(.title2.bold())
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("本月情緒趨勢").font(.headline)
                    ForEach(emotions, id: \.0) { emo in
                        HStack {
                            Text(emo.0).frame(width: 50, alignment: .leading)
                            ProgressView(value: emo.1).tint(emo.2)
                            Text("\(Int(emo.1 * 100))%").frame(width: 40, alignment: .trailing)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("常用詞彙分析").font(.headline)
                    Text("平靜 朋友 陽光 希望 工作 思考 忙碌 計畫")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("情緒洞察").font(.headline)
                    Text("根據您本月的日記內容分析，您的情緒整體呈現平穩趨勢...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .background(AppColors.lightYellow) // 👈 加上背景色
    }
}

#Preview {
    EmotionAnalysisView()
}

