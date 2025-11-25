import SwiftUI

struct ProfileView: View {
    @State private var quote = "你的故事還沒有結束，最精彩的章節還在後面"
    @State private var showingSupportReasons = false
    @State private var showingCollectionBox = false
    
    private let samplePhotos: [PhotoItem] = [
        PhotoItem(title: "我和小黃的合照", subtitle: "2023/05/15 - 快樂的一天"),
        PhotoItem(title: "我和小黃的合照", subtitle: "2023/05/15 - 快樂的一天"),
        PhotoItem(title: "我和小黃的合照", subtitle: "2023/05/15 - 快樂的一天"),
        PhotoItem(title: "我和小黃的合照", subtitle: "2023/05/15 - 快樂的一天")
    ]
    
    private let sampleVideos: [VideoItem] = [
        VideoItem(title: "海浪聲音", subtitle: "放鬆冥想影片"),
        VideoItem(title: "海浪聲音", subtitle: "放鬆冥想影片"),
        VideoItem(title: "海浪聲音", subtitle: "放鬆冥想影片")
    ]
    
    private let sampleAudios: [AudioItem] = [
        AudioItem(title: "媽媽的鼓勵", duration: "1:30"),
        AudioItem(title: "媽媽的鼓勵", duration: "1:30"),
        AudioItem(title: "媽媽的鼓勵", duration: "1:30"),
        AudioItem(title: "媽媽的鼓勵", duration: "1:30")
    ]
    
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
                
                // MARK: - 情緒行李箱
                emotionBoxSection
                
                // MARK: - 今日提醒
                dailyReminderCard
                
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
            .sheet(isPresented: $showingCollectionBox) {
                SafeCollectionModal(
                    photos: samplePhotos,
                    videos: sampleVideos,
                    audios: sampleAudios
                ) {
                    showingCollectionBox = false
                }
            }
        }
        .background(Color.yellow.opacity(0.1).ignoresSafeArea())
        .navigationTitle("個人檔案")
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
        HStack(spacing: 16) {
            Circle()
                .fill(Color.orange.opacity(0.8))
                .frame(width: 80, height: 80)
                .overlay(
                    Text("小美")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("這是一個屬於你的安全空間，在這裡可以整理情緒、收集力量、找到希望。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label("今天感覺：平靜", systemImage: "face.smiling")
                        .font(.caption)
                    Spacer()
                    Label("連續登入：7天", systemImage: "calendar")
                        .font(.caption)
                }
                .foregroundColor(.brown)
                .padding(.top, 4)
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
                    EmotionBoxCard(
                        title: "安心收藏箱",
                        description: "收藏能給你帶來安慰和力量的影片、照片和語音。",
                        buttonTitle: "打開收藏箱",
                        color: .orange,
                        onButtonTap: {
                            showingCollectionBox = true
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
    
    
    // 今日提醒
    private var dailyReminderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今日提醒")
                .font(.headline)
                .foregroundColor(.brown)
            
            Text("「\(quote)」")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .minimumScaleFactor(0.9)
                .padding(.bottom, 4)
            
            Spacer(minLength: 0)
            
            Button {
                quote = randomQuote()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("換一句")
                }
                .font(.caption)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.15))
                )
            }
            .foregroundColor(.orange)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(cardBackground)
    }
    
    
    // 緊急聯繫
    private var emergencySection: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                    subtitle: "李雅雯：0912-345-678",
                    buttonText: "立即撥打"
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
    
    
    // MARK: - 隨機名言
    func randomQuote() -> String {
        [
            "你的故事還沒有結束，最精彩的章節還在後面。",
            "今天的努力，是明天的底氣。",
            "即使慢，也不要停止前進。",
            "有時候，溫柔比勇敢更強大。"
        ].randomElement()!
    }
}


#Preview {
    NavigationView {
        ProfileView()
    }
}
