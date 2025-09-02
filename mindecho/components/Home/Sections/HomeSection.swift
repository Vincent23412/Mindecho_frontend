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
    @State private var showingPHQ9Test = false
    @State private var showingGAD7Test = false
    @State private var showingBSRS5Test = false
    @State private var showingRFQ8Test = false
    
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
        .sheet(isPresented: $showingPHQ9Test) {
            PHQ9TestView(isPresented: $showingPHQ9Test)
        }
        .sheet(isPresented: $showingGAD7Test) {
            GAD7TestView(isPresented: $showingGAD7Test)
        }
        .sheet(isPresented: $showingBSRS5Test) {
            BSRS5TestView(isPresented: $showingBSRS5Test)
        }
        .sheet(isPresented: $showingRFQ8Test) {
            RFQ8TestView(isPresented: $showingRFQ8Test)
        }
    }
    
    private func handleTestAction(_ action: TestAction) {
        switch action {
        case .phq9:
            showingPHQ9Test = true
        case .gad7:
            showingGAD7Test = true
        case .bsrs5:
            showingBSRS5Test = true
        case .rfq8:
            showingRFQ8Test = true
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MentalHealthResourcesSection()
        PsychologicalTestsSection()
    }
    .background(AppColors.lightYellow)
}
