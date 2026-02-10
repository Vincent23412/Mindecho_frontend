import SwiftUI
import PhotosUI
import UIKit
import AVKit
import AVFoundation

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
                
                // MARK: - 時光藏寶盒
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
        .background(AppColors.lightYellow.ignoresSafeArea())
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
    @State private var fullName: String = ""
    @State private var birthDate: Date = Date(timeIntervalSince1970: 1036003200) // 2002-10-30
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var showBirthPicker = false
    
    var body: some View {
        Form {
            Section(header: Text("基本資料")) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("姓名", text: $fullName)
                Button {
                    showBirthPicker = true
                } label: {
                    HStack {
                        Text("生日")
                        Spacer()
                        Text(birthMonthDisplay)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
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
        .sheet(isPresented: $showBirthPicker) {
            MonthYearPickerSheet(selectedDate: $birthDate, isPresented: $showBirthPicker)
        }
    }
    
    private func hydrateUser() {
        guard let user = authService.currentUser else { return }
        email = user.email
        fullName = buildFullName(user)
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
    
    private var birthMonthDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: birthDate)
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
            let parts = splitFullName(fullName)
            let user = try await APIService.shared.updateUserProfile(
                userId: userId,
                email: email,
                firstName: parts.firstName,
                lastName: parts.lastName
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
    
    private func splitFullName(_ value: String) -> (firstName: String, lastName: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ("", "")
        }
        
        if containsCJK(trimmed) {
            let compact = String(trimmed.filter { !$0.isWhitespace })
            guard let firstChar = compact.first else {
                return ("", "")
            }
            let lastName = String(firstChar)
            let firstName = String(compact.dropFirst())
            return (firstName, lastName)
        }
        
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace })
        guard let firstPart = parts.first else {
            return ("", "")
        }
        let lastName = String(firstPart)
        let firstName = parts.dropFirst().joined(separator: " ")
        return (firstName, lastName)
    }
    
    private func containsCJK(_ value: String) -> Bool {
        for scalar in value.unicodeScalars {
            switch scalar.value {
            case 0x4E00...0x9FFF, 0x3400...0x4DBF, 0xF900...0xFAFF, 0x2F800...0x2FA1F:
                return true
            default:
                continue
            }
        }
        return false
    }
    
    private func buildFullName(_ user: User) -> String {
        let parts = [user.lastName, user.firstName].filter { !$0.isEmpty }
        if !parts.isEmpty {
            return parts.joined(separator: " ")
        }
        return user.fullName
    }
}

