import Foundation

// MARK: - API 請求/回應模型
struct SendMessageRequest: Codable {
    let message: String
    let mode: TherapyMode
}

struct ChatAPIResponse: Codable {
    let reply: String
    let messageId: String
    let timestamp: String
}

struct ChatMessagesResponse: Codable {
    let messages: [APIMessage]
}

struct APIMessage: Codable {
    let id: String
    let content: String
    let isFromUser: Bool
    let timestamp: String
    let mode: TherapyMode
}

struct APISessionInfo: Codable {
    let id: String
    let title: String
    let mode: TherapyMode
    let createdAt: String
}

struct ChatSessionResponse: Codable {
    let session: APISessionInfo
}

struct ChatSessionsResponse: Codable {
    let sessions: [APISessionInfo]
}

// MARK: - API 錯誤類型
enum ChatAPIError: Error, LocalizedError {
    case networkError(String)
    case invalidResponse
    case serverError(Int)
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "網路錯誤: \(message)"
        case .invalidResponse:
            return "伺服器回應格式錯誤"
        case .serverError(let code):
            return "伺服器錯誤 (\(code))"
        case .unauthorized:
            return "未授權，請重新登入"
        }
    }
}

// MARK: - 聊天 API 服務
class ChatAPI: NSObject, URLSessionDelegate {
    static let shared = ChatAPI()
    
    private let baseURL = "https://localhost/dev-api"
    private let allowInsecureSelfSigned = true
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        return URLSession(
            configuration: config,
            delegate: allowInsecureSelfSigned ? self : nil,
            delegateQueue: nil
        )
    }()
    
    private override init() {
        super.init()
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard allowInsecureSelfSigned,
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
    
    // MARK: - 發送訊息
    func sendMessage(sessionId: String, request: SendMessageRequest, token: String) async throws -> ChatAPIResponse {
        guard let url = URL(string: "\(baseURL)/chat/sessions/\(sessionId)/messages") else {
            throw ChatAPIError.networkError("無效的 URL")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)" ,forHTTPHeaderField: "Authorization")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            let (data, response) = try await session.data(for: urlRequest)
            
            // 檢查 HTTP 狀態碼
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    break // 成功
                case 401:
                    throw ChatAPIError.unauthorized
                default:
                    throw ChatAPIError.serverError(httpResponse.statusCode)
                }
            }
            
            return try JSONDecoder().decode(ChatAPIResponse.self, from: data)
            
        } catch {
            if error is ChatAPIError {
                throw error
            } else {
                throw ChatAPIError.networkError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - 獲取聊天記錄
    func getChatHistory(sessionId: String, token: String, limit: Int = 50, before: String? = nil) async throws -> ChatMessagesResponse {
        var components = URLComponents(string: "\(baseURL)/chat/sessions/\(sessionId)/messages")
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "limit", value: String(limit))]
        if let before {
            queryItems.append(URLQueryItem(name: "before", value: before))
        }
        components?.queryItems = queryItems
        guard let url = components?.url else {
            throw ChatAPIError.networkError("無效的 URL")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    break
                case 401:
                    throw ChatAPIError.unauthorized
                default:
                    throw ChatAPIError.serverError(httpResponse.statusCode)
                }
            }
            
            return try JSONDecoder().decode(ChatMessagesResponse.self, from: data)
            
        } catch {
            if error is ChatAPIError {
                throw error
            } else {
                throw ChatAPIError.networkError(error.localizedDescription)
            }
        }
    }

    // MARK: - 取得會話列表
    func getSessions(token: String, limit: Int = 20, offset: Int = 0) async throws -> ChatSessionsResponse {
        var components = URLComponents(string: "\(baseURL)/chat/sessions")
        components?.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        guard let url = components?.url else {
            throw ChatAPIError.networkError("無效的 URL")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    break
                case 401:
                    throw ChatAPIError.unauthorized
                default:
                    throw ChatAPIError.serverError(httpResponse.statusCode)
                }
            }
            
            return try JSONDecoder().decode(ChatSessionsResponse.self, from: data)
            
        } catch {
            if error is ChatAPIError {
                throw error
            } else {
                throw ChatAPIError.networkError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - 建立新會話
    func createNewSession(mode: TherapyMode, title: String? = nil, token: String) async throws -> APISessionInfo {
        guard let url = URL(string: "\(baseURL)/chat/sessions") else {
            throw ChatAPIError.networkError("無效的 URL")
        }
        
        var requestBody: [String: String] = ["mode": mode.rawValue]
        if let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            requestBody["title"] = title.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await session.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    break
                case 401:
                    throw ChatAPIError.unauthorized
                default:
                    throw ChatAPIError.serverError(httpResponse.statusCode)
                }
            }
            
            let payload = try JSONDecoder().decode(ChatSessionResponse.self, from: data)
            return payload.session
            
        } catch {
            if error is ChatAPIError {
                throw error
            } else {
                throw ChatAPIError.networkError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - 刪除會話
    func deleteSession(sessionId: String, token: String) async throws {
        guard let url = URL(string: "\(baseURL)/chat/sessions/\(sessionId)") else {
            throw ChatAPIError.networkError("無效的 URL")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await session.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    break
                case 401:
                    throw ChatAPIError.unauthorized
                default:
                    throw ChatAPIError.serverError(httpResponse.statusCode)
                }
            }
            
        } catch {
            if error is ChatAPIError {
                throw error
            } else {
                throw ChatAPIError.networkError(error.localizedDescription)
            }
        }
    }
}

