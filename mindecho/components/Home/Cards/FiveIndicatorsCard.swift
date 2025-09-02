import SwiftUI

struct FiveIndicatorsCard: View {
    @Binding var selectedTimePeriod: String
    @ObservedObject private var checkInManager = DailyCheckInManager.shared
    @State private var showingDropdown = false
    @State private var selectedIndicator: HealthIndicatorType? = nil  // nil = 顯示所有指標

    let timePeriodOptions = HomeConstants.Charts.timePeriodOptions

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("五項指標追蹤")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.titleColor)

                Spacer()

                // 指標選擇器
                Menu {
                    Button("顯示全部") {
                        selectedIndicator = nil
                    }
                    Divider()
                    Button("生理") {
                        selectedIndicator = .physical
                    }
                    Button("心情") {
                        selectedIndicator = .emotional
                    }
                    Button("睡眠") {
                        selectedIndicator = .sleep
                    }
                    Button("精神") {
                        selectedIndicator = .mental
                    }
                    Button("食慾") {
                        selectedIndicator = .appetite
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedIndicator?.displayName ?? "全部")
                            .font(.caption)
                            .foregroundColor(AppColors.titleColor.opacity(0.7))
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.caption2)
                            .foregroundColor(AppColors.titleColor.opacity(0.7))
                    }
                }

                // 時間週期選擇器
                Menu {
                    ForEach(timePeriodOptions, id: \.self) { option in
                        Button(action: {
                            selectedTimePeriod = option
                        }) {
                            Text(option)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedTimePeriod)
                            .font(.caption)
                            .foregroundColor(AppColors.titleColor.opacity(0.7))
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(AppColors.titleColor.opacity(0.7))
                    }
                }
            }

            // 圖例 - 根據選擇顯示
            HStack(spacing: 12) {
                if let selected = selectedIndicator {
                    indicatorLegend(name: selected.displayName, color: selected.color)
                } else {
                    indicatorLegend(name: "生理", color: HealthIndicatorType.physical.color)
                    indicatorLegend(name: "心情", color: HealthIndicatorType.emotional.color)
                    indicatorLegend(name: "睡眠", color: HealthIndicatorType.sleep.color)
                    indicatorLegend(name: "精神", color: HealthIndicatorType.mental.color)
                    indicatorLegend(name: "食慾", color: HealthIndicatorType.appetite.color)
                }
            }

            // 圖表和標籤組合
            VStack(spacing: 4) {
                // 圖表區域
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let dataLabels = checkInManager.getDateLabelsForPeriod(selectedTimePeriod)
                    let dayCount = dataLabels.count
                    let dayWidth = dayCount > 1 ? width / CGFloat(dayCount - 1) : width

                    ZStack {
                        // 背景網格線
                        Path { path in
                            for i in 0..<5 {
                                let y = height * CGFloat(i) / 4
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: width, y: y))
                            }
                        }
                        .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                        
                        // Y軸刻度標籤
                        VStack {
                            ForEach(0..<5, id: \.self) { i in
                                HStack {
                                    Text("\(100 - i * 25)")
                                        .font(.caption2)
                                        .foregroundColor(AppColors.titleColor.opacity(0.6))
                                    Spacer()
                                }
                                if i < 4 { Spacer() }
                            }
                        }
                        .padding(.trailing, width - 30)
                        
                        // 根據選擇顯示指標線條
                        if let selected = selectedIndicator {
                            // 只顯示選中的指標
                            createIndicatorLine(
                                data: checkInManager.getDataForPeriod(selectedTimePeriod, indicator: selected),
                                color: selected.color,
                                width: width,
                                height: height,
                                dayWidth: dayWidth,
                                lineWidth: 3  // 單線時加粗
                            )
                        } else {
                            // 顯示所有指標
                            createIndicatorLine(
                                data: checkInManager.getDataForPeriod(selectedTimePeriod, indicator: .physical),
                                color: HealthIndicatorType.physical.color,
                                width: width,
                                height: height,
                                dayWidth: dayWidth,
                                lineWidth: 2
                            )
                            
                            createIndicatorLine(
                                data: checkInManager.getDataForPeriod(selectedTimePeriod, indicator: .emotional),
                                color: HealthIndicatorType.emotional.color,
                                width: width,
                                height: height,
                                dayWidth: dayWidth,
                                lineWidth: 2
                            )
                            
                            createIndicatorLine(
                                data: checkInManager.getDataForPeriod(selectedTimePeriod, indicator: .sleep),
                                color: HealthIndicatorType.sleep.color,
                                width: width,
                                height: height,
                                dayWidth: dayWidth,
                                lineWidth: 2
                            )
                            
                            createIndicatorLine(
                                data: checkInManager.getDataForPeriod(selectedTimePeriod, indicator: .mental),
                                color: HealthIndicatorType.mental.color,
                                width: width,
                                height: height,
                                dayWidth: dayWidth,
                                lineWidth: 2
                            )
                            
                            createIndicatorLine(
                                data: checkInManager.getDataForPeriod(selectedTimePeriod, indicator: .appetite),
                                color: HealthIndicatorType.appetite.color,
                                width: width,
                                height: height,
                                dayWidth: dayWidth,
                                lineWidth: 2
                            )
                        }
                        
                        // 如果沒有數據，顯示提示
                        if checkInManager.weeklyScores.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppColors.titleColor.opacity(0.3))
                                Text("暫無數據")
                                    .font(.caption)
                                    .foregroundColor(AppColors.titleColor.opacity(0.6))
                                Text("完成每日檢測後查看趨勢")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.titleColor.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .frame(height: HomeConstants.Charts.chartHeight)
                
                // 日期標籤 - 雙行顯示
                HStack(spacing: 0) {
                    ForEach(Array(checkInManager.getDateLabelsForPeriod(selectedTimePeriod).enumerated()), id: \.offset) { index, day in
                        if selectedTimePeriod == "本月" && !day.isEmpty {
                            // 本月：雙行顯示（月份和日期分開）
                            let parts = day.components(separatedBy: "|")
                            VStack(spacing: 1) {
                                Text(parts.first ?? "")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.titleColor.opacity(0.6))
                                Text(parts.last ?? "")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.titleColor)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity, minHeight: 24)
                        } else {
                            // 本週：單行顯示
                            Text(day)
                                .font(.caption2)
                                .foregroundColor(AppColors.titleColor)
                                .frame(maxWidth: .infinity, minHeight: 24)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(HomeConstants.Charts.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: HomeConstants.Charts.cardShadowRadius)
    }
    
    // MARK: - 輔助方法
    
    /// 創建圖例項目
    private func indicatorLegend(name: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(name)
                .font(.caption2)
                .foregroundColor(AppColors.titleColor.opacity(0.8))
        }
    }
    
    /// 創建指標線條
    private func createIndicatorLine(
        data: [Int],
        color: Color,
        width: CGFloat,
        height: CGFloat,
        dayWidth: CGFloat,
        lineWidth: CGFloat = 2
    ) -> some View {
        ZStack {
            // 線條
            Path { path in
                var hasStarted = false
                for i in 0..<data.count {
                    if data[i] > 0 {
                        let x = CGFloat(i) * dayWidth
                        let normalizedValue = CGFloat(data[i]) / 100.0
                        let y = height - (normalizedValue * height)

                        if !hasStarted {
                            path.move(to: CGPoint(x: x, y: y))
                            hasStarted = true
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            
            // 數據點
            ForEach(Array(data.enumerated()), id: \.offset) { i, value in
                if value > 0 {
                    Circle()
                        .fill(color)
                        .frame(width: lineWidth + 2, height: lineWidth + 2)
                        .position(
                            x: CGFloat(i) * dayWidth,
                            y: height - (CGFloat(value) / 100.0 * height)
                        )
                        .shadow(color: color.opacity(0.3), radius: 2)
                }
            }
        }
    }
}

// 擴展 HealthIndicatorType 添加顯示名稱
extension HealthIndicatorType {
    var displayName: String {
        switch self {
        case .physical: return "生理"
        case .mental: return "精神"
        case .emotional: return "心情"
        case .sleep: return "睡眠"
        case .appetite: return "食慾"
        case .overall: return "整體"
        }
    }
}

#Preview {
    FiveIndicatorsCard(selectedTimePeriod: .constant("本週"))
        .padding()
        .background(AppColors.lightYellow)
}
