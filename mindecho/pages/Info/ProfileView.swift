import SwiftUI

struct ProfileView: View {
    @State private var showingSupportReasons = false
    @State private var showingPersonalInfo = false
    @ObservedObject private var authService = AuthService.shared
    
    private let supportReasons: [SupportReason] = [
        SupportReason(
            title: "我的家人",
            detail: "媽媽的笑容、爸爸的擁抱，他們需要我，我也需要他們。",
            date: "2023/06/15",
            isFavorite: true
        ),
        SupportReason(
            title: "未完成的夢想",
            detail: "我還沒去過的地方，沒嘗試過的美食，沒完成的計畫。",
            date: "2023/05/20",
            isFavorite: false
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - 使用者卡片
                userInfoCard
                NavigationLink(
                    destination: PersonalInfoView(user: authService.currentUser),
                    isActive: $showingPersonalInfo
                ) {
                    EmptyView()
                }
                .hidden()
                
                // MARK: - 情緒行李箱
                emotionBoxSection
                
                // MARK: - 緊急聯繫
                emergencySection
                
                Spacer()
            }
            .padding(.horizontal) // 全部統一左右內距
            .padding(.vertical, 16)
            .sheet(isPresented: $showingSupportReasons) {
                SupportReasonsModal(reasons: supportReasons) {
                    showingSupportReasons = false
                }
            }
        }
        .background(Color.yellow.opacity(0.1).ignoresSafeArea())
        .navigationTitle("個人檔案")
        .task {
            await refreshUserProfile()
        }
    }
}

// MARK: - 編輯個人資訊頁
struct EditPersonalInfoView: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var email: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthDate: Date = Date(timeIntervalSince1970: 1036003200) // 2002-10-30
    @State private var errorMessage: String?
    @State private var isSaving = false
    
    var body: some View {
        Form {
            Section(header: Text("基本資料")) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("名", text: $firstName)
                TextField("姓", text: $lastName)
                DatePicker("生日", selection: $birthDate, displayedComponents: .date)
            }
            
            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                }
            }
            
            Section {
                Button {
                    Task { await saveProfile() }
                } label: {
                    HStack {
                        Spacer()
                        Text(isSaving ? "保存中..." : "保存變更")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(isSaving)
            }
        }
        .navigationTitle("編輯個人資訊")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            hydrateUser()
        }
    }
    
    private func hydrateUser() {
        guard let user = authService.currentUser else { return }
        email = user.email
        firstName = user.firstName
        lastName = user.lastName
        if let date = parseBirthDate(user.dateOfBirth) {
            birthDate = date
        }
    }
    
    private func parseBirthDate(_ value: String?) -> Date? {
        guard let value = value, !value.isEmpty else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: value) ?? ISO8601DateFormatter().date(from: value) {
            return date
        }
        let fallback = DateFormatter()
        fallback.dateFormat = "yyyy-MM-dd"
        return fallback.date(from: value)
    }
    
    private func saveProfile() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        
        do {
            guard let userId = authService.currentUser?.primaryId, !userId.isEmpty else {
                await MainActor.run {
                    errorMessage = "找不到使用者資訊"
                }
                return
            }
            let user = try await APIService.shared.updateUserProfile(
                userId: userId,
                email: email,
                firstName: firstName,
                lastName: lastName
            )
            await MainActor.run {
                authService.updateProfile(user)
            }
        } catch {
            await MainActor.run {
                errorMessage = "更新失敗，請重試"
            }
        }
    }
}

// MARK: - 支撐我的片刻 Modal
private struct SupportReasonsModal: View {
    let reasons: [SupportReason]
    let onClose: () -> Void
    
    @State private var reminder: ReminderTime = .morning
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    
                    reasonsSection
                    
