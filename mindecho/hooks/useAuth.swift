import Foundation
import SwiftUI
import Combine

// MARK: - 認證視圖模型
class AuthViewModel: ObservableObject {
    
    // MARK: - Published 屬性 (自動觸發 UI 更新)
    @Published var authState: AuthState = .idle
    @Published var errorMessage: String = ""
    @Published var successMessage: String = ""
    @Published var isLoading: Bool = false
    
    // MARK: - 表單驗證器
    @Published var formValidator = FormValidator()
    
    // MARK: - 依賴注入
    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    init(authService: AuthService = AuthService.shared) {
        self.authService = authService
        setupBindings()
    }
    
    // MARK: - 設置數據綁定
    private func setupBindings() {
        // 監聽認證服務的狀態變化
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.authState = .authenticated
                } else {
                    self?.authState = .unauthenticated
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 註冊功能
    func register(
        email: String,
        password: String,
        confirmPassword: String,
        firstName: String,
        lastName: String,
        dateOfBirth: String
    ) {
        // 清除之前的訊息
        clearMessages()
        
        // 驗證表單
        let validationErrors = Validation.validateRegistrationForm(
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth
        )
        
        if !validationErrors.isEmpty {
            showError(validationErrors.first?.localizedDescription ?? "表單驗證失敗")
            return
        }
        
        // 開始載入狀態
        setLoading(true)
        
        // 建立註冊請求
        let request = RegisterRequest(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password,
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            dateOfBirth: dateOfBirth
        )
        
        // 發送註冊請求 (使用模擬 API) 真實改成Register
        authService.register(request: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.setLoading(false)
                    
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.showError("註冊失敗: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success == true {
                        self?.showSuccess(response.message ?? "註冊成功！歡迎加入 MindEcho！")
                        self?.authState = .authenticated
                    } else {
                        self?.showError(response.message ?? "註冊失敗，請重試")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - 登錄功能
    func login(email: String, password: String) {
        // 清除之前的訊息
        clearMessages()
        
        // 驗證表單
        let validationErrors = Validation.validateLoginForm(email: email, password: password)
        
        if !validationErrors.isEmpty {
            showError(validationErrors.first?.localizedDescription ?? "表單驗證失敗")
            return
        }
        
        // 開始載入狀態
        setLoading(true)
        
        // 建立登錄請求
        let request = LoginRequest(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
        
        // 發送登錄請求 (使用真實 API)
        authService.login(request: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.setLoading(false)
                    
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.showError("登錄失敗: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success == true {
                        self?.showSuccess(response.message ?? "登錄成功！")
                        self?.authState = .authenticated
                    } else {
                        self?.showError(response.message ?? "電子郵件或密碼錯誤")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - 登出功能
    func logout() {
        authService.logout()
        authState = .unauthenticated
        clearMessages()
    }
    
    // MARK: - 重置密碼功能
    func resetPassword(email: String) {
        clearMessages()
        
        if !Validation.isValidEmail(email) {
            showError("請輸入有效的電子郵件地址")
            return
        }
        
        setLoading(true)
        
        // 模擬重置密碼請求
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.setLoading(false)
            self.showSuccess("密碼重置連結已發送到您的電子郵件")
        }
    }
    
    // MARK: - 輔助方法
    private func setLoading(_ loading: Bool) {
        isLoading = loading
        if loading {
            authState = .loading
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        successMessage = ""
        authState = .error(message)
        
        // 3秒後自動清除錯誤訊息
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.errorMessage == message {
                self.clearMessages()
            }
        }
    }
    
    private func showSuccess(_ message: String) {
        successMessage = message
        errorMessage = ""
        
        // 3秒後自動清除成功訊息
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.successMessage == message {
                self.clearMessages()
            }
        }
    }
    
    private func clearMessages() {
        errorMessage = ""
        successMessage = ""
        if case .loading = authState {
            authState = .idle
        }
    }
    
    // MARK: - 實時表單驗證
    func validateFieldRealTime(field: FormField, value: String) {
        switch field {
        case .email:
            formValidator.emailState.text = value
            formValidator.validateEmail()
        case .password:
            formValidator.passwordState.text = value
            formValidator.validatePassword()
            // 如果確認密碼已經輸入，也要重新驗證
            if !formValidator.confirmPasswordState.text.isEmpty {
                formValidator.validateConfirmPassword()
            }
        case .confirmPassword:
            formValidator.confirmPasswordState.text = value
            formValidator.validateConfirmPassword()
        case .firstName:
            formValidator.firstNameState.text = value
            formValidator.validateFirstName()
        case .lastName:
            formValidator.lastNameState.text = value
            formValidator.validateLastName()
        case .dateOfBirth:
            formValidator.dateOfBirthState.text = value
            formValidator.validateDateOfBirth()
        }
    }
    
    // MARK: - 獲取當前用戶
    var currentUser: User? {
        return authService.currentUser
    }
    
    // MARK: - 檢查是否已認證
    var isAuthenticated: Bool {
        return authService.isAuthenticated
    }
    
    // MARK: - 檢查表單是否有效
    var isRegistrationFormValid: Bool {
        return formValidator.isRegistrationFormValid
    }
    
    var isLoginFormValid: Bool {
        return formValidator.isLoginFormValid
    }
}

// MARK: - 視圖模型擴展 - 便利方法
extension AuthViewModel {
    
    // 獲取密碼強度
    func getPasswordStrength(_ password: String) -> PasswordStrength {
        return Validation.passwordStrength(password)
    }
    
    // 格式化出生日期
    func formatDateOfBirth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // 檢查字段是否有錯誤
    func hasError(for field: FormField) -> Bool {
        switch field {
        case .email:
            return !formValidator.emailState.isValid && !formValidator.emailState.text.isEmpty
        case .password:
            return !formValidator.passwordState.isValid && !formValidator.passwordState.text.isEmpty
        case .confirmPassword:
            return !formValidator.confirmPasswordState.isValid && !formValidator.confirmPasswordState.text.isEmpty
        case .firstName:
            return !formValidator.firstNameState.isValid && !formValidator.firstNameState.text.isEmpty
        case .lastName:
            return !formValidator.lastNameState.isValid && !formValidator.lastNameState.text.isEmpty
        case .dateOfBirth:
            return !formValidator.dateOfBirthState.isValid && !formValidator.dateOfBirthState.text.isEmpty
        }
    }
    
    // 獲取字段錯誤訊息
    func getErrorMessage(for field: FormField) -> String {
        switch field {
        case .email:
            return formValidator.emailState.errorMessage
        case .password:
            return formValidator.passwordState.errorMessage
        case .confirmPassword:
            return formValidator.confirmPasswordState.errorMessage
        case .firstName:
            return formValidator.firstNameState.errorMessage
        case .lastName:
            return formValidator.lastNameState.errorMessage
        case .dateOfBirth:
            return formValidator.dateOfBirthState.errorMessage
        }
    }
}
