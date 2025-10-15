//
//  SettingsView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("soundsEnabled") private var enablingSounds: Bool = true
    @AppStorage(HapticManager.hapticsEnabledKey) private var enableHapticFeeling: Bool = false
    @AppStorage("charismaticAIEnabled") private var enableCharizmaticAI: Bool = true
    
    // Centralized control for taptic feedback state from Settings
    private func setTapticFeedbackEnabled(_ enabled: Bool) {
        // Persisted via @AppStorage already; ensure runtime manager state matches
        HapticManager.setEnabled(enabled)
        // Provide immediate feedback so user feels the change
        if enabled {
            HapticManager.playNotification(.success, force: true)
        } else {
            // Optionally play a light selection to acknowledge turning it off
            HapticManager.playSelection(force: true)
        }
    }
    
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
                    Toggle(isOn: $enableHapticFeeling) {
                        Text("Enable Haptics")
                    }
                    .onChange(of: enableHapticFeeling) { oldValue, newValue in
                        setTapticFeedbackEnabled(newValue)
                    }
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
            .onAppear {
                setTapticFeedbackEnabled(enableHapticFeeling)
            }
        }
        
    }
}

#Preview {
    SettingsView()
}

