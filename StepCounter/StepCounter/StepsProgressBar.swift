//
//  StepsProgressBar.swift
//  StepCounter
//
//  Created by Evan Templeton on 1/6/25.
//

import SwiftUI

struct StepsProgressBar: View {
    let currentSteps: Int
    private let maxSteps = 10000
    
    private var progress: Double {
        Double(currentSteps) / Double(maxSteps)
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.black, lineWidth: 1)
                    .frame(height: 20)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(.blue)
                    .frame(width: CGFloat(progress) * 300, height: 20)
            }
            .frame(width: 300)
            
            Text("\(maxSteps.formatted()) Steps")
                .font(.subheadline)
        }
        .padding()
    }
}
