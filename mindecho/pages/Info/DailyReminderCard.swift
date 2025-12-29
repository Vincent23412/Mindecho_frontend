import SwiftUI

struct DailyReminderCard: View {
    @State private var reminder: ReminderItem = DailyReminderCard.randomReminder()
    private let cardHeight: CGFloat = HomeConstants.Charts.chartHeight + 32

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // MARK: - 今日提醒標題
            Text("今日提醒")
                .font(.headline)
                .foregroundColor(.brown)
                .frame(maxWidth: .infinity, alignment: .leading)

            // MARK: - 引言文字
            Text(reminder.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppColors.titleColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(reminder.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(5)
                .minimumScaleFactor(0.95)
                .padding(.bottom, 4)
                .frame(minHeight: 50, alignment: .topLeading) // 固定高度避免版面抖動
                .frame(maxWidth: .infinity, alignment: .leading)

            // MARK: - 換一句按鈕
            Button {
                reminder = Self.randomReminder()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("換一句")
                }
                .font(.caption)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.15))
                )
            }
            .foregroundColor(.orange)
        }
        .padding(.horizontal, 16)
        .padding(.top, 0)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity) // 固定寬度，交由外層控制
        .frame(height: cardHeight)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.yellow.opacity(0.15))
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - 隨機句子
    private struct ReminderItem {
        let title: String
        let content: String
    }
    
    private static let reminders: [ReminderItem] = [
        ReminderItem(title: "追尋", content: "不論成功或失敗，我選擇追尋心中堅定不移的方向。成功者追尋更大的可能，失敗者追尋新的希望。"),
        ReminderItem(title: "接觸", content: "我允許自己深深接觸情緒，盡情大哭、盡情大笑，讓情緒成為重整、轉化與整合的資源。"),
        ReminderItem(title: "迎新", content: "迎向新希望，開啟人生的轉折點。"),
        ReminderItem(title: "給予", content: "不求回報地給予他人，使我重新拾回內在的能量與滿足。我知道，自己就是一股力量。"),
        ReminderItem(title: "微笑", content: "微笑，是我與世界連結的開始，是一種表達愉悅、歡樂與幸福的方式。"),
        ReminderItem(title: "誠實", content: "誠實面對內心的傷口，以愛回應自己，也回應他人。"),
        ReminderItem(title: "及時", content: "愛要及時，活在當下，珍惜此刻。"),
        ReminderItem(title: "創造", content: "不再受限於陳舊的信念，我親力親為，創造屬於自己的嶄新生活與正向環境。"),
        ReminderItem(title: "定位", content: "我給自己重新定位，找到真正想追求的目標。"),
        ReminderItem(title: "決心", content: "深呼吸，在猶豫之後下定決心，然後持續往前走。"),
        ReminderItem(title: "執行", content: "掌握當下，確實行動，讓決心落地。"),
        ReminderItem(title: "毅力", content: "世人缺乏的往往不是力量，而是堅持到底的毅力。"),
        ReminderItem(title: "奮鬥", content: "我捍衛所堅信的價值，奮鬥，是夢想實現的開始。"),
        ReminderItem(title: "平衡", content: "人生如同騎單車，唯有向前，才能保持平衡。"),
        ReminderItem(title: "謙虛", content: "柔軟謙和，是我最強大的力量。"),
        ReminderItem(title: "重複", content: "我明白，所有能力與技能，皆來自無數次緩慢卻踏實的重複練習。"),
        ReminderItem(title: "志氣", content: "昂首闊步，我以自己為榮，為高尚而遠大的目標前行。"),
        ReminderItem(title: "綻放", content: "以付出與滋養，讓生命之花自然綻放，讓世界見證我的美好。"),
        ReminderItem(title: "美", content: "世界不缺少美，缺少的是發現美的眼睛。我選擇用心體驗生活中的每一刻。"),
        ReminderItem(title: "舒坦", content: "不再鑽牛角尖，讓心回到放鬆與舒坦。"),
        ReminderItem(title: "經營", content: "我用心經營生命中的每一刻，處處皆有美好。"),
        ReminderItem(title: "思考", content: "停下忙亂的腳步，靜心思考，親近自己。"),
        ReminderItem(title: "能力", content: "我認識並相信自己的力量，在能力範圍內突破每一次挑戰。"),
        ReminderItem(title: "願景", content: "我找回心中最初的願景，不再被眼前的挫折遮蔽雙眼。"),
        ReminderItem(title: "夢想", content: "我正走在通往夢想的路上，即使跌倒，也依然帶著喜悅前行。"),
        ReminderItem(title: "無限", content: "我探索自身無限的潛能，接納生命中的各種可能。"),
        ReminderItem(title: "勤勉", content: "我願意付出時間與心力，完成屬於我的任務與挑戰。"),
        ReminderItem(title: "感恩", content: "感恩，開啟豐富的人生，讓我體驗身旁的人、事、物與所擁有的一切。"),
        ReminderItem(title: "關懷", content: "我關懷自己，也關懷他人，用心體會其中的溫柔與美好。"),
        ReminderItem(title: "尋找", content: "當我尋找出路時，我記得：雨後的天空，終會出現彩虹。"),
        ReminderItem(title: "提升", content: "開啟內在的正向潛能，成為更完整的自己。"),
        ReminderItem(title: "忠誠", content: "忠於真實的我，誠實面對自己與他人。"),
        ReminderItem(title: "欣賞", content: "這一次，我選擇以欣賞的眼光看世界，看見不同的風景。"),
        ReminderItem(title: "克服", content: "挑戰不只是困境，也是成長的契機。"),
        ReminderItem(title: "責任", content: "我是我自己，也願為自己的選擇負責。"),
        ReminderItem(title: "嘗試", content: "每一次小小的嘗試，都可能帶來巨大的改變。"),
        ReminderItem(title: "修養", content: "回歸內在，傾聽自己的聲音。"),
        ReminderItem(title: "理想", content: "穩健的步伐，引領我走向心中的理想。"),
        ReminderItem(title: "奉獻", content: "投入、奉獻，在學習中成長。"),
        ReminderItem(title: "感動", content: "珍惜內心被觸動的時刻，好好靠近自己。")
    ]
    
    private static func randomReminder() -> ReminderItem {
        reminders.randomElement() ?? reminders[0]
    }
}

#Preview {
    DailyReminderCard()
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color(.systemBackground))
}