                    reminderSection
                }
                .padding(20)
                .background(AppColors.lightYellow.ignoresSafeArea())
            }
            .navigationBarHidden(true)
        }
    }
    
    private var header: some View {
        HStack {
            Text("支撐我的片刻")
                .font(.title2.weight(.bold))
                .foregroundColor(AppColors.titleColor)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.titleColor)
                    .padding(10)
                    .background(AppColors.orange.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.bottom, 4)
    }
    
    private var reasonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("我的理由珍藏")
                        .font(.headline)
                        .foregroundColor(AppColors.titleColor)
                    Text("這些是值得你繼續前行的理由")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("新增理由")
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColors.orange.opacity(0.2))
                    .foregroundColor(AppColors.titleColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            VStack(spacing: 12) {
                ForEach(reasons) { reason in
                    ReasonCard(reason: reason)
                }
            }
        }
    }
    
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("設定提醒")
                .font(.headline)
                .foregroundColor(AppColors.titleColor)
            Text("選擇何時收到你收藏的理由提醒：")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 10) {
                ForEach(ReminderTime.allCases) { time in
                    Button(action: { reminder = time }) {
                        Text(time.label)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(width: 92)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(reminder == time ? AppColors.orange.opacity(0.8) : Color.white)
                            )
                            .foregroundColor(reminder == time ? .white : AppColors.titleColor)
                            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct ReasonCard: View {
    let reason: SupportReason
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(reason.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppColors.titleColor)
                Spacer()
                HStack(spacing: 12) {
                    Image(systemName: reason.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(AppColors.orange)
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(AppColors.titleColor.opacity(0.7))
                }
            }
            
            Text(reason.detail)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(2)
            
            HStack {
                Text(reason.date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 12) {
                    Image(systemName: "square.and.pencil")
                    Image(systemName: "trash")
                }
                .foregroundColor(AppColors.titleColor.opacity(0.8))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.orange.opacity(0.12))
        )
    }
}

private struct SupportReason: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let date: String
    let isFavorite: Bool
}

private enum ReminderTime: String, CaseIterable, Identifiable {
    case morning, noon, night, custom
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .morning: return "每天早上"
        case .noon: return "每天中午"
        case .night: return "睡前"
        case .custom: return "自訂"
        }
    }
}

// MARK: - 安心收藏箱 Modal
private struct SafeCollectionModal: View {
    let photos: [PhotoItem]
    let videos: [VideoItem]
    let audios: [AudioItem]
    let onClose: () -> Void
    
    @State private var activeTab: CollectionTab = .photo
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                header
                tabBar
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        addButton
                        content
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
                .background(AppColors.lightYellow.ignoresSafeArea())
            }
            .navigationBarHidden(true)
        }
    }
    
    private var header: some View {
        HStack {
            Text("安心收藏箱")
                .font(.title2.weight(.bold))
                .foregroundColor(AppColors.titleColor)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.titleColor)
                    .padding(10)
                    .background(AppColors.orange.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [AppColors.orange.opacity(0.9), AppColors.orange.opacity(0.75)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .overlay(Color.white.opacity(0.05))
        )
    }
    
    private var tabBar: some View {
        HStack(spacing: 24) {
            ForEach(CollectionTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut) {
                        activeTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(activeTab == tab ? AppColors.titleColor : .secondary)
                        Rectangle()
                            .fill(activeTab == tab ? AppColors.titleColor : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
    }
    
    private var addButton: some View {
        HStack {
            Spacer()
            Button(action: {}) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text(activeTab.addTitle)
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.orange.opacity(0.2))
                .foregroundColor(AppColors.titleColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch activeTab {
        case .photo:
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(photos) { item in
                    PhotoCard(item: item)
                }
                ForEach(0..<2, id: \.self) { _ in
                    Rectangle()
                        .fill(AppColors.orange.opacity(0.12))
                        .frame(height: 160)
                        .cornerRadius(10)
                }
            }
        case .video:
            VStack(spacing: 14) {
                ForEach(videos) { item in
                    VideoCard(item: item)
                }
                ForEach(0..<1, id: \.self) { _ in
                    Rectangle()
                        .fill(AppColors.orange.opacity(0.12))
                        .frame(height: 160)
                        .cornerRadius(10)
                }
            }
        case .audio:
            VStack(spacing: 14) {
                ForEach(audios) { item in
                    AudioRow(item: item)
                }
            }
        }
    }
}

private enum CollectionTab: String, CaseIterable, Identifiable {
    case photo, video, audio
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .photo: return "照片"
        case .video: return "影片"
        case .audio: return "語音"
        }
    }
    
    var addTitle: String {
        switch self {
        case .photo: return "新增照片"
        case .video: return "新增影片"
        case .audio: return "新增語音"
        }
    }
}

private struct PhotoItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
}