private struct MonthYearPickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    
    private var minimumDate: Date {
        Calendar.current.date(byAdding: .year, value: -150, to: Date()) ?? Date()
    }
    
    private var maximumDate: Date {
        Date()
    }
    
    private var years: [Int] {
        let calendar = Calendar.current
        let minYear = calendar.component(.year, from: minimumDate)
        let maxYear = calendar.component(.year, from: maximumDate)
        return Array(minYear...maxYear).reversed()
    }
    
    private var months: [Int] {
        Array(1...12)
    }
    
    init(selectedDate: Binding<Date>, isPresented: Binding<Bool>) {
        _selectedDate = selectedDate
        _isPresented = isPresented
        let calendar = Calendar.current
        let date = selectedDate.wrappedValue
        _selectedYear = State(initialValue: calendar.component(.year, from: date))
        _selectedMonth = State(initialValue: calendar.component(.month, from: date))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("選擇出生年月")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.darkBrown)
                    .padding(.top, 20)
                
                HStack(spacing: 0) {
                    Picker("年", selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text("\(year)年").tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    
                    Picker("月", selection: $selectedMonth) {
                        ForEach(months, id: \.self) { month in
                            Text("\(month)月").tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 180)
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button("確認") {
                    selectedDate = clampedDate()
                    isPresented = false
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppColors.orange)
                .cornerRadius(12)
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
        .onChange(of: selectedYear) { _, _ in
            selectedDate = clampedDate()
        }
        .onChange(of: selectedMonth) { _, _ in
            selectedDate = clampedDate()
        }
    }
    
    private func clampedDate() -> Date {
        let calendar = Calendar.current
        let maxYear = calendar.component(.year, from: maximumDate)
        let maxMonth = calendar.component(.month, from: maximumDate)
        let minYear = calendar.component(.year, from: minimumDate)
        let minMonth = calendar.component(.month, from: minimumDate)
        
        var year = selectedYear
        var month = selectedMonth
        
        if year > maxYear {
            year = maxYear
        } else if year == maxYear, month > maxMonth {
            month = maxMonth
        }
        
        if year < minYear {
            year = minYear
        } else if year == minYear, month < minMonth {
            month = minMonth
        }
        
        let components = DateComponents(year: year, month: month, day: 1)
        return calendar.date(from: components) ?? Date()
    }
}

// MARK: - 支撐我的片刻 Modal
private struct SupportReasonsModal: View {
    let onClose: () -> Void
    
    @State private var showingAddText = false
    @State private var localReasons: [SupportReason]
    @State private var editingReason: SupportReason?
    @State private var errorMessage: String?
    @State private var supportImages: [SupportImage] = []
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var supportVideos: [SupportVideo] = []
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var activeVideo: SupportVideo?
    
    private static let apiDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    init(reasons: [SupportReason], onClose: @escaping () -> Void) {
        self.onClose = onClose
        _localReasons = State(initialValue: reasons)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    
                    reasonsSection
                }
                .padding(28)
            }
            .background(AppColors.lightYellow.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .task {
            await loadReasons()
            supportImages = SupportReasonImageStore.loadImages()
            supportVideos = SupportReasonVideoStore.loadVideos()
        }
        .sheet(isPresented: $showingAddText) {
            AddSupportTextView(
                onSave: { title, detail in
                    Task {
                        await createReason(title: title, detail: detail)
                    }
                },
                onCancel: {
                    showingAddText = false
                }
            )
        }
        .sheet(item: $editingReason) { reason in
            AddSupportTextView(
                titleText: "編輯文字",
                initialTitle: reason.title,
                initialDetail: reason.detail,
                onSave: { title, detail in
                    Task {
                        await updateReason(reason, title: title, detail: detail)
                    }
                },
                onCancel: {
                    editingReason = nil
                }
            )
        }
        .onChange(of: selectedImageItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let image = SupportReasonImageStore.saveImageData(data) {
                    await MainActor.run {
                        supportImages.insert(image, at: 0)
                    }
                }
            }
        }
        .onChange(of: selectedVideoItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let video = SupportReasonVideoStore.saveVideoData(data) {
                    await MainActor.run {
                        supportVideos.insert(video, at: 0)
                    }
                }
            }
        }
        .fullScreenCover(item: $activeVideo) { video in
            VideoPlayer(player: AVPlayer(url: video.url))
                .ignoresSafeArea()
                .onDisappear {
                    activeVideo = nil
                }
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
        return VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("我的理由珍藏")
                        .font(.headline)
                        .foregroundColor(AppColors.titleColor)
                    Text("在陽光燦爛的日子，為雨天存一點光。邀請你在這裡存下那些值得留住的瞬間，讓它們在困難時刻給你溫暖，陪伴你找回前行的力量。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            HStack {
                sectionHeader("文字")
                Spacer()
                Button(action: { showingAddText = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("新增文字")
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColors.orange.opacity(0.2))
                    .foregroundColor(AppColors.titleColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            if localReasons.isEmpty {
                emptySectionHint("尚未新增文字內容")
            } else {
                VStack(spacing: 12) {
                    ForEach(localReasons) { reason in
                        TextReasonCard(
                            reason: reason,
                            onEdit: { editingReason = reason },
                            onDelete: { Task { await deleteReason(reason) } }
                        )
                    }
                }
                .padding(.horizontal, 6)
            }
            
            HStack {
                sectionHeader("圖片")
                Spacer()
                PhotosPicker(selection: $selectedImageItem, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("新增圖片")
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColors.orange.opacity(0.2))
                    .foregroundColor(AppColors.titleColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            if supportImages.isEmpty {
                emptySectionHint("尚未新增圖片內容")
            } else {
                VStack(spacing: 12) {
                    ForEach(supportImages) { image in
                        ImageSupportCard(
                            image: image,
                            onDelete: { deleteImage(image) }
                        )
                    }
                }
                .padding(.horizontal, 6)
            }
            
            HStack {
                sectionHeader("影片")
                Spacer()
                PhotosPicker(selection: $selectedVideoItem, matching: .videos) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("新增影片")
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColors.orange.opacity(0.2))
                    .foregroundColor(AppColors.titleColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            if supportVideos.isEmpty {
                emptySectionHint("尚未新增影片內容")
            } else {
                VStack(spacing: 12) {
                    ForEach(supportVideos) { video in
                        VideoReasonCard(
                            video: video,
                            onPlay: { activeVideo = video },
                            onDelete: { deleteVideo(video) }
                        )
                    }
                }
                .padding(.horizontal, 6)
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(AppColors.titleColor)
    }
    
    private func emptySectionHint(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(AppColors.titleColor.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
    }
    
    private func deleteVideo(_ video: SupportVideo) {
        SupportReasonVideoStore.deleteVideo(with: video.id)
        supportVideos.removeAll { $0.id == video.id }
    }
    
    private func loadReasons() async {
        guard AuthService.shared.authToken != nil else { return }
        do {
            let reasons = try await APIService.shared.getReasons()
            localReasons = reasons.map(mapReason)
            errorMessage = nil
        } catch {
            // 忽略載入失敗，避免在無資料時顯示錯誤
            errorMessage = nil
        }
    }
    
    private func createReason(title: String, detail: String) async {
        do {
            let reason = try await APIService.shared.createReason(
                title: title,
                content: detail,
                date: Date()
            )
            localReasons.insert(mapReason(reason), at: 0)
            showingAddText = false
            errorMessage = nil
        } catch {
            errorMessage = "新增文字失敗，請稍後再試"
        }
    }
    
    private func updateReason(_ reason: SupportReason, title: String, detail: String) async {
        do {
            let updated = try await APIService.shared.updateReason(
                id: reason.id,
                title: title,
                content: detail,
                date: reason.apiDate,
                isDeleted: false
            )
            if let index = localReasons.firstIndex(where: { $0.id == reason.id }) {
                localReasons[index] = mapReason(updated)
            }
            editingReason = nil
            errorMessage = nil
        } catch {
            errorMessage = "更新文字失敗，請稍後再試"
        }
    }
    
    private func deleteReason(_ reason: SupportReason) async {
        do {
            _ = try await APIService.shared.deleteReason(id: reason.id)
            localReasons.removeAll { $0.id == reason.id }
            errorMessage = nil
        } catch {
            errorMessage = "刪除文字失敗，請稍後再試"
        }
    }
    
    private func deleteImage(_ image: SupportImage) {
        SupportReasonImageStore.deleteImage(with: image.id)
        supportImages.removeAll { $0.id == image.id }
    }
    
    private func mapReason(_ reason: ReasonItem) -> SupportReason {
        let date = parseAPIDate(reason.date)
        return SupportReason(
            id: reason.id,
            title: reason.title,
            detail: reason.content,
            date: SupportReason.displayDate(from: date),
            isFavorite: false,
            apiDate: date
        )
    }
    
    private func parseAPIDate(_ value: String) -> Date {
        if let date = Self.apiDateFormatter.date(from: value) {
            return date
        }
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        return fallback.date(from: value) ?? Date()
    }
}

private struct TextReasonCard: View {
    let reason: SupportReason
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(reason.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppColors.titleColor)
                Spacer()
                HStack(spacing: 12) {
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
                    Button(action: onEdit) {
                        Image(systemName: "square.and.pencil")
                    }
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                    }
                }
                .foregroundColor(AppColors.titleColor.opacity(0.8))
                .buttonStyle(.plain)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.orange.opacity(0.12))
        )
    }
}

private struct ImageSupportCard: View {
    let image: SupportImage
    let onDelete: () -> Void
    
    @State private var uiImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .clipped()
                    .cornerRadius(10)
            }
            
            HStack {
                Text(image.displayDate)
                    .font(.caption)
                    .foregroundColor(AppColors.titleColor.opacity(0.7))
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .foregroundColor(AppColors.titleColor.opacity(0.8))
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.orange.opacity(0.12))
        )
        .onAppear {
            if uiImage == nil,
               let data = try? Data(contentsOf: image.url),
               let image = UIImage(data: data) {
                uiImage = image
            }
        }
    }
}

