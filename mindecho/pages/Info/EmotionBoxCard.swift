import SwiftUI

struct EmotionBoxCard: View {
    let title: String
    let description: String
    let buttonTitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 上半部（標題區）
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.leading, 12)
                Spacer()
            }
            .frame(height: 36)
            .frame(maxWidth: .infinity)
            .background(color)
            
            // MARK: - 下半部（內容 + 按鈕）
            VStack(alignment: .leading, spacing: 8) {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)

                Spacer(minLength: 0)

                Button(action: {}) {
                    Text(buttonTitle)
                        .font(.caption.bold())
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(color)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
        }
        .frame(width: 160, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    // 上半橘底圓角覆蓋
                    VStack(spacing: 0) {
                        color.frame(height: 36)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                )
                .shadow(color: .gray.opacity(0.15), radius: 3, x: 0, y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    EmotionBoxCard(
        title: "支撐我的片刻",
        description: "記下那些讓你有動力繼續向前行的理由。",
        buttonTitle: "查看我的理由",
        color: Color.orange.opacity(0.9)
    )
    .padding()
    .background(Color.yellow.opacity(0.1))
}
