import SwiftUI

struct DailyCheckInReminderCard: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "heart.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("今日健康檢測")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    
                    Text("花1分鐘記錄今天的身心狀態")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack {
                        Text("開始檢測")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
                
                VStack {
                    Image(systemName: "list.clipboard.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [
                        AppColors.orange,
                        AppColors.orange.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DailyCheckInReminderCard(onTap: {})
        .padding()
        .background(AppColors.lightYellow)
}