private struct VideoReasonCard: View {
    let video: SupportVideo
    let onPlay: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onPlay) {
                ZStack {
                    VideoThumbnailView(url: video.url)
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .buttonStyle(.plain)
            
            HStack {
                Text(video.displayDate)
                    .font(.caption)
                    .foregroundColor(AppColors.titleColor.opacity(0.7))
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .foregroundColor(AppColors.titleColor.opacity(0.8))
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.orange.opacity(0.12))
        )
    }
}

private struct SupportReason: Identifiable {
    let id: String
    let title: String
    let detail: String
    let date: String
    let isFavorite: Bool
    let apiDate: Date
    
    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    static func displayDate(from date: Date) -> String {
        displayFormatter.string(from: date)
    }
    
    init(
        id: String = UUID().uuidString,
        title: String,
        detail: String,
        date: String,
        isFavorite: Bool,
        apiDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.date = date
        self.isFavorite = isFavorite
        self.apiDate = apiDate ?? Self.displayFormatter.date(from: date) ?? Date()
    }
}

private struct SupportImage: Identifiable, Codable {
    let id: String
    let createdAt: Date
    let fileName: String
    
    var url: URL {
        SupportReasonImageStore.imageURL(for: fileName)
    }
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: createdAt)
    }
}

private struct SupportVideo: Identifiable, Codable {
    let id: String
    let createdAt: Date
    let fileName: String
    
