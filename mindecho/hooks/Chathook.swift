import SwiftUI
import Foundation

// MARK: - 聊天狀態管理 Hook
@MainActor
class ChatHook: ObservableObject {
    // MARK: - 發布的狀態變數
    @Published var chatSessions: [ChatSession] = []
    @Published var messages: [UUID: [ChatMessage]] = [:]
    @Published var isLoading = false
    @Published var error: String?
    @Published var showError = false
    @Published var isTyping = false
    
    // MARK: - 私有屬性
    private let chatAPI = ChatAPI.shared
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "chatSessions"
    private let messagesKey = "chatMessages"
    
    // 當前用戶信息（從 TokenManager 獲取）
    private var currentUserId: String {
        // 這裡應該從你的 TokenManager 獲取實際的用戶 ID
        return "current_user_id" // 暫時用固定值
    }
    
    private var authToken: String? {
        // 這裡應該從你的 TokenManager 獲取實際的 token
        return "current_auth_token" // 暫時用固定值
    }
    
    // MARK: - 初始化
    init() {
        loadLocalData()
        createSampleDataIfNeeded()
    }
    
    // MARK: - 會話管理方法
    
    /// 建立新的聊天會話
    func createNewSession(mode: TherapyMode) async -> ChatSession? {
        isLoading = true
        error = nil
        
        do {
            // 如果有真實後端，使用 API
            if let token = authToken {
                let apiSessionInfo = try await chatAPI.createNewSession(mode: mode, token: token)
                
                // 將 API 回應轉換為本地模型
                let session = ChatSession(
                    id: UUID(uuidString: apiSessionInfo.id) ?? UUID(),
                    title: apiSessionInfo.title,
                    therapyMode: mode,
                    lastMessage: "",
                    tags: [mode.shortName]
                )
                
                chatSessions.insert(session, at: 0)
                messages[session.id] = []
                
                // 添加歡迎訊息
                await addWelcomeMessage(to: session.id, mode: mode)
                
                saveLocalData()
                isLoading = false
                return session
                
            } else {
                // 離線模式：直接建立本地會話
                let session = createLocalSession(mode: mode)
                chatSessions.insert(session, at: 0)
                messages[session.id] = []
                
                await addWelcomeMessage(to: session.id, mode: mode)
                
                saveLocalData()
                isLoading = false
                return session
            }
            
        } catch {
            self.error = error.localizedDescription
            showError = true
            isLoading = false
            return nil
        }
    }
    
