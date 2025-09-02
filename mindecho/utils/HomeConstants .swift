import Foundation

// MARK: - 首頁相關常數
struct HomeConstants {
    
    // MARK: - 每日檢測
    struct DailyCheckIn {
        static let questions = [
            DailyCheckInQuestion(
                title: "你今天的身體感覺如何？",
                subtitle: "評估你的整體身體健康狀況",
                category: .physical
            ),
            DailyCheckInQuestion(
                title: "你今天的精神狀態如何？",
                subtitle: "評估你的專注力和清晰度",
                category: .mental
            ),
            DailyCheckInQuestion(
                title: "你今天的心情如何？",
                subtitle: "評估你的情緒穩定性",
                category: .emotional
            ),
            DailyCheckInQuestion(
                title: "你昨晚的睡眠品質如何？",
                subtitle: "評估你的睡眠品質和充足度",
                category: .sleep
            ),
            DailyCheckInQuestion(
                title: "你今天的食慾如何？",
                subtitle: "評估你的飲食狀態",
                category: .appetite
            )
        ]
        
        static let moodOptions = [
            MoodOption(emoji: "😰", label: "很差", value: 20),
            MoodOption(emoji: "😞", label: "不好", value: 40),
            MoodOption(emoji: "😐", label: "一般", value: 60),
            MoodOption(emoji: "😊", label: "良好", value: 80),
            MoodOption(emoji: "😄", label: "極佳", value: 100)
        ]
    }
    
    // MARK: - 生理節律
    struct Biorhythm {
        static let physicalCycle = 23    // 體力週期
        static let emotionalCycle = 28   // 情緒週期
        static let intellectualCycle = 33 // 智力週期
        
        // 個人模式最少需要的數據天數
        static let minimumDataDays = 14
        
        // 月份標籤
        static let monthLabels = ["1月", "2月", "3月", "4月", "5月", "6月",
                                 "7月", "8月", "9月", "10月", "11月", "12月"]
    }
    
    // MARK: - 心理健康資源
    struct Resources {
        static let mentalHealthResources = [
            MentalHealthResource(
                title: "24小時心理諮詢熱線",
                subtitle: "專業心理師即時協助",
                icon: "phone.fill",
                buttonText: "立即撥打",
                action: .hotline
            ),
            MentalHealthResource(
                title: "心理健康指南",
                subtitle: "全面了解心理健康知識",
                icon: "book.fill",
                buttonText: "查看更多",
                action: .guide
            ),
            MentalHealthResource(
                title: "情緒管理技巧",
                subtitle: "學習有效調節情緒方法",
                icon: "heart.circle.fill",
                buttonText: "查看更多",
                action: .techniques
            ),
            MentalHealthResource(
                title: "附近心理診所",
                subtitle: "尋找專業醫療協助",
                icon: "location.fill",
                buttonText: "查看地圖",
                action: .map
            )
        ]
    }
    
    // MARK: - 心理測驗
    struct Tests {
        static let psychologicalTests = [
            PsychologicalTest(
                title: "PHQ-9 憂鬱症篩檢",
                subtitle: "評估憂鬱症狀嚴重程度",
                icon: "heart.circle.fill",
                duration: "3分鐘",
                questions: "9題",
                action: .phq9
            ),
            PsychologicalTest(
                title: "GAD-7 焦慮症篩檢",
                subtitle: "評估廣泛性焦慮症狀",
                icon: "brain.head.profile",
                duration: "2分鐘",
                questions: "7題",
                action: .gad7
            ),
            PsychologicalTest(
                title: "BSRS-5 心理症狀量表",
                subtitle: "篩檢心理健康狀況",
                icon: "list.clipboard.fill",
                duration: "2分鐘",
                questions: "5題",
                action: .bsrs5
            ),
            PsychologicalTest(
                title: "RFQ-8 反思功能量表",
                subtitle: "評估心智化能力",
                icon: "lightbulb.fill",
                duration: "3分鐘",
                questions: "8題",
                action: .rfq8
            )
        ]
    }
    
    // MARK: - 圖表設定
    struct Charts {
        static let defaultAnimationDuration: Double = 1.0
        static let chartHeight: CGFloat = 200
        static let cardCornerRadius: CGFloat = 12
        static let cardShadowRadius: CGFloat = 2
        
        // 時間週期選項
        static let timePeriodOptions = ["本週", "本月"]
    }
    
    // MARK: - UserDefaults 鍵值
    struct UserDefaultsKeys {
        static let todayScores = "home_today_scores"
        static let weeklyScores = "home_weekly_scores"
        static let birthDate = "home_birth_date"
        static let biorhythmMode = "home_biorhythm_mode"
    }
    
    // MARK: - 動畫設定
    struct Animation {
        static let cardAppearDuration: Double = 0.3
        static let biorhythmAnimationDuration: Double = 2.0
        static let moodSelectionDuration: Double = 0.2
    }
}
