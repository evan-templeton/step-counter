//
//  StepsServiceMock.swift
//  StepCounter
//
//  Created by Evan Templeton on 1/13/25.
//

import Foundation

final class StepsServiceMock: StepsServiceProtocol {
    
    var isAuthorizedOverride = true
    var isAuthorized: Bool {
        return isAuthorizedOverride
    }
    
    var requestAuthorizationShouldThrow = false
    func requestAuthorization() async throws {
        if requestAuthorizationShouldThrow {
            throw StepsServiceError.healthKitDataUnavailable
        }
    }
    
    var fetchStepsByHourShouldThrow = false
    var stepsByHourOverride = [Int]()
    func fetchStepsByHour() async throws -> [Int] {
        if fetchStepsByHourShouldThrow {
            throw StepsServiceError.fetchSteps
        } else {
            return stepsByHourOverride
        }
    }
    
    var fetchStepsByDayShouldThrow = false
    var stepsByDayOverride = [DailyStepsResult]()
    func fetchStepsForLast30Days() async throws -> [DailyStepsResult] {
        if fetchStepsByDayShouldThrow {
            throw StepsServiceError.fetchSteps
        } else {
            return stepsByDayOverride
        }
    }
}
