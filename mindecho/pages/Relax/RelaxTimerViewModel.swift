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
    @Published var timeLeft: Int = 300
    @Published var isRunning = false
    
    private var timer: Timer?
    
    func toggleTimer() {
        if isRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    func resetTimer(for mode: Mode) {
        stopTimer()
        timeLeft = (mode == .breath) ? 300 : 1500
    }
    
    func increaseTime() {
        timeLeft += 60
    }
    
    func decreaseTime() {
        if timeLeft > 60 {
            timeLeft -= 60
        }
    }
    
    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.timeLeft > 0 {
                self.timeLeft -= 1
            } else {
                self.stopTimer()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
}

struct RelaxTimerPreviewWrapper: View {
    @StateObject private var viewModel = RelaxTimerViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            Text("目前模式：\(viewModel.selectedMode.rawValue)")
            Text("剩餘時間：\(viewModel.timeLeft) 秒")
            Button(viewModel.isRunning ? "暫停" : "開始") {
                viewModel.toggleTimer()
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

#Preview {
    RelaxTimerPreviewWrapper()
}
