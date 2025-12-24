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

#Preview {
    VStack(spacing: 20) {
        MentalHealthResourcesSection()
        PsychologicalTestsSection()
    }
    .background(AppColors.lightYellow)
}
