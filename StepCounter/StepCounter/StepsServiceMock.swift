//
//  StepsServiceMock.swift
//  StepCounter
//
//  Created by Evan Templeton on 1/13/25.
//

import Foundation

final class StepsServiceMock: StepsServiceProtocol {
    var isAuthorized: Bool = true
    
    func requestAuthorization() async throws {
        
    }
    
    func fetchStepsByHour() async throws -> [Int] {
        return Array(repeating: 0, count: 20)
    }
    
    func fetchStepsForLast30Days() async throws -> [DailyStepsResult] {
        return []
    }
    
    func uploadSteps(_ steps: Int) async throws {
        
    }
}
