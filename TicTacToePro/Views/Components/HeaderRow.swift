//
//  HeaderRow.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//

import SwiftUI

struct HeaderRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }
}
