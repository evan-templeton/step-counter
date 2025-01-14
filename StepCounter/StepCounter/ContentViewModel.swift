//
//  ContentViewModel.swift
//  StepCounter
//
//  Created by Evan Templeton on 1/5/25.
//

import SwiftUI
import class Combine.AnyCancellable

@MainActor
final class ContentViewModel: ObservableObject {
    
    private let stepsService: StepsServiceProtocol
    
    @Published var stepsByHour = [Int]()
    @Published var stepsByDay = [DailyStepsResult]()
    
    @Published var nonFatalError: StepsServiceError?
    @Published var fatalErrorMessage: String?
    
    let timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
    private var timerBag = Set<AnyCancellable>()
    
    var isAuthorized: Bool {
        return stepsService.isAuthorized
    }
    
    init(stepsService: StepsServiceProtocol) {
        self.stepsService = stepsService
        getStepsOnTimerPublish()
    }
    
    private func getStepsOnTimerPublish() {
        self.timer.sink { _ in
            Task {
                await self.getStepsByHour()
            }
        }.store(in: &timerBag)
    }
    
    func requestAuthorization() async {
        nonFatalError = nil
        do {
            try await stepsService.requestAuthorization()
        } catch {
            handleError(error)
        }
    }
    
    func getStepsByHour() async {
        nonFatalError = nil
        do {
            let steps = try await stepsService.fetchStepsByHour()
            stepsByHour = steps
        } catch {
            handleError(error)
        }
    }
    
    func getStepsByDay() async {
        nonFatalError = nil
        do {
            let steps = try await stepsService.fetchStepsForLast30Days()
            stepsByDay = steps
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        if let error = error as? StepsServiceError {
            switch error.severity {
                case .fatal: fatalErrorMessage = error.userMessage
                case .nonFatal: nonFatalError = error
            }
        } else {
            nonFatalError = .unknown
        }
    }
}

