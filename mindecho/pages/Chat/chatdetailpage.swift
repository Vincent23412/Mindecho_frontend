import SwiftUI

struct ChatDetailPage: View {
    let session: ChatSession
    
    // MARK: - Hook 狀態管理
    @ObservedObject var chatHook: ChatHook
    
    // MARK: - UI 狀態
    @State private var messageText = ""
    @State private var selectedMode: TherapyMode
    @State private var showingModeChangeConfirmation = false
    @State private var targetMode: TherapyMode?
    @State private var showingClearChatAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    init(session: ChatSession, chatHook: ChatHook) {
        self.session = session
        self.chatHook = chatHook
        self._selectedMode = State(initialValue: session.therapyMode)
    }
    
    // MARK: - 計算屬性
    private var messages: [ChatMessage] {
        chatHook.getMessages(for: session.id)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題欄
            ChatHeaderView(
                session: session,
                selectedMode: $selectedMode,
                onModeChange: { newMode in
                    if newMode != selectedMode {
                        targetMode = newMode
                        showingModeChangeConfirmation = true
                    }
                },
                onBack: {
                    presentationMode.wrappedValue.dismiss()
                },
                onClearChat: {
                    showingClearChatAlert = true
                }
            )
            
            // 聊天消息列表
            ChatMessagesView(
                messages: messages,
                selectedMode: selectedMode,
                isTyping: chatHook.isTyping
            )
            
            // 輸入框
            ChatInputView(
                messageText: $messageText,
                onSend: sendMessage,
                mode: selectedMode
            )
        }
        .background(AppColors.chatBackground)
        .navigationBarHidden(true)
        .overlay(
            // 模式切換確認對話框
            Group {
                if showingModeChangeConfirmation, let target = targetMode {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showingModeChangeConfirmation = false
                                targetMode = nil
                            }
                        
                        ModeChangeConfirmationView(
                            currentMode: selectedMode,
                            targetMode: target,
                            onConfirm: {
                                selectedMode = target
                                Task {
                                    await chatHook.updateSessionMode(session.id, mode: target)
                                }
                                showingModeChangeConfirmation = false
                                targetMode = nil
                            },
                            onCancel: {
                                showingModeChangeConfirmation = false
                                targetMode = nil
                            }
                        )
                        .padding(.horizontal, 32)
                    }
                }
            }
        )
        .alert("清除對話", isPresented: $showingClearChatAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                clearCurrentChat()
            }
        } message: {
            Text("確定要清除當前對話的所有訊息嗎？此操作無法復原。")
        }
        .alert("錯誤", isPresented: $chatHook.showError) {
            Button("確定", role: .cancel) {
                chatHook.error = nil
            }
        } message: {
            if let error = chatHook.error {
                Text(error)
            }
        }
        .task {
            // 頁面載入時載入聊天記錄
            await chatHook.loadChatHistory(for: session.id)
        }
    }
    
    // MARK: - 私有方法
    
    private func clearCurrentChat() {
        Task {
            await chatHook.clearMessages(for: session.id)
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        // 清空輸入框
        messageText = ""
        
        // 發送訊息
        Task {
            await chatHook.sendMessage(to: session.id, content: trimmedMessage)
        }
    }
}

// MARK: - 聊天訊息視圖
struct ChatMessagesView: View {
    let messages: [ChatMessage]
    let selectedMode: TherapyMode
    let isTyping: Bool
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }
                    
                    // 打字指示器
                    if isTyping {
                        HStack {
                            HStack(alignment: .top, spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(selectedMode.color.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    
                                    Text(selectedMode.shortName)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(selectedMode.color)
                                }
                                
                                TypingIndicatorView()
                                
                                Spacer()
                            }
                            
                            Spacer()
                        }
                        .id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .onChange(of: messages.count) { _ in
                // 自動滾動到最新消息
                if let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: isTyping) { typing in
                if typing {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }
}

// MARK: - 聊天標題欄（保持原樣，但使用 AppColors）
struct ChatHeaderView: View {
    let session: ChatSession
    @Binding var selectedMode: TherapyMode
    let onModeChange: (TherapyMode) -> Void
    let onBack: () -> Void
    let onClearChat: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // 頂部導航欄
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        Text("返回")
                            .font(.subheadline)
                    }
                    .foregroundColor(AppColors.chatModeColor)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(session.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.titleColor)
                        .lineLimit(1)
                    
                    Text("最後活動: \(formatRelativeTime(session.lastUpdated))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 會話選項按鈕
                Menu {
                    Button(action: {
                        // TODO: 分享功能
                    }) {
                        Label("分享對話", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        // TODO: 匯出功能
                    }) {
                        Label("匯出對話", systemImage: "doc.text")
                    }
                    
                    Divider()
                    
                    Button(action: {
                        onClearChat()
                    }) {
                        Label("清除對話", systemImage: "trash")
                    }
                    .foregroundColor(.red)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // 模式選擇器
            HStack(spacing: 8) {
                ForEach(TherapyMode.allCases, id: \.self) { mode in
                    Button(action: {
                        if selectedMode != mode {
                            onModeChange(mode)
                        }
                    }) {
                        Text(mode.shortName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedMode == mode ? .white : mode.color)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedMode == mode ? mode.color : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(mode.color, lineWidth: 1)
                                    )
                            )
                    }
                    .scaleEffect(selectedMode == mode ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: selectedMode)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "剛剛"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分鐘前"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)小時前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            formatter.locale = Locale(identifier: "zh_Hant_TW")
            return formatter.string(from: date)
        }
    }
}



#Preview {
    NavigationView {
        ChatDetailPage(session: ChatSession(
            title: "測試對話",
            therapyMode: .chatMode,
            lastMessage: "最後一條消息",
            tags: ["測試"]
        ), chatHook: ChatHook())
    }
}