    /// 刪除聊天會話
    func deleteSession(_ sessionId: UUID) async {
        isLoading = true
        error = nil
        
        do {
            // 如果有真實後端，先刪除遠端資料
            if let token = authToken {
                try await chatAPI.deleteSession(sessionId: sessionId.uuidString, token: token)
            }
            
            // 刪除本地資料
            chatSessions.removeAll { $0.id == sessionId }
            messages.removeValue(forKey: sessionId)
            
            saveLocalData()
            
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    /// 更新會話模式
    func updateSessionMode(_ sessionId: UUID, mode: TherapyMode) async {
        guard let index = chatSessions.firstIndex(where: { $0.id == sessionId }) else { return }
        
        chatSessions[index].therapyMode = mode
        chatSessions[index].lastUpdated = Date()
        
        // 添加模式切換訊息
        await addMessage(
            to: sessionId,
            content: mode.welcomeMessage,
            isFromUser: false
        )
        
        saveLocalData()
    }
    
    // MARK: - 訊息管理方法
    
    /// 發送訊息
    func sendMessage(to sessionId: UUID, content: String) async {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        
        guard let session = chatSessions.first(where: { $0.id == sessionId }) else { return }
        
        // 1. 立即添加用戶訊息到 UI
        await addMessage(to: sessionId, content: trimmedContent, isFromUser: true)
        
        // 2. 顯示打字指示器
        isTyping = true
        
        do {
            // 3. 呼叫 API 獲取 AI 回覆
            let aiResponse: String
            
            if let token = authToken {
                // 使用真實 API
                let request = SendMessageRequest(
                    message: trimmedContent,
                    userId: currentUserId,
                    sessionId: sessionId.uuidString,
                    therapyMode: session.therapyMode
                )
                
                let response = try await chatAPI.sendMessage(request, token: token)
                aiResponse = response.reply
                
            } else {
                // 使用模擬 API
                let mockResponse = chatAPI.generateMockResponse(
                    for: trimmedContent,
                    mode: session.therapyMode
                )
                
                // 模擬網路延遲
                try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 秒
                aiResponse = mockResponse.reply
            }
            
            // 4. 隱藏打字指示器
            isTyping = false
            
            // 5. 添加 AI 回覆
            await addMessage(to: sessionId, content: aiResponse, isFromUser: false)
            
        } catch {
            isTyping = false
            self.error = error.localizedDescription
            showError = true
        }
    }
    
    /// 添加訊息（內部方法）
    private func addMessage(to sessionId: UUID, content: String, isFromUser: Bool) async {
        guard let sessionIndex = chatSessions.firstIndex(where: { $0.id == sessionId }) else { return }
        
        let session = chatSessions[sessionIndex]
        let message = ChatMessage(
            content: content,
            isFromUser: isFromUser,
            mode: session.therapyMode
        )
        
        // 添加到訊息列表
        if messages[sessionId] == nil {
            messages[sessionId] = []
        }
        messages[sessionId]?.append(message)
        
        // 更新會話信息
        chatSessions[sessionIndex].lastMessage = content
        chatSessions[sessionIndex].lastUpdated = Date()
        chatSessions[sessionIndex].messageCount = messages[sessionId]?.count ?? 0
        
        // 如果是用戶的第一條訊息，更新標題
        if isFromUser && messages[sessionId]?.filter({ $0.isFromUser }).count == 1 {
            let title = String(content.prefix(20)) + (content.count > 20 ? "..." : "")
            chatSessions[sessionIndex].title = title
        }
        
        // 將最新會話移到最前面
        let updatedSession = chatSessions[sessionIndex]
        chatSessions.remove(at: sessionIndex)
        chatSessions.insert(updatedSession, at: 0)
        
        saveLocalData()
    }
    
    /// 添加歡迎訊息
    private func addWelcomeMessage(to sessionId: UUID, mode: TherapyMode) async {
        await addMessage(to: sessionId, content: mode.welcomeMessage, isFromUser: false)
    }
    
    /// 清除會話的所有訊息
    func clearMessages(for sessionId: UUID) async {
        messages[sessionId] = []
        
        // 更新會話信息
        if let index = chatSessions.firstIndex(where: { $0.id == sessionId }) {
            chatSessions[index].lastMessage = ""
            chatSessions[index].lastUpdated = Date()
            chatSessions[index].messageCount = 0
            
            // 重新添加歡迎訊息
            let mode = chatSessions[index].therapyMode
            await addWelcomeMessage(to: sessionId, mode: mode)
        }
        
        saveLocalData()
    }
    
    /// 獲取特定會話的訊息
    func getMessages(for sessionId: UUID) -> [ChatMessage] {
        return messages[sessionId] ?? []
    }
    
    // MARK: - 資料同步方法
    
    /// 從伺服器載入聊天記錄
    func loadChatHistory(for sessionId: UUID) async {
        guard let token = authToken else { return }
        
        isLoading = true
        error = nil
        
        do {
            let historyResponse = try await chatAPI.getChatHistory(
                sessionId: sessionId.uuidString,
                token: token
            )
            
            // 將 API 訊息轉換為本地模型
            let apiMessages = historyResponse.messages.map { apiMessage in
                ChatMessage(
                    id: UUID(uuidString: apiMessage.id) ?? UUID(),
                    content: apiMessage.content,
                    isFromUser: apiMessage.isFromUser,
                    timestamp: ISO8601DateFormatter().date(from: apiMessage.timestamp) ?? Date(),
                    mode: apiMessage.mode
                )
            }
            
            messages[sessionId] = apiMessages
            
            // 更新會話信息
            if let index = chatSessions.firstIndex(where: { $0.id == sessionId }) {
                let sessionInfo = historyResponse.sessionInfo
                chatSessions[index].title = sessionInfo.title
                chatSessions[index].therapyMode = sessionInfo.mode
                chatSessions[index].lastUpdated = ISO8601DateFormatter().date(from: sessionInfo.lastUpdated) ?? Date()
                chatSessions[index].messageCount = apiMessages.count
                chatSessions[index].lastMessage = apiMessages.last?.content ?? ""
            }
            
            saveLocalData()
            
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - 本地資料管理
    
    /// 儲存資料到本地
    private func saveLocalData() {
        // 保存會話
        if let sessionsData = try? JSONEncoder().encode(chatSessions) {
            userDefaults.set(sessionsData, forKey: sessionsKey)
        }
        
        // 保存訊息
        if let messagesData = try? JSONEncoder().encode(messages) {
            userDefaults.set(messagesData, forKey: messagesKey)
        }
    }
    
    /// 從本地載入資料
    private func loadLocalData() {
        // 載入會話
        if let sessionsData = userDefaults.data(forKey: sessionsKey),
           let sessions = try? JSONDecoder().decode([ChatSession].self, from: sessionsData) {
            chatSessions = sessions
        }
        
        // 載入訊息
        if let messagesData = userDefaults.data(forKey: messagesKey),
           let loadedMessages = try? JSONDecoder().decode([UUID: [ChatMessage]].self, from: messagesData) {
            messages = loadedMessages
        }
    }
    
    /// 建立本地會話（離線模式）
    private func createLocalSession(mode: TherapyMode) -> ChatSession {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        
        return ChatSession(
            title: "\(mode.shortName) - \(formatter.string(from: now))",
            therapyMode: mode,
            tags: [mode.shortName]
        )
    }
    
    // MARK: - 示例資料（開發用）
    
    /// 建立示例資料（僅在沒有本地資料時使用）
    private func createSampleDataIfNeeded() {
        guard chatSessions.isEmpty else { return }
        
        let sampleSessions = [
            ChatSession(
                title: "工作壓力",
                therapyMode: .cbtMode,
                lastMessage: "讓我們分析一下這些想法",
                lastUpdated: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date(),
                tags: ["CBT", "工作"],
                messageCount: 5
            ),
            ChatSession(
                title: "人際關係困擾",
                therapyMode: .mbtMode,
                lastMessage: "我們一起探索這個關係",
                lastUpdated: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                tags: ["MBT", "人際"],
                messageCount: 3
            ),
            ChatSession(
                title: "週末計畫",
                therapyMode: .chatMode,
                lastMessage: "聽起來很不錯！",
                lastUpdated: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                tags: ["聊天", "生活"],
                messageCount: 7
            )
        ]
        
        chatSessions = sampleSessions
        
        // 為每個會話創建示例訊息
        for session in sampleSessions {
            let sampleMessages = createSampleMessages(for: session)
            messages[session.id] = sampleMessages
        }
        
        saveLocalData()
    }
    
    /// 建立示例訊息
    private func createSampleMessages(for session: ChatSession) -> [ChatMessage] {
        switch session.therapyMode {
        case .cbtMode:
            return [
                ChatMessage(content: session.therapyMode.welcomeMessage, isFromUser: false, mode: .cbtMode),
                ChatMessage(content: "我最近工作壓力很大，總是擔心做不好", isFromUser: true, mode: .cbtMode),
                ChatMessage(content: "我理解您的擔憂。讓我們用CBT的方式來分析這個問題。當您說「總是擔心做不好」時，這是一個怎樣的想法模式？", isFromUser: false, mode: .cbtMode),
                ChatMessage(content: "就是覺得自己能力不夠，可能會犯錯", isFromUser: true, mode: .cbtMode)
            ]
        case .mbtMode:
            return [
                ChatMessage(content: session.therapyMode.welcomeMessage, isFromUser: false, mode: .mbtMode),
                ChatMessage(content: "和同事相處有些困難，不知道他們在想什麼", isFromUser: true, mode: .mbtMode),
                ChatMessage(content: "人際關係確實複雜。讓我們用心智化的角度來看，您能具體描述一下是什麼樣的互動讓您感到困惑嗎？", isFromUser: false, mode: .mbtMode)
            ]
        case .mentalization:
            return [
                ChatMessage(content: session.therapyMode.welcomeMessage, isFromUser: false, mode: .mentalization),
                ChatMessage(content: "最近和朋友誤會很多，不知道彼此在想什麼", isFromUser: true, mode: .mentalization),
                ChatMessage(content: "我們可以一起拆解這些互動。當時你怎麼理解對方的意圖？你自己的情緒又是什麼呢？", isFromUser: false, mode: .mentalization)
            ]
        case .chatMode:
            return [
                ChatMessage(content: session.therapyMode.welcomeMessage, isFromUser: false, mode: .chatMode),
                ChatMessage(content: "這個週末想做點什麼放鬆的事情", isFromUser: true, mode: .chatMode),
                ChatMessage(content: "聽起來您需要好好休息一下！有什麼特別想做的嗎？戶外活動、看電影，還是其他的興趣愛好？", isFromUser: false, mode: .chatMode)
            ]
        }
    }
    
    // MARK: - 清理方法（測試用）
    
    /// 清除所有資料
    func clearAllData() {
        chatSessions.removeAll()
        messages.removeAll()
        userDefaults.removeObject(forKey: sessionsKey)
        userDefaults.removeObject(forKey: messagesKey)
    }
}