private struct VideoItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
}

private struct AudioItem: Identifiable {
    let id = UUID()
    let title: String
    let duration: String
}

// MARK: - 收藏卡片
private struct PhotoCard: View {
    let item: PhotoItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(AppColors.orange.opacity(0.15))
                .frame(height: 140)
                .cornerRadius(10)
            
            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppColors.titleColor)
            Text(item.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: "trash")
                Image(systemName: "square.and.pencil")
            }
            .foregroundColor(AppColors.titleColor.opacity(0.7))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

private struct VideoCard: View {
    let item: VideoItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle()
                .fill(AppColors.orange.opacity(0.15))
                .frame(height: 140)
                .cornerRadius(10)
            
            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppColors.titleColor)
            Text(item.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: "trash")
                Image(systemName: "square.and.pencil")
            }
            .foregroundColor(AppColors.titleColor.opacity(0.7))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

private struct AudioRow: View {
    let item: AudioItem
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {}) {
                Image(systemName: "play.fill")
                    .foregroundColor(AppColors.orange)
                    .padding(10)
                    .background(AppColors.orange.opacity(0.15))
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppColors.titleColor)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColors.orange.opacity(0.15))
                            .frame(height: 8)
                        Capsule()
                            .fill(AppColors.orange)
                            .frame(width: geo.size.width * 0.7, height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            Text(item.duration)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Image(systemName: "trash")
                .foregroundColor(AppColors.titleColor.opacity(0.7))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
    }
}

// MARK: - 各區塊拆分為 Computed Property，結構更乾淨
extension ProfileView {
    
    // 使用者卡片
    private var userInfoCard: some View {
        let displayName = authService.currentUser?.firstName.isEmpty == false
            ? authService.currentUser?.firstName ?? "使用者"
            : "使用者"
        let initials = authService.currentUser?.initials.isEmpty == false
            ? authService.currentUser?.initials ?? "ME"
            : "ME"

        return HStack(spacing: 16) {
            Button {
                showingPersonalInfo = true
            } label: {
                Circle()
                    .fill(Color.orange.opacity(0.8))
                    .frame(width: 80, height: 80)
                    .overlay(
                        VStack(spacing: 2) {
                            Text(initials)
                                .font(.title3.bold())
                            Text("個人資訊")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.18))
                                .cornerRadius(6)
                        }
                        .foregroundColor(.white)
                    )
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(displayName)
                    .font(.headline)
                    .foregroundColor(AppColors.titleColor)
                Text("這是一個屬於你的安全空間，在這裡可以整理情緒、收集力量、找到希望。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
            }
        }
        .padding()
        .background(cardBackground)
    }
    
    
    // 情緒行李箱
    private var emotionBoxSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("情緒行李箱")
                .font(.headline)
                .foregroundColor(.brown)
                .padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                EmotionBoxCard(
                    title: "支撐我的片刻",
                    description: "記下那些讓你有動力繼續向前的理由。",
                    buttonTitle: "查看我的理由",
                    color: .orange,
                    onButtonTap: {
                        showingSupportReasons = true
                    }
                )
