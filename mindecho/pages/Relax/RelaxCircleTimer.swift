//
//  RelaxCircleTimer.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/10/21.
//

import SwiftUI

struct RelaxCircleTimer: View {
    @ObservedObject var viewModel: RelaxTimerViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // 時間調整
            HStack {
                Button(action: viewModel.decreaseTime) {
                    Image(systemName: "chevron.left")
                }
                Text("\(viewModel.timeLeft / 60) 分鐘")
                    .font(.headline)
                Button(action: viewModel.increaseTime) {
                    Image(systemName: "chevron.right")
                }
            }
            .foregroundColor(AppColors.titleColor)
            .font(.title3.bold())
            
            // 計時圓形
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [
                            AppColors.chatModeColor.opacity(0.35),
                            AppColors.chatModeColor.opacity(0.15)
                        ],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 220, height: 220)
                    .shadow(radius: 5)
                
                Text(timeString(from: viewModel.timeLeft))
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                    .foregroundColor(AppColors.titleColor)
            }
        }
        .padding(.top, 20)
    }
    
    private func timeString(from seconds: Int) -> String {
        let min = seconds / 60
        let sec = seconds % 60
        return String(format: "%02d:%02d", min, sec)
    }
}

#Preview {
    RelaxCircleTimer(viewModel: RelaxTimerViewModel())
}
