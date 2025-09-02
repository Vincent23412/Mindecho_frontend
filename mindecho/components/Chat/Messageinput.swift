import SwiftUI

// MARK: - 聊天輸入框
struct ChatInputView: View {
    @Binding var messageText: String
    let onSend: () -> Void
    let mode: TherapyMode
    
    @State private var isComposing = false
    @State private var showingQuickReplies = false
    
    var placeholder: String {
        switch mode {
        case .chatMode:
            return "輸入訊息..."
        case .cbtMode:
            return "分享您的想法或困擾..."
        case .mbtMode:
            return "描述您的感受或人際困擾..."
        }
    }
    
    var quickReplies: [String] {
        switch mode {
        case .chatMode:
            return ["我今天心情不錯", "有點累", "想聊聊", "最近怎麼樣？"]
        case .cbtMode:
            return ["我感到很焦慮", "總是擔心", "覺得壓力很大", "想不通"]
        case .mbtMode:
            return ["人際關係困擾", "不理解他人", "情緒複雜", "感受不明"]
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 快速回覆
            if showingQuickReplies {
                QuickReplyView(
                    suggestions: quickReplies,
                    onSelect: { reply in
                        messageText = reply
                        showingQuickReplies = false
                    },
                    mode: mode
                )
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack(spacing: 12) {
                // 附件/快速回覆按鈕
                Button(action: {
                    showingQuickReplies.toggle()
                }) {
                    Image(systemName: showingQuickReplies ? "xmark.circle" : "plus.circle")
                        .font(.title2)
                        .foregroundColor(showingQuickReplies ? .red : .gray)
                }
                
                // 輸入框
                HStack(spacing: 8) {
                    TextField(placeholder, text: $messageText, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .lineLimit(1...4)
                        .onChange(of: messageText) {
                            isComposing = !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        }
                    
                    // 字數統計（當輸入較長時顯示）
                    if messageText.count > 100 {
                        Text("\(messageText.count)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isComposing ? mode.color.opacity(0.5) : Color.gray.opacity(0.3),
                            lineWidth: isComposing ? 2 : 1
                        )
                )
                
                // 發送按鈕
                Button(action: {
                    onSend()
                    isComposing = false
                    showingQuickReplies = false
                }) {
                    Image(systemName: isComposing ? "arrow.up.circle.fill" : "arrow.up.circle")
                        .font(.title2)
                        .foregroundColor(isComposing ? mode.color : .gray)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .scaleEffect(isComposing ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isComposing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AppColors.chatBackground)
    }
}

// MARK: - 快速回覆建議
struct QuickReplyView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    let mode: TherapyMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("快速回覆")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(mode.color)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(action: {
                            onSelect(suggestion)
                        }) {
                            Text(suggestion)
                                .font(.subheadline)
                                .foregroundColor(mode.color)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(mode.color.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
        .background(AppColors.chatBackground.opacity(0.5))
    }
}

#Preview {
    VStack(spacing: 20) {
        ChatInputView(
            messageText: .constant(""),
            onSend: {},
            mode: .chatMode
        )
        
        ChatInputView(
            messageText: .constant("測試訊息"),
            onSend: {},
            mode: .cbtMode
        )
        
        QuickReplyView(
            suggestions: ["測試1", "測試2", "測試3"],
            onSelect: { _ in },
            mode: .mbtMode
        )
    }
    .padding()
    .background(AppColors.chatBackground)
}
