//
//  HeaderRow.swift
//  TicTacToePro watchOS
//
//  Created by Sunnatbek on 20/09/25.
//  watchOS compatible
//

import SwiftUI

struct HeaderRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption.weight(.semibold))
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }
}
