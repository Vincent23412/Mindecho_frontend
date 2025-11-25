//
//  RelaxControlButtons.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/10/21.
//

import SwiftUI

struct RelaxControlButtons: View {
    @ObservedObject var viewModel: RelaxTimerViewModel
    
    var body: some View {
        HStack(spacing: 40) {
            Button(action: {
                viewModel.resetTimer(for: viewModel.selectedMode)
            }) {
                Text("重置")
                    .font(.headline)
                    .frame(width: 100, height: 44)
                    .background(AppColors.chatModeColor.opacity(0.2))
                    .foregroundColor(AppColors.titleColor)
                    .cornerRadius(6)
            }
            
            Button(action: {
                viewModel.toggleTimer()
            }) {
                Text(viewModel.isRunning ? "暫停" : "開始")
                    .font(.headline)
                    .frame(width: 100, height: 44)
                    .background(AppColors.chatModeColor)
                    .foregroundColor(AppColors.aiBubbleColor)
                    .cornerRadius(6)
            }
        }
        .padding(.top, 16)
    }
}

#Preview {
    RelaxControlButtons(viewModel: RelaxTimerViewModel())
}
