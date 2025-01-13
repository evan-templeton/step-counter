//
//  SelectableButton.swift
//  StepCounter
//
//  Created by Evan Templeton on 1/13/25.
//

import SwiftUI

struct SelectableButton: View {
    let isSelected: Bool
    
    let text: String
    let handler: () -> Void
    
    var body: some View {
        Button {
            handler()
        } label: {
            Text(text)
                .padding(10)
                .frame(maxWidth: .infinity)
                .foregroundColor(isSelected ? .white : .secondary)
                .background {
                    if isSelected {
                        Color.blue
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.thinMaterial)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