    var url: URL {
        SupportReasonVideoStore.videoURL(for: fileName)
    }
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: createdAt)
    }
}

private enum SupportReasonImageStore {
    private static let folderName = "support_reason_images"
    private static let metadataKey = "support_reason_images_meta"
    
    static func loadImages() -> [SupportImage] {
        guard let data = UserDefaults.standard.data(forKey: metadataKey),
              let images = try? JSONDecoder().decode([SupportImage].self, from: data) else {
            return []
        }
        return images.filter { FileManager.default.fileExists(atPath: $0.url.path) }
    }
    
    static func saveImageData(_ data: Data) -> SupportImage? {
        let id = UUID().uuidString
        let fileName = "\(id).jpg"
        let url = imageURL(for: fileName)
        do {
            try data.write(to: url, options: [.atomic])
        } catch {
            return nil
        }
        let image = SupportImage(id: id, createdAt: Date(), fileName: fileName)
        var current = loadImages()
        current.insert(image, at: 0)
        persist(current)
        return image
    }
    
    static func deleteImage(with id: String) {
        var current = loadImages()
        guard let image = current.first(where: { $0.id == id }) else { return }
        try? FileManager.default.removeItem(at: image.url)
        current.removeAll { $0.id == id }
        persist(current)
    }
    
    static func imageURL(for fileName: String) -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderURL = base.appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        return folderURL.appendingPathComponent(fileName)
    }
    
    private static func persist(_ images: [SupportImage]) {
        if let data = try? JSONEncoder().encode(images) {
            UserDefaults.standard.set(data, forKey: metadataKey)
        }
    }
}

private enum SupportReasonVideoStore {
    private static let folderName = "support_reason_videos"
    private static let metadataKey = "support_reason_videos_meta"
    
