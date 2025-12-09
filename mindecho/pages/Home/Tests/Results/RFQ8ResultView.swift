import SwiftUI

struct RFQ8ResultView: View {
    let rfqCScore: Int
    let rfqUScore: Int
    @Binding var isPresented: Bool
    @State private var showComfortSheet = false
    
    var rfqCLevel: String {
        switch rfqCScore {
        case 0...6: return "過度心智化程度低"
        case 7...12: return "過度心智化程度中等"
        case 13...18: return "過度心智化程度高"
        default: return "過度心智化程度中等"
        }
    }
    
    var rfqULevel: String {
        switch rfqUScore {
        case 0...6: return "心智化缺陷程度低"
        case 7...12: return "心智化缺陷程度中等"
        case 13...18: return "心智化缺陷程度高"
        default: return "心智化缺陷程度中等"
        }
    }
    
    var recommendation: String {
        if rfqCScore >= 13 && rfqUScore >= 13 {
            return "您在心智化方面可能存在較明顯的困難，建議尋求專業協助。"
        } else if rfqCScore >= 13 {
            return "您可能有過度心智化的傾向，建議學習更客觀地理解自己和他人的心理狀態。"
        } else if rfqUScore >= 13 {
            return "您可能在理解心理狀態方面存在困難，建議練習提升自我覺察能力。"
        } else {
            return "您的心智化能力整體良好，請繼續保持。"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.titleColor)
            
            Text("RFQ-8 測試結果")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppColors.titleColor)
            
            VStack(spacing: 16) {
                // RFQ-C 分數
                VStack(spacing: 8) {
                    Text("過度心智化分數 (RFQ-C)")
                        .font(.headline)
                        .foregroundColor(AppColors.titleColor)
                    
                    Text("\(rfqCScore)/18")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(AppColors.orange)
                    
                    Text(rfqCLevel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.titleColor)
                }
                .padding()
                .background(AppColors.cardBackground)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2)
                
                // RFQ-U 分數
                VStack(spacing: 8) {
                    Text("心智化缺陷分數 (RFQ-U)")
                        .font(.headline)
                        .foregroundColor(AppColors.titleColor)
                    
                    Text("\(rfqUScore)/18")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(AppColors.orange)
                    
                    Text(rfqULevel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.titleColor)
                }
                .padding()
                .background(AppColors.cardBackground)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2)
            }
            
            Text(recommendation)
                .font(.body)
                .foregroundColor(AppColors.titleColor)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .background(AppColors.cardBackground)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("💡 量表說明：")
                    .font(.headline)
                    .foregroundColor(AppColors.titleColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• RFQ-C：評估對心理狀態的過度確信")
                    Text("• RFQ-U：評估對心理狀態的不確定性")
                    Text("• 兩個分數都較低表示心智化能力良好")
                }
                .font(.body)
                .foregroundColor(AppColors.titleColor)
            }
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2)
            
            Button(action: { isPresented = false }) {
                Text("完成")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.darkBrown)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
        .background(AppColors.lightYellow)
        .onAppear {
            if rfqCScore >= 13 || rfqUScore >= 13 {
                showComfortSheet = true
            }
        }
        .sheet(isPresented: $showComfortSheet) {
            ComfortSupportView {
                showComfortSheet = false
                isPresented = false
            }
        }
    }
}

private struct ComfortSupportView: View {
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("給自己一點溫柔")
                .font(.title3.weight(.bold))
                .foregroundColor(AppColors.titleColor)
            
            Text("分數偏高時，代表你近期在心智化上感到吃力。先給自己一些時間與空間，並考慮尋求專業協助。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button(action: onClose) {
                Text("收到，回到頁面")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.darkBrown)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(AppColors.lightYellow)
        .presentationDetents([.fraction(0.75)])
    }
}

private struct SupportReasonQuick: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

#Preview {
    RFQ8ResultView(rfqCScore: 8, rfqUScore: 10, isPresented: .constant(true))
}
