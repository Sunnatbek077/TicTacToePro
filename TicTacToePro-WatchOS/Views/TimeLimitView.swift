//
//  TimeLimitView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 10/12/25.
//  Refactored for clarity, accessibility & performance.
//

import SwiftUI
#if os(iOS)
import CoreHaptics
#endif


// MARK: - Time Limit View
struct TimeLimitView: View {
    // MARK: Constants
    private let cardWidth: CGFloat = 120
    private let iconSize: CGFloat = 50
    private let springDuration: Double = 0.3
    
    // MARK: Bindings & Environment
    @Binding var selectedTimeLimit: TimeLimitOption
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var animateIn = false
    
    var body: some View {
        VStack(spacing: 12) {
            optionsScrollView
        }
        .padding(.vertical, 8)
        .onAppear {
            animateIn = true
        }
    }
    
    private var optionsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(TimeLimitOption.allCases.enumerated()), id: \.element) { index, option in
                    TimeLimitCard(
                        timeLimit: option,
                        isSelected: selectedTimeLimit == option,
                        colorScheme: colorScheme
                    ) {
                        withAnimation(.spring(duration: springDuration, bounce: 0.4)) {
                            selectedTimeLimit = option
                        }
                        
                    }
                    .opacity(animateIn ? 1 : 0)
                    .scaleEffect(animateIn ? 1 : 0.8)
                    .animation(
                        .spring(duration: 0.5, bounce: 0.4)
                            .delay(Double(index) * 0.05),
                        value: animateIn
                    )
                }
            }
            .padding(.horizontal)
        }
        .accessibilityHint("Swipe horizontally to see more options")
    }
}

// MARK: - Time Limit Card
struct TimeLimitCard: View {
    let timeLimit: TimeLimitOption
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    private let cornerRadius: CGFloat = 16
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected
                                    ? [timeLimit.color.opacity(0.8), timeLimit.color]
                                    : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: isSelected ? timeLimit.color.opacity(0.5) : .clear,
                                radius: 8)
                    
                    Text(timeLimit.emoji)
                        .font(.system(size: 24))
                }
                
                // Title
                Text(timeLimit.title)
                    .font(.body.bold())
                    .foregroundColor(isSelected ? timeLimit.color : .primary)
                
                // Description
                Text(timeLimit.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 120)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .shadow(color: shadowColor, radius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isSelected ? timeLimit.selectionGradient : LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: isSelected ? 2 : 0
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(duration: 0.3, bounce: 0.4), value: isSelected)
        }
        .padding(.vertical)
        .buttonStyle(.plain)
        .contentShape(Rectangle())               // larger tap area
        .accessibilityLabel("\(timeLimit.title), \(timeLimit.description)")
        .accessibilityHint(isSelected ? "Selected" : "Tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : .white
    }
    
    private var shadowColor: Color {
        isSelected ? timeLimit.color.opacity(0.3) : .black.opacity(0.1)
    }
}

// MARK: - Preview
#if DEBUG
struct TimeLimitView_Previews: PreviewProvider {
    static var previews: some View {
        TimeLimitView(selectedTimeLimit: .constant(.tenMinutes))
            .previewLayout(.sizeThatFits)
            .padding()
#if os(iOS)
            .background(Color(uiColor: .systemBackground))
#elseif os(macOS)
            .background(Color(NSColor.windowBackgroundColor))
#else
            .background(Color.clear)
#endif
    }
}
#endif

