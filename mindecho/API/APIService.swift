import Foundation
import Combine

class APIService: NSObject, ObservableObject, URLSessionDelegate {
    static let shared = APIService()
    
    private let baseURL = "http://localhost/dev-api"

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
