import Foundation
import SwiftUI

// MARK: - 用戶數據模型
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let dateOfBirth: String?     // 改為可選，因為後端可能不回傳
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
            case id = "userId"
            case email
            case firstName
            case lastName
            case dateOfBirth
            case createdAt
            case updatedAt
        }

    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    var initials: String {
        let firstInitial = firstName.first?.uppercased() ?? ""
        let lastInitial = lastName.first?.uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
}

// MARK: - 註冊請求數據模型
struct RegisterRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let dateOfBirth: String
    
    func toDictionary() -> [String: Any] {
        return [
            "email": email,
            "password": password,
            "firstName": firstName,
            "lastName": lastName,
            "dateOfBirth": dateOfBirth
        ]
    }
}

// MARK: - 登錄請求數據模型
struct LoginRequest: Codable {
    let email: String
    let password: String
    
    func toDictionary() -> [String: Any] {
        return [
            "email": email,
            "password": password
        ]
    }
}

// MARK: - 認證回應數據模型
struct AuthResponse: Codable {
    let success: Bool?
    let message: String?
    let user: User?
    let token: String?
    let refreshToken: String?
    
    // 自訂初始化方法，處理後端回應格式
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        self.user = try container.decodeIfPresent(User.self, forKey: .user)
        self.token = try container.decodeIfPresent(String.self, forKey: .token)
        self.refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        
        // 如果後端沒有 success 字段，根據其他條件判斷
        if let success = try container.decodeIfPresent(Bool.self, forKey: .success) {
            self.success = success
        } else {
            // 如果有 user 或 token 就認為成功，否則根據 message 判斷
            if self.user != nil || self.token != nil {
                self.success = true
            } else if let message = self.message, message.lowercased().contains("success") {
                self.success = true
            } else {
                self.success = false
            }
        }
    }
    
    // 保留原始的初始化方法（用於手動創建）
    init(success: Bool?, message: String?, user: User?, token: String?, refreshToken: String?) {
        self.success = success
        self.message = message
        self.user = user
        self.token = token
        self.refreshToken = refreshToken
    }
    
    enum CodingKeys: String, CodingKey {
        case success, message, user, token, refreshToken
    }
}

// MARK: - 表單驗證錯誤類型
enum ValidationError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emptyFirstName
    case emptyLastName
    case invalidDateOfBirth
    case passwordMismatch
    case emptyField(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "請輸入有效的電子郵件地址"
        case .weakPassword:
            return "密碼至少需要6個字符"
        case .emptyFirstName:
            return "請輸入名字"
        case .emptyLastName:
            return "請輸入姓氏"
        case .invalidDateOfBirth:
            return "請選擇有效的出生日期"
        case .passwordMismatch:
            return "密碼不一致"
        case .emptyField(let fieldName):
            return "\(fieldName)不能為空"
        }
    }
}

// MARK: - 認證狀態枚舉
enum AuthState: Equatable {
    case idle           // 初始狀態
    case loading        // 載入中
    case authenticated  // 已認證
    case unauthenticated // 未認證
    case error(String)  // 錯誤狀態
    
    // 實現 Equatable 協議
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.authenticated, .authenticated), (.unauthenticated, .unauthenticated):
            return true
        case let (.error(lhsMessage), .error(rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

// MARK: - 表單字段類型
enum FormField: CaseIterable {
    case email
    case password
    case confirmPassword
    case firstName
    case lastName
    case dateOfBirth
    
    var placeholder: String {
        switch self {
        case .email:
            return "電子郵件"
        case .password:
            return "密碼"
        case .confirmPassword:
            return "確認密碼"
        case .firstName:
            return "名字"
        case .lastName:
            return "姓氏"
        case .dateOfBirth:
            return "出生日期"
        }
    }
    
    var keyboardType: UIKeyboardType {
        switch self {
        case .email:
            return .emailAddress
        case .password, .confirmPassword:
            return .default
        case .firstName, .lastName:
            return .namePhonePad
        case .dateOfBirth:
            return .numbersAndPunctuation
        }
    }
    
    var isSecure: Bool {
        switch self {
        case .password, .confirmPassword:
            return true
        default:
            return false
        }
    }
}
