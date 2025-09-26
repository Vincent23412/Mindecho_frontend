//
//  HealthDataView.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/9/26.
//

import SwiftUI

struct HealthDataView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // 📊 數據總覽
                Text("數據概覽")
                    .font(.headline)
                    .padding(.horizontal)
                
                // 四個數據卡片（兩行 Grid）
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    HealthDataCard(title: "心率變異性 (HRV)", subtitle: "心臟健康指標", value: "48", unit: "ms", color: .orange)
                    
                    HealthDataCard(title: "睡眠質量", subtitle: "深度睡眠時間", value: "2.4", unit: "小時", color: .brown)
                    
                    HealthDataCard(title: "活動量", subtitle: "每日步數", value: "7200", unit: "步", color: .teal)
                    
                    HealthDataCard(title: "體重", subtitle: "體重變化趨勢", value: "53.2", unit: "公斤", color: .blue)
                }
                .padding(.horizontal)
                
                // 💡 健康建議
                VStack(alignment: .leading, spacing: 12) {
                    Text("健康建議")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text("提高 HRV\n嘗試每天進行 10 分鐘的深呼吸練習，有助於提高心率變異性，降低壓力水平。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.purple)
                        Text("改善睡眠質量\n您的深度睡眠時間略有下降。建議睡前一小時避免使用電子設備，保持臥室溫度在 18–20°C。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
        }
        .background(Color.yellow.opacity(0.05).ignoresSafeArea())
        .navigationTitle("健康追蹤")
    }
}

// MARK: - 單一卡片元件
struct HealthDataCard: View {
    let title: String
    let subtitle: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                Spacer()
                Text("詳情")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title.bold())
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 簡單折線圖 placeholder
            Rectangle()
                .fill(color.opacity(0.2))
                .frame(height: 30)
                .cornerRadius(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2)
        )
    }
}
