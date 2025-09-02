import SwiftUI

struct HotlineDetailView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "phone.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.titleColor)
                    
                    Text("24小時心理諮詢熱線")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.titleColor)
                    
                    VStack(spacing: 16) {
                        HotlineCard(
                            title: "生命線協談專線",
                            number: "1995",
                            description: "24小時免費心理諮詢服務",
                            icon: "heart.fill"
                        )
                        
                        HotlineCard(
                            title: "張老師專線",
                            number: "1980",
                            description: "青少年輔導專線",
                            icon: "person.fill"
                        )
                        
                        HotlineCard(
                            title: "安心專線",
                            number: "1925",
                            description: "心理健康諮詢服務",
                            icon: "brain.head.profile"
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📞 使用提醒")
                            .font(.headline)
                            .foregroundColor(AppColors.titleColor)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• 所有專線均提供免費諮詢服務")
                            Text("• 通話內容完全保密")
                            Text("• 如遇危急情況，請立即撥打 119 或前往急診室")
                            Text("• 專業諮詢師將提供情緒支持與建議")
                        }
                        .font(.body)
                        .foregroundColor(AppColors.titleColor)
                    }
                    .padding()
                    .background(AppColors.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2)
                }
                .padding()
            }
            .background(AppColors.lightYellow)
            .navigationTitle("心理諮詢熱線")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("關閉") { isPresented = false })
        }
    }
}

struct HotlineCard: View {
    let title: String
    let number: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(AppColors.titleColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppColors.titleColor)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(AppColors.titleColor.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: {
                if let url = URL(string: "tel:\(number)") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text(number)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppColors.darkBrown)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2)
    }
}

#Preview {
    HotlineDetailView(isPresented: .constant(true))
}
