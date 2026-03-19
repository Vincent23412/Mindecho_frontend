import Foundation

// MARK: - 首頁相關常數
struct HomeConstants {
    
    // MARK: - 每日檢測
    struct DailyCheckIn {
        static let questions = [
            DailyCheckInQuestion(
                title: "身體感覺有活力嗎？",
                subtitle: "評估你的身體活力狀態",
                category: .physical
            ),
            DailyCheckInQuestion(
                title: "今天心情如何？",
                subtitle: "評估你的情緒狀態",
                category: .mental
            ),
            DailyCheckInQuestion(
                title: "腦筋覺得靈活好使嗎？",
                subtitle: "評估你的思緒清晰度",
                category: .emotional
            ),
            DailyCheckInQuestion(
                title: "這一夜的睡眠品質如何？",
                subtitle: "評估你的睡眠品質",
                category: .sleep
            ),
            DailyCheckInQuestion(
                title: "今天的食慾如何？",
                subtitle: "評估你的飲食狀態",
                category: .appetite
            )
        ]
        
        static let moodOptions = [
            MoodOption(emoji: "😰", label: "很差", value: 1),
            MoodOption(emoji: "😞", label: "不好", value: 2),
            MoodOption(emoji: "😐", label: "一般", value: 3),
            MoodOption(emoji: "😊", label: "良好", value: 4),
            MoodOption(emoji: "😄", label: "極佳", value: 5)
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
//            MentalHealthResource(
//                title: "心理健康指南",
//                subtitle: "全面了解心理健康知識",
//                icon: "book.fill",
//                buttonText: "查看更多",
//                action: .guide
//            ),
            MentalHealthResource(
                title: "情緒管理技巧",
                subtitle: "學習有效調節情緒方法",
                icon: "heart.circle.fill",
                buttonText: "查看更多",
                action: .techniques
            )
//            ,
//            MentalHealthResource(
//                title: "附近心理診所",
//                subtitle: "尋找專業醫療協助",
//                icon: "location.fill",
//                buttonText: "查看地圖",
//                action: .map
//            )
        ]
    }
    
    // MARK: - 心理測驗
    struct Tests {
        static let psychologicalTests = [
            makeTest(action: .cesd, title: "憂鬱量表：CES-D", subtitle: "CES-D Depression Scale", icon: "heart.circle.fill"),
            makeTest(action: .bsrs5, title: "BSRS-5 簡式健康量表", subtitle: "Brief Symptom Rating Scale-5", icon: "list.clipboard.fill"),
            makeTest(action: .sats, title: "SATS 消沉心態量表", subtitle: "SATS Scale", icon: "cloud.rain.fill"),
            makeTest(action: .aq10, title: "AQ-10 自閉特質量表", subtitle: "Autism Spectrum Quotient-10", icon: "person.2.fill"),
            makeTest(action: .psycap, title: "PCS 心理資本量表", subtitle: "Psychological Capital Scale", icon: "sparkles"),
            makeTest(action: .cdrisc, title: "CD-RISC 復原力量表", subtitle: "Connor-Davidson Resilience Scale", icon: "shield.lefthalf.fill"),
            makeTest(action: .pansi, title: "PANSI 自殺意念量表", subtitle: "Positive and Negative Suicide Ideation", icon: "exclamationmark.triangle.fill"),
            makeTest(action: .bss, title: "BSS 自殺意念評估", subtitle: "Beck Scale for Suicide Ideation", icon: "waveform.path.ecg"),
            makeTest(action: .rfq8, title: "RFQ-8 心智化量表", subtitle: "Reflective Functioning Questionnaire-8", icon: "brain.head.profile")
        ]
        
        private static func makeTest(action: TestAction, title: String, subtitle: String, icon: String) -> PsychologicalTest {
            let count = action == .rfq8 ? 8 : (scaleMetaByAction[action]?.questionCount ?? 0)
            let minutes = max(1, Int(ceil(Double(count) / 2.0)))
            return PsychologicalTest(
                title: title,
                subtitle: subtitle,
                icon: icon,
                duration: "\(minutes)分鐘",
                questions: "\(count)題",
                action: action
            )
        }

        static let scaleMetas: [ScaleMeta] = [
            ScaleMeta(
                action: .cesd,
                code: "CESD20",
                title: "CES-D 憂鬱量表 (CES-D Depression Scale)",
                questionCount: 20,
                instructions: "請依「過去一週內」的情形作答（4、8、12、16為反向題）",
                reverseIndices: Set([4, 8, 12, 16])
            ),
            ScaleMeta(
                action: .bsrs5,
                code: "BSRS5",
                title: "BSRS-5 簡式健康量表 (Brief Symptom Rating Scale-5)",
                questionCount: 5,
                instructions: "最近一週內的感受",
                reverseIndices: Set<Int>()
            ),
            ScaleMeta(
                action: .sats,
                code: "SATS8",
                title: "SATS 消沉心態量表 (SATS Scale)",
                questionCount: 8,
                instructions: "請依近期感受作答",
                reverseIndices: Set<Int>()
            ),
            ScaleMeta(
                action: .aq10,
                code: "AQ10",
                title: "AQ-10 自閉特質量表 (Autism Spectrum Quotient-10)",
                questionCount: 10,
                instructions: "請依實際狀況作答",
                reverseIndices: Set<Int>()
            ),
            ScaleMeta(
                action: .psycap,
                code: "PCS12",
                title: "PCS 心理資本量表 (Psychological Capital Scale)",
                questionCount: 12,
                instructions: "請依實際狀況作答",
                reverseIndices: Set<Int>()
            ),
            ScaleMeta(
                action: .cdrisc,
                code: "CDRISC25",
                title: "CD-RISC 復原力量表 (Connor-Davidson Resilience Scale)",
                questionCount: 25,
                instructions: "請依實際狀況作答",
                reverseIndices: Set<Int>()
            ),
            ScaleMeta(
                action: .pansi,
                code: "PANSI14",
                title: "PANSI 自殺意念量表 (Positive and Negative Suicide Ideation)",
                questionCount: 14,
                instructions: "請依實際狀況作答",
                reverseIndices: Set<Int>()
            ),
            ScaleMeta(
                action: .bss,
                code: "BSS21",
                title: "BSS 自殺意念評估 (Beck Scale for Suicide Ideation)",
                questionCount: 21,
                instructions: "請依實際狀況作答",
                reverseIndices: Set<Int>()
            )
        ]

        static let scaleMetaByAction: [TestAction: ScaleMeta] = {
            var map: [TestAction: ScaleMeta] = [:]
            for meta in scaleMetas {
                map[meta.action] = meta
            }
            return map
        }()
    }
    
    // MARK: - 圖表設定
    struct Charts {
        static let defaultAnimationDuration: Double = 1.0
        static let chartHeight: CGFloat = 200
        static let cardCornerRadius: CGFloat = 12
        static let cardShadowRadius: CGFloat = 2
        
        // 時間週期選項
        static let timePeriodOptions = ["本週", "最近七週", "最近七月", "最近三年半"]
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
