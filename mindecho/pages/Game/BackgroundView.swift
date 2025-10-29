//
//  BackgroundView.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/10/29.
//


import SwiftUI

struct BackgroundView: View {
    let imageName: String

    var body: some View {
        GeometryReader { geo in
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .ignoresSafeArea()
        }
    }
}

#Preview {
    BackgroundView(imageName: "sky")
}
