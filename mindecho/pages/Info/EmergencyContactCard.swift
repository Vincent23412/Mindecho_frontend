//
//  EmergencyContactCard.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/10/21.
//
import SwiftUI

struct EmergencyContactCard: View {
    let title: String
    let subtitle: String
    let buttonText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.brown)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button(buttonText) {}
                .font(.caption)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
        .frame(width: 160, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.15), radius: 3, x: 0, y: 2)
        )
    }
}

#Preview{
    EmergencyContactCard(title: "title", subtitle: "subtitle", buttonText: "button")
}
