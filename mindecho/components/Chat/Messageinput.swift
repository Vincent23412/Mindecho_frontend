import SwiftUI

// MARK: - 聊天輸入框（含自殺字詞偵測與導向 ProfileView）
struct ChatInputView: View {
    @Binding var messageText: String
    let onSend: () -> Void
    let mode: TherapyMode

    @State private var isComposing = false
    @State private var showingQuickReplies = false

    // ✅ 新增：危機偵測
    @State private var showCrisisAlert = false
    @State private var goToProfile = false

    // 需放在 NavigationStack 之下
    var crisisKeywords: [String] = [
        "自殺","想死","活不下去","結束生命","跳樓","輕生","割腕","不想活了","suicide","kill myself","end my life"
    ]

    var placeholder: String {
        switch mode {
        case .chatMode: return "輸入訊息..."
        case .cbtMode:  return "分享您的想法或困擾..."
        case .mbtMode:  return "描述您的感受或人際困擾..."
        case .mentalization: return "聊聊你當下的想法與感受..."
        }
    }

    var quickReplies: [String] {
        switch mode {
        case .chatMode: return ["我今天心情不錯", "有點累", "想聊聊", "最近怎麼樣？"]
        case .cbtMode:  return ["我感到很焦慮", "總是擔心", "覺得壓力很大", "想不通"]
        case .mbtMode:  return ["人際關係困擾", "不理解他人", "情緒複雜", "感受不明"]
        case .mentalization: return ["我在想他們怎麼看我", "感覺有點複雜", "我不確定他的意圖", "想釐清自己的情緒"]
        }
    }

    // ✅ 新增：檢測函式（大小寫與空白處理）
    func containsCrisisTerms(_ text: String) -> Bool {
        let t = text.lowercased()
        return crisisKeywords.contains { kw in
            t.contains(kw.lowercased())
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 隱形導頁錨點（需在 NavigationStack 內）
            NavigationLink(destination: ProfileView(), isActive: $goToProfile) {
                EmptyView()
            }.hidden()

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

            Divider().background(Color.gray.opacity(0.3))

            HStack(spacing: 12) {
                Button(action: { showingQuickReplies.toggle() }) {
                    Image(systemName: showingQuickReplies ? "xmark.circle" : "plus.circle")
                        .font(.title2)
                        .foregroundColor(showingQuickReplies ? .red : .gray)
                }

                HStack(spacing: 8) {
                    TextField(placeholder, text: $messageText, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .lineLimit(1...4)
                        .onChange(of: messageText) {
                            isComposing = !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        }

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

                // 送出
                Button(action: {
                    let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }

                    if containsCrisisTerms(trimmed) {
                        // ✅ 偵測到高風險字詞：觸發警示，讓使用者一鍵前往緊急資訊頁
                        showCrisisAlert = true
                    } else {
                        onSend()
                    }
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
        // ✅ 危機引導警示
        .alert("需要立即協助嗎？", isPresented: $showCrisisAlert) {
            Button("前往緊急聯絡資訊") {
                goToProfile = true
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("偵測到您提及嚴重負面/自傷意念。如果您正處於危險或緊急情況，請立即尋求協助。")
        }
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
