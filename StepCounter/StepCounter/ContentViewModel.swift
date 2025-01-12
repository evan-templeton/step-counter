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
    @Published var errorMessage: String?
    
    let timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
    private var timerBag = Set<AnyCancellable>()
    
    var isAuthorized: Bool {
        return stepsService.isAuthorized
    }
    
    init(stepsService: StepsServiceProtocol) {
        self.stepsService = stepsService
        self.timer.sink { _ in
            Task {
                await self.getSteps()
            }
        }.store(in: &timerBag)
    }
    
    func requestAuthorization() async {
        errorMessage = nil
        do {
            try await stepsService.requestAuthorization()
        } catch {
            handleError(error)
        }
    }
    
    func getSteps() async {
        errorMessage = nil
        do {
            let steps = try await stepsService.fetchStepsByHour()
            stepsByHour = steps
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        if let error = error as? StepsServiceError {
            errorMessage = error.userMessage
        } else {
            errorMessage = "Unknown error"
        }
    }
}