// MARK: - 模擬 API（開發階段使用）
extension ChatAPI {
    // 這個方法在你還沒有真實後端時可以使用
    func generateMockResponse(for message: String, mode: TherapyMode) -> ChatAPIResponse {
        let response = generateAIResponse(for: message, mode: mode)
        
        return ChatAPIResponse(
            reply: response,
            messageId: UUID().uuidString,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    // 從你原本的 ChatManager 移過來的 AI 回覆邏輯
    private func generateAIResponse(for message: String, mode: TherapyMode) -> String {
        let lowercaseMessage = message.lowercased()
        
        switch mode {
        case .chatMode:
            if lowercaseMessage.contains("壓力") {
                return "聽起來您最近壓力不小。能告訴我是什麼讓您感到有壓力嗎？"
            } else if lowercaseMessage.contains("開心") || lowercaseMessage.contains("高興") {
                return "很高興聽到您心情不錯！是有什麼特別的事情讓您開心嗎？"
            } else if lowercaseMessage.contains("累") || lowercaseMessage.contains("疲憊") {
                return "感覺您很疲憊。最近工作或生活節奏是不是比較緊張？"
            } else if lowercaseMessage.contains("週末") || lowercaseMessage.contains("休息") {
                return "聽起來您需要好好休息一下！有什麼特別想做的嗎？戶外活動、看電影，還是其他的興趣愛好？"
            } else if lowercaseMessage.contains("感受不明") {
                return "感受是很重要的信息。能告訴我這種感受在您身體的哪個部位最明顯嗎？"
            } else {
                return "我理解您的感受。能告訴我更多關於這個情況的細節嗎？"
            }
            
        case .cbtMode:
            if lowercaseMessage.contains("總是") || lowercaseMessage.contains("永遠") {
                return "我注意到您用了「總是」這個詞。讓我們檢視一下這個想法是否準確。能給我一些具體的例子嗎？"
            } else if lowercaseMessage.contains("失敗") || lowercaseMessage.contains("做不好") {
                return "失敗的感受很難受。讓我們分析一下這個想法背後的證據。什麼讓您覺得是失敗？"
            } else if lowercaseMessage.contains("焦慮") || lowercaseMessage.contains("擔心") {
                return "焦慮和擔心是很常見的情緒。讓我們用CBT的方式來分析這些想法，看看哪些是基於事實的。"
            } else {
                return "讓我們用認知行為療法的方式來分析這個問題。首先，我們可以識別一些可能影響您情緒的想法模式。"
            }
            
        case .mbtMode:
            if lowercaseMessage.contains("不理解") || lowercaseMessage.contains("不懂") {
                return "理解他人的想法確實不容易。讓我們試著從心智化的角度來看，您覺得對方可能在想什麼？"
            } else if lowercaseMessage.contains("感受") || lowercaseMessage.contains("情緒") {
                return "感受是很重要的信息。能告訴我這種感受在您身體的哪個部位最明顯嗎？"
            } else if lowercaseMessage.contains("關係") || lowercaseMessage.contains("人際") {
                return "人際關係是複雜的。讓我們一起探索在這個關係中，您和對方各自的感受和需求。"
            } else if lowercaseMessage.contains("感受不明") {
                return "感受混亂時很正常的。讓我們慢慢來，先試著感受一下您現在身體的狀態，有什麼地方特別緊繃或放鬆嗎？"
            } else {
                return "在正念為基礎的療法中，我們關注當下的感受和體驗。讓我們花一點時間覺察您現在的感受。"
            }
        }
    }
}
