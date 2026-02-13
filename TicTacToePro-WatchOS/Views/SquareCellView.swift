//
//  SquareCellView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//

import SwiftUI
import Foundation
import Combine



class Square: ObservableObject {
    @Published var squareStatus: SquareStatus
    
    init(status: SquareStatus) {
        self.squareStatus = status
    }
}


struct SquareCellView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var dataSource: Square
    var action: () -> Void?

    @State private var animatePress = false
    @State private var shine = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                animatePress = true
                action()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animatePress = false
            }
        }) {
            ZStack {
                // Glassy Card
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(colorScheme == .dark ? 0.35 : 0.6),
                                        .white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.8
                            )
                    )
                    .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 10)
                    .shadow(color: .white.opacity(colorScheme == .dark ? 0.08 : 0.4), radius: 8, x: -4, y: -4)

                // Symbol with luxury gradient
                Text(symbol)
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundStyle(textGradient)
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 2, y: 2)
                    .scaleEffect(animatePress ? 0.85 : 1.0)
                    .overlay {
                        if isWinning {
                            // Shine sweep
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.6), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .rotationEffect(.degrees(30))
                                .offset(x: shine ? 120 : -120, y: 0)
                                .blendMode(.overlay)
                                .mask(Text(symbol)
                                    .font(.system(size: 60, weight: .black, design: .rounded)))
                                .onAppear {
                                    withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                                        shine.toggle()
                                    }
                                }
                        }
                    }
            }
            .frame(width: 92, height: 92)
            .padding(6)
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: dataSource.squareStatus)
    }

    // MARK: Helpers
    private var symbol: String {
        switch dataSource.squareStatus {
        case .x, .xw: "X"
        case .o, .ow: "O"
        default: " "
        }
    }

    private var textGradient: LinearGradient {
        switch dataSource.squareStatus {
        case .xw, .ow:
            return LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .x:
            return LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .o:
            return LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)], startPoint: .top, endPoint: .bottom)
        }
    }

    private var isWinning: Bool {
        dataSource.squareStatus == .xw || dataSource.squareStatus == .ow
    }
}
