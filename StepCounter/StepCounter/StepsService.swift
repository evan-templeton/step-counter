//
//  StepsService.swift
//  StepCounter
//
//  Created by Evan Templeton on 1/5/25.
//

import SwiftUI
import HealthKit

protocol StepsServiceProtocol {
    var isAuthorized: Bool { get }
    func requestAuthorization() async throws
    func fetchStepsByHour() async throws -> [Int]
    func uploadSteps(_ steps: Int) async throws
}

enum StepsServiceError: Error {
    case fetchSteps
    case healthKitDataUnavailable
    case utcTime
    case uploadSteps
    
    var userMessage: String {
        return switch self {
            case .healthKitDataUnavailable:
                "This device doesn't have access to your health data."
            case .fetchSteps:
                "There was an error fetching steps."
            case .utcTime:
                "There was an error getting UTC time"
            case .uploadSteps:
                "There was an error uploading steps."
        }
    }
}

final class StepsService: StepsServiceProtocol {
    
    private let healthStore = HKHealthStore()
    
    var isAuthorized: Bool {
        let status = healthStore.authorizationStatus(for: HKQuantityType(.stepCount))
        return status != .notDetermined
    }
    
    func requestAuthorization() async throws {
        if !HKHealthStore.isHealthDataAvailable() {
            throw StepsServiceError.healthKitDataUnavailable
        } else {
            let status = healthStore.authorizationStatus(for: HKQuantityType(.stepCount))
            if status == .notDetermined {
                try await healthStore.requestAuthorization(toShare: [], read: [HKQuantityType(.stepCount)])
            }
        }
    }

    func fetchStepsByHour() async throws -> [Int] {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let hourlyInterval = DateComponents(hour: 1)
        
        let steps: [Int] = try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: HKQuantityType(.stepCount),
                quantitySamplePredicate: nil,
                options: .cumulativeSum,
                anchorDate: startOfDay,
                intervalComponents: hourlyInterval
            )
            
            query.initialResultsHandler = { _, result, _ in
                var stepsByHour = [Int]()
                
                guard let result else {
                    continuation.resume(throwing: StepsServiceError.fetchSteps)
                    return
                }
                
                result.enumerateStatistics(from: startOfDay, to: now) { statistics, _ in
                    let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    stepsByHour.append(Int(steps))
                }
                
                continuation.resume(returning: stepsByHour)
            }
            
            healthStore.execute(query)
        }
        
        try await uploadSteps(steps.reduce(0, +))
        return steps
    }
    
    func uploadSteps(_ steps: Int) async throws {
        let token = try await fetchAuthToken()
        try await uploadSteps(authToken: token, steps: steps)
    }
    
    private func fetchAuthToken() async throws -> String {
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            return token
        }
        guard let url = URL(string: "https://testapi.mindware.us/auth/local") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let authData = AuthRequest(identifier: "user1@test.com", password: "Test123!")
        do {
            request.httpBody = try JSONEncoder().encode(authData)
        } catch {
            throw error
        }
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)
        let token = response.jwt
        UserDefaults.standard.set(token, forKey: "authToken")
        return token
    }
    
    private func uploadSteps(authToken: String, steps: Int) async throws {
        do {
            var request = try Self.buildUploadRequest(authToken: authToken)
            let datetime = try getDateInUTC()
            let model = StepsRequest(username: "user1@test.com", date: datetime, time: datetime, totalByDay: 0, count: steps)
            request.httpBody = try JSONEncoder().encode(model)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                let responseString = String(decoding: data, as: UTF8.self)
                print("Error uploading steps: \(responseString)")
                return
            }
            print("successfully uploaded steps")
        } catch {
            throw error
        }
    }
    
    private static func buildUploadRequest(authToken: String) throws -> URLRequest {
        guard let url = URL(string: "https://testapi.mindware.us/steps") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    private func getDateInUTC() throws -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: .gmt, from: Date())
        guard let datetime = calendar.date(from: components) else {
            throw StepsServiceError.utcTime
        }
        return datetime
    }
    
    struct AuthRequest: Codable {
        let identifier: String
        let password: String
    }
    
    struct AuthResponse: Codable {
        let jwt: String
    }
    
    struct StepsRequest: Codable {
        let username: String
        let date: Date
        let time: Date
        let totalByDay: Int
        let count: Int
        
        enum CodingKeys: String, CodingKey {
            case username
            case date = "steps_date"
            case time = "steps_datetime"
            case count = "steps_count"
            case totalByDay = "steps_total_by_day"
        }
    }

}
