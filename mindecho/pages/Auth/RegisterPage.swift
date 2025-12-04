import SwiftUI

// MARK: - 註冊頁面
struct RegisterPage: View {

    // MARK: - 環境和狀態
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()
    @StateObject private var validator = FormValidator()

    // MARK: - 表單狀態
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dateOfBirth = ""
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var showLoginPage = false
    @State private var agreeToTerms = false

    // MARK: - 動畫和UI狀態
    @State private var animateContent = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var currentStep = 0 // 0: 基本信息, 1: 個人信息

    // MARK: - 焦點管理
    @FocusState private var focusedField: FormField?

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // 頂部區域
                        headerSection
                            .frame(height: max(150, geometry.size.height * 0.25 - keyboardHeight * 0.2))

                        // 主要內容區域
                        mainContentSection
                            .frame(minHeight: geometry.size.height * 0.75)

                       
                    }
                }
                .scrollIndicators(.hidden)
                .background(backgroundGradient)
            }
            .navigationBarHidden(true)
            .loadingOverlay(
                isVisible: viewModel.isLoading,
                message: "註冊中...",
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
        .fullScreenCover(isPresented: $showLoginPage) {
            LoginPage()
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                selectedDate: $selectedDate,
                dateOfBirth: $dateOfBirth,
                isPresented: $showDatePicker
            )
        }
    }

    // MARK: - 底部區域
    var bottomSection: some View {
        VStack(spacing: 16) {
            // 登錄提示
            HStack(spacing: 4) {
                Text("已經有帳戶了？")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.mediumBrown)

                Button("立即登錄") {
                    showLoginPage = true
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.orange)
            }
            .opacity(animateContent ? 1 : 0)
        }
    }
}

