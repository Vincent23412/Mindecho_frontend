import Foundation
import Combine

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "localhost/dev-api/"

    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        self.session = URLSession(configuration: config)
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

    
    func getMetrics() -> AnyPublisher<[APIMetricEntry], Error> {
        guard let user = AuthService.shared.currentUser,
              let token = AuthService.shared.authToken else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var components = URLComponents(string: "\(baseURL)/api/main/getMetrics")
        components?.queryItems = [URLQueryItem(name: "userId", value: user.id)]
        
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
            .decode(type: MetricResponse.self, decoder: JSONDecoder())
            .map { response in
                print("🔄 Decoded metrics from API for date: \(response.metrics.entryDate)")
                return [response.metrics]  // 包裝成數組返回
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// ✅ 保持原來的結構，服務器返回單個對象
struct MetricResponse: Codable {
    let message: String
    let metrics: APIMetricEntry  // 保持單個對象
}

struct APIMetricEntry: Codable {
    let physical: APIMetricValue
    let mood: APIMetricValue
    let sleep: APIMetricValue
    let energy: APIMetricValue
    let appetite: APIMetricValue
    let userId: String
    let entryDate: String
    
    func toDailyCheckInScores() -> DailyCheckInScores? {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: entryDate) else {
            // 如果 ISO8601 解析失敗，嘗試其他格式
            let backupFormatter = DateFormatter()
            backupFormatter.dateFormat = "yyyy-M-dd"
            guard let backupDate = backupFormatter.date(from: entryDate) else {
                print("⚠️ 無法解析日期: \(entryDate)")
                return nil
            }
            return DailyCheckInScores(
                physical: physical.value,
                mental: energy.value,
                emotional: mood.value,
                sleep: sleep.value,
                appetite: appetite.value,
                date: backupDate
            )
        }
        
        return DailyCheckInScores(
            physical: physical.value,
            mental: energy.value,
            emotional: mood.value,
            sleep: sleep.value,
            appetite: appetite.value,
            date: date
        )
    }
}

struct APIMetricValue: Codable {
    let description: String
    let value: Int
}
