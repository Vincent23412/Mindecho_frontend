import Foundation
import Combine

class APIService: NSObject, ObservableObject, URLSessionDelegate {
    static let shared = APIService()
    
    private let baseURL = "https://localhost/dev-api"
    private let reasonBaseURL = "https://localhost/dev-api/reason"
    private let diaryBaseURL = "https://localhost/dev-api/diary"
    private let healthAdviceURL = "https://localhost/dev-api/health/advice"
    private let emotionAnalysisURL = "https://localhost/dev-api/emotion/analysis"
    private static let reasonDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private static let diaryDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private let allowInsecureSelfSigned = true
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        return URLSession(
            configuration: config,
            delegate: allowInsecureSelfSigned ? self : nil,
            delegateQueue: nil
        )
    }()
    
    private override init() {
        super.init()
    }
    
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
    
    func updateMetrics(data: [String: Any]) -> AnyPublisher<Bool, Error> {
        guard let url = URL(string: "\(baseURL)/api/main/updateMetrics"),
              let token = AuthService.shared.authToken else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: request)
            .handleEvents(receiveOutput: { data, response in
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 [updateMetrics] Status Code: \(httpResponse.statusCode)")
                }

                let responseText = String(data: data, encoding: .utf8) ?? "No body"
                print("🧾 [updateMetrics] Response Body: \(responseText)")
            })
            .tryMap { data, response -> Bool in
                if let httpResponse = response as? HTTPURLResponse {
                    guard (200...299).contains(httpResponse.statusCode) else {
                        throw URLError(.badServerResponse)
                    }
                }
                return true
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    
    func getMetrics() -> AnyPublisher<[DailyQuestionEntry], Error> {
        guard let user = AuthService.shared.currentUser,
              let token = AuthService.shared.authToken else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var components = URLComponents(string: "\(baseURL)/main/dailyQuestions")
        components?.queryItems = [URLQueryItem(name: "userId", value: user.primaryId)]
        
        guard let url = components?.url else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🚀 Request URL: \(request.url?.absoluteString ?? "invalid url")")

        
        return session.dataTaskPublisher(for: request)
            .handleEvents(receiveOutput: { data, response in
                // 添加調試輸出
                let responseText = String(data: data, encoding: .utf8) ?? "No body"
                print("📥 [getMetrics] Response: \(responseText)")
            })
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode != 200 {
                        print("HTTP Error Code: \(httpResponse.statusCode)")
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
            .decode(type: DailyQuestionsResponse.self, decoder: JSONDecoder())
            .map { response in
                let dates = response.dailyQuestions.map { $0.entryDate }.joined(separator: ", ")
                print("🔄 Decoded daily questions from API for date(s): \(dates)")
                return response.dailyQuestions
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func getScaleQuestions(code: String) async throws -> [String] {
        let items = try await getScaleQuestionItems(code: code)
        return items.map { $0.text }
    }
    
    func getScaleQuestionItems(code: String) async throws -> [ScaleQuestionItem] {
        guard let url = URL(string: "\(baseURL)/main/scales/\(code)/questions") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        if let payload = try? decoder.decode(ScaleQuestionsResponse.self, from: data) {
            return payload.scale.questions.sorted { $0.order < $1.order }
        }
        if let items = try? decoder.decode([ScaleQuestionItem].self, from: data) {
            return items.sorted { $0.order < $1.order }
        }
        if let list = try? decoder.decode([String].self, from: data) {
            return list.enumerated().map { index, text in
                ScaleQuestionItem(id: "\(code)_\(index + 1)", order: index + 1, text: text, isReverse: false)
            }
        }
        
        return []
    }

    func submitScaleAnswers(code: String, userId: String, answers: [ScaleAnswerPayload]) async throws {
        guard let url = URL(string: "\(baseURL)/main/scales/\(code)/answers") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let payload = ScaleAnswersRequest(userId: userId, answers: answers)
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (_, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
    }

    func getScaleSessions(userId: String) async throws -> [ScaleSessionScale] {
        var components = URLComponents(string: "https://localhost/dev-api/main/scales/sessions")
        components?.queryItems = [URLQueryItem(name: "userId", value: userId)]
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("ScaleSessions: GET \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let payload = try JSONDecoder().decode(ScaleSessionsResponse.self, from: data)
        print("ScaleSessions: received \(payload.scales.count) scales")
        return payload.scales
    }

    func createDiaryEntry(content: String, mood: String, entryDate: Date) async throws -> DiaryEntry {
        guard let url = URL(string: diaryBaseURL) else {
            throw URLError(.badURL)
        }
        
        let payload = DiaryEntryCreateRequest(
            content: content,
            mood: mood,
            entryDate: Self.diaryDateFormatter.string(from: entryDate)
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let payloadResponse = try JSONDecoder().decode(DiaryEntryResponse.self, from: data)
        return payloadResponse.entry
    }
    
    func getDiaryEntries(startDate: Date? = nil, endDate: Date? = nil, limit: Int? = nil, offset: Int? = nil) async throws -> [DiaryEntry] {
        var components = URLComponents(string: diaryBaseURL)
        var queryItems: [URLQueryItem] = []
        if let startDate {
            queryItems.append(URLQueryItem(name: "startDate", value: Self.diaryDateFormatter.string(from: startDate)))
        }
        if let endDate {
            queryItems.append(URLQueryItem(name: "endDate", value: Self.diaryDateFormatter.string(from: endDate)))
        }
        if let limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let offset {
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        }
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let payload = try JSONDecoder().decode(DiaryEntriesResponse.self, from: data)
        return payload.entries
    }
    
    func getDiaryEntry(id: String) async throws -> DiaryEntry {
        guard let url = URL(string: "\(diaryBaseURL)/\(id)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let payload = try JSONDecoder().decode(DiaryEntryResponse.self, from: data)
        return payload.entry
    }
    
    func updateDiaryEntry(id: String, content: String, mood: String, entryDate: Date) async throws -> DiaryEntry {
        guard let url = URL(string: "\(diaryBaseURL)/\(id)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let payload = DiaryEntryUpdateRequest(
            content: content,
            mood: mood,
            entryDate: Self.diaryDateFormatter.string(from: entryDate)
        )
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let payloadResponse = try JSONDecoder().decode(DiaryEntryResponse.self, from: data)
        return payloadResponse.entry
    }
    
    func deleteDiaryEntry(id: String) async throws -> DiaryEntry {
        guard let url = URL(string: "\(diaryBaseURL)/\(id)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let payloadResponse = try JSONDecoder().decode(DiaryEntryResponse.self, from: data)
        return payloadResponse.entry
    }

    func getHealthAdvice(request: HealthAdviceRequest) async throws -> HealthAdviceResponse {
        guard let url = URL(string: healthAdviceURL) else {
            throw URLError(.badURL)
        }
        
        var requestURL = URLRequest(url: url)
        requestURL.httpMethod = "POST"
        requestURL.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            requestURL.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        requestURL.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await session.data(for: requestURL)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(HealthAdviceResponse.self, from: data)
    }
    
    func getEmotionAnalysis(request: EmotionAnalysisRequest) async throws -> EmotionAnalysisResponse {
        guard let url = URL(string: emotionAnalysisURL) else {
            throw URLError(.badURL)
        }
        
        var requestURL = URLRequest(url: url)
        requestURL.httpMethod = "POST"
        requestURL.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            requestURL.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        requestURL.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await session.data(for: requestURL)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(EmotionAnalysisResponse.self, from: data)
    }

    func getUserProfile() async throws -> User {
        guard let url = URL(string: "\(baseURL)/api/users/profile") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        if let payload = try? decoder.decode(UserProfileResponse.self, from: data),
           let user = payload.user {
            return user
        }
        if let user = try? decoder.decode(User.self, from: data) {
            return user
        }
        
        throw URLError(.cannotParseResponse)
    }

    func updateUserProfile(userId: String, email: String, firstName: String, lastName: String) async throws -> User {
        guard let url = URL(string: "\(baseURL)/api/users/profile") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let payload = UserProfileUpdateRequest(userId: userId, email: email, firstName: firstName, lastName: lastName)
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        if let payload = try? decoder.decode(UserProfileResponse.self, from: data),
           let user = payload.user {
            return user
        }
        if let user = try? decoder.decode(User.self, from: data) {
            return user
        }
        
        throw URLError(.cannotParseResponse)
    }
    
    func createReason(title: String, content: String, date: Date) async throws -> ReasonItem {
        guard let url = URL(string: reasonBaseURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let payload = ReasonCreateRequest(
            title: title,
            content: content,
            date: Self.reasonDateFormatter.string(from: date)
        )
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let payloadResponse = try JSONDecoder().decode(ReasonResponse.self, from: data)
        return payloadResponse.reason
    }
    
    func getReasons(includeDeleted: Bool = false) async throws -> [ReasonItem] {
        var components = URLComponents(string: reasonBaseURL)
        if includeDeleted {
            components?.queryItems = [URLQueryItem(name: "includeDeleted", value: "true")]
        }
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let payload = try JSONDecoder().decode(ReasonsResponse.self, from: data)
        return payload.reasons
    }
    
    func getReason(id: String, includeDeleted: Bool = false) async throws -> ReasonItem {
        var components = URLComponents(string: "\(reasonBaseURL)/\(id)")
        if includeDeleted {
            components?.queryItems = [URLQueryItem(name: "includeDeleted", value: "true")]
        }
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let payload = try JSONDecoder().decode(ReasonResponse.self, from: data)
        return payload.reason
    }
    
    func updateReason(id: String, title: String, content: String, date: Date, isDeleted: Bool) async throws -> ReasonItem {
        guard let url = URL(string: "\(reasonBaseURL)/\(id)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let payload = ReasonUpdateRequest(
            title: title,
            content: content,
            date: Self.reasonDateFormatter.string(from: date),
            isDeleted: isDeleted
        )
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let payloadResponse = try JSONDecoder().decode(ReasonResponse.self, from: data)
        return payloadResponse.reason
    }
    
    func deleteReason(id: String) async throws -> ReasonItem {
        guard let url = URL(string: "\(reasonBaseURL)/\(id)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let payloadResponse = try JSONDecoder().decode(ReasonResponse.self, from: data)
        return payloadResponse.reason
    }
}

struct DailyQuestionsResponse: Codable {
    let message: String
    let dailyQuestions: [DailyQuestionEntry]
}

struct DailyQuestionEntry: Codable {
    let physical: Int
    let mental: Int
    let emotion: Int
    let sleep: Int
    let diet: Int
    let userId: String
    let entryDate: String
    
    func toDailyCheckInScores() -> DailyCheckInScores? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: entryDate) else {
            // 如果 ISO8601 解析失敗，嘗試其他格式
            let backupFormatter = DateFormatter()
            backupFormatter.dateFormat = "yyyy-M-dd"
            guard let backupDate = backupFormatter.date(from: entryDate) else {
                print("⚠️ 無法解析日期: \(entryDate)")
                return nil
            }
            return DailyCheckInScores(
                physical: normalizeScore(physical),
                mental: normalizeScore(mental),
                emotional: normalizeScore(emotion),
                sleep: normalizeScore(sleep),
                appetite: normalizeScore(diet),
                date: backupDate
            )
        }
        
        return DailyCheckInScores(
            physical: normalizeScore(physical),
            mental: normalizeScore(mental),
            emotional: normalizeScore(emotion),
            sleep: normalizeScore(sleep),
            appetite: normalizeScore(diet),
            date: date
        )
    }

    private func normalizeScore(_ value: Int) -> Int {
        if value <= 5 {
            return max(1, value)
        }
        switch value {
        case ..<21: return 1
        case ..<41: return 2
        case ..<61: return 3
        case ..<81: return 4
        default: return 5
        }
    }
}

struct ScaleQuestionsResponse: Decodable {
    let message: String
    let scale: ScaleResponse
}

struct ScaleResponse: Decodable {
    let id: String
    let code: String
    let name: String
    let description: String
    let questions: [ScaleQuestionItem]
}

struct ScaleQuestionItem: Decodable {
    let id: String
    let order: Int
    let text: String
    let isReverse: Bool
}

struct ScaleAnswersRequest: Encodable {
    let userId: String
    let answers: [ScaleAnswerPayload]
}

struct ScaleAnswerPayload: Encodable {
    let questionId: String
    let value: Int
}

struct ScaleSessionsResponse: Decodable {
    let message: String
    let scales: [ScaleSessionScale]
}

struct ScaleSessionScale: Decodable, Identifiable {
    let id: String
    let code: String
    let name: String
    let description: String
    let sessions: [ScaleSessionEntry]
}

struct ScaleSessionEntry: Decodable, Identifiable {
    let id: String
    let totalScore: Int
    let createdAt: String
}

struct DiaryEntryCreateRequest: Encodable {
    let content: String
    let mood: String
    let entryDate: String
}

struct DiaryEntryUpdateRequest: Encodable {
    let content: String
    let mood: String
    let entryDate: String
}

struct DiaryEntriesResponse: Decodable {
    let message: String
    let entries: [DiaryEntry]
}

struct DiaryEntryResponse: Decodable {
    let message: String
    let entry: DiaryEntry
}

struct DiaryEntry: Decodable {
    let id: String
    let diaryId: String?
    let userId: String?
    let content: String?
    let mood: String?
    let entryDate: String?
    let createdAt: String?
    let updatedAt: String?
}

struct HealthAdviceRequest: Encodable {
    let range: HealthAdviceRange
    let metrics: HealthAdviceMetrics
}

struct HealthAdviceRange: Encodable {
    let startDate: String
    let endDate: String
}

struct HealthAdviceMetrics: Encodable {
    let hrv: [HealthMetricPoint]
    let sleepHours: [HealthMetricPoint]
    let steps: [HealthMetricPoint]
    let weightKg: [HealthMetricPoint]
}

struct HealthMetricPoint: Encodable {
    let value: Double
    let date: String
}

struct HealthAdviceResponse: Decodable {
    let summary: String
    let items: [HealthAdviceItem]
}

struct HealthAdviceItem: Decodable, Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let severity: String
}

struct EmotionAnalysisRequest: Encodable {
    let range: HealthAdviceRange
    let entries: [EmotionEntryPayload]
}

struct EmotionEntryPayload: Encodable {
    let date: String
    let mood: String
    let content: String
}

struct EmotionAnalysisResponse: Decodable {
    let trend: [EmotionTrendItem]
    let keywords: [String]
    let insight: String
}

struct EmotionTrendItem: Decodable, Identifiable {
    let id = UUID()
    let label: String
    let ratio: Double
}

struct UserProfileResponse: Decodable {
    let message: String?
    let user: User?
}

struct UserProfileUpdateRequest: Encodable {
    let userId: String
    let email: String
    let firstName: String
    let lastName: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case firstName
        case lastName
    }
}

struct ReasonCreateRequest: Encodable {
    let title: String
    let content: String
    let date: String
}

struct ReasonUpdateRequest: Encodable {
    let title: String
    let content: String
    let date: String
    let isDeleted: Bool
}

struct ReasonsResponse: Decodable {
    let message: String
    let reasons: [ReasonItem]
}

struct ReasonResponse: Decodable {
    let message: String
    let reason: ReasonItem
}

struct ReasonItem: Decodable {
    let id: String
    let userId: String
    let title: String
    let content: String
    let date: String
    let isDeleted: Bool
    let createdAt: String
    let updatedAt: String
}