// MARK: - 視圖組件
private extension RegisterPage {
    
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
            // 關閉按鈕和進度條
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(AppColors.mediumBrown.opacity(0.6))
                }
                
                Spacer()
                
                // 步驟進度條
                progressIndicator
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
            
            // Logo 和標題
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.orange)
                    
                    Text("MindEcho")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.darkBrown)
                }
                .scaleEffect(animateContent ? 1 : 0.8)
                
                Text(currentStep == 0 ? "創建您的帳戶" : "完善個人信息")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.darkBrown)
                    .opacity(animateContent ? 1 : 0)
            }
            
            Spacer()
        }
    }
    
    // 進度指示器
    var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<2, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .frame(width: 30, height: 4)
                    .foregroundColor(
                        index <= currentStep ? AppColors.orange : AppColors.lightBrown.opacity(0.3)
                    )
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
    
    // 主要內容區域
    var mainContentSection: some View {
        VStack(spacing: 0) {
            // 註冊表單卡片
            registerFormCard
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
    
    // 註冊表單卡片
    var registerFormCard: some View {
        VStack(spacing: 24) {
            // 表單內容
            if currentStep == 0 {
                basicInfoForm
            } else {
                personalInfoForm
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: AppColors.darkBrown.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // 基本信息表單 (步驟 1)
    var basicInfoForm: some View {
        VStack(spacing: 24) {
            // 表單標題
            Text("基本信息")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.darkBrown)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 表單字段
            VStack(spacing: 20) {
                // 電子郵件
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
                
                // 密碼
                AuthTextField(
                    field: .password,
                    text: $password,
                    isValid: !viewModel.hasError(for: .password) && password.count > 1,
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
                        focusedField = .confirmPassword
                    }
                )
                .focused($focusedField, equals: .password)
                .onChange(of: password) { _, newValue in
                    viewModel.validateFieldRealTime(field: .password, value: newValue)
                }
                
                // 確認密碼
                AuthTextField(
                    field: .confirmPassword,
                    text: $confirmPassword,
                    isValid: confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines) == password.trimmingCharacters(in: .whitespacesAndNewlines),
                    errorMessage: viewModel.formValidator.confirmPasswordState.errorMessage,
                    onEditingChanged: { isFocused in
                        if isFocused {
                            focusedField = .confirmPassword
                        }
                        if !isFocused && !confirmPassword.isEmpty {
                            viewModel.validateFieldRealTime(field: .confirmPassword, value: confirmPassword)
                        }
                    },
                    onCommit: {
                        if isBasicInfoValid {
                            nextStep()
                        }
                    }
                )
                .focused($focusedField, equals: .confirmPassword)
                .onChange(of: confirmPassword) { _, newValue in
                    viewModel.validateFieldRealTime(field: .confirmPassword, value: newValue.trimmingCharacters(in: .whitespacesAndNewlines))
                }

                
            }
            
            // 錯誤和成功訊息
            if !viewModel.successMessage.isEmpty {
                successMessageView
            }
            
            if !viewModel.errorMessage.isEmpty {
                errorMessageView
            }
            
           
            
            // 下一步按鈕
            AuthButton.primary(
                title: "下一步",
                size: .large,
                isDisabled: !isBasicInfoValid
            ) {
                nextStep()
            }
        }
    }
    
    // 個人信息表單 (步驟 2)
    var personalInfoForm: some View {
        VStack(spacing: 24) {
            // 表單標題
            Text("個人信息")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.darkBrown)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 表單字段
            VStack(spacing: 20) {
                // 名字
                AuthTextField(
                    field: .firstName,
                    text: $firstName,
                    isValid: !viewModel.hasError(for: .firstName),
                    errorMessage: viewModel.getErrorMessage(for: .firstName),
                    onEditingChanged: { isFocused in
                        if isFocused {
                            focusedField = .firstName
                        }
                        if !isFocused && !firstName.isEmpty {
                            viewModel.validateFieldRealTime(field: .firstName, value: firstName)
                        }
                    },
                    onCommit: {
                        focusedField = .lastName
                    }
                )
                .focused($focusedField, equals: .firstName)
                .onChange(of: firstName) { _, newValue in
                    viewModel.validateFieldRealTime(field: .firstName, value: newValue)
                }
                
                // 姓氏
                AuthTextField(
                    field: .lastName,
                    text: $lastName,
                    isValid: !viewModel.hasError(for: .lastName),
                    errorMessage: viewModel.getErrorMessage(for: .lastName),
                    onEditingChanged: { isFocused in
                        if isFocused {
                            focusedField = .lastName
                        }
                        if !isFocused && !lastName.isEmpty {
                            viewModel.validateFieldRealTime(field: .lastName, value: lastName)
                        }
                    },
                    onCommit: {
                        showDatePicker = true
                    }
                )
                .focused($focusedField, equals: .lastName)
                .onChange(of: lastName) { _, newValue in
                    viewModel.validateFieldRealTime(field: .lastName, value: newValue)
                }
                
                // 出生日期選擇器
                dateOfBirthField
            }
            
            // 服務條款同意
            termsAgreementSection
            
            // 錯誤和成功訊息
            if !viewModel.errorMessage.isEmpty {
                errorMessageView
            }
            
            if !viewModel.successMessage.isEmpty {
                successMessageView
            }
            
            // 按鈕組
            VStack(spacing: 12) {
                // 註冊按鈕
                LoadingButton(
                    title: "創建帳戶",
                    isLoading: viewModel.isLoading,
                    isDisabled: !isPersonalInfoValid || !agreeToTerms
                ) {
                    performRegistration()
                }
                
                // 返回按鈕
                AuthButton.secondary(
                    title: "返回上一步",
                    size: .medium
                ) {
                    previousStep()
                }
            }
        }
    }
    
    // 出生日期字段
    var dateOfBirthField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("出生日期")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.darkBrown)
            
            Button(action: {
                showDatePicker = true
            }) {
                HStack {
                    Text(dateOfBirth.isEmpty ? "選擇出生日期" : dateOfBirth)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(dateOfBirth.isEmpty ? AppColors.mediumBrown.opacity(0.6) : AppColors.darkBrown)
                    
                    Spacer()
                    
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            viewModel.hasError(for: .dateOfBirth) && !dateOfBirth.isEmpty
                                ? Color.red
                                : AppColors.lightBrown.opacity(0.5),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 錯誤訊息
            if viewModel.hasError(for: .dateOfBirth) && !dateOfBirth.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    
                    Text(viewModel.getErrorMessage(for: .dateOfBirth))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                    
                    Spacer()
                }
            }
        }
    }
    
    // 服務條款同意區域
    var termsAgreementSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    agreeToTerms.toggle()
                }
            }) {
                Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(agreeToTerms ? AppColors.orange : AppColors.mediumBrown.opacity(0.6))
                    .scaleEffect(agreeToTerms ? 1.1 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("我同意 MindEcho 的")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.mediumBrown)
                
                HStack(spacing: 4) {
                    Button("服務條款") {
                        // TODO: 顯示服務條款
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.orange)
                    
                    Text("和")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.mediumBrown)
                    
                    Button("隱私政策") {
                        // TODO: 顯示隱私政策
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.orange)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.lightYellow.opacity(0.5))
        )
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

