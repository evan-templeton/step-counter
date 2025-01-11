//
//  StepCounterApp.swift
//  StepCounter
//
//  Created by Evan Templeton on 1/2/25.
//

import SwiftUI

@main
struct StepCounterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ContentViewModel(stepsService: StepsService()))
        }
    }
}
