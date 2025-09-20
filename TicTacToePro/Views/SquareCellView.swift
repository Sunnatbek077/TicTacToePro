//
//  SquareCellView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//

import SwiftUI
import Foundation
import Combine

enum SquareStatus {
    case empty
    case x
    case o
    case xw
    case ow
}

class Square: ObservableObject {
    @Published var squareStatus: SquareStatus
    
    init(status: SquareStatus) {
        self.squareStatus = status
    }
}

struct SquareCellView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var dataSource: Square
    var action : () -> Void?
    var body: some View {
        Button(action: {
            self.action()
        }, label: {
            Text(self.dataSource.squareStatus == .x || self.dataSource.squareStatus == .xw ?
                 "X" : self.dataSource.squareStatus == .o || self.dataSource.squareStatus == .ow ? "O" : " ")
                .font(.system(size: 60))
                .bold()
                .frame(width: 90, height: 90, alignment: .center)
                .background(colorScheme == .dark ? Color.white.opacity(0.3).cornerRadius(10) : Color.gray.opacity(0.3).cornerRadius(10))
                .foregroundColor(self.dataSource.squareStatus == .xw || self.dataSource.squareStatus == .ow ? (Color.green.opacity(0.9)) : (colorScheme == .dark ? Color.white.opacity(0.9) : Color.black.opacity(0.9)))
                .padding(4)
        })
    }
}

#Preview {
    SquareCellView(dataSource: Square(status: .x), action: {})
}
