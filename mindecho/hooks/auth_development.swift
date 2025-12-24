import Foundation
import SwiftUI

// MARK: - 開發模式擴展
extension AuthViewModel {
    
    // MARK: - 開發模式登錄（跳過 API）
    func loginDevelopmentMode(email: String, password: String) {
        // 驗證表單
        let validationErrors = Validation.validateLoginForm(email: email, password: password)
        
        if !validationErrors.isEmpty {
            errorMessage = validationErrors.first?.localizedDescription ?? "表單驗證失敗"
            return
        }
        
        // 開始載入狀態
        isLoading = true
        authState = .loading
        
        // 🎯 開發模式：直接模擬成功
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            
            // 直接設定為已認證
            AuthService.shared.isAuthenticated = true
            self.updateDailyCheckInVisibility()
            
            self.successMessage = "登錄成功！（開發模式）"
            self.errorMessage = ""
            self.authState = .authenticated
        }
    }
    
    // MARK: - 開發模式註冊（跳過 API）
    func registerDevelopmentMode(
        email: String,
        password: String,
        confirmPassword: String,
        firstName: String,
        lastName: String,
        dateOfBirth: String,
        gender: String,
        educationLevel: Int,
        supportContactName: String,
        supportContactInfo: String,
        familyContactName: String,
        familyContactInfo: String
    ) {
        // 驗證表單
        let validationErrors = Validation.validateRegistrationForm(
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth,
            gender: gender,
            educationLevel: educationLevel,
            supportContactName: supportContactName,
            supportContactInfo: supportContactInfo,
            familyContactName: familyContactName,
            familyContactInfo: familyContactInfo
        )
        
        if !validationErrors.isEmpty {
            errorMessage = validationErrors.first?.localizedDescription ?? "表單驗證失敗"
            return
        }
        
        // 開始載入狀態
        isLoading = true
        authState = .loading
        
        // 🎯 開發模式：直接模擬成功
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            
            // 直接設定為已認證
            AuthService.shared.isAuthenticated = true
            self.updateDailyCheckInVisibility()
            
            self.successMessage = "註冊成功！歡迎加入 MindEcho！（開發模式）"
            self.errorMessage = ""
            self.authState = .authenticated
        }
    }
}
