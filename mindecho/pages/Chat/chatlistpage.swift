import SwiftUI

struct ChatListPage: View {
    // MARK: - Hook 狀態管理
    @StateObject private var chatHook = ChatHook()
    
    // MARK: - UI 狀態
    @State private var navigateToNewChat = false
    @State private var newChatSession: ChatSession?
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: ChatSession?
    @State private var selectedMode: TherapyMode = .chatMode
    @State private var showingTitlePrompt = false
    @State private var pendingTitle = ""
    
    // MARK: - 計算屬性
    var filteredChats: [ChatSession] {
        chatHook.chatSessions
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 標題區域
                HeaderView()
                
                // 模式卡片
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(modeCards) { card in
                            TherapyModeResourceCard(card: card) {
                                startNewChat(for: card.mode)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 16)
                
                // 聊天列表內容
                ChatListContent(
                    filteredChats: filteredChats,
                    isLoading: chatHook.isLoading,
                    onDeleteSession: deleteSession,
                    chatHook: chatHook
                )
                
                Spacer()
            }
            .background(Color.yellow.opacity(0.1).ignoresSafeArea())
            .task {
                await chatHook.loadSessions()
            }
            .background(
                // 隱藏的 NavigationLink，用於程式化導航
                NavigationLink(
                    destination: Group {
                        if let session = newChatSession {
                            ChatDetailPage(session: session, chatHook: chatHook)
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: $navigateToNewChat
                ) {
                    EmptyView()
                }
                .hidden()
            )
            .alert("確認刪除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {
                    sessionToDelete = nil
                }
                Button("刪除", role: .destructive) {
                    if let session = sessionToDelete {
                        Task {
                            await chatHook.deleteSession(session.id)
                        }
                        sessionToDelete = nil
                    }
                }
            } message: {
                if let session = sessionToDelete {
                    Text("確定要刪除「\(session.title)」對話嗎？此操作無法復原。")
                }
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
            .alert("聊天室名稱", isPresented: $showingTitlePrompt) {
                TextField("可選填", text: $pendingTitle)
                Button("略過") {
                    Task {
                        if let newSession = await chatHook.createNewSession(mode: selectedMode, title: nil) {
                            newChatSession = newSession
                            navigateToNewChat = true
                        }
                    }
                }
                Button("確定") {
                    Task {
                        let title = pendingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let newSession = await chatHook.createNewSession(
                            mode: selectedMode,
                            title: title.isEmpty ? nil : title
                        ) {
                            newChatSession = newSession
                            navigateToNewChat = true
                        }
                    }
                }
            } message: {
                Text("請輸入聊天室名稱（可留空）")
            }
        }
    }
    
    // MARK: - 刪除功能
    private func deleteSession(_ session: ChatSession) {
        sessionToDelete = session
        showingDeleteAlert = true
    }
    
    private func deleteSessionsAtOffsets(_ offsets: IndexSet) {
        for index in offsets {
            let session = filteredChats[index]
            Task {
                await chatHook.deleteSession(session.id)
            }
        }
    }
    
    private func startNewChat(for mode: TherapyMode) {
        guard !chatHook.isLoading else { return }
        selectedMode = mode
        pendingTitle = ""
        showingTitlePrompt = true
    }
    
    private var modeCards: [TherapyModeCard] {
        [
            TherapyModeCard(
                mode: .chatMode,
                title: "聊天",
                subtitle: "輕鬆自在的日常對話",
                icon: "bubble.left.and.bubble.right"
            ),
            TherapyModeCard(
                mode: .cbtMode,
                title: "CBT",
                subtitle: "釐清想法與情緒，調整負向思維",
                icon: "brain.head.profile"
            ),
            TherapyModeCard(
                mode: .mbtMode,
                title: "MBT",
                subtitle: "理解自己與他人感受，增進關係",
                icon: "person.2.fill"
            )
        ]
    }
}

// MARK: - 標題區域元件
struct HeaderView: View {
    var body: some View {
        HStack {
            Text("聊天紀錄")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppColors.titleColor)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// MARK: - 聊天列表內容
struct ChatListContent: View {
    let filteredChats: [ChatSession]
    let isLoading: Bool
    let onDeleteSession: (ChatSession) -> Void
    let chatHook: ChatHook
    
    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if filteredChats.isEmpty {
                EmptyChatState()
            } else {
                ChatSessionsList(
                    sessions: filteredChats.filter { !$0.lastMessage.isEmpty },
                    chatHook: chatHook,
                    onDeleteSession: onDeleteSession
                )
            }
        }
    }
}

// MARK: - 聊天會話列表
struct ChatSessionsList: View {
    let sessions: [ChatSession]
    let chatHook: ChatHook
    let onDeleteSession: (ChatSession) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(sessions) { session in
                    NavigationLink(destination: ChatDetailPage(session: session, chatHook: chatHook)) {
                        ChatListItemView(session: session)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        // 刪除按鈕
                        Button(role: .destructive, action: {
                            onDeleteSession(session)
                        }) {
                            Label("刪除", systemImage: "trash")
                        }
                        
                        // 編輯按鈕
                        Button(action: {
                            // TODO: 實現編輯功能
                        }) {
                            Label("編輯", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .contextMenu {
                        Button(action: {
                            // TODO: 分享功能
                        }) {
                            Label("分享對話", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: {
                            // TODO: 標記重要
                        }) {
                            Label("標記重要", systemImage: "star")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            onDeleteSession(session)
                        }) {
                            Label("刪除對話", systemImage: "trash")
                        }
                    }
                    
                    if session.id != sessions.last?.id {
                        Divider()
                            .padding(.leading, 80)
                    }
                }
            }
            .padding(.top, 16)
        }
    }
}

// MARK: - 載入視圖
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("載入中...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 聊天列表項目（保持原樣）
struct ChatListItemView: View {
    let session: ChatSession
    
    var body: some View {
        HStack(spacing: 16) {
            // 模式圖標
            ZStack {
                Circle()
                    .fill(session.therapyMode.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(session.therapyMode.shortName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(session.therapyMode.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.titleColor)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(formatDate(session.lastUpdated))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text(session.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if !session.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(session.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.chatBackground)
                                .foregroundColor(AppColors.chatModeColor)
                                .cornerRadius(8)
                        }
                        
                        if session.tags.count > 2 {
                            Text("+\(session.tags.count - 2)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) == true {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "zh_Hant_TW")
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - 空狀態視圖（保持原樣）
struct EmptyChatState: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 64))
                    .foregroundColor(.gray.opacity(0.6))
                
                Text("還沒有聊天紀錄")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("開始您的第一次心靈對話")
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.8))
            }
            
            Spacer()
        }
    }
}

private struct TherapyModeCard: Identifiable {
    let mode: TherapyMode
    let title: String
    let subtitle: String
    let icon: String
    
    var id: String { mode.rawValue }
}

private struct TherapyModeResourceCard: View {
    let card: TherapyModeCard
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: card.icon)
                        .font(.title2)
                        .foregroundColor(AppColors.darkBrown)
                    Spacer()
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.darkBrown)
                    
                    Text(card.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.darkBrown.opacity(0.7))
                        .lineLimit(2)
                    
                    Text("建立聊天室")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.darkBrown)
                        .cornerRadius(8)
                        .padding(.top, 4)
                }
            }
            .padding(16)
            .frame(width: 160, height: 150)
            .background(
                LinearGradient(
                    colors: [
                        AppColors.resourceCardYellow,
                        AppColors.resourceCardOrange,
                        AppColors.orange.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(HomeConstants.Charts.cardCornerRadius)
            .shadow(color: .black.opacity(0.1), radius: HomeConstants.Charts.cardShadowRadius)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ChatListPage()
}
