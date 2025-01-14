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
    func fetchStepsForLast30Days() async throws -> [DailyStepsResult]
}

enum StepsServiceError: Error, Identifiable {
    var id: Int { hashValue }
    
    case healthKitFetchSteps
    case mindwareFetchSteps
    case healthKitDataUnavailable
    case utcTime
    case uploadSteps
    case unknown
    
    var userMessage: String {
        return switch self {
            case .healthKitDataUnavailable: "This device doesn't have access to your health data."
            case .healthKitFetchSteps: "There was an error fetching steps from HealthKit."
            case .mindwareFetchSteps: "There was an error fetching steps from the Mindware API."
            case .utcTime: "There was an error converting current time to UTC."
            case .uploadSteps: "There was an error uploading steps."
            case .unknown: "An unknown error occurred."
        }
    }
}

extension StepsServiceError {
    enum ErrorSeverity {
        case fatal, nonFatal
    }
    
    var severity: ErrorSeverity {
        return switch self {
            case .healthKitDataUnavailable: .fatal
            default: .nonFatal
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

    // MARK: - Fetch steps by hour from HealthKit
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
                    continuation.resume(throwing: StepsServiceError.healthKitFetchSteps)
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
    
    // MARK: - Fetch steps by day from testapi.mindware.us/steps
    func fetchStepsForLast30Days() async throws -> [DailyStepsResult] {
        let token = try await fetchAuthToken()
        let request = try Self.buildFetchRequest(authToken: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse, response.statusCode != 200 {
            let responseString = String(decoding: data, as: UTF8.self)
            debugPrint("Error fetching steps: \(responseString)")
            throw StepsServiceError.mindwareFetchSteps
        }
        let steps = try JSONDecoder().decode([DailyStepsResult].self, from: data)
        return steps.sorted(by: { $0.datetime < $1.datetime })
    }
    
    private func uploadSteps(_ steps: Int) async throws {
        let token = try await fetchAuthToken()
        var request = try Self.buildUploadRequest(authToken: token)
        let datetime = try Self.getDateInUTC()
        let model = StepsRequest(username: "user1@test.com", date: datetime, time: datetime, totalByDay: 0, count: steps)
        request.httpBody = try JSONEncoder().encode(model)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse, response.statusCode != 200 {
            let responseString = String(decoding: data, as: UTF8.self)
            debugPrint("Error uploading steps: \(responseString)")
            return
        }
    }
    
    // MARK: - API Auth
    private func fetchAuthToken() async throws -> String {
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            return token
        }
        let request = try Self.buildFetchAuthTokenRequest()
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)
        let token = response.jwt
        UserDefaults.standard.set(token, forKey: "authToken")
        return token
    }
    
    // MARK: - Request builders
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
    
    private static func buildFetchRequest(authToken: String) throws -> URLRequest {
        guard var urlComponents = URLComponents(string: "https://testapi.mindware.us/steps") else {
            throw URLError(.badURL)
        }
        urlComponents.queryItems = [URLQueryItem(name: "_limit", value: "30")]
        guard let url = urlComponents.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        return request
    }
    
    private static func buildFetchAuthTokenRequest() throws -> URLRequest {
        guard let url = URL(string: "https://testapi.mindware.us/auth/local") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let authData = AuthRequest(identifier: "user1@test.com", password: "Test123!")
        do {
            request.httpBody = try JSONEncoder().encode(authData)
            return request
        } catch {
            throw error
        }
    }
    
    private static func getDateInUTC() throws -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: .gmt, from: Date())
        guard let datetime = calendar.date(from: components) else {
            throw StepsServiceError.utcTime
        }
        return datetime
    }
}
