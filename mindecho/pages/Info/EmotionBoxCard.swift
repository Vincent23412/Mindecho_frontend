//
//  EmotionBoxCard.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/10/21.
//
import SwiftUI

struct EmotionBoxCard: View {
    let title: String
    let description: String
    let buttonTitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.brown)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button(buttonTitle) {}
                .font(.caption)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(color.opacity(0.9))
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
        .frame(width: 160, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.15), radius: 3, x: 0, y: 2)
        )
    }
}
