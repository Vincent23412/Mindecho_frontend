import SwiftUI

struct RPGSceneView: View {
    @State private var dialogue = "您不用擔心，我會繼續前進，讓我稍微休息一下吧..."
    @State private var characterName = "loffy"
    @State private var showCharacter = false
    @State private var displayedText = ""

    var body: some View {
        ZStack {
            // 背景
            BackgroundView(imageName: "sky")

            VStack {
                Spacer()

                // 人物
                CharacterView(imageName: "loffy", show: showCharacter, maxWidth: 280)
                    .padding(.bottom, 40)

                // 對話框
                DialogueBoxView(
                    characterName: characterName,
                    dialogue: displayedText
                ) {
                    displayedText = ""
                    typeWriterEffect(for: "前方的路還很長，我們必須保持警覺。")
                }
            }
        }
        .onAppear {
            showCharacter = true
            typeWriterEffect(for: dialogue)
        }
    }

    // 打字機效果
    private func typeWriterEffect(for text: String) {
        displayedText = ""
        let characters = Array(text)
        for (index, char) in characters.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                displayedText.append(char)
            }
        }
    }
}

#Preview {
    RPGSceneView()
}
