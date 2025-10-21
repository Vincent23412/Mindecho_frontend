import SwiftUI

struct ProfileView: View {
    @State private var quote = "你的故事還沒有結束，最精彩的章節還在後面"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - 使用者卡片
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
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .gray.opacity(0.15), radius: 4, x: 0, y: 2)
                )
                
                // MARK: - 情緒行李箱
                VStack(alignment: .leading, spacing: 16) {
                    Text("情緒行李箱")
                        .font(.headline)
                        .foregroundColor(.brown)
                    
                    HStack(spacing: 12) {
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
                    }
                }
                
                // MARK: - 今日提醒
                VStack(alignment: .leading, spacing: 12) {
                    Text("今日提醒")
                        .font(.headline)
                        .foregroundColor(.brown)
                    
                    Text("“\(quote)”")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    
                    Button {
                        quote = randomQuote()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("換一句")
                        }
                        .font(.caption)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.orange.opacity(0.1))
                )
                
                // MARK: - 緊急聯繫
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
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .gray.opacity(0.15), radius: 4, x: 0, y: 2)
                )
                
                Spacer()
            }
            .padding()
        }
        .background(Color.yellow.opacity(0.05).ignoresSafeArea())
        .navigationTitle("個人檔案")
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

// MARK: - 子元件

struct EmotionBoxCard: View {
    let title: String
    let description: String
    let buttonTitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.brown)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button(buttonTitle) {}
                .font(.caption)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(color.opacity(0.9))
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
        .frame(width: 160, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.15), radius: 3, x: 0, y: 2)
        )
    }
}

struct EmergencyContactCard: View {
    let title: String
    let subtitle: String
    let buttonText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.brown)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button(buttonText) {}
                .font(.caption)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
        .frame(width: 160, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.15), radius: 3, x: 0, y: 2)
        )
    }
}

#Preview {
    NavigationView {
        ProfileView()
    }
}