    static func loadVideos() -> [SupportVideo] {
        guard let data = UserDefaults.standard.data(forKey: metadataKey),
              let videos = try? JSONDecoder().decode([SupportVideo].self, from: data) else {
            return []
        }
        return videos.filter { FileManager.default.fileExists(atPath: $0.url.path) }
    }
    
    static func saveVideoData(_ data: Data) -> SupportVideo? {
        let id = UUID().uuidString
        let fileName = "\(id).mp4"
        let url = videoURL(for: fileName)
        do {
            try data.write(to: url, options: [.atomic])
        } catch {
            return nil
        }
        let video = SupportVideo(id: id, createdAt: Date(), fileName: fileName)
        var current = loadVideos()
        current.insert(video, at: 0)
        persist(current)
        return video
    }
    
    static func deleteVideo(with id: String) {
        var current = loadVideos()
        guard let video = current.first(where: { $0.id == id }) else { return }
        try? FileManager.default.removeItem(at: video.url)
        current.removeAll { $0.id == id }
        persist(current)
    }
    
    static func videoURL(for fileName: String) -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderURL = base.appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        return folderURL.appendingPathComponent(fileName)
    }
    
    private static func persist(_ videos: [SupportVideo]) {
        if let data = try? JSONEncoder().encode(videos) {
            UserDefaults.standard.set(data, forKey: metadataKey)
        }
    }
}

private struct VideoThumbnailView: View {
    let url: URL
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(AppColors.orange.opacity(0.12))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.titleColor))
                    )
            }
        }
        .onAppear {
            if image == nil {
                loadThumbnail()
            }
        }
    }
    
    private func loadThumbnail() {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.5, preferredTimescale: 600)
        DispatchQueue.global(qos: .userInitiated).async {
            if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                let uiImage = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    image = uiImage
                }
            }
        }
    }
}

private struct AddSupportTextView: View {
    let titleText: String
    let initialTitle: String
    let initialDetail: String
    let onSave: (String, String) -> Void
    let onCancel: () -> Void
    
    @State private var title = ""
    @State private var detail = ""
    
