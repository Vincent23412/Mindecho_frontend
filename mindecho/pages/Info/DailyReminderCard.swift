import SwiftUI

struct DailyReminderCard: View {
    @State private var quote: String = "你的故事還沒有結束，最精彩的章節還在後面"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - 今日提醒標題
            Text("今日提醒")
                .font(.headline)
                .foregroundColor(.brown)

            // MARK: - 引言文字
            Text("「\(quote)」")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
                .frame(minHeight: 50, alignment: .topLeading) // 固定高度避免版面抖動

            // MARK: - 換一句按鈕
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
        .frame(minHeight: 120) // 統一卡片最小高度
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.yellow.opacity(0.15))
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }

    // MARK: - 隨機句子
    private func randomQuote() -> String {
        let quotes = [
            "你的故事還沒有結束，最精彩的章節還在後面",
            "每一次低潮，都是成長的伏筆",
            "請相信，你正在變得越來越好",
            "再難的今天，也擋不住明天的陽光",
            "溫柔對待自己，是勇敢的開始"
        ]
        return quotes.randomElement() ?? quotes[0]
    }
}

#Preview {
    DailyReminderCard()
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color(.systemBackground))
}
