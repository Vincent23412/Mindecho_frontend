import Foundation
import Combine

// MARK: - 認證服務類
class AuthService: NSObject, ObservableObject, URLSessionDelegate {
    
    // MARK: - 單例模式
    static let shared = AuthService()
    
    // MARK: - Published 屬性 (用於 SwiftUI 自動更新 UI)
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var authToken: String?
    
    // MARK: - 私有屬性
    private let baseURL = "https://mindechoserver.com:8443/api"
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AuthConstants.Network.requestTimeout
        config.timeoutIntervalForResource = AuthConstants.Network.requestTimeout * 2
        return URLSession(
            configuration: config,
            delegate: allowInsecureSelfSigned ? self : nil,
            delegateQueue: nil
        )
    }()
    /// 僅開發用：允許自簽/無效憑證（正式版請關閉）
    private let allowInsecureSelfSigned = true
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UserDefaults 鍵值
    private enum Keys {
        static let authToken = AuthConstants.UserDefaultsKeys.authToken
        static let refreshToken = AuthConstants.UserDefaultsKeys.refreshToken
        static let userData = AuthConstants.UserDefaultsKeys.userData
        static let loginDate = AuthConstants.UserDefaultsKeys.loginDate
    }

    var hasStoredAuth: Bool {
        if AppConfig.skipStoredAuth {
            return false
        }
        let token = UserDefaults.standard.string(forKey: Keys.authToken)
        let userData = UserDefaults.standard.data(forKey: Keys.userData)
        let loginDate = UserDefaults.standard.double(forKey: Keys.loginDate)
        return token != nil && userData != nil && loginDate > 0
    }

    func isStoredAuthValid(maxAgeDays: Int = 30) -> Bool {
        guard hasStoredAuth else { return false }
        let loginDateValue = UserDefaults.standard.double(forKey: Keys.loginDate)
        let loginDate = Date(timeIntervalSince1970: loginDateValue)
        let maxAgeSeconds = TimeInterval(maxAgeDays * 24 * 60 * 60)
        return Date().timeIntervalSince(loginDate) <= maxAgeSeconds
    }
    
    private override init() {
        super.init()
        loadStoredAuth()
    }

    // MARK: - URLSessionDelegate（僅開發用，信任自簽憑證）
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
    
    // MARK: - 載入本地存儲的認證資訊
    fileprivate func loadStoredAuth() {
        if AppConfig.skipStoredAuth {
            return
        }
        if let token = UserDefaults.standard.string(forKey: Keys.authToken),
           let userData = UserDefaults.standard.data(forKey: Keys.userData),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            
            self.authToken = token
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    // MARK: - 儲存認證資訊到本地
    private func saveAuth(user: User, token: String, refreshToken: String? = nil) {
        UserDefaults.standard.set(token, forKey: Keys.authToken)

        if let refreshToken = refreshToken {
            UserDefaults.standard.set(refreshToken, forKey: Keys.refreshToken)
        }

        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: Keys.userData)
        }
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Keys.loginDate)
        
        DispatchQueue.main.async {
            self.authToken = token
            self.currentUser = user
            self.isAuthenticated = true
        }
    }

    func updateProfile(_ user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: Keys.userData)
        }
        
        DispatchQueue.main.async {
            self.currentUser = user
        }
    }
    
    // MARK: - 清除認證資訊
    private func clearAuth() {
        UserDefaults.standard.removeObject(forKey: Keys.authToken)
        UserDefaults.standard.removeObject(forKey: Keys.refreshToken)
        UserDefaults.standard.removeObject(forKey: Keys.userData)
        UserDefaults.standard.removeObject(forKey: Keys.loginDate)
        
        DispatchQueue.main.async {
            self.authToken = nil
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    // MARK: - 註冊功能
    func register(request: RegisterRequest) -> AnyPublisher<AuthResponse, Error> {
     
        // 指向本機 dev API（若在模擬器/實機測試請視需求改成 127.0.0.1 或區網 IP）
        guard let url = URL(string: "\(baseURL)/auth/register") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        print("🚀 發送註冊請求到: \(url)")
        print("📦 請求數據: \(request)")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 JSON 數據: \(jsonString)")
            }
        } catch {
            print("❌ JSON 編碼錯誤: \(error)")
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: urlRequest)
            .handleEvents(receiveOutput: { data, response in
                print("📥 收到回應: \(response)")
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 HTTP 狀態碼: \(httpResponse.statusCode)")
                }
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 回應內容: \(jsonString)")
                } else {
                    print("❌ 無法解析回應數據")
                }
            })
            .tryMap { data, response -> Data in
                // 處理 HTTP 狀態碼
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 400 {
                        // 400 錯誤時，先嘗試解析錯誤訊息
                        if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let message = errorData["message"] as? String {
                            print("⚠️ 後端錯誤訊息: \(message)")
                            
                            // 建立自訂錯誤回應
                            let errorResponse = AuthResponse(
                                success: false,
                                message: message,
                                user: nil,
                                token: nil,
                                refreshToken: nil
                            )
                            
                            if let encodedData = try? JSONEncoder().encode(errorResponse) {
                                return encodedData
                            }
                        }
                    }
                }
                return data
            }
            .decode(type: AuthResponse.self, decoder: JSONDecoder())
            .catch { error -> AnyPublisher<AuthResponse, Error> in
                print("❌ 解析錯誤: \(error)")
                
                // 如果是解析錯誤，返回自訂錯誤訊息
                let customResponse = AuthResponse(
                    success: false,
                    message: "伺服器連線正常，但回應格式異常。請聯繫技術支援。",
                    user: nil,
                    token: nil,
                    refreshToken: nil
                )
                return Just(customResponse)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] response in
                if response.success == true,
                   let user = response.user,
                   let token = response.token {
                    self?.saveAuth(user: user, token: token, refreshToken: response.refreshToken)
                }
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - 登錄功能
    func login(request: LoginRequest) -> AnyPublisher<AuthResponse, Error> {

        // 本地反向代理登入端點
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        print("🚀 發送登錄請求到: \(url)")
        print("📦 登錄請求數據: \(request)")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 登錄 JSON: \(jsonString)")
            }
        } catch {
            print("❌ 登錄 JSON 編碼錯誤: \(error)")
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: urlRequest)
            .handleEvents(receiveOutput: { data, response in
                print("📥 登錄回應: \(response)")
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 登錄狀態碼: \(httpResponse.statusCode)")
                }
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 登錄回應內容: \(jsonString)")
                } else {
                    print("❌ 無法解析登錄回應數據")
                }
            })
            .tryMap { data, response -> Data in
                // 處理 HTTP 狀態碼
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 400 || httpResponse.statusCode == 401 {
                        // 登錄錯誤時，先嘗試解析錯誤訊息
                        if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let message = errorData["message"] as? String {
                            print("⚠️ 登錄錯誤訊息: \(message)")
                            
                            // 建立自訂錯誤回應
                            let errorResponse = AuthResponse(
                                success: false,
                                message: message,
                                user: nil,
                                token: nil,
                                refreshToken: nil
                            )
                            
                            if let encodedData = try? JSONEncoder().encode(errorResponse) {
                                return encodedData
                            }
                        }
                    }
                }
                return data
            }
            .decode(type: AuthResponse.self, decoder: JSONDecoder())
            .catch { error -> AnyPublisher<AuthResponse, Error> in
                print("❌ 登錄解析錯誤: \(error)")
                
                // 如果是解析錯誤，返回自訂錯誤訊息
                let customResponse = AuthResponse(
                    success: false,
                    message: "伺服器連線正常，但回應格式異常。請聯繫技術支援。",
                    user: nil,
                    token: nil,
                    refreshToken: nil
                )
                return Just(customResponse)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] response in
                if response.success == true,
                   let user = response.user,
                   let token = response.token {
                    self?.saveAuth(user: user, token: token, refreshToken: response.refreshToken)
                }
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - 登出功能
    func logout() {
        // 如果需要通知服務器用戶登出，可以在這裡添加 API 請求
        clearAuth()
    }
    
    // MARK: - Token 刷新功能
    func refreshToken() -> AnyPublisher<AuthResponse, Error> {
        guard let refreshToken = UserDefaults.standard.string(forKey: Keys.refreshToken),
              let url = URL(string: "\(baseURL)/auth/refresh") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
        
        return session.dataTaskPublisher(for: urlRequest)
            .handleEvents(receiveOutput: { data, response in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Auth refresh: status \(httpResponse.statusCode)")
                }
                if let body = String(data: data, encoding: .utf8) {
                    print("Auth refresh: response body \(body)")
                }
            })
            .map(\.data)
            .decode(type: AuthResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] response in
                if response.success == true,
                   let user = response.user,
                   let token = response.token {
                    self?.saveAuth(user: user, token: token, refreshToken: response.refreshToken)
                }
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - 建立帶有認證 Header 的請求
    func authenticatedRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
    
    /// 確保從本地載入最新認證資訊（供外部需要時呼叫）
    func refreshStoredAuthIfNeeded() {
        if currentUser == nil || authToken == nil {
            loadStoredAuth()
        }
    }
}

