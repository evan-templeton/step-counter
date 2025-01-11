//
//  TodayView.swift
//  StepCounter
//
//  Created by Evan Templeton on 1/6/25.
//

import SwiftUI
import Charts

struct TodayView: View {
    
    let steps: Int
    let stepsByHour: [Int]
    
    @State private var topContentHeight = 0.0
    
    var body: some View {
        VStack {
            if !stepsByHour.isEmpty {
                Spacer()
                VStack {
                    Text(String(steps))
                        .font(.largeTitle)
                    Text("Steps")
                        .font(.title3)
                        .bold()
                    StepsProgressBar(currentSteps: steps)
                }
                .readSize { topContentHeight = $0.height }
                Spacer()
                stepsByHourChart
                // I prefer self-sizing using dynamic elements/screen size, but some see this as overkill.
                // Hardcoding maxHeight (like below) also works.
//                .frame(maxHeight: 300)
            } else {
                ProgressView("Fetching steps...")
            }
        }
    }
    
    private var stepsByHourChart: some View {
        Chart {
            ForEach(Array(stepsByHour.enumerated()), id: \.0) { index, stepCount in
                let hour = hourForIndex(index)
                BarMark(x: .value("hour", hour), y: .value("steps", stepCount))
            }
        }
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: 6)
        .defaultScrollAnchor(.trailing)
        .frame(maxHeight: topContentHeight * 2)
    }
    
    private func hourForIndex(_ i: Int) -> String {
        let hour = i % 12 == 0 ? 12 : i % 12
        let period = i < 12 ? "AM" : "PM"
        return "\(hour) \(period)"
    }
}

#Preview {
    let viewModel = ContentViewModel(stepsService: StepsServiceMock())
    return ContentView(viewModel: viewModel)
}
