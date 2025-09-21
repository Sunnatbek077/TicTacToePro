//
//  AppState.swift
//  TicTacToePro
//
//  Created by Assistant on 22/09/25.
//

import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var isGameOpen: Bool = false
}