// MARK: - 模擬服務 (開發測試用)
extension AuthService {
    
    // 模擬註冊 (用於測試，實際開發時請移除)
    func simulateRegister(request: RegisterRequest) -> AnyPublisher<AuthResponse, Error> {
        // 模擬網路延遲
        return Just(())
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .tryMap { _ in
                // 模擬成功回應
                let user = User(
                    id: UUID().uuidString,
                    userId: UUID().uuidString,
                    email: request.email,
                    firstName: request.firstName,
                    lastName: request.lastName,
                    dateOfBirth: request.dateOfBirth,
                    gender: request.gender,
                    educationLevel: request.educationLevel,
                    supportContactName: request.supportContactName,
                    supportContactInfo: request.supportContactInfo,
                    familyContactName: request.familyContactName,
                    familyContactInfo: request.familyContactInfo,
                    isActive: true,
                    preferences: nil,
                    createdAt: nil,
                    updatedAt: nil
                )
                
                return AuthResponse(
                    success: true,
                    message: "註冊成功！",
                    user: user,
                    token: "mock_token_\(UUID().uuidString)",
                    refreshToken: "mock_refresh_token_\(UUID().uuidString)"
                )
            }
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] response in
                if let user = response.user, let token = response.token {
                    self?.saveAuth(user: user, token: token, refreshToken: response.refreshToken)
                }
            })
            .eraseToAnyPublisher()
    }
    
    // 模擬登錄 (用於測試，實際開發時請移除)
    func simulateLogin(request: LoginRequest) -> AnyPublisher<AuthResponse, Error> {
        return Just(())
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .tryMap { _ in
                // 模擬登錄驗證
                if request.email == "test@mindecho.com" && request.password == "123456" {
                    let user = User(
                        id: "test_user_id",
                        userId: "test_user_id",
                        email: request.email,
                        firstName: "測試",
                        lastName: "用戶",
                        dateOfBirth: "1990-01-01",
                        gender: "unknown",
                        educationLevel: nil,
                        supportContactName: nil,
                        supportContactInfo: nil,
                        familyContactName: nil,
                        familyContactInfo: nil,
                        isActive: true,
                        preferences: nil,
                        createdAt: nil,
                        updatedAt: nil
                    )
                    
                    return AuthResponse(
                        success: true,
                        message: "登錄成功！",
                        user: user,
                        token: "mock_token_123456",
                        refreshToken: "mock_refresh_token_123456"
                    )
                } else {
                    return AuthResponse(
                        success: false,
                        message: "電子郵件或密碼錯誤",
                        user: nil,
                        token: nil,
                        refreshToken: nil
                    )
                }
            }
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] response in
                if response.success!, let user = response.user, let token = response.token {
                    self?.saveAuth(user: user, token: token, refreshToken: response.refreshToken)
                }
            })
            .eraseToAnyPublisher()
    }
}
