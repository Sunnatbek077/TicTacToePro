//
//  AboutView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 04/11/2025.
//  Improved & Enhanced on 04/11/2025
//

import SwiftUI

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundGradient: LinearGradient {
        // tvOS-safe colors
        let startColor: Color
        let endColor: Color
        if colorScheme == .dark {
            startColor = Color.black.opacity(0.85)
            endColor = Color.black.opacity(0.65)
        } else {
            startColor = Color.white
            endColor = Color(white: 0.94)
        }
        
        return LinearGradient(
            colors: [startColor, endColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic Background
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // App Icon (Custom Tic-Tac-Toe Grid)
                        ZStack {
                            Circle()
                                .fill(
                                    AngularGradient(
                                        colors: [.pink, .purple, .blue, .pink],
                                        center: .center
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "grid")
                                .font(.system(size: 44, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 32)
                        .accessibilityHidden(true)
                        
                        // App Name & Version
                        VStack(spacing: 4) {
                            Text("Tic Tac Pro")
                                .font(.largeTitle.bold())
                                .foregroundColor(.primary)
                            
                            Text("Version 1.2.2")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Tagline
                        Text("A modern take on the classic game with stunning visuals, multiplayer support, and AI opponents.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .lineSpacing(4)
                        
                        // Features Section
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(features, id: \.title) { feature in
                                FeatureRow(
                                    icon: feature.icon,
                                    title: feature.title,
                                    description: feature.description
                                )
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(.quaternary, lineWidth: 0.5)
                                )
                        )
                        .padding(.horizontal)
                        
                        // Credits
                        VStack(spacing: 8) {
                            Text("Created with passion by")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Sunnatbek")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 20)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("About")
            // Not available on tvOS
            #if !os(tvOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }
    
    // MARK: - Features Data
    private let features = [
        FeatureData(icon: "brain.head.profile", title: "Smart AI", description: "Three difficulty levels"),
        FeatureData(icon: "person.2.fill", title: "Multiplayer", description: "Play with friends online"),
        FeatureData(icon: "square.grid.3x3.fill", title: "Custom Boards", description: "3×3 up to 9×9 grids"),
        FeatureData(icon: "paintbrush.fill", title: "Beautiful Design", description: "Premium UI/UX experience")
    ]
}

// MARK: - Feature Data Model
private struct FeatureData: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - Preview
#Preview {
    AboutView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    AboutView()
        .preferredColorScheme(.dark)
}
