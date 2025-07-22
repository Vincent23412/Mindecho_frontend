import Foundation
import Combine

// MARK: - 認證服務類
class AuthService: ObservableObject {
    
    // MARK: - 單例模式
    static let shared = AuthService()
    
    // MARK: - Published 屬性 (用於 SwiftUI 自動更新 UI)
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var authToken: String?
    
    // MARK: - 私有屬性
    private let baseURL = AppEnvironment.current.apiBaseURL
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UserDefaults 鍵值
    private enum Keys {
        static let authToken = AuthConstants.UserDefaultsKeys.authToken
        static let refreshToken = AuthConstants.UserDefaultsKeys.refreshToken
        static let userData = AuthConstants.UserDefaultsKeys.userData
    }
    
    private init() {
        // 配置 URLSession
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AuthConstants.Network.requestTimeout
        config.timeoutIntervalForResource = AuthConstants.Network.requestTimeout * 2
        self.session = URLSession(configuration: config)
        
        loadStoredAuth()
    }
    
    // MARK: - 載入本地存儲的認證資訊
    private func loadStoredAuth() {
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
        
        DispatchQueue.main.async {
            self.authToken = token
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    // MARK: - 清除認證資訊
    private func clearAuth() {
        UserDefaults.standard.removeObject(forKey: Keys.authToken)
        UserDefaults.standard.removeObject(forKey: Keys.refreshToken)
        UserDefaults.standard.removeObject(forKey: Keys.userData)
        
        DispatchQueue.main.async {
            self.authToken = nil
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    // MARK: - 註冊功能
    func register(request: RegisterRequest) -> AnyPublisher<AuthResponse, Error> {
        guard let url = URL(string: "\(baseURL)\(AuthConstants.API.register)") else {
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
        guard let url = URL(string: "\(baseURL)\(AuthConstants.API.login)") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: urlRequest)
            .map(\.data)
            .decode(type: AuthResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] response in
                if response.success!,
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
            .map(\.data)
            .decode(type: AuthResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] response in
                if response.success!,
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
                    email: request.email,
                    firstName: request.firstName,
                    lastName: request.lastName,
                    dateOfBirth: request.dateOfBirth,
                    createdAt: Date(),
                    updatedAt: Date()
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
                        email: request.email,
                        firstName: "測試",
                        lastName: "用戶",
                        dateOfBirth: "1990-01-01",
                        createdAt: Date(),
                        updatedAt: Date()
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
