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
    
    // 當前用戶信息（從 TokenManager 獲取）
    private var currentUserId: String {
        // 這裡應該從你的 TokenManager 獲取實際的用戶 ID
        return "current_user_id" // 暫時用固定值
    }
    
    private var authToken: String? {
        AuthService.shared.authToken
    }
    
    // MARK: - 初始化
    init() {
        // 不使用本地快取與預設聊天資料
        filterLegacySessions()
        Task { await loadSessions() }
    }

    private func filterLegacySessions() {
        chatSessions.removeAll { $0.therapyMode.rawValue == "mentalization" }
    }
    
    // MARK: - 會話管理方法
    
    /// 建立新的聊天會話
    func createNewSession(mode: TherapyMode, title: String? = nil) async -> ChatSession? {
        isLoading = true
        error = nil
        
        do {
            // 如果有真實後端，使用 API
            if let token = authToken {
                let apiSessionInfo = try await chatAPI.createNewSession(mode: mode, title: title, token: token)
                
                // 將 API 回應轉換為本地模型
                let session = ChatSession(
                    id: UUID(),
                    backendId: apiSessionInfo.id,
                    title: apiSessionInfo.title,
                    therapyMode: mode,
                    lastMessage: "",
                    lastUpdated: parseAPIDate(apiSessionInfo.createdAt) ?? Date(),
                    tags: [mode.shortName]
                )
                
                chatSessions.insert(session, at: 0)
                messages[session.id] = []
                
                // 添加歡迎訊息
                await addWelcomeMessage(to: session.id, mode: mode)
                
                isLoading = false
                return session
                
            } else {
                // 離線模式：直接建立本地會話
                let session = createLocalSession(mode: mode)
                chatSessions.insert(session, at: 0)
                messages[session.id] = []
                
                await addWelcomeMessage(to: session.id, mode: mode)
                
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
            if let token = authToken,
               let backendId = chatSessions.first(where: { $0.id == sessionId })?.backendId {
                try await chatAPI.deleteSession(sessionId: backendId, token: token)
            }
            
            // 刪除本地資料
            chatSessions.removeAll { $0.id == sessionId }
            messages.removeValue(forKey: sessionId)
            
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
                    mode: session.therapyMode
                )

                guard let backendId = session.backendId else {
                    throw ChatAPIError.invalidResponse
                }
                let response = try await chatAPI.sendMessage(
                    sessionId: backendId,
                    request: request,
                    token: token
                )
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
        
    }
    
    /// 獲取特定會話的訊息
    func getMessages(for sessionId: UUID) -> [ChatMessage] {
        return messages[sessionId] ?? []
    }
    
    // MARK: - 資料同步方法
    
    /// 從伺服器載入聊天記錄
    func loadChatHistory(for sessionId: UUID) async {
        guard let token = authToken else { return }
        guard let backendId = chatSessions.first(where: { $0.id == sessionId })?.backendId else {
            return
        }
        error = nil
        
        do {
            let historyResponse = try await chatAPI.getChatHistory(
                sessionId: backendId,
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
            
            if !apiMessages.isEmpty {
                messages[sessionId] = apiMessages
                
                // 更新會話信息
                if let index = chatSessions.firstIndex(where: { $0.id == sessionId }) {
                    let lastUpdated = apiMessages.last?.timestamp ?? Date()
                    chatSessions[index].lastUpdated = lastUpdated
                    chatSessions[index].messageCount = apiMessages.count
                    chatSessions[index].lastMessage = apiMessages.last?.content ?? ""
                }
            } else if messages[sessionId] == nil {
                messages[sessionId] = []
            }
            
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
    }

    /// 取得會話列表（後端）
    func loadSessions(limit: Int = 20, offset: Int = 0) async {
        guard let token = authToken else { return }
        isLoading = true
        error = nil
        
        do {
            let response = try await chatAPI.getSessions(token: token, limit: limit, offset: offset)
            let existingIds: [String: UUID] = Dictionary(uniqueKeysWithValues: chatSessions.compactMap { session -> (String, UUID)? in
                guard let backendId = session.backendId else { return nil }
                return (backendId, session.id)
            })
            let mapped = response.sessions.map { session in
                ChatSession(
                    id: existingIds[session.id] ?? UUID(),
                    backendId: session.id,
                    title: session.title,
                    therapyMode: session.mode,
                    lastMessage: "",
                    lastUpdated: parseAPIDate(session.createdAt) ?? Date(),
                    tags: [session.mode.shortName]
                )
            }
            chatSessions = mapped
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }

    private func parseAPIDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
    
    // 不使用本地快取
    
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
    // 移除示例資料
    
    // MARK: - 清理方法（測試用）
    
    /// 清除所有資料
    func clearAllData() {
        chatSessions.removeAll()
        messages.removeAll()
    }
}
