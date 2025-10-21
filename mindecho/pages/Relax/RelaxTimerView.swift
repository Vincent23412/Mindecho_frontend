//
//  RelaxTimerView.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/9/30.
//

import SwiftUI

struct RelaxTimerView: View {
    @StateObject private var viewModel = RelaxTimerViewModel()
    
    var body: some View {
        VStack(spacing: 24) {
            RelaxHeaderView()
            RelaxModeSelector(viewModel: viewModel)
            RelaxCircleTimer(viewModel: viewModel)
            RelaxControlButtons(viewModel: viewModel)
            Spacer()
        }
        .padding()
        .background(Color.yellow.opacity(0.1).ignoresSafeArea())
    }
}

#Preview {
    RelaxTimerView()
}
