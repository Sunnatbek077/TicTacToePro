//
//  SettingsView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var enablingSounds: Bool = false
    @State private var enableHapticFeeling: Bool = false
    @State private var enableCharizmaticAI: Bool = true
    
    var body: some View {
        NavigationStack {
            List {
                // Sounds Toggle
                HStack {
                    Image(systemName: enablingSounds ? "speaker.wave.3.fill" : "speaker.slash.fill")
                    Toggle("Enable Sounds", isOn: $enablingSounds)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                // Haptic Toggle
                HStack {
                    Image(systemName: enableHapticFeeling ? "iphone.gen2.radiowaves.left.and.right" : "iphone.gen2.slash")
                    Toggle("Enable Haptic Feeling", isOn: $enableHapticFeeling)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                // Charizmatic AI Toggle
                HStack {
                    Image(systemName: enableCharizmaticAI ? "brain.head.profile" : "brain")
                    Toggle("Enable Charizmatic AI", isOn: $enableCharizmaticAI)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                // NavigationLink
                NavigationLink("About Developer") {
                    VStack {
                        Text("Developer: Your Name")
                            .font(.title2)
                            .padding()
                        Text("This TicTacToe game was created with ❤️ using SwiftUI.")
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
            }
            .navigationTitle("Settings")
            .listStyle(InsetGroupedListStyle())
        }
        
    }
}

#Preview {
    SettingsView()
}