// MARK: - 計算屬性和方法
private extension RegisterPage {
    
    // 基本信息是否有效
    var isBasicInfoValid: Bool {
        let trimmedPass = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !email.isEmpty &&
               !trimmedPass.isEmpty &&
               !trimmedConfirm.isEmpty &&
               Validation.isValidPassword(trimmedPass) &&
               trimmedPass == trimmedConfirm &&
               !viewModel.hasError(for: .email)
    }
    
    // 個人信息是否有效
    var isPersonalInfoValid: Bool {
        return !firstName.isEmpty &&
               !lastName.isEmpty &&
               !dateOfBirth.isEmpty &&
               !viewModel.hasError(for: .firstName) &&
               !viewModel.hasError(for: .lastName) &&
               !viewModel.hasError(for: .dateOfBirth)
    }
    
    func startAnimation() {
        withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
            animateContent = true
        }
    }
    
    func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = 1
        }
        // 清除焦點
        focusedField = nil
    }
    
    func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = 0
        }
    }
    
    func performRegistration() {
        // 隱藏鍵盤
        focusedField = nil
        
        // 🎯 使用開發模式註冊
        /*
        viewModel.registerDevelopmentMode(
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth
        )
         */
        // 🚫 真實 API 註冊
        
        viewModel.register(
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth
        )
        
    }
}

// MARK: - 日期選擇器 Sheet
struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var dateOfBirth: String
    @Binding var isPresented: Bool
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // 計算最小和最大日期
    private var minimumDate: Date {
        Calendar.current.date(byAdding: .year, value: -150, to: Date()) ?? Date()
    }
    
    private var maximumDate: Date {
        Date() // 今天
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("選擇您的出生日期")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.darkBrown)
                    .padding(.top, 20)
                
                DatePicker(
                    "出生日期",
                    selection: $selectedDate,
                    in: minimumDate...maximumDate,
                    displayedComponents: .date
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 確認按鈕
                AuthButton.primary(
                    title: "確認",
                    size: .large
                ) {
                    dateOfBirth = dateFormatter.string(from: selectedDate)
                    isPresented = false
                }
                .padding(.horizontal, 24)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                    .foregroundColor(AppColors.orange)
                }
            }
        }
    }
}

// MARK: - 預覽
struct RegisterPage_Previews: PreviewProvider {
    static var previews: some View {
        RegisterPage()
            .previewDisplayName("註冊頁面")
        
        DatePickerSheet(
            selectedDate: .constant(Date()),
            dateOfBirth: .constant(""),
            isPresented: .constant(true)
        )
        .previewDisplayName("日期選擇器")
    }
}
