//
//  ScaleSelection.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/9/30.
//

import SwiftUI

struct ScaleSelectionView: View {
    @State private var selectedScale: String? = nil
    @State private var showQuestions = false
    
    let scales = [
        "PHQ-9 憂鬱量表",
        "GAD-7 焦慮量表",
        "BSRS-5 簡式健康量表",
        "RFQ-8 反思功能量表"
    ]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("選擇量表")
                    .font(.headline)
                
                ForEach(scales, id: \.self) { scale in
                    Button {
                        selectedScale = scale
                        showQuestions = true
                    } label: {
                        HStack {
                            Text(scale)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2)
                        )
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color.yellow.opacity(0.05).ignoresSafeArea())
            .navigationTitle("健康追蹤")
            .navigationDestination(isPresented: $showQuestions) {
                if let scale = selectedScale {
                    ScaleQuestionView(scaleName: scale)
                }
            }
        }
    }
}

struct ScaleQuestionView: View {
    let scaleName: String
    @State private var answers: [Int] = Array(repeating: 0, count: 3) // 假設三題
    @State private var showResult = false
    
    let options = ["完全沒有", "幾天", "一半以上", "幾乎每天"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(scaleName)
                    .font(.headline)
                
                // 👉 把所有題目包進一個卡片
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(0..<3, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("題目 \(index + 1)：隨便寫的題目")
                                .font(.subheadline)
                            Picker("答案", selection: $answers[index]) {
                                ForEach(0..<options.count, id: \.self) { i in
                                    Text(options[i]).tag(i)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        if index < 2 { // 題目之間加分隔線
                            Divider()
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2)
                )
                
                Button("提交") {
                    showResult = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .background(Color.yellow.opacity(0.05).ignoresSafeArea()) // 👈 改成統一黃色底
        .navigationTitle("量表作答")
        .navigationDestination(isPresented: $showResult) {
            ScaleResultView(scaleName: scaleName, score: answers.reduce(0, +))
        }
    }
}


struct ScaleResultView: View {
    let scaleName: String
    let score: Int
    
    var body: some View {
        VStack(spacing: 24) {
            Text("\(scaleName) 測驗結果")
                .font(.headline)
            
            VStack(spacing: 12) {
                Text("您的總分是 \(score) 分")
                    .font(.title2.bold())
                
                if score < 5 {
                    Text("恭喜你，身心狀況良好 🎉")
                        .foregroundColor(.green)
                } else {
                    Text("建議關注自身狀態，必要時尋求協助 🙏")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2)
            )
            
            Button("返回") {
                // pop 回去
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .background(Color.yellow.opacity(0.05).ignoresSafeArea())
    }
}

#Preview {
    ScaleSelectionView()
}

#Preview {
    ScaleQuestionView(scaleName: "測試問題")
}

#Preview {
    ScaleResultView(scaleName: "結果預覽", score: 100)
}
