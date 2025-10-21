import SwiftUI

struct ProfileView: View {
    @State private var quote = "你的故事還沒有結束，最精彩的章節還在後面"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - 使用者卡片
                userInfoCard
                
                // MARK: - 情緒行李箱
                emotionBoxSection
                
                // MARK: - 今日提醒
                dailyReminderCard
                
                // MARK: - 緊急聯繫
                emergencySection
                
                Spacer()
            }
            .padding(.horizontal) // 全部統一左右內距
            .padding(.vertical, 16)
        }
        .background(Color.yellow.opacity(0.1).ignoresSafeArea())
        .navigationTitle("個人檔案")
    }
}

// MARK: - 各區塊拆分為 Computed Property，結構更乾淨
extension ProfileView {
    
    // 使用者卡片
    private var userInfoCard: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.orange.opacity(0.8))
                .frame(width: 80, height: 80)
                .overlay(
                    Text("小美")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("這是一個屬於你的安全空間，在這裡可以整理情緒、收集力量、找到希望。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label("今天感覺：平靜", systemImage: "face.smiling")
                        .font(.caption)
                    Spacer()
                    Label("連續登入：7天", systemImage: "calendar")
                        .font(.caption)
                }
                .foregroundColor(.brown)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(cardBackground)
    }
    
    
    // 情緒行李箱
    private var emotionBoxSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("情緒行李箱")
                .font(.headline)
                .foregroundColor(.brown)
                .padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    EmotionBoxCard(
                        title: "支撐我的片刻",
                        description: "記下那些讓你有動力繼續向前的理由。",
                        buttonTitle: "查看我的理由",
                        color: .orange
                    )
                    EmotionBoxCard(
                        title: "安心收藏箱",
                        description: "收藏能給你帶來安慰和力量的影片、照片和語音。",
                        buttonTitle: "打開收藏箱",
                        color: .orange.opacity(0.7)
                    )
                    EmotionBoxCard(
                        title: "療癒語錄牆",
                        description: "收集那些曾經撫慰你的話語與詩句。",
                        buttonTitle: "前往查看",
                        color: .orange.opacity(0.6)
                    )
                    EmotionBoxCard(
                        title: "心情樹洞",
                        description: "寫下你的心事，讓自己慢慢釋放。",
                        buttonTitle: "打開樹洞",
                        color: .orange.opacity(0.5)
                    )
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
            }
        }
        .padding(.vertical, 8)

    }
    
    
    // MARK: - 今日提醒
    private var dailyReminderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日提醒")
                .font(.headline)
                .foregroundColor(.brown)
            
            // 固定文字區塊高度，避免 quote 過長造成版面抖動
            Text("「\(quote)」")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
                .frame(minHeight: 50, alignment: .topLeading) // 💡固定高度

            Button {
                quote = randomQuote()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("換一句")
                }
                .font(.caption)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.15))
                )
            }
            .foregroundColor(.orange)
        }
        .padding()
        .frame(minHeight: 120) // 💡整張卡片最小高度統一
        .background(cardBackground)
    }

    
    // 緊急聯繫
    private var emergencySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("緊急聯繫")
                .font(.headline)
                .foregroundColor(.brown)
            
            HStack(spacing: 12) {
                EmergencyContactCard(
                    title: "24小時救援專線",
                    subtitle: "1925（依愛我）",
                    buttonText: "立即撥打"
                )
                EmergencyContactCard(
                    title: "我的支持者",
                    subtitle: "李雅雯：0912-345-678",
                    buttonText: "立即撥打"
                )
            }
        }
        .padding()
        .background(cardBackground)
    }
    
    
    // MARK: - 共用卡片背景樣式
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
            .shadow(color: .gray.opacity(0.15), radius: 4, x: 0, y: 2)
    }
    
    
    // MARK: - 隨機名言
    func randomQuote() -> String {
        [
            "你的故事還沒有結束，最精彩的章節還在後面。",
            "今天的努力，是明天的底氣。",
            "即使慢，也不要停止前進。",
            "有時候，溫柔比勇敢更強大。"
        ].randomElement()!
    }
}


#Preview {
    NavigationView {
        ProfileView()
    }
}
