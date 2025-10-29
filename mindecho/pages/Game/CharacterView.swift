//
//  CharacterView.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/10/29.
//


import SwiftUI

struct CharacterView: View {
    let imageName: String
    let show: Bool
    let maxWidth: CGFloat

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: maxWidth)
            .shadow(radius: 10)
            .opacity(show ? 1 : 0)
            .animation(.easeIn(duration: 1.2), value: show)
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        CharacterView(imageName: "loffy", show: true, maxWidth: 280)
    }
}
