//
//  RelaxTimerViewModel.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/10/21.
//

import SwiftUI
import Combine

class RelaxTimerViewModel: ObservableObject {
    enum Mode: String, CaseIterable {
        case breath = "呼吸"
        case meditation = "冥想"
    }
    
    @Published var selectedMode: Mode = .breath
    
    struct VideoItem: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let url: URL
    }
    
    func videos(for mode: Mode) -> [VideoItem] {
        switch mode {
        case .breath:
            return [
                VideoItem(
                    title: "5 分鐘方框呼吸",
                    subtitle: "短時間穩定情緒的方框呼吸練習",
                    url: URL(string: "https://www.youtube.com/watch?v=EYQsRBNYdPk")!
                ),
                VideoItem(
                    title: "4-7-8 呼吸法",
                    subtitle: "入睡前放鬆的經典呼吸技巧",
                    url: URL(string: "https://www.youtube.com/watch?v=YRPh_GaiL8s")!
                ),
                VideoItem(
                    title: "引導式深呼吸",
                    subtitle: "搭配舒緩音樂的深呼吸引導",
                    url: URL(string: "https://www.youtube.com/watch?v=aXItOY0sLRY")!
                )
            ]
        case .meditation:
            return [
                VideoItem(
                    title: "10 分鐘靜心冥想",
                    subtitle: "簡單易入門的日常靜心",
                    url: URL(string: "https://www.youtube.com/watch?v=inpok4MKVLM")!
                ),
                VideoItem(
                    title: "正念身體掃描",
                    subtitle: "覺察身體、放鬆緊繃的引導",
                    url: URL(string: "https://www.youtube.com/watch?v=ltVPj6-5qFg")!
                ),
                VideoItem(
                    title: "睡前冥想",
                    subtitle: "柔和語音，幫助安穩入睡",
                    url: URL(string: "https://www.youtube.com/watch?v=oKxuiw3iMBE")!
                )
            ]
        }
    }
}

struct RelaxTimerPreviewWrapper: View {
    @StateObject private var viewModel = RelaxTimerViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("預覽模式：\(viewModel.selectedMode.rawValue)")
                .font(.headline)
            ForEach(viewModel.videos(for: viewModel.selectedMode)) { item in
                Text(item.title)
                    .font(.subheadline)
            }
        }
        .padding(16)
        .previewLayout(.sizeThatFits)
    }
}

#Preview {
    RelaxTimerPreviewWrapper()
}
