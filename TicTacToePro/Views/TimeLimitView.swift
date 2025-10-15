//
//  TimeLimitView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 10/12/25.
//

import SwiftUI
#if os(iOS)
import CoreHaptics
#endif

// MARK: - Time Limit Options
enum TimeLimitOption: Int, CaseIterable, Identifiable {
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case twentyMinutes = 20
    case thirtyMinutes = 30
    case unlimited = 0
    
    var id: Int { rawValue }
    
    var title: String {
        rawValue == 0 ? "Unlimited" : "\(rawValue) min"
    }
    
    var description: String {
        switch self {
        case .fiveMinutes: return "Quick Match"
        case .tenMinutes: return "Standard"
        case .fifteenMinutes: return "Moderate"
        case .twentyMinutes: return "Extended"
        case .thirtyMinutes: return "Long Play"
        case .unlimited: return "No Time Limit"
        }
    }
    
    var emoji: String {
        switch self {
        case .fiveMinutes: return "⚡"
        case .tenMinutes: return "⏱️"
        case .fifteenMinutes: return "⌛"
        case .twentyMinutes: return "⏳"
        case .thirtyMinutes: return "🕰️"
        case .unlimited: return "∞"
        }
    }
    
    var color: Color {
        switch self {
        case .fiveMinutes: return .red
        case .tenMinutes: return .blue
        case .fifteenMinutes: return .purple
        case .twentyMinutes: return .orange
        case .thirtyMinutes: return .green
        case .unlimited: return .cyan
        }
    }
}

struct TimeLimitView: View {
    // MARK: - Properties
    @Binding var selectedTimeLimit: TimeLimitOption
    @Environment(\.colorScheme) private var colorScheme
    
    #if os(iOS)
    @State private var hapticsEngine: CHHapticEngine?
    #endif
    
    @State private var animateIn = false
    
    private let accentGradient = LinearGradient(
        colors: [.pink.opacity(0.9), .purple.opacity(0.9), .blue.opacity(0.9)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 12) {
            // Header
            VStack(spacing: 8) {
                Text("Time Limit")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                Text("Select the duration for your game")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Time Limit Options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TimeLimitOption.allCases) { timeLimit in
                        TimeLimitCard(
                            timeLimit: timeLimit,
                            isSelected: selectedTimeLimit == timeLimit,
                            colorScheme: colorScheme
                        ) {
                            withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                                selectedTimeLimit = timeLimit
                            }
                            #if os(iOS)
                            triggerHaptic()
                            #endif
                        }
                        .scaleEffect(animateIn ? 1 : 0.8)
                        .opacity(animateIn ? 1 : 0)
                        .animation(
                            .spring(duration: 0.5, bounce: 0.4)
                                .delay(Double(timeLimit.rawValue == 0 ? 30 : timeLimit.rawValue - 5) * 0.05),
                            value: animateIn
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            animateIn = true
            #if os(iOS)
            prepareHaptics()
            #endif
        }
    }
    
    // MARK: - Haptics
    #if os(iOS)
    private func prepareHaptics() {
        do {
            hapticsEngine = try CHHapticEngine()
            try hapticsEngine?.start()
        } catch { }
    }
    
    private func triggerHaptic() {
        guard let hapticsEngine else { return }
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [sharpness, intensity], relativeTime: 0)
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticsEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch { }
    }
    #else
    private func triggerHaptic() {}
    #endif
}

// MARK: - Time Limit Card
struct TimeLimitCard: View {
    let timeLimit: TimeLimitOption
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
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
                        .shadow(color: isSelected ? timeLimit.color.opacity(0.5) : .clear, radius: 8)
                    
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
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(white: 0.15) : .white)
                    .shadow(color: isSelected ? timeLimit.color.opacity(0.3) : .black.opacity(0.1), radius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected
                        ? LinearGradient(colors: [timeLimit.color, timeLimit.color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: isSelected ? 2 : 0
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(duration: 0.3, bounce: 0.4), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select \(timeLimit.title) time limit")
    }
}

#Preview {
    TimeLimitView(selectedTimeLimit: .constant(.tenMinutes))
        .environmentObject(AppState())
}
