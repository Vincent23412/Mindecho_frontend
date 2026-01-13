import Foundation
import SwiftUI
import Combine

// MARK: - 每日檢測數據管理器（修正版）
class DailyCheckInManager: NSObject, ObservableObject {
    static let shared = DailyCheckInManager()
    
    // MARK: - Published 屬性
    @Published var weeklyScores: [DailyCheckInScores] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: - 計算屬性（取代原本的 @Published 屬性）
    var todayScores: DailyCheckInScores? {
        return weeklyScores.first { Calendar.current.isDateInToday($0.date) }
    }
    
    var hasCompletedToday: Bool {
        return todayScores != nil
    }
    
    // MARK: - 私有屬性
    private let userDefaults = UserDefaults.standard
    private let weeklyScoresKey = HomeConstants.UserDefaultsKeys.weeklyScores
    private var cancellables = Set<AnyCancellable>()
    private let allowInsecureSelfSigned = true
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config,
                          delegate: allowInsecureSelfSigned ? self : nil,
                          delegateQueue: nil)
    }()
    
    // MARK: - 初始化
    private override init() {
        super.init()
        loadWeeklyScores()
        
        // 當用戶登錄時，自動從 API 獲取數據
        AuthService.shared.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.loadWeeklyScores()
                    self?.loadDataFromAPI()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 保存今日檢測
    func saveDailyCheckIn(scores: DailyCheckInScores) {
        AuthService.shared.refreshStoredAuthIfNeeded()
        // 移除同一天的舊數據（如果存在）
        let targetDate = Calendar.current.startOfDay(for: scores.date)
        weeklyScores.removeAll {
            Calendar.current.startOfDay(for: $0.date) == targetDate
        }
        
        // 添加新數據
        weeklyScores.append(scores)
        
        // 按日期排序，最新的在前
        weeklyScores.sort { $0.date > $1.date }
        
        // 保存到本地
        saveWeeklyScores()
        
        // 保存到 API（先註解掉，避免錯誤）
        saveToAPI(scores)
        
        
        print("已保存數據到: \(scores.date)")
    }
    
    // MARK: - 從 API 載入數據
    func loadDataFromAPI() {
        guard AuthService.shared.isAuthenticated else { return }
        
        isLoading = true
        errorMessage = ""
        
        APIService.shared.getMetrics()
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "載入數據失敗: \(error.localizedDescription)"
                        print("載入 API 數據失敗: \(error)")
                    }
                },
                receiveValue: { [weak self] metrics in
                    self?.processAPIData(metrics)
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - 處理 API 返回的數據
    private func processAPIData(_ metrics: [DailyQuestionEntry]) {
        
        for metric in metrics {
            if let dailyScore = metric.toDailyCheckInScores() {
         
                
                // 移除相同日期的舊數據（如果有）
                let targetDate = Calendar.current.startOfDay(for: dailyScore.date)
                weeklyScores.removeAll { existingScore in
                    Calendar.current.startOfDay(for: existingScore.date) == targetDate
                }
                
                // 添加新數據
                weeklyScores.append(dailyScore)
                print("✅ 已更新日期 \(targetDate) 的數據")
            }
        }
        
        // 按日期排序，最新的在前
        weeklyScores.sort { $0.date > $1.date }
        
        // 保存到本地
        saveWeeklyScores()
        
        print("📊 最終共有 \(weeklyScores.count) 筆數據")
    }
    
    // MARK: - 保存到 API（暫時註解）
    private func saveToAPI(_ scores: DailyCheckInScores) {
        guard let user = AuthService.shared.currentUser else {
            print("⚠️ No user found")
            return }
        
        print("💡 user.id being sent: \(user.primaryId)")
        
        // 🎯 修改日期格式
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-M-dd"  // 符合後端期望格式
        
        let requestData: [String: Any] = [
            "userId": user.primaryId,
            "physical": [
                "description": getDescription(scores.physical),
                "value": scores.physical
            ],
            "mood": [
                "description": getDescription(scores.emotional),
                "value": scores.emotional
            ],
            "sleep": [
                "description": getDescription(scores.sleep),
                "value": scores.sleep
            ],
            "energy": [
                "description": getDescription(scores.mental),
                "value": scores.mental
            ],
            "appetite": [
                "description": getDescription(scores.appetite),
                "value": scores.appetite
            ],
            "entryDate": dateFormatter.string(from: scores.date)  // 🎯 使用新的格式
        ]
        
        print("🚀 Requesting: https://mindechoserver.com/api/main/updateMetrics")
        print("📦 Parameters: \(requestData)")
        print("🕒 entryDate: \(dateFormatter.string(from: scores.date))")



        APIService.shared.updateMetrics(data: requestData)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("API save result: error")
                    }
                },
                receiveValue: { success in
                    print("API save result: success")
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - 上傳每日問卷答案
    func sendDailyQuestions(questions: [String], answers: [Int], date: Date = Date()) {
        AuthService.shared.refreshStoredAuthIfNeeded()
        guard let user = AuthService.shared.currentUser else {
            print("⚠️ sendDailyQuestions: no user")
            return
        }
        guard questions.count == 5, answers.count == 5 else {
            print("⚠️ sendDailyQuestions: invalid question/answer count")
            return
        }
        guard let token = AuthService.shared.authToken else {
            print("⚠️ sendDailyQuestions: no auth token")
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let entryDate = formatter.string(from: date)

        let payload: [String: Any] = [
            "userId": user.primaryId,
            "physical": answers[0],
            "mental": answers[1],
            "emotion": answers[2],
            "sleep": answers[3],
            "diet": answers[4],
            "entryDate": entryDate
        ]

        guard let url = URL(string: "https://localhost/dev-api/main/dailyQuestions") else {
            print("❌ sendDailyQuestions: bad URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("❌ sendDailyQuestions: encode error \(error)")
            return
        }

        print("🚀 sendDailyQuestions -> \(url.absoluteString)")
        print("🧾 payload: \(payload)")

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ sendDailyQuestions error: \(error)")
                return
            }
            if let http = response as? HTTPURLResponse {
                print("✅ dailyQuestions status: \(http.statusCode)")
                if !(200...299).contains(http.statusCode) {
                    print("❗️ dailyQuestions non-2xx response")
                }
            }
            if let data, let text = String(data: data, encoding: .utf8) {
                print("📄 dailyQuestions response: \(text)")
            }
        }.resume()
    }
    
    // MARK: - 分數轉描述
    private func getDescription(_ value: Int) -> String {
        switch value {
        case 1: return "awful"
        case 2: return "bad"
        case 3: return "okay"
        case 4: return "good"
        default: return "great"
        }
    }

    
    // MARK: - 本地存儲方法
    private func loadWeeklyScores() {
        guard let key = userScopedWeeklyScoresKey(),
              let data = userDefaults.data(forKey: key),
              let scores = try? JSONDecoder().decode([DailyCheckInScores].self, from: data) else {
            weeklyScores = []
            return
        }
        
        weeklyScores = scores.sorted { $0.date > $1.date }
        print("已載入 \(weeklyScores.count) 筆歷史數據")
    }
    
    private func saveWeeklyScores() {
        guard let key = userScopedWeeklyScoresKey(),
              let data = try? JSONEncoder().encode(weeklyScores) else {
            return
        }
        userDefaults.set(data, forKey: key)
            print("已保存 \(weeklyScores.count) 筆數據到本地")
    }

    private func userScopedWeeklyScoresKey() -> String? {
        guard let userId = AuthService.shared.currentUser?.primaryId, !userId.isEmpty else {
            return nil
        }
        return "\(weeklyScoresKey)_\(userId)"
    }
    
    // MARK: - 其他方法保持不變
    func getDataForPeriod(_ period: String, indicator: HealthIndicatorType) -> [Int] {
        let calendar = Calendar.current
        var data: [Int] = []
        var dayCount: Int

        switch period {
        case "本週":
            dayCount = 7
        case "最近七週":
            dayCount = 7
        case "最近七月":
            dayCount = 7
        default:
            dayCount = 7
        }

        switch period {
        case "最近七月":
            let calendar = Calendar.current
            for offset in (0..<dayCount).reversed() {
                guard let targetMonth = calendar.date(byAdding: .month, value: -offset, to: Date()) else {
                    data.append(0)
                    continue
                }
                let monthScores = weeklyScores.filter { score in
                    let components = calendar.dateComponents([.year, .month], from: score.date)
                    let targetComponents = calendar.dateComponents([.year, .month], from: targetMonth)
                    return components.year == targetComponents.year && components.month == targetComponents.month
                }
                let values = monthScores.map { score -> Int in
                    switch indicator {
                    case .physical: return score.physical
                    case .mental: return score.mental
                    case .emotional: return score.emotional
                    case .sleep: return score.sleep
                    case .appetite: return score.appetite
                    case .overall: return score.overall
                    }
                }
                data.append(values.isEmpty ? 0 : values.reduce(0, +) / values.count)
            }
            return data
        case "最近七週":
            for offset in (0..<dayCount).reversed() {
                guard let weekStart = calendar.date(byAdding: .day, value: -(offset * 7), to: calendar.startOfDay(for: Date())) else {
                    data.append(0)
                    continue
                }
                let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
                let weekScores = weeklyScores.filter { score in
                    let day = calendar.startOfDay(for: score.date)
                    return day >= weekStart && day <= weekEnd
                }
                let values = weekScores.map { score -> Int in
                    switch indicator {
                    case .physical: return score.physical
                    case .mental: return score.mental
                    case .emotional: return score.emotional
                    case .sleep: return score.sleep
                    case .appetite: return score.appetite
                    case .overall: return score.overall
                    }
                }
                data.append(values.isEmpty ? 0 : values.reduce(0, +) / values.count)
            }
            return data
        default:
            for i in (0..<dayCount).reversed() {
                let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
                let dayStart = calendar.startOfDay(for: date)
                
                if let dayScore = weeklyScores.first(where: {
                    calendar.startOfDay(for: $0.date) == dayStart
                }) {
                    switch indicator {
                    case .physical:
                        data.append(dayScore.physical)
                    case .mental:
                        data.append(dayScore.mental)
                    case .emotional:
                        data.append(dayScore.emotional)
                    case .sleep:
                        data.append(dayScore.sleep)
                    case .appetite:
                        data.append(dayScore.appetite)
                    case .overall:
                        data.append(dayScore.overall)
                    }
                } else {
                    data.append(0)
                }
            }
            return data
        }
    }
    
    func getDateLabelsForPeriod(_ period: String) -> [String] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        var labels: [String] = []
        var dayCount: Int
        
        switch period {
        case "本週":
            dayCount = 7
            dateFormatter.dateFormat = "E"
            
            for i in (0..<dayCount).reversed() {
                let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
                let fullDay = dateFormatter.string(from: date)
                let shortDay = fullDay.replacingOccurrences(of: "週", with: "")
                labels.append(shortDay)
            }
            
        case "最近七月":
            dayCount = 7
            for offset in (0..<dayCount).reversed() {
                if let date = calendar.date(byAdding: .month, value: -offset, to: Date()) {
                    let month = calendar.component(.month, from: date)
                    labels.append("\(month)月")
                } else {
                    labels.append("")
                }
            }
        case "最近七週":
            dayCount = 7
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            for offset in (0..<dayCount).reversed() {
                guard let weekStart = calendar.date(byAdding: .day, value: -(offset * 7), to: calendar.startOfDay(for: Date())) else {
                    labels.append("")
                    continue
                }
                labels.append(formatter.string(from: weekStart))
            }
            
        default:
            dayCount = 7
            dateFormatter.dateFormat = "E"
            for i in (0..<dayCount).reversed() {
                let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
                labels.append(dateFormatter.string(from: date))
            }
        }
        
        return labels
    }
    
    func getTodayScore(for indicator: HealthIndicatorType) -> Int {
        guard let todayScores = todayScores else { return 0 }
        
        switch indicator {
        case .physical:
            return todayScores.physical
        case .mental:
            return todayScores.mental
        case .emotional:
            return todayScores.emotional
        case .sleep:
            return todayScores.sleep
        case .appetite:
            return todayScores.appetite
        case .overall:
            return todayScores.overall
        }
    }
    
    func getAverageScore(for indicator: HealthIndicatorType, days: Int = 7) -> Int {
        let data = getDataForPeriod("本週", indicator: indicator).filter { $0 > 0 }
        guard !data.isEmpty else { return 0 }
        
        let sum = data.reduce(0, +)
        return sum / data.count
    }
    
    func getWeeklyData(for indicator: HealthIndicatorType) -> [Int] {
        return getDataForPeriod("本週", indicator: indicator)
    }
    
    // MARK: - 手動刷新數據
    func refreshData() {
        loadDataFromAPI()
    }
    
    // MARK: - 重置和清除方法
    func resetTodayData() {
        // 只移除今天的數據
        let today = Calendar.current.startOfDay(for: Date())
        weeklyScores.removeAll {
            Calendar.current.startOfDay(for: $0.date) == today
        }
        
        saveWeeklyScores()
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func clearAllData() {
        weeklyScores = []
        userDefaults.removeObject(forKey: weeklyScoresKey)
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}

// MARK: - 自簽憑證處理（僅開發用）
extension DailyCheckInManager: URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard allowInsecureSelfSigned,
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}
