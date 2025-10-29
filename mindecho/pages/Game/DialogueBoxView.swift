//
//  DialogueBoxView.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/10/29.
//


import SwiftUI

struct DialogueBoxView: View {
    let characterName: String
    let dialogue: String
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 名稱
            Text(characterName)
                .font(.headline)
                .foregroundColor(.white)

            // 對話文字
            Text(dialogue)
                .font(.body)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            // 下一句按鈕
            HStack {
                Spacer()
                Button(action: onNext) {
                    Text("▶ 下一句")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.8))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.65))
                .shadow(radius: 5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
}

#Preview {
    DialogueBoxView(
        characterName: "安德斯 Anders",
        dialogue: "這是一段示範文字。",
        onNext: {}
    )
    .background(Color.gray)
}
