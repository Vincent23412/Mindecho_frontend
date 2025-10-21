import SwiftUI

struct ChatListPage: View {
    // MARK: - Hook 狀態管理
    @StateObject private var chatHook = ChatHook()
    
    // MARK: - UI 狀態
    @State private var searchText = ""
    @State private var showingNewChat = false
    @State private var navigateToNewChat = false
    @State private var newChatSession: ChatSession?
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: ChatSession?
    
    // MARK: - 計算屬性
    var filteredChats: [ChatSession] {
        if searchText.isEmpty {
            return chatHook.chatSessions
        } else {
            return chatHook.chatSessions.filter { session in
                session.title.localizedCaseInsensitiveContains(searchText) ||
                session.lastMessage.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 標題區域
                HeaderView(onNewChat: {
                    showingNewChat = true
                })
                
                // 搜尋框
                SearchBar(searchText: $searchText)
                
                // 聊天列表內容
                ChatListContent(
                    filteredChats: filteredChats,
                    isLoading: chatHook.isLoading,
                    onNewChat: { showingNewChat = true },
                    onDeleteSession: deleteSession
                )
                
                Spacer()
            }
            .background(Color.yellow.opacity(0.1).ignoresSafeArea())
            .sheet(isPresented: $showingNewChat) {
                NewChatView(
                    isPresented: $showingNewChat,
                    onChatCreated: { session in
                        newChatSession = session
                        navigateToNewChat = true
                    }
                )
            }
            .background(
                // 隱藏的 NavigationLink，用於程式化導航
                NavigationLink(
                    destination: Group {
                        if let session = newChatSession {
                            ChatDetailPage(session: session)
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
}

// MARK: - 標題區域元件
struct HeaderView: View {
    let onNewChat: () -> Void
    
    var body: some View {
        HStack {
            Text("聊天紀錄")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppColors.titleColor)
            
            Spacer()
            
            Button(action: onNewChat) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("新對話")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(AppColors.chatModeColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// MARK: - 搜尋框元件
struct SearchBar: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜尋對話...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.chatBackground)
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// MARK: - 聊天列表內容
struct ChatListContent: View {
    let filteredChats: [ChatSession]
    let isLoading: Bool
    let onNewChat: () -> Void
    let onDeleteSession: (ChatSession) -> Void
    
    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if filteredChats.isEmpty {
                EmptyChatState(onNewChat: onNewChat)
            } else {
                ChatSessionsList(
                    sessions: filteredChats,
                    onDeleteSession: onDeleteSession
                )
            }
        }
    }
}

// MARK: - 聊天會話列表
struct ChatSessionsList: View {
    let sessions: [ChatSession]
    let onDeleteSession: (ChatSession) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(sessions) { session in
                    NavigationLink(destination: ChatDetailPage(session: session)) {
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
    let onNewChat: () -> Void
    
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
            
            Button(action: onNewChat) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("開始新對話")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AppColors.chatModeColor)
                .cornerRadius(25)
            }
            
            Spacer()
        }
    }
}

// MARK: - 新對話視圖（重構版）
struct NewChatView: View {
    @Binding var isPresented: Bool
    let onChatCreated: (ChatSession) -> Void
    @State private var selectedMode: TherapyMode = .chatMode
    @StateObject private var chatHook = ChatHook()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("選擇對話模式")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.titleColor)
                    
                    Text("選擇最適合您當前需求的對話方式")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                
                VStack(spacing: 16) {
                    ForEach(TherapyMode.allCases, id: \.self) { mode in
                        TherapyModeSelectionCard(
                            mode: mode,
                            isSelected: selectedMode == mode,
                            onSelect: {
                                selectedMode = mode
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: {
                    Task {
                        if let newSession = await chatHook.createNewSession(mode: selectedMode) {
                            isPresented = false
                            onChatCreated(newSession)
                        }
                    }
                }) {
                    Text(chatHook.isLoading ? "建立中..." : "開始對話")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(chatHook.isLoading ? Color.gray : AppColors.chatModeColor)
                        .cornerRadius(12)
                }
                .disabled(chatHook.isLoading)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(AppColors.chatBackground)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                }
                .disabled(chatHook.isLoading)
            )
            .alert("錯誤", isPresented: $chatHook.showError) {
                Button("確定", role: .cancel) {
                    chatHook.error = nil
                }
            } message: {
                if let error = chatHook.error {
                    Text(error)
                }
            }
        }
    }
}

#Preview {
    ChatListPage()
}
