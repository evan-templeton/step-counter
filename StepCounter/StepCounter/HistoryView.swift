//
//  HistoryView.swift
//  StepCounter
//
//  Created by Evan Templeton on 1/6/25.
//

import SwiftUI
import Charts

struct HistoryView: View {
    
    let thirtyDaySteps: [DailyStepsResult]
    
    let buttonPressed: () -> Void
    
    private var sevenDaySteps: [DailyStepsResult] {
        Array(thirtyDaySteps.suffix(7))
    }
    
    @State private var selection: DateRange = .sevenDays
    
    private var selectedSteps: [DailyStepsResult] {
        switch selection {
            case .sevenDays: sevenDaySteps
            case .thirtyDays: thirtyDaySteps
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                ForEach(DateRange.allCases) { range in
                    SelectableButton(isSelected: selection == range, text: range.title) {
                        selection = range
                        buttonPressed()
                    }
                }
            }
            Spacer()
            Chart {
                ForEach(selectedSteps) { item in
                    BarMark(x: .value("day", item.datetime.monthAndDay), y: .value("steps", item.totalSteps))
                }
            }
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 6)
            .defaultScrollAnchor(.trailing)
            .frame(maxHeight: 300)
        }
        .onAppear(perform: buttonPressed)
    }
}

extension HistoryView {
    enum DateRange: CaseIterable, Identifiable {
        case sevenDays, thirtyDays
        
        var id: String { self.title }
        
        var title: String {
            return switch self {
                case .sevenDays: "7 Days"
                case .thirtyDays: "30 Days"
            }
        }
    }
}

#Preview {
    let viewModel = ContentViewModel(stepsService: StepsServiceMock())
    return ContentView(viewModel: viewModel)
}
