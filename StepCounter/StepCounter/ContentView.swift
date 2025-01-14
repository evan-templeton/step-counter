//
//  ContentView.swift
//  StepCounter
//
//  Created by Evan Templeton on 1/2/25.
//

import SwiftUI

struct ContentView: View {
    
    @State private var selectedTab: Tab = .today
    
    @ObservedObject private var viewModel: ContentViewModel
    
    init(viewModel: ContentViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        if let fatalErrorMessage = viewModel.fatalErrorMessage {
            ContentUnavailableView(
                "Something went wrong",
                systemImage: "heart.slash.fill",
                description: Text(fatalErrorMessage)
            )
        } else {
            mainView
                .sheet(item: $viewModel.nonFatalError) { error in
                    Text(error.userMessage)
                        .presentationDetents([.medium])
                }
        }
    }
    
    private var mainView: some View {
        VStack {
            Picker("", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.displayValue)
                }
            }
            .pickerStyle(.segmented)
            TabView(selection: $selectedTab) {
                TodayView(stepsByHour: viewModel.stepsByHour, openSettingsTapped: openSettings)
                    .tag(Tab.today)
                HistoryView(thirtyDaySteps: viewModel.stepsByDay, buttonPressed: {
                    Task {
                        await viewModel.getStepsByDay()
                    }
                })
                .tag(Tab.history)
            }
            .task {
                if !viewModel.isAuthorized {
                    await viewModel.requestAuthorization()
                }
                await viewModel.getStepsByHour()
            }
        }
        .padding()
    }
    
    private func openSettings() {
        if let url = URL(string: "App-Prefs:Privacy&path=HEALTH"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }
    }
}

fileprivate enum Tab: CaseIterable {
    case today
    case history
    
    var displayValue: String {
        return switch self {
            case .today: "Today"
            case .history: "History"
        }
    }
}

#Preview {
    let service = StepsServiceMock()
    service.fetchStepsByHourShouldThrow = false
    service.fetchStepsByDayShouldThrow = false
    service.stepsByHourOverride = [1, 2, 3, 4, 5]
    let viewModel = ContentViewModel(stepsService: service)
    return ContentView(viewModel: viewModel)
}