    init(
        titleText: String = "新增文字",
        initialTitle: String = "",
        initialDetail: String = "",
        onSave: @escaping (String, String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.titleText = titleText
        self.initialTitle = initialTitle
        self.initialDetail = initialDetail
        self.onSave = onSave
        self.onCancel = onCancel
        _title = State(initialValue: initialTitle)
        _detail = State(initialValue: initialDetail)
    }
    
    private var isSaveDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text(titleText)
                    .font(.title2.weight(.bold))
                    .foregroundColor(AppColors.titleColor)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("標題")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppColors.titleColor)
                    TextField("輸入標題", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("內文")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppColors.titleColor)
                    TextEditor(text: $detail)
                        .frame(minHeight: 140)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                }
                
                Spacer()
            }
            .padding(20)
            .background(AppColors.lightYellow.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        onSave(title, detail)
                    }
                    .disabled(isSaveDisabled)
                }
            }
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
        let displayName = profileDisplayName(authService.currentUser)
        let initials = profileInitials(authService.currentUser)

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
    
    
    // 時光藏寶盒
    private var emotionBoxSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("時光藏寶盒")
                .font(.headline)
                .foregroundColor(.brown)
                .padding(.horizontal, 5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                EmotionBoxCard(
                    title: "支撐我的片刻",
                    description: "在陽光燦爛的日子，為雨天存一點光。",
                    buttonTitle: "查看我的理由",
                    color: .orange,
                    onButtonTap: {
                        showingSupportReasons = true
                    }
                )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .padding(.vertical, 10)

    }
    
    
    // 緊急聯繫
    private var emergencySection: some View {
        let emergencyContacts = emergencyContactsForDisplay()

        return VStack(alignment: .leading, spacing: 16) {
            Text("緊急聯繫")
                .font(.headline)
                .foregroundColor(.brown)
            
            HStack(spacing: 12) {
                EmergencyContactCard(
                    title: "24小時救援專線",
                    subtitle: "1925（依愛我）",
                    buttonText: "立即撥打",
                    phoneNumber: "1925"
                )
                if let first = emergencyContacts.first {
                    EmergencyContactCard(
                        title: first.title,
                        subtitle: "\(first.name)（\(first.title)）：\(first.contactInfo)",
                        buttonText: "立即撥打",
                        phoneNumber: first.contactInfo
                    )
                }
            }
            ForEach(emergencyContacts.dropFirst()) { contact in
                EmergencyContactCard(
                    title: contact.title,
                    subtitle: "\(contact.name)（\(contact.title)）：\(contact.contactInfo)",
                    buttonText: "立即撥打",
                    phoneNumber: contact.contactInfo
                )
            }
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
    
    private func profileDisplayName(_ user: User?) -> String {
        guard let user else { return "使用者" }
        if let nickname = user.nickname, !nickname.isEmpty {
            return nickname
        }
        let parts = [user.lastName, user.firstName].filter { !$0.isEmpty }
        if !parts.isEmpty {
            return parts.joined(separator: " ")
        }
        return user.fullName.isEmpty ? "使用者" : user.fullName
    }
    
    private func profileInitials(_ user: User?) -> String {
        guard let user else { return "ME" }
        let lastInitial = user.lastName.first?.uppercased() ?? ""
        let firstInitial = user.firstName.first?.uppercased() ?? ""
        let combined = "\(lastInitial)\(firstInitial)"
        if !combined.isEmpty {
            return combined
        }
        let fallback = user.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = fallback.first {
            return String(first).uppercased()
        }
        return "ME"
    }
    
    private struct EmergencyDisplayContact: Identifiable {
        let id: String
        let title: String
        let name: String
        let contactInfo: String
    }
    
    private func emergencyContactsForDisplay() -> [EmergencyDisplayContact] {
        guard let user = authService.currentUser else { return [] }
        if let contacts = user.emergencyContacts, !contacts.isEmpty {
            let sorted = contacts.sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }
            return sorted.map { contact in
                EmergencyDisplayContact(
                    id: contact.id,
                    title: contact.relation.isEmpty ? "緊急聯絡人" : contact.relation,
                    name: contact.name,
                    contactInfo: contact.contactInfo
                )
            }
        }
        var fallback: [EmergencyDisplayContact] = []
        if let name = user.supportContactName, let info = user.supportContactInfo,
           !name.isEmpty, !info.isEmpty {
            fallback.append(
                EmergencyDisplayContact(
                    id: "support",
                    title: "緊急聯絡人",
                    name: name,
                    contactInfo: info
                )
            )
        }
        if let name = user.familyContactName, let info = user.familyContactInfo,
           !name.isEmpty, !info.isEmpty {
            fallback.append(
                EmergencyDisplayContact(
                    id: "family",
                    title: "緊急聯絡人",
                    name: name,
                    contactInfo: info
                )
            )
        }
        if let name = user.emergencyContactName, let info = user.emergencyContactPhone,
           !name.isEmpty, !info.isEmpty {
            fallback.append(
                EmergencyDisplayContact(
                    id: "legacy",
                    title: "緊急聯絡人",
                    name: name,
                    contactInfo: info
                )
            )
        }
        return fallback
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
        let fullName = formattedFullName(user)
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
            formatter.dateFormat = "yyyy-MM"
            return formatter.string(from: date)
        }
        if value.count >= 7 {
            return String(value.prefix(7))
        }
        return value
    }
    
    private func formattedFullName(_ user: User?) -> String {
        guard let user else { return "使用者" }
        if !user.lastName.isEmpty || !user.firstName.isEmpty {
            let parts = [user.lastName, user.firstName].filter { !$0.isEmpty }
            let combined = parts.joined(separator: " ")
            return combined.isEmpty ? "使用者" : combined
        }
        return user.fullName.isEmpty ? "使用者" : user.fullName
    }
}
