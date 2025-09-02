import SwiftUI

// MARK: - 登錄頁面
struct LoginPage: View {
    
    // MARK: - 環境和狀態
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()
    
    // MARK: - 表單狀態
    @State private var email = ""
    @State private var password = ""
    @State private var showRegisterPage = false
    @State private var showForgotPassword = false
    
    // MARK: - 動畫狀態
    @State private var animateContent = false
    @State private var keyboardHeight: CGFloat = 0
    
    // MARK: - 焦點管理
    @FocusState private var focusedField: FormField?
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // 頂部區域
                        headerSection
                            .frame(height: max(200, geometry.size.height * 0.3 - keyboardHeight * 0.3))
                        
                        // 主要內容區域
                        mainContentSection
                            .frame(minHeight: geometry.size.height * 0.7)
                    }
                }
                .scrollIndicators(.hidden)
                .background(backgroundGradient)
            }
            .navigationBarHidden(true)
            .loadingOverlay(
                isVisible: viewModel.isLoading,
                message: "登錄中...",
                style: .spinner
            )
            .onAppear {
                startAnimation()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.easeOut(duration: 0.3)) {
                        keyboardHeight = keyboardFrame.height
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    keyboardHeight = 0
                }
            }
            .onChange(of: viewModel.authState) { _, state in
                if case .authenticated = state {
                    dismiss()
                }
            }
        }
        .fullScreenCover(isPresented: $showRegisterPage) {
            RegisterPage()
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordPage()
        }
    }
}

// MARK: - 視圖組件
private extension LoginPage {
    
    // 背景漸變
    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                AppColors.lightYellow,
                Color.white
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    // 頂部區域
    var headerSection: some View {
        VStack(spacing: 16) {
            // 關閉按鈕
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(AppColors.mediumBrown.opacity(0.6))
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
            
            // Logo 和標題
            VStack(spacing: 12) {
                // MindEcho Logo
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.orange)
                    
                    Text("MindEcho")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(AppColors.darkBrown)
                }
                .scaleEffect(animateContent ? 1 : 0.8)
                
                Text("歡迎回來")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(AppColors.darkBrown)
                    .opacity(animateContent ? 1 : 0)
                
                Text("登錄您的帳戶繼續使用")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.mediumBrown)
                    .opacity(animateContent ? 0.8 : 0)
            }
            
            Spacer()
        }
    }
    
    // 主要內容區域
    var mainContentSection: some View {
        VStack(spacing: 0) {
            // 登錄表單卡片
            loginFormCard
                .padding(.horizontal, 24)
                .offset(y: animateContent ? 0 : 50)
                .opacity(animateContent ? 1 : 0)
            
            Spacer(minLength: 20)
            
            // 底部區域
            bottomSection
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
        }
    }
    
    // 登錄表單卡片
    var loginFormCard: some View {
        VStack(spacing: 24) {
            // 表單標題
            Text("登錄")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.darkBrown)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 表單字段
            VStack(spacing: 20) {
                // 電子郵件輸入框
                AuthTextField(
                    field: .email,
                    text: $email,
                    isValid: !viewModel.hasError(for: .email),
                    errorMessage: viewModel.getErrorMessage(for: .email),
                    onEditingChanged: { isFocused in
                        if isFocused {
                            focusedField = .email
                        }
                        if !isFocused && !email.isEmpty {
                            viewModel.validateFieldRealTime(field: .email, value: email)
                        }
                    },
                    onCommit: {
                        focusedField = .password
                    }
                )
                .focused($focusedField, equals: .email)
                .onChange(of: email) { _, newValue in
                    viewModel.validateFieldRealTime(field: .email, value: newValue)
                }
                
                // 密碼輸入框
                AuthTextField(
                    field: .password,
                    text: $password,
                    isValid: !viewModel.hasError(for: .password),
                    errorMessage: viewModel.getErrorMessage(for: .password),
                    onEditingChanged: { isFocused in
                        if isFocused {
                            focusedField = .password
                        }
                        if !isFocused && !password.isEmpty {
                            viewModel.validateFieldRealTime(field: .password, value: password)
                        }
                    },
                    onCommit: {
                        if viewModel.isLoginFormValid {
                            performLogin()
                        }
                    }
                )
                .focused($focusedField, equals: .password)
                .onChange(of: password) { _, newValue in
                    viewModel.validateFieldRealTime(field: .password, value: newValue)
                }
            }
            
            // 忘記密碼鏈接
            HStack {
                Spacer()
                Button("忘記密碼？") {
                    showForgotPassword = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.orange)
            }
            
            // 錯誤和成功訊息
            if !viewModel.errorMessage.isEmpty {
                errorMessageView
            }
            
            if !viewModel.successMessage.isEmpty {
                successMessageView
            }
            
            // 登錄按鈕
            LoadingButton(
                title: "登錄",
                isLoading: viewModel.isLoading,
                isDisabled: !viewModel.isLoginFormValid || viewModel.isLoading
            ) {
                performLogin()
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: AppColors.darkBrown.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // 底部區域
    var bottomSection: some View {
        VStack(spacing: 16) {
            // 註冊提示
            HStack(spacing: 4) {
                Text("還沒有帳戶？")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.mediumBrown)
                
                Button("立即註冊") {
                    showRegisterPage = true
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.orange)
            }
            .opacity(animateContent ? 1 : 0)
            
            // 服務條款
            Text("繼續即表示您同意我們的服務條款和隱私政策")
                .font(.system(size: 12))
                .foregroundColor(AppColors.mediumBrown.opacity(0.7))
                .multilineTextAlignment(.center)
                .opacity(animateContent ? 0.7 : 0)
        }
    }
    
    // 錯誤訊息視圖
    var errorMessageView: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(.red)
            
            Text(viewModel.errorMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // 成功訊息視圖
    var successMessageView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.green)
            
            Text(viewModel.successMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.green)
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - 方法
private extension LoginPage {
    
    func startAnimation() {
        withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
            animateContent = true
        }
    }
    
    func performLogin() {
        // 隱藏鍵盤
        focusedField = nil
        
        // 🎯 使用開發模式登錄
        // viewModel.loginDevelopmentMode(email: email, password: password)
        
        // 🚫 真實 API 登錄（暫時不用）
        viewModel.login(email: email, password: password)
    }
}

