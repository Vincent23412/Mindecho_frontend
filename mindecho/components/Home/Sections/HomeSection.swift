import SwiftUI

// MARK: - 心理健康資源區塊
struct MentalHealthResourcesSection: View {
    @State private var showingHotlineSheet = false
    @State private var showingGuideSheet = false
    @State private var showingTechniquesSheet = false
    @State private var showingMapSheet = false
    
    private let resources = HomeConstants.Resources.mentalHealthResources
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("心理健康資源")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.titleColor)
                    .padding(.leading, 16)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(resources) { resource in
                        MentalHealthResourceCard(
                            resource: resource,
                            onTap: {
                                handleResourceAction(resource.action)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $showingHotlineSheet) {
            HotlineDetailView(isPresented: $showingHotlineSheet)
        }
        .sheet(isPresented: $showingGuideSheet) {
            GuideDetailView(isPresented: $showingGuideSheet)
        }
        .sheet(isPresented: $showingTechniquesSheet) {
            TechniquesDetailView(isPresented: $showingTechniquesSheet)
        }
        .sheet(isPresented: $showingMapSheet) {
            MapDetailView(isPresented: $showingMapSheet)
        }
    }
    
    private func handleResourceAction(_ action: ResourceAction) {
        switch action {
        case .hotline:
            showingHotlineSheet = true
        case .guide:
            showingGuideSheet = true
        case .techniques:
            showingTechniquesSheet = true
        case .map:
            showingMapSheet = true
        }
    }
}

// MARK: - 心理測驗區塊
struct PsychologicalTestsSection: View {
    @State private var activeScale: ScaleMeta?
    
    private let tests = HomeConstants.Tests.psychologicalTests
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("心理測驗")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.titleColor)
                    .padding(.leading, 16)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(tests) { test in
                        PsychologicalTestCard(
                            test: test,
                            onTap: {
                                handleTestAction(test.action)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .sheet(item: $activeScale) { meta in
            ScaleTestView(meta: meta, isPresented: Binding(
                get: { activeScale != nil },
                set: { if !$0 { activeScale = nil } }
            ))
        }
    }
    
    private func handleTestAction(_ action: TestAction) {
        activeScale = HomeConstants.Tests.scaleMetaByAction[action]
    }
}

// MARK: - 快捷入口區塊
struct QuickAccessSection: View {
    @State private var showingRelax = false
    @State private var showingChat = false
    @State private var showingEmotionBox = false
    
    private let items: [QuickAccessItem] = [
        QuickAccessItem(
            title: "放鬆",
            subtitle: "呼吸與音樂放鬆練習",
            icon: "leaf.fill",
            buttonText: "開始放鬆",
            destination: .relax
        ),
        QuickAccessItem(
            title: "聊天",
            subtitle: "選擇模式開始對話",
            icon: "bubble.left.and.bubble.right.fill",
            buttonText: "開始聊天",
            destination: .chat
        ),
        QuickAccessItem(
            title: "情緒行李箱",
            subtitle: "整理情緒與收集力量",
            icon: "suitcase.fill",
            buttonText: "前往查看",
            destination: .emotionBox
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("快捷入口")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.titleColor)
                    .padding(.leading, 16)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { item in
                        QuickAccessCard(item: item) {
                            handleDestination(item.destination)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $showingRelax) {
            RelaxTimerView()
        }
        .sheet(isPresented: $showingChat) {
            ChatListPage()
        }
        .sheet(isPresented: $showingEmotionBox) {
            NavigationView {
                ProfileView()
            }
        }
    }
    
    private func handleDestination(_ destination: QuickAccessDestination) {
        switch destination {
        case .relax:
            showingRelax = true
        case .chat:
            showingChat = true
        case .emotionBox:
            showingEmotionBox = true
        }
    }
}

private struct QuickAccessItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let buttonText: String
    let destination: QuickAccessDestination
}

private enum QuickAccessDestination {
    case relax
    case chat
    case emotionBox
}

private struct QuickAccessCard: View {
    let item: QuickAccessItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: item.icon)
                        .font(.title2)
                        .foregroundColor(AppColors.darkBrown)
                    Spacer()
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.darkBrown)
                        .multilineTextAlignment(.leading)
                    
                    Text(item.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.darkBrown.opacity(0.7))
                        .multilineTextAlignment(.leading)
                    
                    Text(item.buttonText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.darkBrown)
                        .cornerRadius(8)
                        .padding(.top, 4)
                }
            }
            .padding(16)
            .frame(width: 160, height: 140)
            .background(
                LinearGradient(
                    colors: [
                        AppColors.resourceCardYellow,
                        AppColors.resourceCardOrange,
                        AppColors.orange.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(HomeConstants.Charts.cardCornerRadius)
            .shadow(color: .black.opacity(0.1), radius: HomeConstants.Charts.cardShadowRadius)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        MentalHealthResourcesSection()
        PsychologicalTestsSection()
        QuickAccessSection()
    }
    .background(AppColors.lightYellow)
}
