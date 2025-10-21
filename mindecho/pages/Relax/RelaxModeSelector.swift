//
//  RelaxModeSelector.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/10/21.
//

import SwiftUI

struct RelaxModeSelector: View {
    @ObservedObject var viewModel: RelaxTimerViewModel
    
    var body: some View {
        HStack {
            ForEach(RelaxTimerViewModel.Mode.allCases, id: \.self) { mode in
                Button {
                    viewModel.selectedMode = mode
                    viewModel.resetTimer(for: mode)
                } label: {
                    VStack(spacing: 6) {
                        Text(mode.rawValue)
                            .font(.headline)
                            .foregroundColor(.brown)
                        
                        Rectangle()
                            .fill(viewModel.selectedMode == mode ? Color.orange : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    RelaxModeSelector(viewModel: RelaxTimerViewModel())
}