// MARK: - 忘記密碼頁面
struct ForgotPasswordPage: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @FocusState private var emailFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 頂部區域
                VStack(spacing: 16) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.orange)
                    
                    Text("重置密碼")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.darkBrown)
                    
                    Text("輸入您的電子郵件地址，我們將發送重置密碼的連結給您")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.mediumBrown)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 40)
                
                // 表單區域
                VStack(spacing: 20) {
                    AuthTextField(
                        field: .email,
                        text: $email,
                        isValid: !viewModel.hasError(for: .email),
                        errorMessage: viewModel.getErrorMessage(for: .email)
                    )
                    .focused($emailFocused)
                    .onChange(of: email) { _, newValue in
                        viewModel.validateFieldRealTime(field: .email, value: newValue)
                    }
                    
                    // 錯誤和成功訊息
                    if !viewModel.errorMessage.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(viewModel.errorMessage)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .font(.system(size: 14, weight: .medium))
                    }
                    
                    if !viewModel.successMessage.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(viewModel.successMessage)
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .font(.system(size: 14, weight: .medium))
                    }
                    
                    LoadingButton(
                        title: "發送重置連結",
                        isLoading: viewModel.isLoading,
                        isDisabled: email.isEmpty || viewModel.hasError(for: .email)
                    ) {
                        viewModel.resetPassword(email: email)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // 返回登錄
                Button("返回登錄") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.orange)
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.lightYellow, Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.orange)
                }
            }
        }
    }
}

// MARK: - 預覽
struct LoginPage_Previews: PreviewProvider {
    static var previews: some View {
        LoginPage()
            .previewDisplayName("登錄頁面")
        
        ForgotPasswordPage()
            .previewDisplayName("忘記密碼頁面")
    }
}
