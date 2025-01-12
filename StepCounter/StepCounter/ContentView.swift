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
        if let errorMessage = viewModel.errorMessage {
            ContentUnavailableView(
                "Something went wrong",
                systemImage: "heart.slash.fill",
                description: Text(errorMessage)
            )
        } else {
            mainView
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
                HistoryView()
                    .tag(Tab.history)
            }
            .task {
                if !viewModel.isAuthorized {
                    await viewModel.requestAuthorization()
                }
                await viewModel.getSteps()
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
    let viewModel = ContentViewModel(stepsService: StepsServiceMock())
    return ContentView(viewModel: viewModel)
}

final class StepsServiceMock: StepsServiceProtocol {
    var isAuthorized: Bool = true
    
    func requestAuthorization() async throws {
        
    }
    
    func fetchStepsByHour() async throws -> [Int] {
        return Array(repeating: 0, count: 20)
    }
    
    func uploadSteps(_ steps: Int) async throws {
        print("Uploaded \(steps) steps")
    }
}
