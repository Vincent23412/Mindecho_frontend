import SwiftUI

struct DailyScoresTableCard: View {
    let scores: [DailyCheckInScores]
    let selectedTimePeriod: String
    @State private var showingAllRecords = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter
    }()
    
    private var filteredScores: [DailyCheckInScores] {
        let calendar = Calendar.current
        let startDate: Date
        switch selectedTimePeriod {
        case "本週":
            startDate = calendar.date(byAdding: .day, value: -6, to: Date()) ?? Date()
        case "最近七週":
            startDate = calendar.date(byAdding: .day, value: -48, to: Date()) ?? Date()
        case "最近七月":
            startDate = calendar.date(byAdding: .day, value: -209, to: Date()) ?? Date()
        case "最近三年半":
            startDate = calendar.date(byAdding: .month, value: -42, to: Date()) ?? Date()
        case "本月":
            startDate = calendar.date(byAdding: .day, value: -29, to: Date()) ?? Date()
        default:
            startDate = calendar.date(byAdding: .day, value: -6, to: Date()) ?? Date()
        }
        
        return scores
            .filter { $0.date >= startDate }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("每日檢測紀錄")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.titleColor)
                Spacer()
                if !scores.isEmpty {
                    Button("查看全部") {
                        showingAllRecords = true
                    }
                    .font(.caption)
                    .foregroundColor(AppColors.orange)
                }
            }
            
            if filteredScores.isEmpty {
                Text("暫無資料")
                    .font(.caption)
                    .foregroundColor(AppColors.titleColor.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 6) {
                    HStack {
                        tableHeaderCell("日期")
                        tableHeaderCell("生理")
                        tableHeaderCell("心情")
                        tableHeaderCell("睡眠")
                        tableHeaderCell("精神")
                        tableHeaderCell("食慾")
                    }
                    .padding(.vertical, 6)
                    .background(AppColors.lightYellow.opacity(0.4))
                    .cornerRadius(6)
                    
                    ForEach(filteredScores) { score in
                        HStack {
                            tableCell(dateFormatter.string(from: score.date))
                            tableCell("\(score.physical)")
                            tableCell("\(score.mental)")
                            tableCell("\(score.sleep)")
                            tableCell("\(score.emotional)")
                            tableCell("\(score.appetite)")
                        }
                        .padding(.vertical, 4)
                    }
                }
                .font(.caption2)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(HomeConstants.Charts.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: HomeConstants.Charts.cardShadowRadius)
        .sheet(isPresented: $showingAllRecords) {
            DailyScoresAllRecordsView(scores: scores)
        }
    }
    
    private func tableHeaderCell(_ text: String) -> some View {
        Text(text)
            .frame(maxWidth: .infinity, alignment: .center)
            .fontWeight(.semibold)
            .foregroundColor(AppColors.titleColor)
    }
    
    private func tableCell(_ text: String) -> some View {
        Text(text)
            .frame(maxWidth: .infinity, alignment: .center)
            .foregroundColor(AppColors.titleColor.opacity(0.8))
    }
}

private struct DailyScoresAllRecordsView: View {
    let scores: [DailyCheckInScores]
    @Environment(\.dismiss) private var dismiss

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 8) {
                    HStack {
                        tableHeaderCell("日期")
                        tableHeaderCell("生理")
                        tableHeaderCell("心情")
                        tableHeaderCell("睡眠")
                        tableHeaderCell("精神")
                        tableHeaderCell("食慾")
                    }
                    .padding(.vertical, 6)
                    .background(AppColors.lightYellow.opacity(0.4))
                    .cornerRadius(6)

                    ForEach(scores.sorted { $0.date > $1.date }) { score in
                        HStack {
                            tableCell(dateFormatter.string(from: score.date))
                            tableCell("\(score.physical)")
                            tableCell("\(score.mental)")
                            tableCell("\(score.sleep)")
                            tableCell("\(score.emotional)")
                            tableCell("\(score.appetite)")
                        }
                        .padding(.vertical, 4)
                    }
                }
                .font(.caption2)
                .padding()
            }
            .background(AppColors.lightYellow.ignoresSafeArea())
            .navigationTitle("每日檢測紀錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(AppColors.orange)
                }
            }
        }
    }

    private func tableHeaderCell(_ text: String) -> some View {
        Text(text)
            .frame(maxWidth: .infinity, alignment: .center)
            .fontWeight(.semibold)
            .foregroundColor(AppColors.titleColor)
    }

    private func tableCell(_ text: String) -> some View {
        Text(text)
            .frame(maxWidth: .infinity, alignment: .center)
            .foregroundColor(AppColors.titleColor.opacity(0.8))
    }
}

#Preview {
    DailyScoresTableCard(
        scores: [
            DailyCheckInScores(physical: 3, mental: 1, emotional: 4, sleep: 2, appetite: 1, date: Date()),
            DailyCheckInScores(physical: 2, mental: 5, emotional: 2, sleep: 5, appetite: 1, date: Date().addingTimeInterval(-86400))
        ],
        selectedTimePeriod: "本週"
    )
    .padding()
    .background(AppColors.lightYellow)
}
