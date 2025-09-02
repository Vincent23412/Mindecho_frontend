import SwiftUI

struct RFQ8TestView: View {
    @Binding var isPresented: Bool
    @State private var currentQuestion = 0
    @State private var answers: [Int] = Array(repeating: 0, count: 8)
    @State private var showingResult = false
    
    let questions = [
        "我總是知道自己為什麼會有某種感覺", // 題目1 - RFQ-C
        "我的情緒常常令我困惑", // 題目2 - RFQ-C & RFQ-U
        "當我心煩意亂時，我不知道自己是悲傷、害怕還是憤怒", // 題目3 - RFQ-C
        "我常常困惑於自己的感受", // 題目4 - RFQ-C & RFQ-U
        "我常常不確定自己的感受", // 題目5 - RFQ-C & RFQ-U
        "當別人告訴我他們對我的感受時，我感到困惑", // 題目6 - RFQ-C & RFQ-U
        "我的感受對我來說是個謎", // 題目7 - RFQ-U
        "我常常不知道為什麼我會生氣" // 題目8 - RFQ-U
    ]
    
    let options = ["非常不同意", "不同意", "有點不同意", "中性", "有點同意", "同意", "非常同意"]
    
    var body: some View {
        NavigationView {
            if showingResult {
                RFQ8ResultView(
                    rfqCScore: calculateRFQCScore(),
                    rfqUScore: calculateRFQUScore(),
                    isPresented: $isPresented
                )
            } else {
                VStack(spacing: 20) {
                    ProgressView(value: Double(currentQuestion + 1), total: Double(questions.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: AppColors.orange))
                    
                    Text("第 \(currentQuestion + 1) 題，共 \(questions.count) 題")
                        .font(.caption)
                        .foregroundColor(AppColors.titleColor.opacity(0.7))
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("請根據您的實際情況選擇最符合的選項：")
                            .font(.subheadline)
                            .foregroundColor(AppColors.titleColor)
                        
                        Text(questions[currentQuestion])
                            .font(.headline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.leading)
                    }
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(0..<options.count, id: \.self) { index in
                                Button(action: {
                                    selectAnswer(index)
                                }) {
                                    HStack {
                                        Text(options[index])
                                            .font(.body)
                                            .foregroundColor(AppColors.titleColor)
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            if isRFQCQuestion(currentQuestion) {
                                                Text("C:\(getRFQCScore(for: index))")
                                                    .font(.caption)
                                                    .foregroundColor(AppColors.titleColor.opacity(0.6))
                                            }
                                            if isRFQUQuestion(currentQuestion) {
                                                Text("U:\(getRFQUScore(for: index))")
                                                    .font(.caption)
                                                    .foregroundColor(AppColors.titleColor.opacity(0.6))
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(AppColors.cardBackground)
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.1), radius: 2)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(AppColors.lightYellow)
                .navigationTitle("RFQ-8 反思功能量表")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button("取消") { isPresented = false })
            }
        }
    }
    
    // 判斷是否為RFQ-C題目 (題目1,2,3,4,5,6 對應索引0,1,2,3,4,5)
    private func isRFQCQuestion(_ questionIndex: Int) -> Bool {
        return questionIndex <= 5
    }
    
    // 判斷是否為RFQ-U題目 (題目2,4,5,6,7,8 對應索引1,3,4,5,6,7)
    private func isRFQUQuestion(_ questionIndex: Int) -> Bool {
        let rfqUIndices = [1, 3, 4, 5, 6, 7]
        return rfqUIndices.contains(questionIndex)
    }
    
    // RFQ-C評分：3, 2, 1, 0, 0, 0, 0
    private func getRFQCScore(for optionIndex: Int) -> Int {
        let rfqCScores = [3, 2, 1, 0, 0, 0, 0]
        return rfqCScores[optionIndex]
    }
    
    // RFQ-U評分：0, 0, 0, 0, 1, 2, 3
    private func getRFQUScore(for optionIndex: Int) -> Int {
        let rfqUScores = [0, 0, 0, 0, 1, 2, 3]
        return rfqUScores[optionIndex]
    }
    
    private func selectAnswer(_ answer: Int) {
        answers[currentQuestion] = answer
        
        if currentQuestion < questions.count - 1 {
            currentQuestion += 1
        } else {
            showingResult = true
        }
    }
    
    private func calculateRFQCScore() -> Int {
        var score = 0
        for i in 0..<answers.count {
            if isRFQCQuestion(i) {
                score += getRFQCScore(for: answers[i])
            }
        }
        return score
    }
    
    private func calculateRFQUScore() -> Int {
        var score = 0
        for i in 0..<answers.count {
            if isRFQUQuestion(i) {
                score += getRFQUScore(for: answers[i])
            }
        }
        return score
    }
}

#Preview {
    RFQ8TestView(isPresented: .constant(true))
}