//                    EmotionBoxCard(
//                        title: "療癒語錄牆",
//                        description: "收集那些曾經撫慰你的話語與詩句。",
//                        buttonTitle: "前往查看",
//                        color: .orange
//                    )
//                    EmotionBoxCard(
//                        title: "心情樹洞",
//                        description: "寫下你的心事，讓自己慢慢釋放。",
//                        buttonTitle: "打開樹洞",
//                        color: .orange
//                    )
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 8)

    }
    
    
    // 緊急聯繫
    private var emergencySection: some View {
        let supportName = authService.currentUser?.supportContactName?.isEmpty == false
            ? authService.currentUser?.supportContactName ?? "支持者"
            : "支持者"
        let supportInfo = authService.currentUser?.supportContactInfo?.isEmpty == false
            ? authService.currentUser?.supportContactInfo ?? "無資料"
            : "無資料"
        let familyName = authService.currentUser?.familyContactName?.isEmpty == false
            ? authService.currentUser?.familyContactName ?? "家人"
            : "家人"
        let familyInfo = authService.currentUser?.familyContactInfo?.isEmpty == false
            ? authService.currentUser?.familyContactInfo ?? "無資料"
            : "無資料"

        return VStack(alignment: .leading, spacing: 16) {
            Text("緊急聯繫")
                .font(.headline)
                .foregroundColor(.brown)
            
            HStack(spacing: 12) {
                EmergencyContactCard(
                    title: "24小時救援專線",
                    subtitle: "1925（依愛我）",
                    buttonText: "立即撥打"
                )
                EmergencyContactCard(
                    title: "我的支持者",
                    subtitle: "\(supportName)：\(supportInfo)",
                    buttonText: "立即撥打"
                )
            }
            
            EmergencyContactCard(
                title: "我的家人",
                subtitle: "\(familyName)：\(familyInfo)",
                    buttonText: "立即撥打"
                )
        }
        .padding()
        .background(cardBackground)
    }
    
    
    // MARK: - 共用卡片背景樣式
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
            .shadow(color: .gray.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

extension ProfileView {
    private func refreshUserProfile() async {
        guard authService.authToken != nil else {
            return
        }
        
        do {
            let user = try await APIService.shared.getUserProfile()
            await MainActor.run {
                authService.updateProfile(user)
            }
        } catch {
            print("Profile: failed to fetch profile: \(error)")
        }
    }
}


#Preview {
    NavigationView {
        ProfileView()
    }
}

// MARK: - 個人資訊頁
struct PersonalInfoView: View {
    let user: User?

    var body: some View {
        let initials = user?.initials.isEmpty == false ? user?.initials ?? "ME" : "ME"
        let fullName = user?.fullName.isEmpty == false ? user?.fullName ?? "使用者" : "使用者"
        let email = user?.email.isEmpty == false ? user?.email ?? "-" : "-"
        let birthday = formatBirthDate(user?.dateOfBirth)

        ScrollView {
            VStack(spacing: 20) {
                // 頂部頭像與基本資料
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.orange.opacity(0.85))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Text(initials)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        )
                    
                    Text(fullName)
                        .font(.title3.bold())
                        .foregroundColor(AppColors.titleColor)
                    Text("安全空間中的個人資訊，僅供自己查看與整理")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // 詳細欄位
                VStack(spacing: 12) {
                    infoRow(icon: "envelope.fill", title: "Email", value: email)
                    infoRow(icon: "person.text.rectangle", title: "姓名", value: fullName)
                    infoRow(icon: "calendar", title: "生日", value: birthday)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                )
                .padding(.horizontal, 16)
                
                // 按鈕區
                VStack(spacing: 12) {
                    NavigationLink {
                        EditPersonalInfoView()
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("編輯個人資訊")
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.orange)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                
                Spacer(minLength: 20)
            }
            .padding(.bottom, 24)
            .background(AppColors.lightYellow.ignoresSafeArea())
        }
        .navigationTitle("個人資訊")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.orange.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .foregroundColor(AppColors.orange)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppColors.titleColor)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }

    private func formatBirthDate(_ value: String?) -> String {
        guard let value = value, !value.isEmpty else {
            return "-"
        }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: value) ?? ISO8601DateFormatter().date(from: value) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
        return value
    }
}
